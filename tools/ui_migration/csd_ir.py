from __future__ import annotations

import re
import xml.etree.ElementTree as ET
from collections import Counter
from pathlib import Path
from typing import Any, Iterable


IR_SCHEMA_VERSION = 1

UNITY_COMPONENT_HINTS = {
    "GameLayerObjectData": ["Canvas", "RectTransform"],
    "GameNodeObjectData": ["RectTransform"],
    "ProjectNodeObjectData": ["RectTransform"],
    "SingleNodeObjectData": ["RectTransform"],
    "PanelObjectData": ["RectTransform", "Image"],
    "ImageViewObjectData": ["RectTransform", "Image"],
    "ButtonObjectData": ["RectTransform", "Image", "Button"],
    "TextObjectData": ["RectTransform", "TextMeshProUGUI"],
    "TextAtlasObjectData": ["RectTransform", "Image"],
    "TextFieldObjectData": ["RectTransform", "TMP_InputField"],
    "ListViewObjectData": ["RectTransform", "ScrollRect", "LayoutGroup"],
    "ScrollViewObjectData": ["RectTransform", "ScrollRect"],
    "PageViewObjectData": ["RectTransform", "ScrollRect"],
    "LoadingBarObjectData": ["RectTransform", "Image(Filled)"],
    "CheckBoxObjectData": ["RectTransform", "Toggle"],
    "SliderObjectData": ["RectTransform", "Slider"],
    "ParticleObjectData": ["RectTransform", "ParticleSystem"],
    "SpriteObjectData": ["RectTransform", "Image"],
}

_INT_RE = re.compile(r"^[+-]?\d+$")
_FLOAT_RE = re.compile(
    r"^[+-]?(?:(?:\d+\.\d*)|(?:\d*\.\d+)|(?:\d+))(?:[eE][+-]?\d+)?$"
)


def smart_value(value: str) -> Any:
    """Convert unambiguous XML scalar values while preserving IDs and paths."""
    if value == "True":
        return True
    if value == "False":
        return False
    if _INT_RE.fullmatch(value):
        try:
            return int(value)
        except ValueError:
            return value
    if _FLOAT_RE.fullmatch(value) and ("." in value or "e" in value.lower()):
        try:
            return float(value)
        except ValueError:
            return value
    return value


def typed_attributes(element: ET.Element | None) -> dict[str, Any]:
    if element is None:
        return {}
    return {key: smart_value(value) for key, value in element.attrib.items()}


def _append_value(target: dict[str, Any], key: str, value: Any) -> None:
    if key not in target:
        target[key] = value
    elif isinstance(target[key], list):
        target[key].append(value)
    else:
        target[key] = [target[key], value]


def element_to_data(element: ET.Element) -> dict[str, Any]:
    """Loss-minimizing conversion for animation and uncommon CSD elements."""
    result: dict[str, Any] = {"tag": element.tag}
    if element.attrib:
        result["attributes"] = typed_attributes(element)
    children = [element_to_data(child) for child in element]
    if children:
        result["children"] = children
    text = (element.text or "").strip()
    if text:
        result["text"] = text
    return result


def _properties_from_children(node: ET.Element) -> dict[str, Any]:
    properties: dict[str, Any] = {}
    for child in node:
        if child.tag == "Children":
            continue
        value = element_to_data(child)
        value.pop("tag", None)
        _append_value(properties, child.tag, value)
    return properties


