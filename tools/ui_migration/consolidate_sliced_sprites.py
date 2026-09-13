#!/usr/bin/env python3
"""Convert copied nine-slice PNG variants into Sprite sub-assets.

The default mode is read-only. ``--apply`` rewrites normalized UI documents and
manifests, creates a Unity migration plan, and backs up every file that the
subsequent Unity batch migration can touch. Unity performs the actual TextureImporter
conversion and serialized Sprite reference migration.
"""

from __future__ import annotations

import argparse
import json
import os
import re
import shutil
import tempfile
import time
from pathlib import Path, PurePosixPath
from typing import Any

from prepare_unity_project import _sprite_name


GUID_PATTERN = re.compile(rb"(?m)^guid: ([0-9a-f]{32})\r?$")
SERIALIZED_SUFFIXES = {
    ".anim",
    ".asset",
    ".controller",
    ".mat",
    ".overridecontroller",
    ".playable",
    ".prefab",
    ".unity",
}
TEXT_SUFFIXES = SERIALIZED_SUFFIXES | {".cs", ".json"}


def _read_json(path: Path) -> dict[str, Any]:
    return json.loads(path.read_text(encoding="utf-8"))


def _write_json(path: Path, value: Any) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(
        json.dumps(value, ensure_ascii=False, indent=2, sort_keys=True) + "\n",
        encoding="utf-8",
    )


def _asset_file(unity_project: Path, asset_path: str) -> Path:
    normalized = asset_path.replace("\\", "/")
    if not normalized.startswith("Assets/") or ".." in PurePosixPath(normalized).parts:
        raise ValueError(f"Unsafe Unity asset path: {asset_path}")
    return unity_project / Path(*normalized.split("/"))


def _border_tuple(definition: dict[str, Any]) -> tuple[int, int, int, int]:
    border = definition.get("border", {})
    return tuple(int(border.get(key, 0)) for key in ("x", "y", "z", "w"))


def _build_mapping(
    definitions: list[dict[str, Any]],
) -> tuple[dict[str, dict[str, Any]], list[dict[str, Any]], list[dict[str, Any]]]:
    groups: dict[str, list[dict[str, Any]]] = {}
    for definition in definitions:
        source = str(definition.get("sourceAssetPath", ""))
        asset = str(definition.get("assetPath", ""))
        if not source or not asset:
            raise ValueError(f"Invalid sprite border definition: {definition}")
        groups.setdefault(source, []).append(definition)

    mapping: dict[str, dict[str, Any]] = {}
    converted: list[dict[str, Any]] = []
    plan: list[dict[str, Any]] = []
    for source, items in sorted(groups.items()):
        canonical = next(
            (
                item
                for item in items
                if item.get("canonical", False) or item.get("assetPath") == source
            ),
            min(items, key=lambda item: (_border_tuple(item), str(item["assetPath"]))),
        )
        multiple = len(items) > 1
        seen_names: set[str] = set()
        for item in sorted(items, key=lambda value: (_border_tuple(value), value["assetPath"])):
            old_asset = str(item["assetPath"])
            is_canonical = item is canonical
            sprite_name = (
                _sprite_name(source, _border_tuple(item), is_canonical) if multiple else ""
            )
            if sprite_name in seen_names:
                raise ValueError(f"Duplicate Sprite sub-asset name: {source}#{sprite_name}")
            seen_names.add(sprite_name)
            replacement = {
                "sourceAssetPath": source,
                "spriteName": sprite_name,
                "canonical": is_canonical,
            }
            mapping[old_asset] = replacement
            definition = dict(item)
            definition["assetPath"] = source
            definition["sourceAssetPath"] = source
            definition["canonical"] = is_canonical
            if sprite_name:
                definition["spriteName"] = sprite_name
            else:
                definition.pop("spriteName", None)
            converted.append(definition)
            if multiple or old_asset != source:
                plan.append(
                    {
                        "oldAssetPath": old_asset,
                        "sourceAssetPath": source,
                        "spriteName": sprite_name or None,
                        "border": item.get("border", {}),
                        "canonical": is_canonical,
                    }
                )
    converted.sort(key=lambda item: (item["assetPath"], item.get("spriteName", "")))
    return mapping, converted, plan


