from __future__ import annotations

import re
from collections import Counter
from typing import Any, Iterable

from csd_ir import UNITY_COMPONENT_HINTS, walk_nodes


_IDENTIFIER_PARTS = re.compile(r"[^0-9A-Za-z_\u0080-\uffff]+")


def property_attributes(node: dict[str, Any], name: str) -> dict[str, Any]:
    value = node.get("properties", {}).get(name, {})
    if isinstance(value, list):
        value = value[0] if value else {}
    return value.get("attributes", {}) if isinstance(value, dict) else {}


def _number(attributes: dict[str, Any], key: str, default: float) -> float:
    value = attributes.get(key, default)
    return float(value) if isinstance(value, (int, float)) else default


def attach_unity_layout(root: dict[str, Any]) -> None:
    """Attach a lossless, bottom-left anchored RectTransform recommendation."""

    def visit(node: dict[str, Any], parent_size: tuple[float, float] | None) -> None:
        size = property_attributes(node, "Size")
        position = property_attributes(node, "Position")
        anchor = property_attributes(node, "AnchorPoint")
        scale = property_attributes(node, "Scale")
        pre_position = property_attributes(node, "PrePosition")
        rotation = property_attributes(node, "RotationSkew")
        attrs = node.get("attributes", {})

        width = _number(size, "X", 0.0)
        height = _number(size, "Y", 0.0)
        x = _number(position, "X", 0.0)
        y = _number(position, "Y", 0.0)
        pivot_x = _number(anchor, "ScaleX", 0.0)
        pivot_y = _number(anchor, "ScaleY", 0.0)
        scale_x = _number(scale, "ScaleX", 1.0)
        scale_y = _number(scale, "ScaleY", 1.0)
        percent_x = bool(attrs.get("PositionPercentXEnabled", False))
        percent_y = bool(attrs.get("PositionPercentYEnabled", False))

        anchor_x = 0.0
        anchor_y = 0.0
        anchored_x = x
        anchored_y = y
        if percent_x:
            anchor_x = _number(pre_position, "X", x / parent_size[0] if parent_size and parent_size[0] else 0.0)
            anchored_x = 0.0
        if percent_y:
            anchor_y = _number(pre_position, "Y", y / parent_size[1] if parent_size and parent_size[1] else 0.0)
            anchored_y = 0.0

        rotation_x = _number(rotation, "X", _number(attrs, "RotationSkewX", 0.0))
        node["unityRect"] = {
            "anchorMin": {"x": anchor_x, "y": anchor_y},
            "anchorMax": {"x": anchor_x, "y": anchor_y},
            "pivot": {"x": pivot_x, "y": pivot_y},
            "anchoredPosition": {"x": anchored_x, "y": anchored_y},
            "sizeDelta": {"x": width, "y": height},
            "localScale": {"x": scale_x, "y": scale_y, "z": 1.0},
            "localEulerAngles": {"x": 0.0, "y": 0.0, "z": -rotation_x},
            "policy": "cocos-bottom-left-v1",
            "sourcePosition": {"x": x, "y": y},
            "usesPercentPosition": {"x": percent_x, "y": percent_y},
        }
        child_parent_size = (width, height)
        for child in node.get("children", []):
            visit(child, child_parent_size)

    visit(root, None)


def attach_paths_and_collect_resources(root: dict[str, Any]) -> list[dict[str, Any]]:
    resources: list[dict[str, Any]] = []

    def visit(node: dict[str, Any], parent_path: str) -> None:
        name = str(node.get("name") or node.get("sourceType") or "Node")
        path = f"{parent_path}/{name}" if parent_path else name
        node["nodePath"] = path
        node["unityComponentHints"] = UNITY_COMPONENT_HINTS.get(
            str(node.get("sourceType", "")), ["RectTransform", "UNSUPPORTED"]
        )
        for reference in node.get("resources", []):
            normalized = dict(reference)
            normalized["nodeName"] = name
            normalized["nodeType"] = node.get("sourceType", "")
            normalized["nodePath"] = path
            resources.append(normalized)
        for child in node.get("children", []):
            visit(child, path)

    visit(root, "")
    return resources


