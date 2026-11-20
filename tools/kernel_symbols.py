#!/usr/bin/env python3
"""Symbolicate Darwin Mach-O images and decode XNU dispatch tables.

The tool reads a Mach-O image and, when given one, its dSYM companion. The
dSYM supplies local text symbols that release kernels do not export; the two
symbol tables are merged so lookups cover every function. It can:

  * print a complete address-ordered symbol map (--write-map),
  * symbolize arbitrary addresses with function-relative offsets
    (--symbolize, or --stdin),
  * resolve DWARF source file/line for an address (--source),
  * decode the x86_64 XNU mach trap table (--mach-traps) and BSD syscall
    table (--syscalls) into handler symbols and argument counts,
  * summarize the image and tables (--summary).

Only the Python standard library is needed; --source uses llvm-dwarfdump
when it is installed.
"""

import argparse
import bisect
import json
import os
import re
import struct
import subprocess
import sys

MH_MAGIC_64 = 0xFEEDFACF
MH_CIGAM_64 = 0xCFFAEDFE
MH_MAGIC = 0xFEEDFACE
MH_CIGAM = 0xCEFAEDFE
LC_SEGMENT_64 = 0x19
LC_SEGMENT = 0x01
LC_SYMTAB = 0x02
LC_UUID = 0x1B
N_STAB = 0xE0
N_TYPE = 0x0E
N_UNDF = 0x00
N_ABS = 0x02
N_SECT = 0x0E
N_EXT = 0x01
S_ATTR_PURE_INSTRUCTIONS = 0x80000000
S_ATTR_SOME_INSTRUCTIONS = 0x00000400
TEXT_SECTION_NAMES = {
    "__text", "__stubs", "__auth_stubs", "__stub_helper", "__init_text",
    "__text_exec", "__text_startup",
}


class MachOError(Exception):
    pass


class Section:
    __slots__ = ("sectname", "segname", "addr", "size", "offset", "flags")

    def __init__(self, sectname, segname, addr, size, offset, flags):
        self.sectname = sectname
        self.segname = segname
        self.addr = addr
        self.size = size
        self.offset = offset
        self.flags = flags

    @property
    def executable(self):
        return (bool(self.flags & S_ATTR_PURE_INSTRUCTIONS)
                or bool(self.flags & S_ATTR_SOME_INSTRUCTIONS)
                or self.sectname in TEXT_SECTION_NAMES)

    def __repr__(self):
        return "%s,%s" % (self.segname, self.sectname)


class Segment:
    __slots__ = ("name", "vmaddr", "vmsize", "fileoff", "filesize")

    def __init__(self, name, vmaddr, vmsize, fileoff, filesize):
        self.name = name
        self.vmaddr = vmaddr
        self.vmsize = vmsize
        self.fileoff = fileoff
        self.filesize = filesize


class Symbol:
    __slots__ = ("addr", "name", "kind", "section", "end")

    def __init__(self, addr, name, kind, section):
        self.addr = addr
        self.name = name
        self.kind = kind
        self.section = section
        self.end = None

    def __repr__(self):
        return "%#x %s %s" % (self.addr, self.kind, self.name)


def _kind_for(section, external):
    if section is None:
        return "A"
    if section.executable:
        return "T" if external else "t"
    name = section.sectname
    if "bss" in name:
        return "B" if external else "b"
    if "data" in name or "common" in name:
        return "D" if external else "d"
    if "const" in name or "cstring" in name or "literal" in name:
        return "S" if external else "s"
    return "S" if external else "s"


