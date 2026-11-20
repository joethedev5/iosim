#!/usr/bin/env python3
"""Generate frameworks/shell_wallpaper.h from a SpringBoard capture.

The wallpaper is reconstructed as a coarse color field: the capture is
sampled on a 48 x 104 grid, UI regions (icons, labels, dock, search pill,
status bar) are excluded, and the holes are filled by diffusion from the
surrounding wallpaper. The runtime upsamples this grid bilinearly. This is
a measured reconstruction, not a copy of the original image asset.

usage: tools/gen_wallpaper.py build/springboard-real.png
"""
import sys
import os

sys.path.insert(0, os.path.join(os.path.dirname(__file__), "..", "build"))
import pixel  # noqa: E402

GW, GH = 48, 104


def main():
    path = sys.argv[1]
    w, h, bpp, rows = pixel.load(path)
    px = lambda x, y: pixel.px(rows, bpp, x, y)  # noqa: E731

    cols = [62.17, 154.72, 247.28, 339.83]        # pt, measured
    row_tops = [120, 220.33, 320.67, 421]          # pt, icon centers - 32
    masks = []
    label_boxes = []
    for cy_pt in (121.83, 222.17, 322.5, 422.83):
        for cx_pt in cols:
            cx = cx_pt * 3
            cy = cy_pt * 3
            masks.append((cx - 99, cy - 99, cx + 99, cy + 99))       # icon
            # Label glyphs are masked per pixel below; the shadowed
            # background stays in the field so the redrawn text sits on it.
            label_boxes.append((cx - 112, cy + 110, cx + 112, cy + 152))
    masks.append((30, 2250, 1176, 2570))    # dock
    masks.append((460, 2120, 745, 2245))    # search pill
    masks.append((60, 30, 320, 150))        # clock
    masks.append((740, 30, 1130, 150))      # status icons

    def masked(x, y):
        for x0, y0, x1, y1 in masks:
            if x0 <= x < x1 and y0 <= y < y1:
                return True
        for x0, y0, x1, y1 in label_boxes:
            if x0 <= x < x1 and y0 <= y < y1:
                c = px(x, y)
                if (c >> 16 & 255) > 232 and (c >> 8 & 255) > 232 and \
                   (c & 255) > 232:
                    return True
        return False

    grid = []
    known = []
    for gy in range(GH):
        for gx in range(GW):
            x0 = gx * w // GW
            x1 = (gx + 1) * w // GW
            y0 = gy * h // GH
            y1 = (gy + 1) * h // GH
            r = g = b = n = 0
            for y in range(y0, y1, 3):
                for x in range(x0, x1, 3):
                    if masked(x, y):
                        continue
                    c = px(x, y)
                    r += (c >> 16) & 255
                    g += (c >> 8) & 255
                    b += c & 255
                    n += 1
            if n:
                grid.append((r // n, g // n, b // n))
                known.append(True)
            else:
                grid.append((0, 0, 0))
                known.append(False)

    # Fill UI holes by diffusing neighbouring wallpaper cells.
    for _ in range(240):
        changed = 0
        for gy in range(GH):
            for gx in range(GW):
                i = gy * GW + gx
                if known[i]:
                    continue
                rs = gs = bs = n = 0
                for dy in (-1, 0, 1):
                    for dx in (-1, 0, 1):
                        nx, ny = gx + dx, gy + dy
                        if 0 <= nx < GW and 0 <= ny < GH:
                            j = ny * GW + nx
                            rs += grid[j][0]
                            gs += grid[j][1]
                            bs += grid[j][2]
                            n += 1
                if n:
                    grid[i] = (rs // n, gs // n, bs // n)
                    changed += 1
        if not changed:
            break

    def sample_field(box, gw, gh, skip):
        x0, y0, x1, y1 = box
        cells = []
        known = []
        for gy in range(gh):
            for gx in range(gw):
                cx0 = x0 + gx * (x1 - x0) // gw
                cx1 = x0 + (gx + 1) * (x1 - x0) // gw
                cy0 = y0 + gy * (y1 - y0) // gh
                cy1 = y0 + (gy + 1) * (y1 - y0) // gh
                r = g = b = n = 0
                for y in range(cy0, cy1, 2):
                    for x in range(cx0, cx1, 2):
                        if skip(x, y):
                            continue
                        c = px(x, y)
                        r += (c >> 16) & 255
                        g += (c >> 8) & 255
                        b += c & 255
                        n += 1
                if n:
                    cells.append((r // n, g // n, b // n))
                    known.append(True)
                else:
                    cells.append((0, 0, 0))
                    known.append(False)
        for _ in range(80):
            changed = 0
            for gy in range(gh):
                for gx in range(gw):
                    i = gy * gw + gx
                    if known[i]:
                        continue
                    rs = gs = bs = n = 0
                    for dy in (-1, 0, 1):
                        for dx in (-1, 0, 1):
                            nx, ny = gx + dx, gy + dy
                            if 0 <= nx < gw and 0 <= ny < gh:
                                j = ny * gw + nx
                                rs += cells[j][0]
                                gs += cells[j][1]
                                bs += cells[j][2]
                                n += 1
                    if n:
                        cells[i] = (rs // n, gs // n, bs // n)
                        changed += 1
            if not changed:
                break
        return cells

    def in_icon(x, y):
        for cx, cy in ((461, 2456), (744, 2456)):
            if abs(x - cx) < 104 and abs(y - cy) < 104:
                return True
        return False

    def search_skip(x, y):
        c = px(x, y)
        return ((c >> 16) & 255) > 175 and ((c >> 8) & 255) > 175 and \
               (c & 255) > 175

    dock = sample_field((54, 2284, 1152, 2551), 8, 3, in_icon)
    search = sample_field((493, 2112, 712, 2199), 4, 2, search_skip)

    out = os.path.join(os.path.dirname(__file__), "..", "frameworks",
                       "shell_wallpaper.h")
    with open(out, "w") as f:
        f.write("/* Generated by tools/gen_wallpaper.py from a sampled\n"
                " * SpringBoard capture: a 48 x 104 color field with UI\n"
                " * regions excluded and filled by diffusion. */\n")
        f.write("#ifndef IOSIM_SHELL_WALLPAPER_H\n#define IOSIM_SHELL_WALLPAPER_H\n")
        f.write("#define SHELL_WALLPAPER_W %d\n" % GW)
        f.write("#define SHELL_WALLPAPER_H %d\n" % GH)
        f.write("static const unsigned shell_wallpaper_grid[%d] = {\n" % (GW * GH))
        for gy in range(GH):
            line = []
            for gx in range(GW):
                r, g, b = grid[gy * GW + gx]
                line.append("0x%02x%02x%02x" % (r, g, b))
            f.write("    " + ", ".join(line) + ",\n")
        f.write("};\n")
        f.write("#define SHELL_DOCK_W 8\n#define SHELL_DOCK_H 3\n")
        f.write("static const unsigned shell_dock_grid[24] = {\n")
        for gy in range(3):
            line = []
            for gx in range(8):
                r, g, b = dock[gy * 8 + gx]
                line.append("0x%02x%02x%02x" % (r, g, b))
            f.write("    " + ", ".join(line) + ",\n")
        f.write("};\n")
        f.write("#define SHELL_SEARCH_W 4\n#define SHELL_SEARCH_H 2\n")
        f.write("static const unsigned shell_search_grid[8] = {\n")
        for gy in range(2):
            line = []
            for gx in range(4):
                r, g, b = search[gy * 4 + gx]
                line.append("0x%02x%02x%02x" % (r, g, b))
            f.write("    " + ", ".join(line) + ",\n")
        f.write("};\n#endif\n")
    print("wrote", out, GW * GH, "cells")


main()
