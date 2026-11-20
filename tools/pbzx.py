#!/usr/bin/env python3
"""Stream an Apple pbzx payload (flat-package Payload) to standard output.

A pbzx file starts with the magic ``pbzx`` and an eight-byte big-endian
format word (0x1000000 for xz-compressed chunks). It is followed by chunks,
each with two big-endian 64-bit lengths: the decompressed size and the stored
size. When the two lengths are equal the chunk is stored raw; otherwise it is
an xz stream. KDK payloads mix both forms, so both are handled.

usage: python3 tools/pbzx.py Payload | cpio -idm
"""
import lzma
import struct
import sys

BLOCK = 1024 * 1024


def read_exact(stream, count):
    data = stream.read(count)
    if len(data) != count:
        raise SystemExit("pbzx: truncated stream")
    return data


def main(path):
    with open(path, "rb") as stream:
        if stream.read(4) != b"pbzx":
            raise SystemExit("pbzx: bad magic")
        fmt = struct.unpack(">Q", read_exact(stream, 8))[0]
        if fmt != 0x1000000:
            raise SystemExit("pbzx: unsupported format word %#x" % fmt)
        out = sys.stdout.buffer
        chunks = 0
        while True:
            header = stream.read(16)
            if not header:
                break
            if len(header) != 16:
                raise SystemExit("pbzx: truncated chunk header")
            out_len, in_len = struct.unpack(">QQ", header)
            if in_len == out_len:
                remaining = in_len
                while remaining:
                    block = read_exact(stream, min(remaining, BLOCK))
                    out.write(block)
                    remaining -= len(block)
                chunks += 1
                continue
            decomp = lzma.LZMADecompressor()
            remaining = in_len
            written = 0
            while remaining:
                block = read_exact(stream, min(remaining, BLOCK))
                remaining -= len(block)
                data = decomp.decompress(block)
                out.write(data)
                written += len(data)
            if written != out_len:
                raise SystemExit("pbzx: chunk %d is %d bytes, expected %d"
                                 % (chunks, written, out_len))
            chunks += 1
        out.flush()
        print("pbzx: %d chunks" % chunks, file=sys.stderr)


if __name__ == "__main__":
    if len(sys.argv) != 2:
        raise SystemExit("usage: tools/pbzx.py PAYLOAD")
    main(sys.argv[1])
