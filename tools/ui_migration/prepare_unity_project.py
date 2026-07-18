#!/usr/bin/env python3
"""Prepare deterministic Unity assets from the Cocos UI migration output.

The generated Unity tree mirrors the legacy client resource root:
client/ProjectX/res/<legacy path> -> unityclient/Assets/ProjectX/res/<legacy path>.
"""

from __future__ import annotations

import argparse
import json
import math
import plistlib
import re
import shutil
from pathlib import Path, PurePosixPath
from typing import Any

from PIL import Image


RECT_NUMBER = re.compile(r"-?\d+(?:\.\d+)?")


def _read_json(path: Path) -> dict[str, Any]:
    return json.loads(path.read_text(encoding="utf-8"))


def _write_json(path: Path, value: Any) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(
        json.dumps(value, ensure_ascii=False, indent=2, sort_keys=True) + "\n",
        encoding="utf-8",
    )


def _safe_relative(path: str) -> Path:
    normalized = PurePosixPath(path.replace("\\", "/"))
    if normalized.is_absolute() or ".." in normalized.parts:
        raise ValueError(f"Unsafe legacy path: {path}")
    return Path(*normalized.parts)


def _asset_key(resource: dict[str, Any]) -> str:
    return "|".join(
        (
            str(resource.get("type", "")).lower(),
            str(resource.get("plist", "")).replace("\\", "/").lower(),
            str(resource.get("path", "")).replace("\\", "/").lower(),
        )
    )


def _numbers(value: Any) -> list[float]:
    if isinstance(value, str):
        return [float(item) for item in RECT_NUMBER.findall(value)]
    if isinstance(value, (list, tuple)):
        return [float(item) for item in value]
    return []


def _rect(value: Any) -> tuple[int, int, int, int]:
    values = _numbers(value)
    if len(values) < 4:
        raise ValueError(f"Unsupported atlas rect: {value!r}")
    return tuple(int(round(item)) for item in values[:4])


def _point(value: Any, default: tuple[int, int]) -> tuple[int, int]:
    values = _numbers(value)
    if len(values) < 2:
        return default
    return int(round(values[0])), int(round(values[1]))


def _find_case_insensitive(mapping: dict[str, Any], wanted: str) -> tuple[str, Any] | None:
    wanted_lower = wanted.replace("\\", "/").lower()
    for key, value in mapping.items():
        if str(key).replace("\\", "/").lower() == wanted_lower:
            return str(key), value
    return None


def _find_sibling(parent: Path, filename: str) -> Path | None:
    direct = parent / filename
    if direct.exists():
        return direct
    wanted = filename.lower()
    return next((item for item in parent.iterdir() if item.name.lower() == wanted), None)


def _is_decodable_image(path: Path) -> bool:
    try:
        with Image.open(path) as image:
            image.verify()
        return True
    except (OSError, ValueError):
        return False


def _select_copy_asset(decision: dict[str, Any], logical_path: str) -> dict[str, Any] | None:
    selected = decision.get("selected") or decision.get("fallbackAsset")
    if not selected or Path(logical_path).suffix.lower() not in {".png", ".jpg", ".jpeg"}:
        return selected
    if _is_decodable_image(Path(selected["path"])):
        return selected
    for candidate in decision.get("candidates", []):
        if _is_decodable_image(Path(candidate["path"])):
            return candidate
    return selected