class MachO:
    def __init__(self, path):
        self.path = path
        with open(path, "rb") as f:
            self.data = f.read()
        self.sections = []
        self.segments = []
        self.symbols = []
        self.uuid = None
        self.cputype = None
        self.filetype = None
        self._parse()

    def _parse(self):
        data = self.data
        if len(data) < 32:
            raise MachOError("%s: file too short" % self.path)
        magic = struct.unpack("<I", data[:4])[0]
        if magic == MH_MAGIC_64:
            self.endian = "<"
            self.is64 = True
        elif magic == MH_CIGAM_64:
            self.endian = ">"
            self.is64 = True
        elif magic == MH_MAGIC:
            self.endian = "<"
            self.is64 = False
        elif magic == MH_CIGAM:
            self.endian = ">"
            self.is64 = False
        else:
            raise MachOError("%s: not a Mach-O image" % self.path)
        e = self.endian
        if self.is64:
            (_, self.cputype, _, self.filetype, ncmds, _, _, _) = \
                struct.unpack(e + "IiiIIIII", data[:32])
        else:
            (_, self.cputype, _, self.filetype, ncmds, _, _) = \
                struct.unpack(e + "IiiIIII", data[:28])
        off = 32 if self.is64 else 28
        symtab = None
        for _ in range(ncmds):
            if off + 8 > len(data):
                raise MachOError("%s: truncated load command" % self.path)
            cmd, cmdsize = struct.unpack(e + "II", data[off:off + 8])
            if cmdsize < 8 or off + cmdsize > len(data):
                raise MachOError("%s: bad load command size" % self.path)
            if cmd == LC_SEGMENT_64:
                (segname, vmaddr, vmsize, fileoff, filesize, _, _, nsects,
                 _) = struct.unpack(e + "16sQQQQIIII",
                                    data[off + 8:off + 72])
                name = segname.split(b"\0", 1)[0].decode("utf-8", "replace")
                self.segments.append(
                    Segment(name, vmaddr, vmsize, fileoff, filesize))
                so = off + 72
                for _ in range(nsects):
                    raw = data[so:so + 80]
                    (sectname, sgname, addr, size, foff, _, _, _, flags, _,
                     _, _) = struct.unpack(e + "16s16sQQIIIIIIII", raw)
                    self.sections.append(Section(
                        sectname.split(b"\0", 1)[0].decode("utf-8", "replace"),
                        sgname.split(b"\0", 1)[0].decode("utf-8", "replace"),
                        addr, size, foff, flags))
                    so += 80
            elif cmd == LC_SEGMENT:
                (segname, vmaddr, vmsize, fileoff, filesize, _, _, nsects,
                 _) = struct.unpack(e + "16sIIIIIIII",
                                    data[off + 8:off + 72])
                name = segname.split(b"\0", 1)[0].decode("utf-8", "replace")
                self.segments.append(
                    Segment(name, vmaddr, vmsize, fileoff, filesize))
                so = off + 72
                for _ in range(nsects):
                    (sectname, sgname, addr, size, foff, _, _, _, flags, _,
                     _, _) = struct.unpack(e + "16s16sIIIIIIII",
                                           data[so:so + 68])
                    self.sections.append(Section(
                        sectname.split(b"\0", 1)[0].decode("utf-8", "replace"),
                        sgname.split(b"\0", 1)[0].decode("utf-8", "replace"),
                        addr, size, foff, flags))
                    so += 68
            elif cmd == LC_SYMTAB:
                symtab = struct.unpack(e + "IIII", data[off + 8:off + 24])
            elif cmd == LC_UUID:
                self.uuid = data[off + 8:off + 24].hex()
            off += cmdsize
        if symtab:
            self._read_symtab(*symtab)

    def _read_symtab(self, symoff, nsyms, stroff, strsize):
        data = self.data
        e = self.endian
        strtab = data[stroff:stroff + strsize]
        for i in range(nsyms):
            base = symoff + i * (16 if self.is64 else 12)
            if base + (16 if self.is64 else 12) > len(data):
                break
            if self.is64:
                strx, ntype, nsect, _, value = struct.unpack(
                    e + "IBBHQ", data[base:base + 16])
            else:
                strx, ntype, nsect, _, value = struct.unpack(
                    e + "IBBHI", data[base:base + 12])
            if ntype & N_STAB:
                continue
            if (ntype & N_TYPE) == N_UNDF and value == 0:
                continue
            if strx >= len(strtab):
                continue
            name = strtab[strx:].split(b"\0", 1)[0].decode(
                "utf-8", "replace")
            section = None
            if (ntype & N_TYPE) == N_SECT and 1 <= nsect <= len(self.sections):
                section = self.sections[nsect - 1]
            kind = _kind_for(section, bool(ntype & N_EXT))
            self.symbols.append(Symbol(value, name, kind, section))

    def read_vm(self, addr, size):
        for seg in self.segments:
            if seg.vmaddr <= addr and addr + size <= seg.vmaddr + seg.vmsize:
                off = seg.fileoff + (addr - seg.vmaddr)
                if off + size > len(self.data):
                    return None
                return self.data[off:off + size]
        return None

    def read_u32(self, addr):
        raw = self.read_vm(addr, 4)
        return None if raw is None else struct.unpack(self.endian + "I",
                                                      raw)[0]

    def section_for(self, addr):
        for section in self.sections:
            if section.addr <= addr < section.addr + section.size:
                return section
        return None


