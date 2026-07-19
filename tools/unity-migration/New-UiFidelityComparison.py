#!/usr/bin/env python3
import argparse
import json
from pathlib import Path

from PIL import Image, ImageChops, ImageEnhance, ImageStat


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--cocos", required=True)
    parser.add_argument("--unity", required=True)
    parser.add_argument("--output", required=True)
    parser.add_argument("--name", required=True)
    args = parser.parse_args()

    cocos = Image.open(args.cocos).convert("RGB")
    unity = Image.open(args.unity).convert("RGB")
    if cocos.size != unity.size:
        unity = unity.resize(cocos.size, Image.Resampling.LANCZOS)

    output = Path(args.output)
    output.mkdir(parents=True, exist_ok=True)
    side = Image.new("RGB", (cocos.width * 2, cocos.height))
    side.paste(cocos, (0, 0))
    side.paste(unity, (cocos.width, 0))
    side.save(output / f"{args.name}-side-by-side.png")
    Image.blend(cocos, unity, 0.5).save(output / f"{args.name}-overlay.png")

    diff = ImageChops.difference(cocos, unity)
    ImageEnhance.Contrast(diff).enhance(3.0).save(output / f"{args.name}-diff.png")
    stat = ImageStat.Stat(diff)
    mean = sum(stat.mean) / len(stat.mean)
    rms = sum(stat.rms) / len(stat.rms)
    changed = sum(1 for pixel in diff.getdata() if max(pixel) > 8)
    report = {
        "name": args.name,
        "size": list(cocos.size),
        "meanAbsoluteError": round(mean, 4),
        "rootMeanSquareError": round(rms, 4),
        "changedPixelRatioOver8": round(changed / (cocos.width * cocos.height), 6),
        "cocos": str(Path(args.cocos).resolve()),
        "unity": str(Path(args.unity).resolve()),
    }
    (output / f"{args.name}-report.json").write_text(
        json.dumps(report, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
    )
    print(json.dumps(report, ensure_ascii=False))


if __name__ == "__main__":
    main()