def _extract_frame(plist_path: Path, frame_name: str, destination: Path) -> None:
    with plist_path.open("rb") as stream:
        data = plistlib.load(stream)
    found = _find_case_insensitive(data.get("frames", {}), frame_name)
    if not found:
        raise KeyError(f"Frame {frame_name!r} not found in {plist_path}")
    _, frame = found
    metadata = data.get("metadata", {})
    texture_name = (
        metadata.get("realTextureFileName")
        or metadata.get("textureFileName")
        or f"{plist_path.stem}.png"
    )
    texture_path = _find_sibling(plist_path.parent, str(texture_name))
    if not texture_path:
        raise FileNotFoundError(f"Atlas texture {texture_name!r} not found beside {plist_path}")

    x, y, width, height = _rect(frame.get("frame") or frame.get("textureRect"))
    rotated = bool(frame.get("rotated") or frame.get("textureRotated"))
    source_width, source_height = _point(
        frame.get("sourceSize") or frame.get("spriteSourceSize"),
        (height, width) if rotated else (width, height),
    )
    offset_x, offset_y = _point(frame.get("offset") or frame.get("spriteOffset"), (0, 0))

    # TexturePacker format 2 stores the unrotated trimmed size in `frame`.
    # A rotated frame occupies height x width pixels in the atlas texture.
    packed_width, packed_height = (height, width) if rotated else (width, height)
    with Image.open(texture_path) as atlas:
        cropped = atlas.convert("RGBA").crop(
            (x, y, x + packed_width, y + packed_height)
        )
    if rotated:
        cropped = cropped.transpose(Image.Transpose.ROTATE_90)

    source_width = max(source_width, cropped.width)
    source_height = max(source_height, cropped.height)
    canvas = Image.new("RGBA", (source_width, source_height), (0, 0, 0, 0))
    paste_x = int(math.floor((source_width - cropped.width) / 2 + offset_x))
    paste_y = int(math.floor((source_height - cropped.height) / 2 - offset_y))
    canvas.alpha_composite(cropped, (paste_x, paste_y))
    destination.parent.mkdir(parents=True, exist_ok=True)
    canvas.save(destination)


def _property_attributes(node: dict[str, Any], name: str) -> dict[str, Any]:
    return node.get("properties", {}).get(name, {}).get("attributes", {})


def _color(node: dict[str, Any], property_name: str = "CColor") -> dict[str, float]:
    attrs = _property_attributes(node, property_name)
    alpha = node.get("attributes", {}).get("Alpha", attrs.get("A", 255))
    return {
        "r": float(attrs.get("R", 255)) / 255.0,
        "g": float(attrs.get("G", 255)) / 255.0,
        "b": float(attrs.get("B", 255)) / 255.0,
        "a": float(alpha) / 255.0,
    }


def _alignment(attributes: dict[str, Any]) -> str:
    horizontal = str(attributes.get("HorizontalAlignmentType", "HT_Center"))
    vertical = str(attributes.get("VerticalAlignmentType", "VT_Center"))
    h = "Left" if "Left" in horizontal else "Right" if "Right" in horizontal else "Center"
    v = "Upper" if "Top" in vertical else "Lower" if "Bottom" in vertical else "Middle"
    return v + h


def _resource_asset_path(resource: dict[str, Any]) -> str:
    logical_path = str(resource.get("path", "")).replace("\\", "/")
    resource_type = str(resource.get("type", ""))
    if not logical_path or resource_type.lower() == "default":
        return ""
    if resource_type.lower() == "markedsubimage":
        return f"Assets/ProjectX/res/csd/UnityMigration/Marked/{logical_path}"
    return f"Assets/ProjectX/res/{logical_path}"


def _normalize_resource(resource: dict[str, Any]) -> dict[str, Any]:
    logical_path = str(resource.get("path", "")).replace("\\", "/")
    resource_type = str(resource.get("type", ""))
    return {
        "property": str(resource.get("property", "")),
        "path": logical_path,
        "plist": str(resource.get("plist", "")).replace("\\", "/"),
        "type": resource_type,
        "assetPath": _resource_asset_path(resource),
    }


def _scale9_border(node: dict[str, Any], image_path: Path) -> tuple[int, int, int, int]:
    attrs = node.get("attributes", {})
    with Image.open(image_path) as image:
        width, height = image.size
    direct = tuple(
        max(0, int(round(float(attrs.get(name, 0) or 0))))
        for name in ("LeftEage", "BottomEage", "RightEage", "TopEage")
    )
    left, bottom, right, top = direct
    if any(direct) and left + right < width and bottom + top < height:
        return direct

    origin_x = max(0, int(round(float(attrs.get("Scale9OriginX", left) or 0))))
    origin_y = max(0, int(round(float(attrs.get("Scale9OriginY", bottom) or 0))))
    center_width = max(1, int(round(float(attrs.get("Scale9Width", 1) or 1))))
    center_height = max(1, int(round(float(attrs.get("Scale9Height", 1) or 1))))
    left = min(origin_x, max(0, width - 1))
    bottom = min(origin_y, max(0, height - 1))
    right = max(0, width - left - center_width)
    top = max(0, height - bottom - center_height)
    if not any((left, bottom, right, top)):
        raise ValueError(f"Scale9 node has no usable border: {node.get('nodePath')}")
    return left, bottom, right, top