class SymbolIndex:
    """Merged symbol table with address-range lookup for text symbols."""

    def __init__(self, images):
        merged = {}
        for image in images:
            for sym in image.symbols:
                merged.setdefault((sym.addr, sym.name), sym)
        self.all_symbols = sorted(merged.values(),
                                  key=lambda s: (s.addr, s.name))
        texts = [s for s in self.all_symbols if s.kind in "Tt"]
        # Symbols in one section are contiguous enough that the next symbol's
        # address bounds the current one; the section end bounds the last.
        self.text_symbols = sorted(texts, key=lambda s: s.addr)
        self.by_name = {}
        for sym in self.all_symbols:
            self.by_name.setdefault(sym.name, sym)
        self._finish_ranges()

    def _finish_ranges(self):
        text = self.text_symbols
        for i, sym in enumerate(text):
            end = None
            if i + 1 < len(text) and text[i + 1].addr > sym.addr:
                end = text[i + 1].addr
            if sym.section is not None:
                section_end = sym.section.addr + sym.section.size
                if end is None or end > section_end:
                    end = section_end
            sym.end = end if end is not None and end > sym.addr else None
        self._starts = [s.addr for s in text]

    def find(self, name):
        sym = self.by_name.get(name)
        if sym is None and name.startswith("_"):
            sym = self.by_name.get(name[1:])
        if sym is None and not name.startswith("_"):
            sym = self.by_name.get("_" + name)
        return sym

    def lookup(self, addr):
        i = bisect.bisect_right(self._starts, addr) - 1
        if i < 0:
            return None
        sym = self.text_symbols[i]
        if sym.end is not None and addr >= sym.end:
            return None
        return sym

    def write_map(self, path):
        with open(path, "w", encoding="utf-8") as f:
            for sym in self.all_symbols:
                f.write("%016x %s %s\n" % (sym.addr, sym.kind, sym.name))

    def coverage(self, macho):
        """Union of symbolized text ranges against executable section size."""
        total = 0
        covered = 0
        missing = []
        for section in macho.sections:
            if not section.executable or not section.size:
                continue
            total += section.size
            spans = []
            for sym in self.text_symbols:
                if sym.section is not section or sym.end is None:
                    continue
                start = max(sym.addr, section.addr)
                end = min(sym.end, section.addr + section.size)
                if end > start:
                    spans.append((start, end))
            spans.sort()
            merged = []
            for start, end in spans:
                if merged and start <= merged[-1][1]:
                    if end > merged[-1][1]:
                        merged[-1][1] = end
                else:
                    merged.append([start, end])
            section_covered = sum(end - start for start, end in merged)
            covered += section_covered
            if section_covered < section.size:
                missing.append({
                    "section": str(section),
                    "size": section.size,
                    "uncovered": section.size - section_covered,
                })
        return {
            "executable_bytes": total,
            "symbolized_bytes": covered,
            "percent": round(100.0 * covered / total, 3) if total else 0.0,
            "gaps": missing,
        }


def _table_layout(index, macho, base, count, layouts):
    """Pick the entry layout whose function pointers resolve to text symbols."""
    best = None
    for layout in layouts:
        stride, func_off = layout[0], layout[1]
        raw = macho.read_vm(base, stride * count)
        if raw is None:
            continue
        resolved = 0
        for i in range(count):
            word = struct.unpack_from("<Q", raw, i * stride + func_off)[0]
            if index.lookup(word):
                resolved += 1
        if best is None or resolved > best[0]:
            best = (resolved,) + tuple(layout)
    return best