def _rewrite_resource_paths(value: Any, mapping: dict[str, dict[str, Any]]) -> int:
    changed = 0
    if isinstance(value, dict):
        asset = value.get("assetPath")
        if isinstance(asset, str) and asset in mapping:
            replacement = mapping[asset]
            desired_asset = replacement["sourceAssetPath"]
            desired_name = replacement["spriteName"]
            if asset != desired_asset:
                value["assetPath"] = desired_asset
                changed += 1
            if desired_name:
                if value.get("spriteName") != desired_name:
                    value["spriteName"] = desired_name
                    changed += 1
            elif "spriteName" in value:
                value.pop("spriteName")
                changed += 1
        for child in value.values():
            changed += _rewrite_resource_paths(child, mapping)
    elif isinstance(value, list):
        for child in value:
            changed += _rewrite_resource_paths(child, mapping)
    return changed


def _refresh_manifest(
    manifest: dict[str, Any],
    mapping: dict[str, dict[str, Any]],
    converted_by_old_asset: dict[str, dict[str, Any]],
) -> int:
    old_definitions = list(manifest.get("spriteBorders", []))
    converted: list[dict[str, Any]] = []
    for item in old_definitions:
        old_asset = str(item.get("assetPath", ""))
        replacement = converted_by_old_asset.get(old_asset)
        if replacement is None:
            raise ValueError(f"Manifest definition is missing from base mapping: {old_asset}")
        converted.append(dict(replacement))
    converted.sort(key=lambda item: (item["assetPath"], item.get("spriteName", "")))
    manifest["spriteBorders"] = converted
    manifest["generatedAssets"] = sorted(
        {
            str(path)
            for path in manifest.get("generatedAssets", [])
            if "/Sliced/" not in str(path).replace("\\", "/")
        }
    )
    statistics = manifest.setdefault("statistics", {})
    statistics["generatedAssets"] = len(manifest["generatedAssets"])
    statistics["slicedSpriteVariants"] = 0
    statistics["slicedSpriteDefinitions"] = len(converted)
    statistics["canonicalSlicedSources"] = len(
        {item["sourceAssetPath"] for item in converted if item.get("canonical", False)}
    )
    statistics["multipleSpriteSources"] = len(
        {item["sourceAssetPath"] for item in converted if item.get("spriteName")}
    )
    statistics["slicedSpriteSubAssets"] = sum(
        bool(item.get("spriteName")) for item in converted
    )
    return len(old_definitions)


def _backup_files(
    repo_root: Path,
    unity_project: Path,
    paths: set[Path],
    backup_root: Path,
) -> int:
    copied = 0
    for path in sorted(paths):
        if not path.exists() or not path.is_file():
            continue
        try:
            relative = path.resolve().relative_to(repo_root.resolve())
        except ValueError:
            relative = Path("external") / path.name
        destination = backup_root / relative
        destination.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(path, destination)
        copied += 1
    _write_json(
        backup_root / "backup-manifest.json",
        {
            "files": [
                str(path.resolve().relative_to(repo_root.resolve())).replace("\\", "/")
                for path in sorted(paths)
                if path.exists() and path.is_file() and path.resolve().is_relative_to(repo_root.resolve())
            ],
            "unityProject": str(unity_project),
        },
    )
    return copied


