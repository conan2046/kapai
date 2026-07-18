from __future__ import annotations

import argparse
import hashlib
import json
import shutil
from pathlib import Path
from typing import Any

from ani_ir import AniFormatError, parse_ani


WELFARE_ANI_PATHS = {"res2/fx/qiandao.ani"}


def _write_json(path: Path, value: Any) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(
        json.dumps(value, ensure_ascii=False, indent=2, sort_keys=True) + "\n",
        encoding="utf-8",
    )


def _digest(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def convert(
    resource_root: Path,
    output_root: Path,
    scope: str,
    unity_project: Path | None = None,
) -> dict[str, Any]:
    paths = sorted(resource_root.rglob("*.ani"), key=lambda item: item.as_posix().casefold())
    if scope == "welfare":
        paths = [
            path
            for path in paths
            if path.relative_to(resource_root).as_posix().casefold() in WELFARE_ANI_PATHS
        ]

    entries = []
    errors = []
    for path in paths:
        relative = path.relative_to(resource_root)
        texture = path.with_suffix(".png")
        try:
            parsed = parse_ani(path, resource_root)
            ir_path = output_root / "ani" / relative.with_suffix(".ani.json")
            _write_json(ir_path, parsed)
            entry = {
                "source": relative.as_posix(),
                "texture": relative.with_suffix(".png").as_posix(),
                "textureExists": texture.is_file(),
                "ir": ir_path.relative_to(output_root).as_posix(),
                "sourceSha256": _digest(path),
                "statistics": parsed["statistics"],
            }
            entries.append(entry)
            if unity_project is not None:
                unity_data = (
                    unity_project
                    / "Assets/ProjectX/Resources/ProjectXAnimation"
                    / relative.with_suffix(".json")
                )
                _write_json(unity_data, parsed)
                if texture.is_file():
                    unity_texture = (
                        unity_project
                        / "Assets/ProjectX/Resources/ProjectXAnimation"
                        / relative.with_suffix(".png")
                    )
                    unity_texture.parent.mkdir(parents=True, exist_ok=True)
                    shutil.copy2(texture, unity_texture)
                entry["unityResourceKey"] = (
                    "ProjectXAnimation/" + relative.with_suffix("").as_posix()
                )
        except (AniFormatError, OSError, ValueError) as exc:
            errors.append({"source": relative.as_posix(), "error": str(exc)})

    manifest = {
        "schemaVersion": 1,
        "scope": scope,
        "resourceRoot": resource_root.as_posix(),
        "entries": entries,
        "errors": errors,
        "statistics": {
            "animations": len(entries),
            "errors": len(errors),
            "texturesPresent": sum(1 for item in entries if item["textureExists"]),
            "unityPrepared": sum(1 for item in entries if "unityResourceKey" in item),
        },
    }
    _write_json(output_root / "ani-manifest.json", manifest)
    return manifest


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Convert ProjectX ImodAnim .ani files to engine-neutral JSON."
    )
    parser.add_argument("--repo-root", type=Path, default=Path(__file__).resolve().parents[2])
    parser.add_argument("--resource-root", type=Path)
    parser.add_argument("--output", type=Path)
    parser.add_argument("--scope", choices=("all", "welfare"), default="all")
    parser.add_argument(
        "--prepare-unity",
        action="store_true",
        help="Copy converted JSON and paired textures into Unity Resources.",
    )
    args = parser.parse_args()
    repo_root = args.repo_root.resolve()
    resource_root = (args.resource_root or repo_root / "client/ProjectX/res").resolve()
    output_root = (args.output or repo_root / "build/ui-migration").resolve()
    unity_project = repo_root / "unityclient" if args.prepare_unity else None
    manifest = convert(resource_root, output_root, args.scope, unity_project)
    print(json.dumps(manifest["statistics"], ensure_ascii=False, indent=2))
    return 1 if manifest["errors"] else 0


if __name__ == "__main__":
    raise SystemExit(main())
