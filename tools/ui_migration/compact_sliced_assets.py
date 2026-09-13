#!/usr/bin/env python3
"""Migrate canonical nine-slice sprites back to their source textures.

Run after prepare_unity_project.py. The default mode is read-only; --apply updates
serialized Unity references, writes canonical TextureImporter borders, and removes
Sliced PNG/meta pairs that are no longer present in the full import manifest.
"""

from __future__ import annotations

import argparse
import json
import re
from pathlib import Path
from typing import Any

from prepare_unity_project import _slice_variant_path


GUID_PATTERN = re.compile(rb"(?m)^guid: ([0-9a-f]{32})\r?$")
SPRITE_BORDER_PATTERN = re.compile(rb"(?m)^([ \t]*spriteBorder: )[^\r\n]*(\r?)$")
TEXT_SUFFIXES = {
    ".anim",
    ".asset",
    ".controller",
    ".cs",
    ".json",
    ".mat",
    ".overridecontroller",
    ".playable",
    ".prefab",
    ".unity",
}


def _read_json(path: Path) -> dict[str, Any]:
    return json.loads(path.read_text(encoding="utf-8"))


def _asset_file(unity_project: Path, asset_path: str) -> Path:
    normalized = asset_path.replace("\\", "/")
    if not normalized.startswith("Assets/") or ".." in Path(normalized).parts:
        raise ValueError(f"Unsafe Unity asset path: {asset_path}")
    return unity_project / Path(*normalized.split("/"))


def _read_guid(meta_path: Path) -> bytes:
    match = GUID_PATTERN.search(meta_path.read_bytes())
    if not match:
        raise ValueError(f"Unity guid is missing from {meta_path}")
    return match.group(1)


def _border_tuple(definition: dict[str, Any]) -> tuple[int, int, int, int]:
    border = definition.get("border", {})
    return tuple(int(border.get(key, 0)) for key in ("x", "y", "z", "w"))


def _collect_asset_path_usage(value: Any, usage: dict[str, int]) -> None:
    if isinstance(value, dict):
        asset_path = value.get("assetPath")
        if isinstance(asset_path, str) and asset_path:
            usage[asset_path] = usage.get(asset_path, 0) + 1
        for child in value.values():
            _collect_asset_path_usage(child, usage)
    elif isinstance(value, list):
        for child in value:
            _collect_asset_path_usage(child, usage)


def _canonical_definitions(
    unity_project: Path, manifest: dict[str, Any]
) -> list[dict[str, Any]]:
    usage: dict[str, int] = {}
    for document in manifest.get("documents", []):
        document_path = str(document.get("documentAssetPath", ""))
        if document_path:
            _collect_asset_path_usage(_read_json(_asset_file(unity_project, document_path)), usage)

    groups: dict[str, list[dict[str, Any]]] = {}
    for definition in manifest.get("spriteBorders", []):
        source_path = str(definition.get("sourceAssetPath", ""))
        if source_path:
            groups.setdefault(source_path, []).append(definition)

    result: list[dict[str, Any]] = []
    for source_path, definitions in groups.items():
        existing = next(
            (item for item in definitions if item.get("assetPath") == source_path),
            None,
        )
        selected = existing or min(
            definitions,
            key=lambda item: (
                -usage.get(str(item.get("assetPath", "")), 0),
                _border_tuple(item),
                str(item.get("assetPath", "")),
            ),
        )
        result.append(selected)
    return result


def _canonical_migrations(
    unity_project: Path, definitions: list[dict[str, Any]]
) -> list[dict[str, Any]]:
    migrations: list[dict[str, Any]] = []
    for definition in definitions:
        source_path = str(definition.get("sourceAssetPath", ""))
        if not source_path:
            continue
        border = _border_tuple(definition)
        old_path = str(definition.get("assetPath", ""))
        if old_path == source_path:
            old_path = _slice_variant_path(source_path, border)
        source_file = _asset_file(unity_project, source_path)
        old_file = _asset_file(unity_project, old_path)
        if not source_file.exists() or not source_file.with_suffix(source_file.suffix + ".meta").exists():
            raise FileNotFoundError(f"Canonical source asset is missing: {source_path}")
        old_meta = old_file.with_suffix(old_file.suffix + ".meta")
        migrations.append(
            {
                "sourcePath": source_path,
                "sourceFile": source_file,
                "sourceGuid": _read_guid(source_file.with_suffix(source_file.suffix + ".meta")),
                "oldPath": old_path,
                "oldFile": old_file,
                "oldGuid": _read_guid(old_meta) if old_meta.exists() else None,
                "border": border,
            }
        )
    return migrations