def _slice_variant_path(source_asset_path: str, border: tuple[int, int, int, int]) -> str:
    prefix = "Assets/ProjectX/res/"
    if not source_asset_path.startswith(prefix):
        raise ValueError(f"Unexpected Unity resource path: {source_asset_path}")
    relative = PurePosixPath(source_asset_path[len(prefix) :])
    left, bottom, right, top = border
    filename = (
        f"{relative.stem}__L{left}_B{bottom}_R{right}_T{top}{relative.suffix}"
    )
    return str(
        PurePosixPath("Assets/ProjectX/res/csd/UnityMigration/Sliced")
        / relative.parent
        / filename
    )


def _normalize_node(
    node: dict[str, Any],
    unity_project: Path,
    slice_variants: dict[str, dict[str, Any]],
) -> dict[str, Any]:
    attrs = node.get("attributes", {})
    resources = [_normalize_resource(item) for item in node.get("resources", [])]
    font_resource = next(
        (
            item
            for item in resources
            if item["property"] == "FontResource"
            and item["assetPath"].lower().endswith((".ttf", ".otf"))
        ),
        None,
    )
    if bool(attrs.get("Scale9Enable", False)):
        for resource in resources:
            source_asset_path = resource["assetPath"]
            if not source_asset_path.lower().endswith(".png"):
                continue
            source_file = unity_project / _safe_relative(source_asset_path)
            if not source_file.exists():
                raise FileNotFoundError(
                    f"Scale9 source image is missing: {source_asset_path}"
                )
            border = _scale9_border(node, source_file)
            variant_path = _slice_variant_path(source_asset_path, border)
            slice_variants.setdefault(
                variant_path,
                {
                    "assetPath": variant_path,
                    "sourceAssetPath": source_asset_path,
                    "border": {
                        "x": border[0],
                        "y": border[1],
                        "z": border[2],
                        "w": border[3],
                    },
                },
            )
            resource["assetPath"] = variant_path
    return {
        "name": str(node.get("name") or "Node"),
        "nodePath": str(node.get("nodePath") or node.get("name") or "Node"),
        "nodeType": str(node.get("sourceType") or attrs.get("ctype") or "NodeObjectData"),
        "tag": int(node.get("tag") or 0),
        "actionTag": int(node.get("actionTag") or 0),
        "visible": bool(attrs.get("VisibleForFrame", attrs.get("Visible", True))),
        "touchEnabled": bool(attrs.get("TouchEnable", False)),
        "clip": bool(attrs.get("ClipAble", False)),
        "scale9": bool(attrs.get("Scale9Enable", False)),
        "checked": bool(attrs.get("CheckedState", False)),
        "progress": float(attrs.get("ProgressInfo", 100.0)) / 100.0,
        "text": str(attrs.get("ButtonText", attrs.get("LabelText", ""))),
        "placeholder": str(attrs.get("PlaceHolderText", "")),
        "fontSize": int(float(attrs.get("FontSize", attrs.get("CharHeight", 20)))),
        "fontAssetPath": (
            font_resource["assetPath"]
            if font_resource
            else "Assets/ProjectX/res/MicrosoftArial.ttf"
        ),
        "alignment": _alignment(attrs),
        "color": _color(node),
        "textColor": _color(node, "TextColor"),
        "outlineEnabled": bool(attrs.get("OutlineEnabled", False)),
        "outlineSize": float(attrs.get("OutlineSize", 1.0) or 1.0),
        "outlineColor": _color(node, "OutlineColor"),
        "shadowEnabled": bool(attrs.get("ShadowEnabled", False)),
        "shadowOffset": {
            "x": float(attrs.get("ShadowOffsetX", 2.0) or 0.0),
            "y": float(attrs.get("ShadowOffsetY", -2.0) or 0.0),
        },
        "shadowColor": _color(node, "ShadowColor"),
        "rect": node.get("unityRect", {}),
        "resources": resources,
        "children": [
            _normalize_node(child, unity_project, slice_variants)
            for child in node.get("children", [])
        ],
    }


