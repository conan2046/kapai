from __future__ import annotations

import json
import subprocess
from collections import Counter
from pathlib import Path
from typing import Any

from csd_ir import UNITY_COMPONENT_HINTS, walk_nodes
from ir_enrichment import attach_paths_and_collect_resources, attach_unity_layout


def parse_csb(
    path: Path,
    dumper: Path,
    temp_output: Path,
    source_root: Path | None = None,
) -> dict[str, Any]:
    temp_output.parent.mkdir(parents=True, exist_ok=True)
    completed = subprocess.run(
        [str(dumper), str(path), str(temp_output)],
        capture_output=True,
        text=True,
        encoding="utf-8",
        errors="replace",
        check=False,
    )
    if completed.returncode != 0:
        raise RuntimeError(
            f"csb_dump failed ({completed.returncode}): {completed.stderr.strip()}"
        )
    with temp_output.open("r", encoding="utf-8") as stream:
        result = json.load(stream)

    rel_path = path.as_posix()
    if source_root is not None:
        try:
            rel_path = path.resolve().relative_to(source_root.resolve()).as_posix()
        except ValueError:
            pass
    result["source"] = {
        "path": rel_path,
        "format": "CSB FlatBuffers",
        "metadata": {
            "Name": path.stem,
            "Version": result.pop("sourceVersion", ""),
            "Fidelity": "layout-and-resources",
        },
    }
    attach_unity_layout(result["root"])
    result["resources"] = attach_paths_and_collect_resources(result["root"])
    type_counts = Counter(
        str(node.get("sourceType", "Unknown")) for node in walk_nodes(result["root"])
    )
    result["statistics"]["nodeTypes"] = dict(sorted(type_counts.items()))
    result["statistics"]["nodeCount"] = sum(type_counts.values())
    result["statistics"]["unsupportedNodeTypes"] = sorted(
        node_type for node_type in type_counts if node_type not in UNITY_COMPONENT_HINTS
    )
    result["statistics"]["resourceReferenceCount"] = len(result["resources"])
    return result