MACH_TRAP_LAYOUTS = [
    # XNU 27 x86_64: [arg info, handler, argument munge]
    (24, 8, 0, 16),
    # classic: [handler, arg bits]
    (16, 0, 8, None),
]

SYSENT_LAYOUTS = [
    # XNU 27 x86_64: sy_call, sy_arg_munge32, return type/narg/arg bytes
    (24, 0, 8),
    (32, 0, 8),
    (32, 0, None),
]


def decode_mach_traps(macho, index):
    table = index.find("_mach_trap_table") or index.find("mach_trap_table")
    if table is None:
        raise MachOError("no _mach_trap_table symbol")
    counter = index.find("_mach_trap_count")
    count = 128
    if counter is not None:
        value = macho.read_u32(counter.addr)
        if value:
            count = value
    layout = _table_layout(index, macho, table.addr, count, MACH_TRAP_LAYOUTS)
    if layout is None or layout[0] == 0:
        raise MachOError("cannot decode _mach_trap_table layout")
    resolved, stride, func_off, info_off, aux_off = layout
    traps = []
    for i in range(count):
        entry = macho.read_vm(table.addr + i * stride, stride)
        if entry is None:
            break
        func = struct.unpack_from("<Q", entry, func_off)[0]
        info = struct.unpack_from("<Q", entry, info_off)[0] if info_off is not None else 0
        aux = struct.unpack_from("<Q", entry, aux_off)[0] if aux_off is not None else 0
        sym = index.lookup(func)
        traps.append({
            "index": i,
            "function": func,
            "name": sym.name if sym else None,
            "offset": func - sym.addr if sym else None,
            "arg_info": info,
            "arg_count": info & 0xFF,
            "munge": aux if aux else None,
            "munge_name": index.lookup(aux).name if aux and index.lookup(aux) else None,
        })
    return {"count": count, "layout": {"stride": stride,
                                       "function_offset": func_off,
                                       "info_offset": info_off,
                                       "aux_offset": aux_off},
            "resolved": resolved, "traps": traps}


def decode_syscalls(macho, index):
    table = index.find("_sysent") or index.find("sysent")
    if table is None:
        raise MachOError("no _sysent symbol")
    counter = index.find("_nsysent")
    count = macho.read_u32(counter.addr) if counter is not None else None
    if not count:
        raise MachOError("no _nsysent value")
    layout = _table_layout(index, macho, table.addr, count, SYSENT_LAYOUTS)
    if layout is None or layout[0] == 0:
        raise MachOError("cannot decode _sysent layout")
    resolved, stride, func_off, munge_off = layout
    entries = []
    for i in range(count):
        entry = macho.read_vm(table.addr + i * stride, stride)
        if entry is None:
            break
        call = struct.unpack_from("<Q", entry, func_off)[0]
        munge = (struct.unpack_from("<Q", entry, munge_off)[0]
                 if munge_off is not None else 0)
        ret_type = narg = arg_bytes = None
        if stride == 24:
            ret_type = struct.unpack_from("<I", entry, 16)[0]
            narg = struct.unpack_from("<h", entry, 20)[0]
            arg_bytes = struct.unpack_from("<h", entry, 22)[0]
        sym = index.lookup(call)
        msym = index.lookup(munge) if munge else None
        entries.append({
            "index": i,
            "function": call,
            "name": sym.name if sym else None,
            "offset": call - sym.addr if sym else None,
            "munge": munge if munge else None,
            "munge_name": msym.name if msym else None,
            "return_type": ret_type,
            "narg": narg,
            "arg_bytes": arg_bytes,
        })
    return {"count": count, "layout": {"stride": stride,
                                       "function_offset": func_off,
                                       "munge_offset": munge_off},
            "resolved": resolved, "syscalls": entries}


