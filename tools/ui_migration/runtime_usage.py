from __future__ import annotations

import re
from pathlib import Path, PurePosixPath
from typing import Any, Iterable


WELFARE_SOURCE_PREFIXES = (
    "view/welfare/",
    "view/dailysign/",
    "view/operationalactivity/",
    "view/welfareactivity/",
)


def normalize_csb_path(value: str) -> str:
    """Return a case-insensitive path relative to the runtime csd directory."""
    normalized = value.replace("\\", "/").strip().lstrip("./")
    lowered = normalized.casefold()
    marker = "csd/"
    marker_index = lowered.find(marker)
    if marker_index >= 0:
        normalized = normalized[marker_index + len(marker) :]
    return PurePosixPath(normalized).as_posix().casefold()


def relative_csb_key(path: Path, root: Path) -> str:
    return path.relative_to(root).with_suffix(".csb").as_posix().casefold()


def _lua_strings(text: str) -> Iterable[tuple[str, int]]:
    """Yield ordinary Lua string literals while ignoring line and block comments."""
    index = 0
    line = 1
    length = len(text)
    while index < length:
        char = text[index]
        if char == "\n":
            line += 1
            index += 1
            continue
        if char == "-" and index + 1 < length and text[index + 1] == "-":
            if text.startswith("--[[", index):
                end = text.find("]]", index + 4)
                if end < 0:
                    return
                line += text[index : end + 2].count("\n")
                index = end + 2
            else:
                end = text.find("\n", index + 2)
                if end < 0:
                    return
                index = end
            continue
        if char not in {"'", '"'}:
            index += 1
            continue

        quote = char
        literal_line = line
        index += 1
        value: list[str] = []
        while index < length:
            char = text[index]
            if char == "\\" and index + 1 < length:
                value.append(text[index + 1])
                index += 2
                continue
            if char == quote:
                index += 1
                break
            if char == "\n":
                line += 1
            value.append(char)
            index += 1
        yield "".join(value), literal_line


def collect_lua_csb_references(source_root: Path) -> dict[str, list[dict[str, Any]]]:
    references: dict[str, list[dict[str, Any]]] = {}
    paths = sorted(
        {path for pattern in ("*.lua", "*.Lua") for path in source_root.rglob(pattern)},
        key=lambda item: item.as_posix().casefold(),
    )
    for path in paths:
        source = path.relative_to(source_root).as_posix()
        text = path.read_text(encoding="utf-8-sig", errors="replace")
        for value, line in _lua_strings(text):
            if not value.casefold().endswith(".csb"):
                continue
            # Formatted and concatenated paths require a separate runtime audit.
            dynamic = bool(re.search(r"[%{}]", value))
            key = normalize_csb_path(value)
            references.setdefault(key, []).append(
                {"source": source, "line": line, "literal": value, "dynamic": dynamic}
            )
    return references