def _normalize_clips(animation_list: dict[str, Any] | None) -> list[dict[str, Any]]:
    if not animation_list:
        return []
    if isinstance(animation_list.get("clips"), list):
        return list(animation_list["clips"])
    clips = []
    for item in animation_list.get("children", []):
        if item.get("tag") != "AnimationInfo":
            continue
        values = item.get("attributes", {})
        clips.append(
            {
                "name": str(values.get("Name", "")),
                "startFrame": int(values.get("StartIndex", 0)),
                "endFrame": int(values.get("EndIndex", 0)),
            }
        )
    return clips


def _normalize_animation(
    animation: dict[str, Any] | None,
    animation_list: dict[str, Any] | None = None,
) -> dict[str, Any] | None:
    if not animation:
        return None
    if isinstance(animation.get("timelines"), list):
        normalized = dict(animation)
        normalized["frameRate"] = 60
        normalized["clips"] = _normalize_clips(animation) or list(animation.get("clips", []))
        normalized["duration"] = max(
            int(normalized.get("duration", 0)),
            max(
                (
                    int(frame.get("frame", 0))
                    for timeline in normalized["timelines"]
                    for frame in timeline.get("frames", [])
                ),
                default=0,
            ),
            max(
                (int(clip.get("endFrame", 0)) for clip in normalized["clips"]),
                default=0,
            ),
        )
        return normalized
    attributes = animation.get("attributes", {})
    timelines = []
    maximum_frame = 0
    for timeline in animation.get("children", []):
        if timeline.get("tag") != "Timeline":
            continue
        timeline_attributes = timeline.get("attributes", {})
        frames = []
        for frame in timeline.get("children", []):
            values = frame.get("attributes", {})
            frame_index = int(values.get("FrameIndex", 0))
            maximum_frame = max(maximum_frame, frame_index)
            easing = next(
                (
                    child.get("attributes", {})
                    for child in frame.get("children", [])
                    if child.get("tag") == "EasingData"
                ),
                {},
            )
            scalar_value = (
                0.0
                if frame.get("tag") == "EventFrame"
                else float(
                    values.get(
                        "Value",
                        values.get("Rotation", values.get("Alpha", 0.0)),
                    )
                    or 0.0
                )
            )
            frames.append(
                {
                    "frame": frame_index,
                    "x": float(values.get("X", values.get("ScaleX", 0.0)) or 0.0),
                    "y": float(values.get("Y", values.get("ScaleY", 0.0)) or 0.0),
                    "value": scalar_value,
                    "visible": bool(values.get("Value", True)),
                    "tween": bool(values.get("Tween", True)),
                    "easingType": int(easing.get("Type", 0)),
                    "eventName": str(values.get("Value", ""))
                    if frame.get("tag") == "EventFrame"
                    else "",
                }
            )
        timelines.append(
            {
                "actionTag": int(timeline_attributes.get("ActionTag", 0)),
                "property": str(timeline_attributes.get("Property", "")),
                "frames": frames,
            }
        )
    clips = _normalize_clips(animation_list)
    duration = max(
        int(attributes.get("Duration", 0)),
        maximum_frame,
        max((int(item["endFrame"]) for item in clips), default=0),
    )
    return {
        "duration": duration,
        "speed": float(attributes.get("Speed", 1.0) or 1.0),
        "frameRate": 60,
        "currentAnimationName": str(attributes.get("ActivedAnimationName", "")),
        "clips": clips,
        "timelines": timelines,
    }


def _prefab_relative(source: str, name: str) -> Path:
    parts = list(PurePosixPath(source.replace("\\", "/")).parts)
    try:
        csd_index = next(index for index, part in enumerate(parts) if part.lower() == "csd")
        relative = Path(*parts[csd_index + 1 :])
    except StopIteration:
        relative = Path(f"{name}.csd")
    if not relative.name:
        relative = Path(f"{name}.csd")
    return relative.with_suffix(".prefab")


