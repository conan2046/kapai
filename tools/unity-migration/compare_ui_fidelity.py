#!/usr/bin/env python3
"""Generate deterministic pixel-difference evidence for Cocos -> Unity UI migration."""

from __future__ import annotations

import argparse
import hashlib
import json
import math
from pathlib import Path

from PIL import Image, ImageChops, ImageEnhance


def file_hash(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for block in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest().upper()


def parse_roi(value: str | None, size: tuple[int, int]) -> tuple[int, int, int, int]:
    if not value:
        return 0, 0, size[0], size[1]
    parts = [int(part) for part in value.split(",")]
    if len(parts) != 4:
        raise ValueError("ROI must be x,y,width,height")
    x, y, width, height = parts
    if x < 0 or y < 0 or width <= 0 or height <= 0 or x + width > size[0] or y + height > size[1]:
        raise ValueError(f"ROI {value} exceeds image size {size[0]}x{size[1]}")
    return x, y, width, height


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--reference", required=True)
    parser.add_argument("--candidate", required=True)
    parser.add_argument("--diff", required=True)
    parser.add_argument("--report", required=True)
    parser.add_argument("--roi", help="x,y,width,height; defaults to the full image")
    parser.add_argument("--threshold", type=int, default=8)
    args = parser.parse_args()

    reference_path = Path(args.reference).resolve()
    candidate_path = Path(args.candidate).resolve()
    diff_path = Path(args.diff).resolve()
    report_path = Path(args.report).resolve()
    reference = Image.open(reference_path).convert("RGB")
    candidate = Image.open(candidate_path).convert("RGB")
    if reference.size != candidate.size:
        raise ValueError(f"Image sizes differ: reference={reference.size}, candidate={candidate.size}")

    x, y, width, height = parse_roi(args.roi, reference.size)
    box = (x, y, x + width, y + height)
    reference_roi = reference.crop(box)
    candidate_roi = candidate.crop(box)
    raw_diff = ImageChops.difference(reference_roi, candidate_roi)
    histogram = raw_diff.histogram()
    channel_pixels = width * height * 3
    absolute_sum = sum((index % 256) * count for index, count in enumerate(histogram))
    squared_sum = sum(((index % 256) ** 2) * count for index, count in enumerate(histogram))
    changed_pixels = sum(
        1
        for pixel in raw_diff.getdata()
        if max(pixel) > args.threshold
    )

    amplified = ImageEnhance.Contrast(raw_diff).enhance(4.0)
    diff_path.parent.mkdir(parents=True, exist_ok=True)
    amplified.save(diff_path)
    report = {
        "schemaVersion": 1,
        "reference": str(reference_path),
        "candidate": str(candidate_path),
        "referenceSha256": file_hash(reference_path),
        "candidateSha256": file_hash(candidate_path),
        "imageSize": {"width": reference.size[0], "height": reference.size[1]},
        "roi": {"x": x, "y": y, "width": width, "height": height},
        "threshold": args.threshold,
        "exactMatch": raw_diff.getbbox() is None,
        "meanAbsoluteError": round(absolute_sum / channel_pixels, 6),
        "rootMeanSquareError": round(math.sqrt(squared_sum / channel_pixels), 6),
        "changedPixelCount": changed_pixels,
        "changedPixelRatio": round(changed_pixels / (width * height), 8),
        "diffImage": str(diff_path),
    }
    report_path.parent.mkdir(parents=True, exist_ok=True)
    report_path.write_text(json.dumps(report, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(json.dumps(report, ensure_ascii=False))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