def _dwarf_lookup(dsym_path, addr):
    tool = os.environ.get("LLVM_DWARFDUMP", "llvm-dwarfdump")
    try:
        proc = subprocess.run(
            [tool, "--debug-info", "--lookup=0x%x" % addr, dsym_path],
            capture_output=True, text=True, timeout=120)
    except (OSError, subprocess.TimeoutExpired):
        return None
    blocks = re.split(r"\n(?=0x[0-9a-f]+:\s+DW_TAG_)", proc.stdout)
    best = None
    line_info = None
    m = re.search(r"Line info: file '([^']*)', line (\d+)", proc.stdout)
    if m:
        line_info = (m.group(1), int(m.group(2)))
    for block in blocks:
        m = re.match(r"0x[0-9a-f]+:\s+DW_TAG_(\w+)", block)
        if not m or m.group(1) not in ("subprogram", "inlined_subroutine"):
            continue
        low = re.search(r"DW_AT_low_pc\s+\((0x[0-9a-f]+)\)", block)
        high = re.search(r"DW_AT_high_pc\s+\(([^)]+)\)", block)
        name = re.search(r'DW_AT_name\s+\("([^"]+)"\)', block)
        decl = re.search(r'DW_AT_decl_file\s+\("([^"]+)"\)', block)
        line = re.search(r"DW_AT_decl_line\s+\((\d+)\)", block)
        if not low or not name:
            continue
        low_pc = int(low.group(1), 16)
        high_pc = None
        if high:
            text = high.group(1)
            try:
                value = int(text, 0)
            except ValueError:
                value = None
            if value is not None:
                high_pc = value if text.lower().startswith("0x") else low_pc + value
        if addr < low_pc or (high_pc is not None and addr >= high_pc):
            continue
        span = (high_pc - low_pc) if high_pc is not None else (1 << 62)
        if best is None or span < best[0]:
            best = (span, m.group(1), name.group(1), decl.group(1) if decl else None,
                    int(line.group(1)) if line else None)
    if best is None:
        return None
    location = line_info or (best[3], best[4])
    return {"tag": best[1], "name": best[2],
            "file": os.path.basename(location[0]) if location[0] else None,
            "line": location[1]}


def format_hit(index, addr):
    sym = index.lookup(addr)
    if sym is None:
        return "0x%016x  ??" % addr
    offset = addr - sym.addr
    where = str(sym.section) if sym.section else "?"
    if offset:
        return "0x%016x  %s + %#x  [%s]" % (addr, sym.name, offset, where)
    return "0x%016x  %s  [%s]" % (addr, sym.name, where)


def parse_address(text):
    text = text.strip()
    if not text:
        return None
    return int(text, 0 if text.lower().startswith("0x") else 16)