def suggested_field_name(name: str, index: int) -> str:
    cleaned = _IDENTIFIER_PARTS.sub("_", name).strip("_") or f"Node{index}"
    if cleaned[0].isdigit():
        cleaned = "Node_" + cleaned
    return cleaned


def build_binding_manifest(ir: dict[str, Any]) -> dict[str, Any]:
    entries: list[dict[str, Any]] = []
    field_counts: Counter[str] = Counter()
    for index, node in enumerate(walk_nodes(ir["root"])):
        name = str(node.get("name") or "")
        if not name:
            continue
        field = suggested_field_name(name, index)
        field_counts[field] += 1
        entries.append(
            {
                "nodePath": node.get("nodePath", name),
                "nodeName": name,
                "sourceType": node.get("sourceType", ""),
                "actionTag": node.get("actionTag"),
                "suggestedField": field,
                "unityComponentHints": node.get("unityComponentHints", []),
                "recommended": node.get("sourceType")
                in {
                    "ButtonObjectData",
                    "CheckBoxObjectData",
                    "TextObjectData",
                    "TextFieldObjectData",
                    "LoadingBarObjectData",
                    "SliderObjectData",
                    "ListViewObjectData",
                    "ScrollViewObjectData",
                    "PageViewObjectData",
                },
            }
        )
    duplicates = sorted(name for name, count in field_counts.items() if count > 1)
    return {
        "schemaVersion": 1,
        "source": ir.get("source", {}),
        "bindingCount": len(entries),
        "duplicateSuggestedFields": duplicates,
        "bindings": entries,
    }


def validate_ir_contract(ir: dict[str, Any]) -> list[str]:
    errors: list[str] = []
    required_top = {
        "schemaVersion",
        "kind",
        "source",
        "coordinateSystem",
        "root",
        "resources",
        "statistics",
    }
    for field in sorted(required_top - ir.keys()):
        errors.append(f"missing top-level field: {field}")
    if ir.get("schemaVersion") != 1:
        errors.append("schemaVersion must be 1")
    required_node = {
        "nodePath",
        "name",
        "sourceType",
        "attributes",
        "properties",
        "resources",
        "unityComponentHints",
        "unityRect",
        "children",
    }
    root = ir.get("root")
    if isinstance(root, dict):
        for node in walk_nodes(root):
            path = node.get("nodePath", "<unknown>")
            for field in sorted(required_node - node.keys()):
                errors.append(f"{path}: missing node field {field}")
    elif "root" in ir:
        errors.append("root must be an object")
    return errors


def select_baselines(files: list[dict[str, Any]], limit: int = 10) -> list[dict[str, Any]]:
    """Deterministic greedy set cover over node types, animation and complexity."""
    candidates = [item for item in files if not item.get("error")]
    uncovered = set()
    for item in candidates:
        uncovered.update(item.get("nodeTypes", {}).keys())
    selected: list[dict[str, Any]] = []
    remaining = list(candidates)
    while remaining and len(selected) < limit:
        def score(item: dict[str, Any]) -> tuple[int, int, int, str]:
            types = set(item.get("nodeTypes", {}))
            new_types = len(types & uncovered)
            animation = int(item.get("animationDuration", 0) > 0)
            complexity = min(int(item.get("nodeCount", 0)), 500)
            return (new_types, animation, complexity, item.get("source", ""))

        best = max(remaining, key=score)
        remaining.remove(best)
        selected.append(best)
        uncovered.difference_update(best.get("nodeTypes", {}).keys())
    return [
        {
            "source": item["source"],
            "name": item.get("name", ""),
            "nodeCount": item.get("nodeCount", 0),
            "nodeTypes": item.get("nodeTypes", {}),
            "animationDuration": item.get("animationDuration", 0),
            "issueCount": item.get("issueCount", 0),
            "bindingPath": item.get("bindingPath", ""),
            "irPath": item.get("irPath", ""),
        }
        for item in selected
    ]
