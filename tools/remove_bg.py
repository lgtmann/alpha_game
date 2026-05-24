#!/usr/bin/env python3
"""
remove_bg.py — strip a solid-colour background from an image and save as PNG
             with a transparent background.

Usage
-----
    python tools/remove_bg.py <input> [output] [options]

Arguments
---------
    input           Source image (JPG, PNG, BMP, …)
    output          Output PNG path. Defaults to <input stem>.png in the same folder.

Options
-------
    --color R G B   Background colour to remove as 0-255 integers.
                    Default: auto-detected by sampling the four corners.
    --tolerance N   Max Euclidean RGB distance from the background colour before
                    a pixel is considered foreground. Default: 40.
                    • Lower  -> only pixels very close to the BG colour go transparent.
                    • Higher -> removes more, useful for compressed/noisy JPEGs.
    --feather N     Blend pixels whose distance is between (tolerance) and
                    (tolerance + N) into partial transparency for softer edges.
                    Default: 10.

Examples
--------
    # Auto-detect green screen, default settings
    python tools/remove_bg.py art/hero_sheet.jpg

    # Explicit green, tight tolerance, no feather
    python tools/remove_bg.py art/hero_sheet.jpg art/hero_sheet.png \\
        --color 0 255 0 --tolerance 30 --feather 0

    # White background
    python tools/remove_bg.py ref/pose.jpg --color 255 255 255 --tolerance 25
"""

import argparse
import math
import sys
from pathlib import Path

import numpy as np
from PIL import Image


# ── helpers ──────────────────────────────────────────────────────────────────

def sample_corners(img: Image.Image) -> tuple[int, int, int]:
    """Average the RGB of the four corner pixels to estimate background colour."""
    w, h = img.size
    corners = [
        img.getpixel((0,     0    ))[:3],
        img.getpixel((w - 1, 0    ))[:3],
        img.getpixel((0,     h - 1))[:3],
        img.getpixel((w - 1, h - 1))[:3],
    ]
    r = round(sum(c[0] for c in corners) / 4)
    g = round(sum(c[1] for c in corners) / 4)
    b = round(sum(c[2] for c in corners) / 4)
    return (r, g, b)


def remove_background(
    input_path:  Path,
    output_path: Path,
    bg_color:    tuple[int, int, int] | None = None,
    tolerance:   int = 40,
    feather:     int = 10,
) -> None:
    img = Image.open(input_path).convert("RGBA")
    w, h = img.size

    if bg_color is None:
        bg_color = sample_corners(img)
        print(f"  Auto-detected background: RGB{bg_color}")

    # Build a float32 array (H × W × 4)
    arr = np.array(img, dtype=np.float32)

    # Euclidean distance from every pixel's RGB to the background colour
    bg  = np.array(bg_color, dtype=np.float32)          # shape (3,)
    rgb = arr[:, :, :3]                                  # shape (H, W, 3)
    dist = np.sqrt(np.sum((rgb - bg) ** 2, axis=2))     # shape (H, W)

    # Hard-transparent zone: distance ≤ tolerance
    transparent = dist <= tolerance

    # Feather zone: tolerance < distance ≤ tolerance + feather  ->  ramp 1->0
    if feather > 0:
        in_feather = (dist > tolerance) & (dist <= tolerance + feather)
        # alpha fraction: 0 at inner edge, 1 at outer edge
        ramp = (dist - tolerance) / feather           # 0.0 … 1.0
        arr[:, :, 3] = np.where(transparent, 0.0,
                        np.where(in_feather, arr[:, :, 3] * ramp,
                                 arr[:, :, 3]))
    else:
        in_feather = np.zeros(dist.shape, dtype=bool)
        arr[transparent, 3] = 0.0

    # Despill: semi-transparent edge pixels often carry green fringing from JPEG
    # compression.  Cap the green channel to max(R, B) on those pixels.
    edge = (arr[:, :, 3] > 0.0) & (arr[:, :, 3] < 255.0)
    max_rb = np.maximum(arr[:, :, 0], arr[:, :, 2])
    arr[:, :, 1] = np.where(edge, np.minimum(arr[:, :, 1], max_rb), arr[:, :, 1])

    # Zero the RGB of fully-transparent pixels so GPU bilinear filtering can't
    # bleed the background colour back in at sprite edges.
    fully_transparent = arr[:, :, 3] == 0.0
    arr[fully_transparent, :3] = 0.0

    result = Image.fromarray(arr.astype(np.uint8), "RGBA")
    output_path.parent.mkdir(parents=True, exist_ok=True)
    result.save(output_path, "PNG")

    removed   = int(np.sum(transparent))
    feathered = int(np.sum(in_feather)) if feather > 0 else 0
    total     = w * h
    print(f"  {w}×{h} px — removed {removed:,} ({removed/total*100:.1f}%) "
          f"+ feathered {feathered:,} ({feathered/total*100:.1f}%)")
    print(f"  Saved -> {output_path}")


# ── CLI ───────────────────────────────────────────────────────────────────────

def main() -> None:
    parser = argparse.ArgumentParser(
        description="Remove a solid-colour background and output a transparent PNG.",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=__doc__,
    )
    parser.add_argument("input",  help="Source image file")
    parser.add_argument("output", nargs="?", help="Output PNG (default: same name, .png extension)")
    parser.add_argument("--color", nargs=3, type=int, metavar=("R", "G", "B"),
                        help="Background colour (default: auto-sampled from corners)")
    parser.add_argument("--tolerance", type=int, default=40,
                        help="Hard-remove threshold 0-441 (default: 40)")
    parser.add_argument("--feather",   type=int, default=10,
                        help="Soft-edge blend width in colour units (default: 10, 0=off)")
    args = parser.parse_args()

    input_path = Path(args.input)
    if not input_path.exists():
        print(f"Error: file not found: {input_path}", file=sys.stderr)
        sys.exit(1)

    output_path = Path(args.output) if args.output else input_path.with_suffix(".png")
    if output_path == input_path:
        output_path = input_path.with_name(input_path.stem + "_nobg.png")

    bg_color = tuple(args.color) if args.color else None

    print(f"Processing: {input_path.name}")
    remove_background(input_path, output_path, bg_color, args.tolerance, args.feather)


if __name__ == "__main__":
    main()