def main(argv=None):
    parser = argparse.ArgumentParser(
        description="Symbolicate a Mach-O image/dSYM and decode XNU tables")
    parser.add_argument("--binary", required=True,
                        help="Mach-O executable, dylib or kernel")
    parser.add_argument("--dsym",
                        help="dSYM Mach-O (Contents/Resources/DWARF/...)")
    parser.add_argument("--symbolize", nargs="*", default=[],
                        metavar="ADDR", help="addresses to symbolize")
    parser.add_argument("--stdin", action="store_true",
                        help="read addresses from standard input")
    parser.add_argument("--source", action="store_true",
                        help="add DWARF file:line for symbolized addresses")
    parser.add_argument("--write-map", metavar="FILE",
                        help="write the full address-ordered symbol table")
    parser.add_argument("--mach-traps", action="store_true",
                        help="decode _mach_trap_table")
    parser.add_argument("--syscalls", action="store_true",
                        help="decode _sysent")
    parser.add_argument("--limit", type=int, default=0,
                        help="limit table rows printed (0 = all)")
    parser.add_argument("--json", action="store_true",
                        help="print table/result data as JSON")
    parser.add_argument("--summary", action="store_true",
                        help="print image summary")
    args = parser.parse_args(argv)

    try:
        image = MachO(args.binary)
        images = [image]
        dsym = None
        if args.dsym:
            dsym = MachO(args.dsym)
            images.append(dsym)
        index = SymbolIndex(images)
    except (OSError, MachOError) as exc:
        print("kernel_symbols: %s" % exc, file=sys.stderr)
        return 1

    if args.write_map:
        index.write_map(args.write_map)

    addresses = []
    for text in args.symbolize:
        value = parse_address(text)
        if value is not None:
            addresses.append(value)
    if args.stdin:
        for line in sys.stdin:
            value = parse_address(line)
            if value is not None:
                addresses.append(value)

    result = {}
    if args.summary:
        coverage = index.coverage(image)
        summary = {
            "path": args.binary,
            "dsym": args.dsym,
            "uuid": image.uuid,
            "cputype": image.cputype,
            "filetype": image.filetype,
            "segments": len(image.segments),
            "sections": len(image.sections),
            "symbols_binary": len(image.symbols),
            "symbols_dsym": len(dsym.symbols) if dsym else 0,
            "symbols_merged": len(index.all_symbols),
            "text_symbols": len(index.text_symbols),
            "text_coverage_percent": coverage["percent"],
            "text_coverage_bytes": coverage["symbolized_bytes"],
            "text_bytes": coverage["executable_bytes"],
        }
        result["summary"] = summary
        if not args.json:
            print("image         %s" % summary["path"])
            print("uuid          %s" % (summary["uuid"] or "?"))
            print("cputype       %d" % summary["cputype"])
            print("symbols       %d binary, %d dSYM, %d merged, %d text"
                  % (summary["symbols_binary"], summary["symbols_dsym"],
                     summary["symbols_merged"], summary["text_symbols"]))
            print("text coverage %.3f%% (%d/%d bytes)"
                  % (summary["text_coverage_percent"],
                     summary["text_coverage_bytes"], summary["text_bytes"]))

    if addresses:
        hits = []
        for addr in addresses:
            hit = {"address": addr, "symbol": None, "offset": None,
                   "text": format_hit(index, addr)}
            sym = index.lookup(addr)
            if sym is not None:
                hit["symbol"] = sym.name
                hit["offset"] = addr - sym.addr
            if args.source and dsym is not None:
                hit["source"] = _dwarf_lookup(args.dsym, addr)
            hits.append(hit)
            if not args.json:
                print(hit["text"])
                source = hit.get("source")
                if source:
                    location = source["file"] or "?"
                    if source["line"]:
                        location += ":%d" % source["line"]
                    print("    at %s (%s)" % (location, source["name"]))
        result["addresses"] = hits

    if args.mach_traps:
        try:
            data = decode_mach_traps(image, index)
        except MachOError as exc:
            print("kernel_symbols: %s" % exc, file=sys.stderr)
            return 1
        result["mach_traps"] = data
        if not args.json:
            print("mach traps: %d entries, layout stride %d, handler@+%d, "
                  "arg info@+%d" % (data["count"], data["layout"]["stride"],
                                    data["layout"]["function_offset"],
                                    data["layout"]["info_offset"]))
            rows = data["traps"]
            if args.limit:
                rows = rows[:args.limit]
            for row in rows:
                name = row["name"] or "0x%x" % row["function"]
                extra = ""
                if row["munge_name"]:
                    extra = "  munge=%s" % row["munge_name"]
                print("%3d  %-46s args=%d%s"
                      % (row["index"], name, row["arg_count"], extra))

    if args.syscalls:
        try:
            data = decode_syscalls(image, index)
        except MachOError as exc:
            print("kernel_symbols: %s" % exc, file=sys.stderr)
            return 1
        result["syscalls"] = data
        if not args.json:
            print("syscalls: %d entries, layout stride %d, call@+%d"
                  % (data["count"], data["layout"]["stride"],
                     data["layout"]["function_offset"]))
            rows = data["syscalls"]
            if args.limit:
                rows = rows[:args.limit]
            for row in rows:
                name = row["name"] or "0x%x" % row["function"]
                munge = row["munge_name"] or "-"
                print("%3d  %-28s narg=%s  %s"
                      % (row["index"], name, row["narg"], munge))

    if args.json:
        print(json.dumps(result, indent=2))
    return 0


if __name__ == "__main__":
    sys.exit(main())
