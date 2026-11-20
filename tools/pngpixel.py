#!/usr/bin/env python3
"""Minimal dependency-free PNG reader for test and parity scripts.

``load(path)`` returns (width, height, bytes_per_pixel, rows); ``px(rows,
bpp, x, y)`` returns one 0xRRGGBB pixel. Supports the 8-bit RGB/RGBA PNGs
written by the runtime framebuffer.

usage: tools/pngpixel.py image.png x y [x2 y2 ...]
"""
import struct
import sys
import zlib


def load(path):
    data = open(path, 'rb').read()
    assert data[:8] == b'\x89PNG\r\n\x1a\n', 'not png'
    pos = 8
    idat = b''
    w = h = bd = ct = None
    while pos < len(data):
        n = struct.unpack('>I', data[pos:pos + 4])[0]
        typ = data[pos + 4:pos + 8]
        chunk = data[pos + 8:pos + 8 + n]
        pos += 12 + n
        if typ == b'IHDR':
            w, h, bd, ct = struct.unpack('>IIBB', chunk[:10])
        elif typ == b'IDAT':
            idat += chunk
        elif typ == b'IEND':
            break
    raw = zlib.decompress(idat)
    bpp = 4 if ct == 6 else 3
    stride = w * bpp
    rows = []
    prev = bytearray(stride)
    i = 0
    for _ in range(h):
        f = raw[i]
        i += 1
        line = bytearray(raw[i:i + stride])
        i += stride
        if f == 1:
            for x in range(bpp, stride):
                line[x] = (line[x] + line[x - bpp]) & 0xff
        elif f == 2:
            for x in range(stride):
                line[x] = (line[x] + prev[x]) & 0xff
        elif f == 3:
            for x in range(stride):
                a = line[x - bpp] if x >= bpp else 0
                line[x] = (line[x] + ((a + prev[x]) >> 1)) & 0xff
        elif f == 4:
            for x in range(stride):
                a = line[x - bpp] if x >= bpp else 0
                b = prev[x]
                c = prev[x - bpp] if x >= bpp else 0
                p = a + b - c
                pa, pb, pc = abs(p - a), abs(p - b), abs(p - c)
                pr = a if (pa <= pb and pa <= pc) else (b if pb <= pc else c)
                line[x] = (line[x] + pr) & 0xff
        rows.append(bytes(line))
        prev = line
    return w, h, bpp, rows


def px(rows, bpp, x, y):
    o = x * bpp
    r = rows[y]
    return (r[o] << 16) | (r[o + 1] << 8) | r[o + 2]


def main():
    path = sys.argv[1]
    w, h, bpp, rows = load(path)
    for k in range(2, len(sys.argv), 2):
        x, y = int(sys.argv[k]), int(sys.argv[k + 1])
        print('%d,%d #%06x' % (x, y, px(rows, bpp, x, y)))


if __name__ == '__main__':
    main()