def consolidate(
    repo_root: Path,
    unity_project: Path,
    apply: bool = False,
    backup_root: Path | None = None,
    plan_path: Path | None = None,
) -> dict[str, int]:
    data_root = unity_project / "Assets/ProjectX/res/csd/UnityMigration"
    manifest_paths = [
        data_root / "unity-import-manifest.json",
        data_root / "unity-import-manifest.timeline.json",
    ]
    base_manifest = _read_json(manifest_paths[0])
    current_definitions = list(base_manifest.get("spriteBorders", []))
    if any(item.get("spriteName") for item in current_definitions):
        invalid = [
            item
            for item in current_definitions
            if item.get("assetPath") != item.get("sourceAssetPath")
        ]
        if invalid:
            raise ValueError("Mixed copied-PNG and Sprite sub-asset definitions are unsupported.")
        sliced_root = data_root / "Sliced"
        return {
            "definitions": len(current_definitions),
            "multipleSpriteSources": len(
                {
                    item["sourceAssetPath"]
                    for item in current_definitions
                    if item.get("spriteName")
                }
            ),
            "subAssets": sum(bool(item.get("spriteName")) for item in current_definitions),
            "physicalVariants": len(list(sliced_root.rglob("*.png")))
            if sliced_root.exists()
            else 0,
            "changedDocuments": 0,
            "pathAndSpriteNameChanges": 0,
            "planEntries": 0,
            "backupFiles": 0,
            "applied": 0,
            "alreadyConsolidated": 1,
        }
    mapping, converted, plan = _build_mapping(current_definitions)
    converted_by_old_asset = {
        str(old["assetPath"]): new
        for old, new in zip(base_manifest.get("spriteBorders", []), converted)
    }
    # Sorting changes order, so rebuild the lookup by matching the stable old asset path.
    converted_by_old_asset = {}
    for old in base_manifest.get("spriteBorders", []):
        replacement = mapping[str(old["assetPath"])]
        updated = dict(old)
        updated["assetPath"] = replacement["sourceAssetPath"]
        updated["sourceAssetPath"] = replacement["sourceAssetPath"]
        updated["canonical"] = replacement["canonical"]
        if replacement["spriteName"]:
            updated["spriteName"] = replacement["spriteName"]
        else:
            updated.pop("spriteName", None)
        converted_by_old_asset[str(old["assetPath"])] = updated

    manifests = [_read_json(path) for path in manifest_paths]
    document_paths = {
        _asset_file(unity_project, str(document["documentAssetPath"]))
        for manifest in manifests
        for document in manifest.get("documents", [])
    }
    changed_documents: dict[Path, dict[str, Any]] = {}
    path_replacements = 0
    for document_path in sorted(document_paths):
        document = _read_json(document_path)
        changes = _rewrite_resource_paths(document, mapping)
        if changes:
            changed_documents[document_path] = document
            path_replacements += changes

    for manifest in manifests:
        _refresh_manifest(manifest, mapping, converted_by_old_asset)

    physical_variants = [
        _asset_file(unity_project, entry["oldAssetPath"])
        for entry in plan
        if entry["oldAssetPath"] != entry["sourceAssetPath"]
    ]
    backup_count = 0
    if apply:
        if backup_root is None:
            raise ValueError("--backup-root is required with --apply")
        backup_paths = set(manifest_paths) | set(changed_documents) | set(physical_variants)
        for path in physical_variants:
            backup_paths.add(Path(str(path) + ".meta"))
        old_guids: set[bytes] = set()
        for entry in plan:
            source_file = _asset_file(unity_project, entry["sourceAssetPath"])
            source_meta = Path(str(source_file) + ".meta")
            backup_paths.add(source_meta)
            old_file = _asset_file(unity_project, entry["oldAssetPath"])
            old_meta = Path(str(old_file) + ".meta")
            if old_meta.exists():
                match = GUID_PATTERN.search(old_meta.read_bytes())
                if match:
                    old_guids.add(match.group(1))
        for path in (unity_project / "Assets").rglob("*"):
            if path.is_file() and path.suffix.lower() in SERIALIZED_SUFFIXES:
                content = path.read_bytes()
                if any(guid in content for guid in old_guids):
                    backup_paths.add(path)
        backup_count = _backup_files(repo_root, unity_project, backup_paths, backup_root)
        for path, manifest in zip(manifest_paths, manifests):
            _write_json(path, manifest)
        for path, document in changed_documents.items():
            _write_json(path, document)
        _write_json(plan_path or repo_root / ".local/ui-sliced-multiple-plan.json", {"entries": plan})

    return {
        "definitions": len(converted),
        "multipleSpriteSources": len(
            {item["sourceAssetPath"] for item in converted if item.get("spriteName")}
        ),
        "subAssets": sum(bool(item.get("spriteName")) for item in converted),
        "physicalVariants": len(physical_variants),
        "changedDocuments": len(changed_documents),
        "pathAndSpriteNameChanges": path_replacements,
        "planEntries": len(plan),
        "backupFiles": backup_count,
        "applied": int(apply),
    }


def _replace_all(content: bytes, replacements: dict[bytes, bytes]) -> tuple[bytes, int]:
    count = 0
    for old, new in replacements.items():
        if old == new:
            continue
        occurrences = content.count(old)
        if occurrences:
            content = content.replace(old, new)
            count += occurrences
    return content, count


def _write_bytes_retry(path: Path, content: bytes) -> None:
    last_error: OSError | None = None
    for attempt in range(6):
        try:
            path.write_bytes(content)
            return
        except OSError as error:
            last_error = error
            time.sleep(0.2 * (attempt + 1))
    temporary_name = ""
    try:
        with tempfile.NamedTemporaryFile(
            dir=path.parent, prefix=f".{path.name}.", suffix=".codex-tmp", delete=False
        ) as temporary:
            temporary.write(content)
            temporary_name = temporary.name
        os.replace(temporary_name, path)
    except OSError:
        if temporary_name:
            Path(temporary_name).unlink(missing_ok=True)
        if last_error is not None:
            raise last_error
        raise


