from __future__ import annotations

import plistlib
import re
from pathlib import Path
from typing import Any


_NUMBER_RE = re.compile(r"-?\d+(?:\.\d+)?")


def _numbers(value: Any) -> list[float]:
    if not isinstance(value, str):
        return []
    return [float(item) for item in _NUMBER_RE.findall(value)]


def _vec2(value: Any) -> dict[str, float] | None:
    numbers = _numbers(value)
    if len(numbers) < 2:
        return None
    return {"x": numbers[0], "y": numbers[1]}


def _rect(value: Any) -> dict[str, float] | None:
    numbers = _numbers(value)
    if len(numbers) < 4:
        return None
    return {
        "x": numbers[0],
        "y": numbers[1],
        "width": numbers[2],
        "height": numbers[3],
    }


def _json_safe(value: Any) -> Any:
    if isinstance(value, bytes):
        return {"encoding": "base64", "byteLength": len(value)}
    if isinstance(value, dict):
        return {str(key): _json_safe(item) for key, item in value.items()}
    if isinstance(value, (list, tuple)):
        return [_json_safe(item) for item in value]
    return value


def _atlas_frame(name: str, raw: dict[str, Any]) -> dict[str, Any]:
    frame_rect = _rect(raw.get("frame") or raw.get("textureRect"))
    source_size = _vec2(raw.get("sourceSize") or raw.get("spriteSourceSize"))
    offset = _vec2(raw.get("offset") or raw.get("spriteOffset"))
    return {
        "name": name,
        "rect": frame_rect,
        "sourceSize": source_size,
        "offset": offset,
        "rotated": bool(raw.get("rotated") or raw.get("textureRotated", False)),
        "aliases": raw.get("aliases", []),
        "raw": _json_safe(raw),
    }


def parse_plist(path: Path, source_root: Path | None = None) -> dict[str, Any]:
    with path.open("rb") as stream:
        data = plistlib.load(stream)
    if not isinstance(data, dict):
        raise ValueError(f"PLIST root must be a dictionary: {path}")

    rel_path = path.as_posix()
    if source_root is not None:
        try:
            rel_path = path.resolve().relative_to(source_root.resolve()).as_posix()
        except ValueError:
            pass

    if isinstance(data.get("frames"), dict):
        frames = [
            _atlas_frame(name, raw)
            for name, raw in sorted(data["frames"].items())
            if isinstance(raw, dict)
        ]
        metadata = data.get("metadata", {})
        texture = None
        if isinstance(metadata, dict):
            texture = (
                metadata.get("realTextureFileName")
                or metadata.get("textureFileName")
                or metadata.get("textureFileName")
            )
        return {
            "schemaVersion": 1,
            "kind": "SpriteAtlas",
            "source": {"path": rel_path, "format": "Apple PLIST"},
            "texture": texture,
            "metadata": _json_safe(metadata),
            "frames": frames,
            "statistics": {"frameCount": len(frames)},
        }

    is_particle = "maxParticles" in data or "emitterType" in data
    return {
        "schemaVersion": 1,
        "kind": "ParticleConfig" if is_particle else "PropertyList",
        "source": {"path": rel_path, "format": "Apple PLIST"},
        "properties": _json_safe(data),
        "statistics": {"propertyCount": len(data)},
    }
