from __future__ import annotations

import struct
from pathlib import Path
from typing import Any


ANI_FRAME_RATE = 30


class AniFormatError(ValueError):
    pass


class _Reader:
    def __init__(self, data: bytes, source: str) -> None:
        self.data = data
        self.source = source
        self.offset = 0

    def byte(self) -> int:
        if self.offset >= len(self.data):
            raise AniFormatError(f"Unexpected end of ANI at byte {self.offset}: {self.source}")
        value = self.data[self.offset]
        self.offset += 1
        return value

    def short(self) -> int:
        if self.offset + 2 > len(self.data):
            raise AniFormatError(f"Unexpected end of ANI at byte {self.offset}: {self.source}")
        value = struct.unpack_from("<h", self.data, self.offset)[0]
        self.offset += 2
        return value


def parse_ani_bytes(data: bytes, source: str = "<memory>") -> dict[str, Any]:
    reader = _Reader(data, source)
    modules = []
    for index in range(reader.byte()):
        modules.append(
            {
                "id": index,
                "x": reader.short(),
                "y": reader.short(),
                "width": reader.short(),
                "height": reader.short(),
            }
        )

    frames = []
    for index in range(reader.byte()):
        parts = []
        part_count = reader.byte()
        if part_count > 1:
            raise AniFormatError(
                f"Frame {index} has {part_count} modules; legacy ImodAnim asserts < 2: {source}"
            )
        for _ in range(part_count):
            parts.append(
                {
                    "x": reader.short(),
                    "y": reader.short(),
                    "module": reader.byte(),
                    "flags": reader.byte(),
                }
            )
        frames.append({"id": index, "parts": parts})

    actions = []
    for index in range(reader.byte()):
        sequence = []
        for _ in range(reader.byte()):
            frame = reader.byte()
            duration = reader.byte()
            sequence.append(
                {
                    "frame": frame,
                    "durationTicks": 5 if duration == 1 else duration,
                    "sourceDurationTicks": duration,
                }
            )
        actions.append({"id": index, "frames": sequence})

    if reader.offset != len(data):
        raise AniFormatError(
            f"ANI has {len(data) - reader.offset} trailing bytes at {reader.offset}: {source}"
        )
    for frame in frames:
        for part in frame["parts"]:
            if part["module"] >= len(modules):
                raise AniFormatError(
                    f"Frame {frame['id']} references missing module {part['module']}: {source}"
                )
    for action in actions:
        for item in action["frames"]:
            if item["frame"] >= len(frames):
                raise AniFormatError(
                    f"Action {action['id']} references missing frame {item['frame']}: {source}"
                )
    return {
        "schemaVersion": 1,
        "format": "ProjectX ImodAnim",
        "source": source,
        "frameRate": ANI_FRAME_RATE,
        "modules": modules,
        "frames": frames,
        "actions": actions,
        "statistics": {
            "bytes": len(data),
            "modules": len(modules),
            "frames": len(frames),
            "actions": len(actions),
        },
    }


def parse_ani(path: Path, source_root: Path | None = None) -> dict[str, Any]:
    source = (
        path.relative_to(source_root).as_posix()
        if source_root is not None
        else path.as_posix()
    )
    return parse_ani_bytes(path.read_bytes(), source)
