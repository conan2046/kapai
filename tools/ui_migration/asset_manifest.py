from __future__ import annotations

import hashlib
import json
from collections import defaultdict
from pathlib import Path
from typing import Any, Callable


NON_ISSUE_DECISIONS = {
    "single",
    "identical-preferred",
    "selected-by-priority",
    "atlas-selected-by-coverage",
}


def logical_key(reference: dict[str, Any]) -> str:
    return "|".join(
        str(reference.get(key) or "").replace("\\", "/").casefold()
        for key in ("type", "plist", "path")
    )


def sha256(path: Path, cache: dict[str, str]) -> str:
    key = str(path.resolve()).casefold()
    if key not in cache:
        digest = hashlib.sha256()
        with path.open("rb") as stream:
            for block in iter(lambda: stream.read(1024 * 1024), b""):
                digest.update(block)
        cache[key] = digest.hexdigest()
    return cache[key]


def _candidate(
    path: Path,
    source_label: Callable[[Path], tuple[int, str]],
    digest_cache: dict[str, str],
) -> dict[str, Any]:
    priority, label = source_label(path)
    return {
        "path": path.resolve().as_posix(),
        "source": label,
        "priority": priority,
        "sha256": sha256(path, digest_cache),
        "size": path.stat().st_size,
    }


def _frame_match(frame: str, available: set[str]) -> tuple[str, str | None]:
    if frame in available:
        return "exact", frame
    basename = Path(frame).name.casefold()
    matches = sorted(item for item in available if Path(item).name.casefold() == basename)
    if len(matches) == 1:
        return "basename", matches[0]
    if len(matches) > 1:
        return "ambiguous", None
    return "missing", None


def choose_atlas_sources(
    references: list[dict[str, Any]],
    resolve_asset: Callable[[str], list[Path]],
    atlas_frames: dict[str, set[str]],
    source_label: Callable[[Path], tuple[int, str]],
) -> dict[str, Path]:
    requests: dict[str, set[str]] = defaultdict(set)
    original_names: dict[str, str] = {}
    for reference in references:
        if reference.get("type") != "PlistSubImage" or not reference.get("plist"):
            continue
        key = str(reference["plist"]).replace("\\", "/").casefold()
        original_names[key] = str(reference["plist"])
        requests[key].add(str(reference.get("path") or ""))

    selections: dict[str, Path] = {}
    for key, frames in requests.items():
        candidates = resolve_asset(original_names[key])
        ranked: list[tuple[int, int, int, str, Path]] = []
        for path in candidates:
            available = atlas_frames.get(str(path.resolve()).casefold(), set())
            exact = sum(1 for frame in frames if _frame_match(frame, available)[0] == "exact")
            basename = sum(
                1 for frame in frames if _frame_match(frame, available)[0] == "basename"
            )
            priority, _ = source_label(path)
            ranked.append((-exact, -basename, priority, path.as_posix().casefold(), path))
        if ranked:
            selections[key] = min(ranked)[-1]
    return selections