def parse_node(node: ET.Element) -> dict[str, Any]:
    attrs = typed_attributes(node)
    source_type = str(attrs.get("ctype", node.tag))
    children_container = node.find("Children")
    children = []
    if children_container is not None:
        children = [parse_node(child) for child in children_container]

    properties = _properties_from_children(node)
    resources: list[dict[str, Any]] = []
    for property_name, property_value in properties.items():
        values = property_value if isinstance(property_value, list) else [property_value]
        for value in values:
            if not isinstance(value, dict):
                continue
            resource_attrs = value.get("attributes", {})
            if "Path" not in resource_attrs and "Plist" not in resource_attrs:
                continue
            resources.append(
                {
                    "nodeName": attrs.get("Name", ""),
                    "nodeType": source_type,
                    "property": property_name,
                    "type": resource_attrs.get("Type", ""),
                    "path": resource_attrs.get("Path", ""),
                    "plist": resource_attrs.get("Plist", ""),
                }
            )

    return {
        "name": attrs.get("Name", ""),
        "sourceTag": node.tag,
        "sourceType": source_type,
        "unityComponentHints": UNITY_COMPONENT_HINTS.get(
            source_type, ["RectTransform", "UNSUPPORTED"]
        ),
        "actionTag": attrs.get("ActionTag"),
        "tag": attrs.get("Tag"),
        "attributes": attrs,
        "properties": properties,
        "resources": resources,
        "children": children,
    }


def walk_nodes(root: dict[str, Any]) -> Iterable[dict[str, Any]]:
    yield root
    for child in root.get("children", []):
        yield from walk_nodes(child)


def iter_resource_references(root: dict[str, Any]) -> Iterable[dict[str, Any]]:
    for node in walk_nodes(root):
        if "resources" in node:
            yield from node["resources"]
            continue
        properties = node.get("properties", {})
        for property_name, property_value in properties.items():
            values = property_value if isinstance(property_value, list) else [property_value]
            for value in values:
                if not isinstance(value, dict):
                    continue
                attrs = value.get("attributes", {})
                if "Path" not in attrs and "Plist" not in attrs:
                    continue
                yield {
                    "nodeName": node.get("name", ""),
                    "nodeType": node.get("sourceType", ""),
                    "property": property_name,
                    "type": attrs.get("Type", ""),
                    "path": attrs.get("Path", ""),
                    "plist": attrs.get("Plist", ""),
                }


def parse_csd(path: Path, source_root: Path | None = None) -> dict[str, Any]:
    tree = ET.parse(path)
    game_file = tree.getroot()
    if game_file.tag != "GameFile":
        raise ValueError(f"Unsupported CSD root '{game_file.tag}': {path}")

    property_group = game_file.find("PropertyGroup")
    content = game_file.find("./Content/Content")
    if content is None:
        raise ValueError(f"CSD has no Content/Content section: {path}")

    object_data = content.find("ObjectData")
    if object_data is None:
        raise ValueError(f"CSD has no ObjectData root: {path}")

    root_node = parse_node(object_data)
    animation = content.find("Animation")
    animation_list = content.find("AnimationList")
    metadata = typed_attributes(property_group)
    rel_path = path.as_posix()
    if source_root is not None:
        try:
            rel_path = path.resolve().relative_to(source_root.resolve()).as_posix()
        except ValueError:
            pass

    type_counts = Counter(
        str(node.get("sourceType", "Unknown")) for node in walk_nodes(root_node)
    )
    unsupported = sorted(
        node_type for node_type in type_counts if node_type not in UNITY_COMPONENT_HINTS
    )
    resources = list(iter_resource_references(root_node))

    return {
        "schemaVersion": IR_SCHEMA_VERSION,
        "kind": "CocosStudioUI",
        "source": {
            "path": rel_path,
            "format": "CSD XML",
            "metadata": metadata,
        },
        "coordinateSystem": {
            "origin": "bottom-left",
            "xAxis": "right",
            "yAxis": "up",
            "unit": "pixel",
        },
        "animation": element_to_data(animation) if animation is not None else None,
        "animationList": (
            element_to_data(animation_list) if animation_list is not None else None
        ),
        "root": root_node,
        "resources": resources,
        "statistics": {
            "nodeCount": sum(type_counts.values()),
            "nodeTypes": dict(sorted(type_counts.items())),
            "unsupportedNodeTypes": unsupported,
            "resourceReferenceCount": len(resources),
        },
    }
