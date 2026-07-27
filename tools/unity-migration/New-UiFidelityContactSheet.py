#!/usr/bin/env python3
import argparse
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--input", required=True)
    parser.add_argument("--output", required=True)
    parser.add_argument("--pattern", default="*-side-by-side.png")
    parser.add_argument("--per-page", type=int, default=8)
    parser.add_argument("--columns", type=int, default=2)
    args = parser.parse_args()

    source = Path(args.input)
    images = sorted(source.glob(args.pattern))
    if not images:
        raise SystemExit(f"No images matched {args.pattern!r} under {source}")

    columns = max(1, args.columns)
    rows = max(1, (args.per_page + columns - 1) // columns)
    cell_width = 800
    image_height = 225
    caption_height = 30
    margin = 18
    cell_height = image_height + caption_height
    font = ImageFont.load_default()
    destination = Path(args.output)
    destination.mkdir(parents=True, exist_ok=True)

    for page_index, offset in enumerate(range(0, len(images), args.per_page), start=1):
        page = Image.new(
            "RGB",
            (
                margin + columns * (cell_width + margin),
                margin + rows * (cell_height + margin),
            ),
            (35, 31, 29),
        )
        draw = ImageDraw.Draw(page)
        for index, path in enumerate(images[offset : offset + args.per_page]):
            column = index % columns
            row = index // columns
            x = margin + column * (cell_width + margin)
            y = margin + row * (cell_height + margin)
            image = Image.open(path).convert("RGB")
            image.thumbnail((cell_width, image_height), Image.Resampling.LANCZOS)
            image_x = x + (cell_width - image.width) // 2
            page.paste(image, (image_x, y))
            label = path.name.removesuffix("-side-by-side.png")
            draw.text((x + 6, y + image_height + 7), label, fill=(245, 236, 219), font=font)
        page.save(destination / f"contact-side-{page_index}.jpg", quality=90)

    print(f"generated={((len(images) - 1) // args.per_page) + 1} images={len(images)}")


if __name__ == "__main__":
    main()