def _runtime_csb_path(source: str, ir_path: Path, kind: str) -> str:
    if kind == "csb":
        relative = ir_path.name.removesuffix(".json")
        parent = ir_path.parent
        return (parent / relative).as_posix().lower()
    parts = list(PurePosixPath(source.replace("\\", "/")).parts)
    try:
        index = next(i for i, part in enumerate(parts) if part.lower() == "csd")
        return PurePosixPath(*parts[index + 1 :]).with_suffix(".csb").as_posix().lower()
    except StopIteration:
        return PurePosixPath(source).with_suffix(".csb").as_posix().lower()


def _document_specs(migration_root: Path, scope: str) -> list[dict[str, Any]]:
    baseline_manifest = _read_json(migration_root / "baselines" / "manifest.json")
    baseline_sources = {
        str(item["source"]).replace("\\", "/").lower()
        for item in baseline_manifest["baselines"]
    }
    if scope == "baseline":
        return [
            {
                "name": str(item["name"]),
                "source": str(item["source"]),
                "irPath": str(item["irPath"]),
                "preview": True,
            }
            for item in baseline_manifest["baselines"]
        ]

    specs: list[dict[str, Any]] = []
    for kind in ("csd", "csb"):
        for ir_path in sorted((migration_root / kind).rglob("*.json")):
            ir = _read_json(ir_path)
            source = str(ir.get("source", {}).get("path", ""))
            name = str(
                ir.get("source", {}).get("metadata", {}).get("Name")
                or ir_path.name.removesuffix(f".{kind}.json")
            )
            specs.append(
                {
                    "name": name,
                    "source": source,
                    "irPath": ir_path.relative_to(migration_root).as_posix(),
                    "preview": source.replace("\\", "/").lower() in baseline_sources,
                    "kind": kind,
                    "runtimePath": _runtime_csb_path(
                        source, ir_path.relative_to(migration_root / kind), kind
                    ),
                }
            )
    if scope in {"referenced", "welfare", "timeline"}:
        usage = _read_json(migration_root / "runtime-ui-usage.json")
        selected = {
            str(value).lower()
            for value in usage["sets"][
                "welfare" if scope == "welfare" else "timeline" if scope == "timeline" else "referenced"
            ]
        }
        specs = [item for item in specs if item["runtimePath"] in selected]
    return specs