def _text_assets(assets_root: Path) -> list[Path]:
    return sorted(
        path
        for path in assets_root.rglob("*")
        if path.is_file() and path.suffix.lower() in TEXT_SUFFIXES
    )


def _replacement_maps(
    migrations: list[dict[str, Any]],
) -> tuple[dict[bytes, bytes], dict[bytes, bytes]]:
    guid_map: dict[bytes, bytes] = {}
    path_map: dict[bytes, bytes] = {}
    for item in migrations:
        old_guid = item["oldGuid"]
        if old_guid:
            guid_map[old_guid] = item["sourceGuid"]
        old_path = item["oldPath"].encode("utf-8")
        source_path = item["sourcePath"].encode("utf-8")
        path_map[old_path] = source_path
        path_map[old_path.replace(b"/", b"\\")] = source_path.replace(b"/", b"\\")
    return guid_map, path_map


def _rewrite_references(
    paths: list[Path],
    guid_map: dict[bytes, bytes],
    path_map: dict[bytes, bytes],
    apply: bool,
) -> tuple[int, int, int]:
    changed_files = 0
    guid_replacements = 0
    path_replacements = 0
    guid_pattern = (
        re.compile(b"|".join(re.escape(value) for value in guid_map))
        if guid_map
        else None
    )
    path_pattern = (
        re.compile(b"|".join(re.escape(value) for value in path_map))
        if path_map
        else None
    )
    for path in paths:
        before = path.read_bytes()
        after = before
        if guid_pattern:
            after, count = guid_pattern.subn(lambda match: guid_map[match.group(0)], after)
            guid_replacements += count
        if path_pattern:
            after, count = path_pattern.subn(lambda match: path_map[match.group(0)], after)
            path_replacements += count
        if after == before:
            continue
        changed_files += 1
        if apply:
            path.write_bytes(after)
    return changed_files, guid_replacements, path_replacements


def _write_source_borders(migrations: list[dict[str, Any]], apply: bool) -> int:
    changed = 0
    for item in migrations:
        meta_path = item["sourceFile"].with_suffix(item["sourceFile"].suffix + ".meta")
        before = meta_path.read_bytes()
        left, bottom, right, top = item["border"]
        value = f"{{x: {left}, y: {bottom}, z: {right}, w: {top}}}".encode("ascii")
        after, count = SPRITE_BORDER_PATTERN.subn(rb"\g<1>" + value + rb"\g<2>", before, count=1)
        if count != 1:
            raise ValueError(f"spriteBorder is missing from {meta_path}")
        if after == before:
            continue
        changed += 1
        if apply:
            meta_path.write_bytes(after)
    return changed


def _obsolete_sliced_assets(
    unity_project: Path,
    manifest: dict[str, Any],
    canonical_old_paths: set[str],
) -> list[tuple[str, Path]]:
    expected = {
        str(item.get("assetPath", "")).replace("\\", "/")
        for item in manifest.get("spriteBorders", [])
        if "/Sliced/" in str(item.get("assetPath", "")).replace("\\", "/")
    }
    expected.difference_update(path.replace("\\", "/") for path in canonical_old_paths)
    sliced_root = unity_project / "Assets/ProjectX/res/csd/UnityMigration/Sliced"
    result: list[tuple[str, Path]] = []
    if not sliced_root.exists():
        return result
    for path in sorted(sliced_root.rglob("*.png")):
        asset_path = path.relative_to(unity_project).as_posix()
        if asset_path not in expected:
            result.append((asset_path, path))
    return result