def finalize(
    repo_root: Path,
    unity_project: Path,
    report_path: Path,
    plan_path: Path,
) -> dict[str, int]:
    report = _read_json(report_path)
    plan = _read_json(plan_path)
    if not report.get("ok"):
        raise ValueError(f"Unity Sprite mapping did not pass: {report_path}")
    reference_replacements: dict[bytes, bytes] = {}
    path_replacements: dict[bytes, bytes] = {}
    for item in report.get("replacements", []):
        reference_replacements[str(item["oldReference"]).encode("ascii")] = str(
            item["newReference"]
        ).encode("ascii")
        old_path = str(item["oldAssetPath"])
        source_path = str(item["sourceAssetPath"])
        path_replacements[old_path.encode("utf-8")] = source_path.encode("utf-8")
        path_replacements[old_path.replace("/", "\\").encode("utf-8")] = source_path.replace(
            "/", "\\"
        ).encode("utf-8")

    changed_files = 0
    reference_count = 0
    path_count = 0
    text_paths = sorted(
        path
        for path in (unity_project / "Assets").rglob("*")
        if path.is_file() and path.suffix.lower() in TEXT_SUFFIXES
    )
    for path in text_paths:
        before = path.read_bytes()
        after, references = _replace_all(before, reference_replacements)
        after, paths = _replace_all(after, path_replacements)
        if after != before:
            _write_bytes_retry(path, after)
            changed_files += 1
        reference_count += references
        path_count += paths

    unresolved: list[str] = []
    needles = set(reference_replacements) | {
        old
        for old, new in path_replacements.items()
        if old != new and b"/Sliced/" in old.replace(b"\\", b"/")
    }
    for path in text_paths:
        content = path.read_bytes()
        if any(needle in content for needle in needles):
            unresolved.append(str(path))
    if unresolved:
        raise RuntimeError(
            "Legacy sliced Sprite references remain: " + ", ".join(unresolved[:10])
        )

    deleted = 0
    for entry in plan.get("entries", []):
        old_asset = str(entry["oldAssetPath"])
        source_asset = str(entry["sourceAssetPath"])
        if old_asset == source_asset:
            continue
        path = _asset_file(unity_project, old_asset)
        if path.exists():
            path.unlink()
            deleted += 1
        meta = Path(str(path) + ".meta")
        if meta.exists():
            meta.unlink()

    sliced_root = unity_project / "Assets/ProjectX/res/csd/UnityMigration/Sliced"
    removed_directories = 0
    if sliced_root.exists():
        for directory in sorted(sliced_root.rglob("*"), reverse=True):
            if directory.is_dir() and not any(directory.iterdir()):
                directory.rmdir()
                removed_directories += 1
                directory_meta = Path(str(directory) + ".meta")
                if directory_meta.exists():
                    directory_meta.unlink()

    result = {
        "changedFiles": changed_files,
        "referenceReplacements": reference_count,
        "pathReplacements": path_count,
        "deletedLegacyAssets": deleted,
        "removedDirectories": removed_directories,
        "remainingSlicedPng": len(list(sliced_root.rglob("*.png")))
        if sliced_root.exists()
        else 0,
    }
    _write_json(repo_root / ".local/ui-sliced-multiple-finalize.json", result)
    return result


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--repo-root", type=Path, default=Path(__file__).resolve().parents[2])
    parser.add_argument("--unity-project", type=Path)
    parser.add_argument("--apply", action="store_true")
    parser.add_argument("--backup-root", type=Path)
    parser.add_argument("--plan-path", type=Path)
    parser.add_argument("--finalize-report", type=Path)
    args = parser.parse_args()
    repo_root = args.repo_root.resolve()
    unity_project = (args.unity_project or repo_root / "unityclient").resolve()
    plan_path = (
        args.plan_path.resolve()
        if args.plan_path
        else repo_root / ".local/ui-sliced-multiple-plan.json"
    )
    if args.finalize_report:
        result = finalize(
            repo_root,
            unity_project,
            args.finalize_report.resolve(),
            plan_path,
        )
    else:
        result = consolidate(
            repo_root,
            unity_project,
            apply=args.apply,
            backup_root=args.backup_root.resolve() if args.backup_root else None,
            plan_path=plan_path,
        )
    print(json.dumps(result, ensure_ascii=False, sort_keys=True))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