def prepare(unity_project: Path, migration_root: Path, scope: str = "all") -> dict[str, Any]:
    assets_root = unity_project / "Assets" / "ProjectX" / "res"
    data_root = assets_root / "csd" / "UnityMigration"
    asset_manifest = _read_json(migration_root / "asset-manifest.json")
    asset_lookup = {item["key"]: item for item in asset_manifest["assets"]}

    documents: list[dict[str, Any]] = []
    pending_documents: list[tuple[dict[str, Any], dict[str, Any], str, Path]] = []
    resources: dict[str, dict[str, Any]] = {}
    for spec in _document_specs(migration_root, scope):
        ir = _read_json(migration_root / _safe_relative(spec["irPath"]))
        source = str(spec["source"])
        prefab_relative = (
            Path("csb") / Path(spec["runtimePath"]).with_suffix(".prefab")
            if spec.get("kind") == "csb"
            else _prefab_relative(source, spec["name"])
        )
        document_relative = Path("documents") / prefab_relative.with_suffix(".json")
        pending_documents.append((spec, ir, source, document_relative))
        documents.append(
            {
                "name": spec["name"],
                "source": source,
                "preview": bool(spec["preview"]),
                "documentAssetPath": "Assets/ProjectX/res/csd/UnityMigration/"
                + document_relative.as_posix(),
                "prefabAssetPath": "Assets/ProjectX/res/csd/Prefabs/"
                + prefab_relative.as_posix(),
            }
        )
        for resource in ir.get("resources", []):
            if resource.get("path"):
                resources.setdefault(_asset_key(resource), resource)

    generated_assets: list[str] = []
    placeholders: list[str] = []
    source_substitutions: list[str] = []
    for key, resource in sorted(resources.items()):
        decision = asset_lookup.get(key)
        if not decision:
            raise KeyError(f"Resource is absent from asset manifest: {key}")
        logical_path = str(resource["path"]).replace("\\", "/")
        asset_path = _resource_asset_path(resource)
        destination = unity_project / _safe_relative(asset_path)
        if str(resource.get("type", "")).lower() == "plistsubimage":
            fallback = decision.get("fallbackAsset")
            frame_name = decision.get("remappedFrame")
            selected = decision.get("selected")
            if fallback and not frame_name:
                destination.parent.mkdir(parents=True, exist_ok=True)
                shutil.copy2(Path(fallback["path"]), destination)
                placeholders.append(logical_path)
            elif selected and frame_name:
                _extract_frame(Path(selected["path"]), frame_name, destination)
            else:
                raise FileNotFoundError(f"No atlas frame or fallback for {key}")
        else:
            selected = _select_copy_asset(decision, logical_path)
            if not selected:
                continue
            preferred = decision.get("selected") or decision.get("fallbackAsset")
            if preferred and selected["path"] != preferred["path"]:
                source_substitutions.append(logical_path)
            destination.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(Path(selected["path"]), destination)
        generated_assets.append(asset_path)

    default_font_source = migration_root.parents[1] / "client" / "ProjectX" / "res" / "MicrosoftArial.ttf"
    default_font_destination = assets_root / "MicrosoftArial.ttf"
    if not default_font_source.exists():
        raise FileNotFoundError(f"Default client font is missing: {default_font_source}")
    default_font_destination.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(default_font_source, default_font_destination)
    generated_assets.append("Assets/ProjectX/res/MicrosoftArial.ttf")

    slice_variants: dict[str, dict[str, Any]] = {}
    for spec, ir, source, document_relative in pending_documents:
        _write_json(
            data_root / document_relative,
            {
                "schemaVersion": 1,
                "name": spec["name"],
                "source": source,
                "root": _normalize_node(ir["root"], unity_project, slice_variants),
                "animation": _normalize_animation(
                    ir.get("animation"), ir.get("animationList")
                ),
            },
        )

    for variant in slice_variants.values():
        source = unity_project / _safe_relative(variant["sourceAssetPath"])
        destination = unity_project / _safe_relative(variant["assetPath"])
        destination.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(source, destination)
        generated_assets.append(variant["assetPath"])

    result = {
        "schemaVersion": 1,
        "legacyClientRoot": "client/ProjectX",
        "unityClientRoot": "unityclient/Assets/ProjectX",
        "resourceRoot": "Assets/ProjectX/res",
        "prefabRoot": "Assets/ProjectX/res/csd/Prefabs",
        "previewScene": "Assets/ProjectX/Scenes/UIMigrationPreview.unity",
        "documents": documents,
        "spriteBorders": sorted(slice_variants.values(), key=lambda item: item["assetPath"]),
        "generatedAssets": sorted(set(generated_assets)),
        "statistics": {
            "scope": scope,
            "documents": len(documents),
            "logicalResources": len(resources),
            "generatedAssets": len(set(generated_assets)),
            "slicedSpriteVariants": len(slice_variants),
            "artRecoveryPlaceholders": len(placeholders),
            "decodableImageSubstitutions": len(source_substitutions),
        },
        "artRecoveryPlaceholders": sorted(placeholders),
        "decodableImageSubstitutions": sorted(source_substitutions),
    }
    manifest_name = (
        "unity-import-manifest.timeline.json"
        if scope == "timeline"
        else "unity-import-manifest.json"
    )
    _write_json(data_root / manifest_name, result)
    return result


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--repo-root", type=Path, default=Path(__file__).resolve().parents[2])
    parser.add_argument("--unity-project", type=Path)
    parser.add_argument("--migration-root", type=Path)
    parser.add_argument(
        "--scope", choices=("all", "baseline", "referenced", "welfare", "timeline"), default="all"
    )
    args = parser.parse_args()
    repo_root = args.repo_root.resolve()
    unity_project = (args.unity_project or repo_root / "unityclient").resolve()
    migration_root = (args.migration_root or repo_root / "build" / "ui-migration").resolve()
    result = prepare(unity_project, migration_root, args.scope)
    print(json.dumps(result["statistics"], ensure_ascii=False, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