def collect_timeline_csb_references(source_root: Path) -> dict[str, list[dict[str, Any]]]:
    """Resolve active CSLoader timelines and literal Utils:PlayAction targets.

    The legacy tree contains one commented createTimeline statement and one helper
    whose CSB path is supplied by callers.  A plain text count therefore cannot be
    used as the import scope.
    """
    references: dict[str, list[dict[str, Any]]] = {}
    assignment_pattern = re.compile(
        r"(?m)^\s*(?:local\s+)?([A-Za-z_]\w*)\s*=\s*(['\"])([^'\"]+\.csb)\2"
    )
    timeline_pattern = re.compile(r"CSLoader:createTimeline\s*\(([^)]*)\)")
    literal_pattern = re.compile(r"^\s*(['\"])([^'\"]+\.csb)\1\s*$")
    helper_pattern = re.compile(
        r"(?:Utils[:.]PlayAction|:PlayAction)\s*\(\s*(['\"])([^'\"]+\.csb)\1"
    )

    for path in sorted(source_root.rglob("*.lua"), key=lambda item: item.as_posix().casefold()):
        source = path.relative_to(source_root).as_posix()
        text = path.read_text(encoding="utf-8-sig", errors="replace")
        assignments = {
            match.group(1): match.group(3) for match in assignment_pattern.finditer(text)
        }
        for line_number, line in enumerate(text.splitlines(), 1):
            if line.lstrip().startswith("--"):
                continue
            timeline = timeline_pattern.search(line)
            value = None
            kind = "createTimeline"
            if timeline:
                expression = timeline.group(1).strip()
                literal = literal_pattern.fullmatch(expression)
                value = literal.group(2) if literal else assignments.get(expression)
                # The unresolved `path` parameter belongs to Utils:PlayAction and
                # is represented by each concrete helper call below.
            helper = helper_pattern.search(line)
            if helper and "function Utils:PlayAction" not in line:
                value = helper.group(2)
                kind = "Utils:PlayAction"
            if not value:
                continue
            key = normalize_csb_path(value)
            references.setdefault(key, []).append(
                {
                    "source": source,
                    "line": line_number,
                    "literal": value,
                    "kind": kind,
                }
            )
    return references


def build_runtime_usage(
    source_root: Path,
    csb_root: Path,
    csd_root: Path,
) -> dict[str, Any]:
    references = collect_lua_csb_references(source_root)
    timeline_references = collect_timeline_csb_references(source_root)
    runtime_paths = {
        path.relative_to(csb_root).as_posix().casefold(): path
        for path in csb_root.rglob("*.csb")
    }
    editor_paths = {
        relative_csb_key(path, csd_root): path for path in csd_root.rglob("*.csd")
    }
    referenced = set(references)
    timeline = set(timeline_references)
    welfare = {
        key
        for key, occurrences in references.items()
        if any(
            str(item["source"]).casefold().startswith(WELFARE_SOURCE_PREFIXES)
            for item in occurrences
        )
    }
    duplicate_names: dict[str, list[str]] = {}
    for key in sorted(runtime_paths):
        duplicate_names.setdefault(PurePosixPath(key).name, []).append(key)
    duplicate_names = {
        name: paths for name, paths in duplicate_names.items() if len(paths) > 1
    }

    entries = []
    for key in sorted(referenced | set(runtime_paths) | set(editor_paths)):
        entries.append(
            {
                "path": key,
                "referenced": key in referenced,
                "welfare": key in welfare,
                "timeline": key in timeline,
                "runtimeExists": key in runtime_paths,
                "editorCsdExists": key in editor_paths,
                "occurrences": references.get(key, []),
                "timelineOccurrences": timeline_references.get(key, []),
            }
        )

    return {
        "schemaVersion": 1,
        "sourceRoot": source_root.as_posix(),
        "runtimeCsbRoot": csb_root.as_posix(),
        "editorCsdRoot": csd_root.as_posix(),
        "entries": entries,
        "duplicateBasenames": duplicate_names,
        "sets": {
            "referenced": sorted(referenced),
            "welfare": sorted(welfare),
            "timeline": sorted(timeline),
            "referencedRuntime": sorted(referenced & set(runtime_paths)),
            "referencedMissingRuntime": sorted(referenced - set(runtime_paths)),
            "referencedMissingEditorCsd": sorted(referenced - set(editor_paths)),
            "runtimeMissingEditorCsd": sorted(set(runtime_paths) - set(editor_paths)),
            "editorCsdMissingRuntime": sorted(set(editor_paths) - set(runtime_paths)),
            "unreferencedRuntime": sorted(set(runtime_paths) - referenced),
        },
        "statistics": {
            "runtimeCsb": len(runtime_paths),
            "editorCsd": len(editor_paths),
            "referenced": len(referenced),
            "welfareReferenced": len(welfare),
            "timelineReferenced": len(timeline),
            "referencedRuntime": len(referenced & set(runtime_paths)),
            "duplicateBasenames": len(duplicate_names),
        },
    }