def _assert_unreferenced(
    paths: list[Path], obsolete: list[tuple[str, Path]]
) -> None:
    needles: dict[bytes, str] = {}
    for asset_path, path in obsolete:
        needles[asset_path.encode("utf-8")] = asset_path
        needles[asset_path.replace("/", "\\").encode("utf-8")] = asset_path
        meta_path = path.with_suffix(path.suffix + ".meta")
        if meta_path.exists():
            needles[_read_guid(meta_path)] = asset_path
    if not needles:
        return
    references: dict[str, list[str]] = {}
    needle_pattern = re.compile(b"|".join(re.escape(value) for value in needles))
    for text_path in paths:
        content = text_path.read_bytes()
        for match in needle_pattern.finditer(content):
            asset_path = needles[match.group(0)]
            found = references.setdefault(asset_path, [])
            path_text = str(text_path)
            if path_text not in found:
                found.append(path_text)
    if references:
        details = "; ".join(
            f"{asset_path}: {', '.join(found[:3])}"
            for asset_path, found in sorted(references.items())
        )
        raise RuntimeError(f"Obsolete sliced assets are still referenced: {details}")


def _refresh_manifest_statistics(manifest_path: Path) -> None:
    if not manifest_path.exists():
        return
    manifest = _read_json(manifest_path)
    sprite_borders = manifest.get("spriteBorders", [])
    generated_assets = sorted(set(manifest.get("generatedAssets", [])))
    manifest["generatedAssets"] = generated_assets
    statistics = manifest.setdefault("statistics", {})
    statistics["generatedAssets"] = len(generated_assets)
    statistics["slicedSpriteVariants"] = sum(
        "/Sliced/" in str(item.get("assetPath", "")).replace("\\", "/")
        for item in sprite_borders
    )
    statistics["slicedSpriteDefinitions"] = len(sprite_borders)
    statistics["canonicalSlicedSources"] = sum(
        item.get("assetPath") == item.get("sourceAssetPath") for item in sprite_borders
    )
    manifest_path.write_text(
        json.dumps(manifest, ensure_ascii=False, indent=2, sort_keys=True) + "\n",
        encoding="utf-8",
    )


def compact(unity_project: Path, apply: bool = False) -> dict[str, int]:
    manifest_path = (
        unity_project
        / "Assets/ProjectX/res/csd/UnityMigration/unity-import-manifest.json"
    )
    manifest = _read_json(manifest_path)
    if any(item.get("spriteName") for item in manifest.get("spriteBorders", [])):
        raise RuntimeError(
            "Manifest already uses Multiple Sprite sub-assets; "
            "compact_sliced_assets.py is only for legacy copied-PNG manifests."
        )
    canonical_definitions = _canonical_definitions(unity_project, manifest)
    migrations = _canonical_migrations(unity_project, canonical_definitions)
    text_paths = _text_assets(unity_project / "Assets")
    guid_map, path_map = _replacement_maps(migrations)
    changed_files, guid_replacements, path_replacements = _rewrite_references(
        text_paths, guid_map, path_map, apply
    )
    changed_metas = _write_source_borders(migrations, apply)
    obsolete = _obsolete_sliced_assets(
        unity_project,
        manifest,
        {str(item["oldPath"]) for item in migrations},
    )

    if apply:
        _refresh_manifest_statistics(manifest_path)
        _refresh_manifest_statistics(
            manifest_path.with_name("unity-import-manifest.timeline.json")
        )
        _assert_unreferenced(text_paths, obsolete)
        for _, path in obsolete:
            path.unlink()
            meta_path = path.with_suffix(path.suffix + ".meta")
            if meta_path.exists():
                meta_path.unlink()
        sliced_root = unity_project / "Assets/ProjectX/res/csd/UnityMigration/Sliced"
        for directory in sorted(sliced_root.rglob("*"), reverse=True):
            if directory.is_dir() and not any(directory.iterdir()):
                directory.rmdir()
                directory_meta = Path(str(directory) + ".meta")
                if directory_meta.exists():
                    directory_meta.unlink()

    return {
        "canonicalSources": len(migrations),
        "changedFiles": changed_files,
        "guidReplacements": guid_replacements,
        "pathReplacements": path_replacements,
        "changedSourceMetas": changed_metas,
        "obsoleteSlicedAssets": len(obsolete),
    }


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--repo-root", type=Path, default=Path(__file__).resolve().parents[2])
    parser.add_argument("--unity-project", type=Path)
    parser.add_argument("--apply", action="store_true")
    args = parser.parse_args()
    repo_root = args.repo_root.resolve()
    unity_project = (args.unity_project or repo_root / "unityclient").resolve()
    result = compact(unity_project, apply=args.apply)
    result["applied"] = int(args.apply)
    print(json.dumps(result, ensure_ascii=False, sort_keys=True))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