def build_asset_manifest(
    references: list[dict[str, Any]],
    resolve_asset: Callable[[str], list[Path]],
    atlas_frames: dict[str, set[str]],
    source_label: Callable[[Path], tuple[int, str]],
) -> tuple[dict[str, Any], dict[str, Any]]:
    digest_cache: dict[str, str] = {}
    unique: dict[str, dict[str, Any]] = {}
    for reference in references:
        unique.setdefault(logical_key(reference), reference)

    atlas_selections = choose_atlas_sources(
        references, resolve_asset, atlas_frames, source_label
    )
    entries: list[dict[str, Any]] = []
    remaps: list[dict[str, Any]] = []
    selected_files: dict[str, dict[str, Any]] = {}
    unresolved = 0
    recovery_required = 0

    for key in sorted(unique):
        reference = unique[key]
        resource_type = str(reference.get("type") or "")
        logical_path = str(reference.get("path") or "")
        plist = str(reference.get("plist") or "")
        target = plist if resource_type == "PlistSubImage" else logical_path
        paths = resolve_asset(target) if target and resource_type != "Default" else []
        paths = sorted(paths, key=lambda item: (*source_label(item), item.as_posix().casefold()))
        candidates = [_candidate(path, source_label, digest_cache) for path in paths]

        selected_path: Path | None = None
        if resource_type == "PlistSubImage" and plist:
            selected_path = atlas_selections.get(plist.replace("\\", "/").casefold())
        elif paths:
            selected_path = paths[0]

        decision = "missing"
        if resource_type == "Default":
            decision = "engine-default"
        elif not target:
            decision = "empty-reference"
        elif selected_path is not None:
            hashes = {item["sha256"] for item in candidates}
            if resource_type == "PlistSubImage":
                decision = "atlas-selected-by-coverage"
            elif len(candidates) == 1:
                decision = "single"
            elif len(hashes) == 1:
                decision = "identical-preferred"
            else:
                decision = "selected-by-priority"

        selected = (
            _candidate(selected_path, source_label, digest_cache)
            if selected_path is not None
            else None
        )
        frame_status = None
        remapped_frame = None
        fallback_asset = None
        if selected_path is not None and resource_type == "PlistSubImage":
            available = atlas_frames.get(str(selected_path.resolve()).casefold(), set())
            frame_status, remapped_frame = _frame_match(logical_path, available)
            if frame_status == "basename" and remapped_frame:
                remaps.append(
                    {
                        "plist": plist,
                        "selectedPlist": selected_path.resolve().as_posix(),
                        "from": logical_path,
                        "to": remapped_frame,
                        "reason": "unique-basename-match",
                    }
                )
            elif frame_status not in {"exact", "basename"}:
                direct_files = resolve_asset(logical_path)
                if direct_files:
                    fallback_path = sorted(
                        direct_files,
                        key=lambda item: (*source_label(item), item.as_posix().casefold()),
                    )[0]
                    fallback_asset = _candidate(
                        fallback_path, source_label, digest_cache
                    )
                    frame_status = "fallback-file"
                    remaps.append(
                        {
                            "plist": plist,
                            "selectedPlist": selected_path.resolve().as_posix(),
                            "from": logical_path,
                            "to": fallback_path.resolve().as_posix(),
                            "reason": "direct-file-fallback",
                        }
                    )
                    selected_files[fallback_asset["path"].casefold()] = fallback_asset
                else:
                    placeholders = resolve_asset("Default/ImageFile.png")
                    if placeholders:
                        placeholder = sorted(
                            placeholders,
                            key=lambda item: (
                                *source_label(item),
                                item.as_posix().casefold(),
                            ),
                        )[0]
                        fallback_asset = _candidate(
                            placeholder, source_label, digest_cache
                        )
                        frame_status = "placeholder-recovery-required"
                        recovery_required += 1
                        remaps.append(
                            {
                                "plist": plist,
                                "selectedPlist": selected_path.resolve().as_posix(),
                                "from": logical_path,
                                "to": placeholder.resolve().as_posix(),
                                "reason": "missing-source-placeholder",
                                "requiresArtRecovery": True,
                            }
                        )
                        selected_files[fallback_asset["path"].casefold()] = fallback_asset
                    else:
                        unresolved += 1

        entry = {
            "key": key,
            "logical": {
                "type": resource_type,
                "path": logical_path,
                "plist": plist,
            },
            "decision": decision,
            "selected": selected,
            "candidateCount": len(candidates),
            "candidates": candidates,
            "frameStatus": frame_status,
            "remappedFrame": remapped_frame,
            "fallbackAsset": fallback_asset,
        }
        entries.append(entry)
        if selected:
            selected_files[selected["path"].casefold()] = selected

    decisions: dict[str, int] = defaultdict(int)
    for entry in entries:
        decisions[entry["decision"]] += 1
    manifest = {
        "schemaVersion": 1,
        "selectionPolicy": [
            "For atlas files, maximize exact requested-frame coverage, then basename coverage.",
            "For other assets, prefer runtime-client, then Cocos Studio source, then editor export.",
            "Identical copies are collapsed by SHA-256 without deleting source files.",
        ],
        "statistics": {
            "uniqueLogicalAssets": len(entries),
            "selectedPhysicalFiles": len(selected_files),
            "decisions": dict(sorted(decisions.items())),
            "atlasRemaps": len(remaps),
            "unresolvedAtlasFrames": unresolved,
            "artRecoveryRequired": recovery_required,
        },
        "selectedFiles": sorted(selected_files.values(), key=lambda item: item["path"]),
        "assets": entries,
    }
    remap_manifest = {
        "schemaVersion": 1,
        "statistics": {
            "remapped": len(remaps),
            "unresolved": unresolved,
            "artRecoveryRequired": recovery_required,
        },
        "remaps": remaps,
        "unresolved": [
            {
                "plist": entry["logical"]["plist"],
                "frame": entry["logical"]["path"],
                "selectedPlist": entry["selected"]["path"] if entry["selected"] else None,
                "status": entry["frameStatus"],
            }
            for entry in entries
            if entry["logical"]["type"] == "PlistSubImage"
            and entry["frameStatus"]
            not in {
                "exact",
                "basename",
                "fallback-file",
                "placeholder-recovery-required",
            }
        ],
    }
    return manifest, remap_manifest
