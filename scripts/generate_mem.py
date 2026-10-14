#!/usr/bin/env python3
# python3 scripts/generate_golden.py --image photo.png --out-dir vectors/photo

import argparse
from PIL import Image
import numpy as np
from pathlib import Path

DUMMY_RGB= {
    "R": [
        [0, 255, 180,0],
        [40, 160, 20,100],
        [70,0, 200,0],
        [30, 220, 80,50],
    ],
    "G": [
        [10, 220, 80,50],
        [40, 250, 20,50],
        [90, 190, 0, 240],
        [220, 60, 5,10]
    ],
    "B": [
        [255, 0, 90, 20],
        [100, 180, 30, 230],
        [40, 210, 10,100],
        [70, 240, 0,0],
    ],
}


def grayscale(image):
    return [
        [((77 * r) + (150 * g) + (29 * b)) >> 8 for (r, g, b) in row]
        for row in image
    ]


def gradients(gray):
    height = len(gray)
    width = len(gray[0])
    result = []
    for y in range(2, height):
        for x in range(2, width):
            left = gray[y - 2][x - 2] + 2 * gray[y - 1][x - 2] + gray[y][x - 2]
            right = gray[y - 2][x] + 2 * gray[y - 1][x] + gray[y][x]
            top = gray[y - 2][x - 2] + 2 * gray[y - 2][x - 1] + gray[y - 2][x]
            bottom = gray[y][x - 2] + 2 * gray[y][x - 1] + gray[y][x]
            magnitude = abs(right - left) + abs(bottom - top)
            result.append(min(255, magnitude >> 2))
    return result


def make_dummy_rgb():
    height = len(DUMMY_RGB["R"])
    width = len(DUMMY_RGB["R"][0])
    return np.array([[(DUMMY_RGB["R"][y][x], DUMMY_RGB["G"][y][x], DUMMY_RGB["B"][y][x]) 
                      for x in range(width)] for y in range(height)])



def write_vectors(image, out_dir):
    height,width = image.shape[:2]

    out_dir = Path(out_dir)
    out_dir.mkdir(parents=True, exist_ok=True)
    rgb_path = out_dir / "rgb_image.mem"
    gray_path = out_dir / "grayscale.txt"
    expected_path = out_dir / "expected_gradient.mem"
    # metadata_path = out_dir / "image_meta.txt"
    with rgb_path.open("w", encoding="ascii") as stream:
        for y in range(height):
            for x in range(width):
                r,g,b = image[y, x]  
                stream.write(f"{r:02X}{g:02X}{b:02X}\n")

    gray = grayscale(image)
    expected = gradients(gray)
    with gray_path.open("w", encoding="ascii") as stream:
        for row in gray:
            stream.write(" ".join(f"{pixel:3d}" for pixel in row) + "\n")

    with expected_path.open("w", encoding="ascii") as stream:
        for value in expected:
            stream.write(f"{value:02X}\n")


parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument("--image", help="target image")
parser.add_argument("--out-dir", default="vectors/dummy",
                    help="directory for generated memory files (default: vectors/dummy)")
args = parser.parse_args()

if args.image:
    if not args.image.is_file():
        print(f"Image not found: {args.image}")
        exit(1)
    with Image.open(args.image) as image:
        rgb_image = image.convert("RGB")
        image = np.array(rgb_image)
else:
    image = make_dummy_rgb()

write_vectors(image, args.out_dir)


