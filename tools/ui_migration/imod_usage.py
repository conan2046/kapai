from __future__ import annotations

import argparse
import json
import re
from pathlib import Path
from typing import Any


IMOD_METHODS = {
    "create",
    "createWithFile",
    "createWithFileSync",
    "initAnimWithName",
    "initAnimWithNameSync",
    "initAnimWithNamesSync",
    "addAnimWithName",
    "addAnimSyncLoad",
    "PlayNewAction",
    "PlayAction",
    "PlayActionRepeat",
    "playFirstFrameIndex",
    "SetCurrentAction",
    "SetSpeedScale",
    "setFlippedX",
    "setFlippedY",
    "setColor",
    "setOpacity",
    "registerScriptEndCBHandler",
    "registerScriptFrameCBHandler",
    "unregisterScriptEndCBHandler",
    "unregisterScriptFrameCBHandler",
    "stopCurrentAni",
    "stop",
    "resume",
    "addAnimWithName",
    "removeAnim",
    "ChangeZorderByIndex",
}

CALL_RE = re.compile(
    r"(?P<receiver>[A-Za-z_][\w.\[\]]*)\s*:\s*(?P<method>[A-Za-z_]\w*)\s*\(",
    re.MULTILINE,
)
ASSIGN_RE = re.compile(
    r"(?P<target>(?:local\s+)?[A-Za-z_][\w.]*\s*(?:\[[^\]]+\])?)\s*=\s*ImodAnim\s*:\s*"
    r"(?:create|createWithFile|createWithFileSync)\s*\(",
    re.MULTILINE,
)
LITERAL_RE = re.compile(r"^\s*(['\"])(.*?)\1\s*$", re.DOTALL)


def _strip_comments(text: str) -> str:
    output: list[str] = []
    index = 0
    quote: str | None = None
    while index < len(text):
        char = text[index]
        if quote:
            output.append(char)
            if char == "\\" and index + 1 < len(text):
                index += 1
                output.append(text[index])
            elif char == quote:
                quote = None
            index += 1
            continue
        if char in "'\"":
            quote = char
            output.append(char)
            index += 1
            continue
        if text.startswith("--[[", index):
            end = text.find("]]", index + 4)
            if end < 0:
                output.extend("\n" for char in text[index:] if char == "\n")
                break
            output.extend("\n" for char in text[index : end + 2] if char == "\n")
            index = end + 2
            continue
        if text.startswith("--", index):
            end = text.find("\n", index + 2)
            if end < 0:
                break
            output.append("\n")
            index = end + 1
            continue
        output.append(char)
        index += 1
    return "".join(output)


def _call_arguments(text: str, opening: int) -> tuple[str, int]:
    depth = 1
    quote: str | None = None
    index = opening + 1
    while index < len(text):
        char = text[index]
        if quote:
            if char == "\\":
                index += 2
                continue
            if char == quote:
                quote = None
        elif char in "'\"":
            quote = char
        elif char == "(":
            depth += 1
        elif char == ")":
            depth -= 1
            if depth == 0:
                return text[opening + 1 : index], index + 1
        index += 1
    return text[opening + 1 :], len(text)


def _split_arguments(value: str) -> list[str]:
    if not value.strip():
        return []
    result: list[str] = []
    start = 0
    depth = 0
    quote: str | None = None
    for index, char in enumerate(value):
        if quote:
            if char == quote and (index == 0 or value[index - 1] != "\\"):
                quote = None
        elif char in "'\"":
            quote = char
        elif char in "({[":
            depth += 1
        elif char in ")}]":
            depth = max(0, depth - 1)
        elif char == "," and depth == 0:
            result.append(value[start:index].strip())
            start = index + 1
    result.append(value[start:].strip())
    return result


def _literal(argument: str) -> str | None:
    match = LITERAL_RE.match(argument)
    return match.group(2) if match else None


def _receiver_shape(value: str) -> str:
    value = value.removeprefix("local ").strip()
    return re.sub(r"\[[^\]]+\]", "[]", value)


def collect_imod_usage(source_root: Path, resource_root: Path | None = None) -> dict[str, Any]:
    calls: list[dict[str, Any]] = []
    for path in sorted(source_root.rglob("*.lua"), key=lambda item: item.as_posix().casefold()):
        raw = path.read_text(encoding="utf-8", errors="replace")
        text = _strip_comments(raw)
        known_receivers = {_receiver_shape(match.group("target")) for match in ASSIGN_RE.finditer(text)}
        for match in CALL_RE.finditer(text):
            receiver = match.group("receiver")
            method = match.group("method")
            if method not in IMOD_METHODS:
                continue
            if receiver != "ImodAnim" and method in {"create", "createWithFile", "createWithFileSync"}:
                continue
            if receiver != "ImodAnim" and _receiver_shape(receiver) not in known_receivers:
                continue
            opening = match.end() - 1
            argument_text, end = _call_arguments(text, opening)
            arguments = _split_arguments(argument_text)
            literals = [_literal(argument) for argument in arguments]
            line = text.count("\n", 0, match.start()) + 1
            calls.append(
                {
                    "source": path.relative_to(source_root).as_posix(),
                    "line": line,
                    "receiver": receiver,
                    "method": method,
                    "arguments": arguments,
                    "literalArguments": literals,
                    "expression": text[match.start() : end].replace("\n", " ").strip(),
                }
            )

    constructors = [item for item in calls if item["receiver"] == "ImodAnim"]
    fixed_paths: set[str] = set()
    for item in calls:
        for literal in item["literalArguments"]:
            if not literal:
                continue
            normalized = literal.replace("\\", "/")
            if normalized.lower().endswith((".ani", ".png")):
                normalized = normalized[:-4]
            if "/" in normalized or item["method"] in {
                "createWithFile",
                "createWithFileSync",
                "initAnimWithName",
                "initAnimWithNameSync",
                "addAnimWithName",
            }:
                fixed_paths.add(normalized)
    dynamic_loads = [
        item
        for item in calls
        if item["method"]
        in {
            "createWithFile",
            "createWithFileSync",
            "initAnimWithName",
            "initAnimWithNameSync",
            "initAnimWithNamesSync",
            "addAnimWithName",
            "addAnimSyncLoad",
        }
        and any(argument and literal is None for argument, literal in zip(item["arguments"], item["literalArguments"]))
    ]
    result = {
        "schemaVersion": 1,
        "sourceRoot": source_root.as_posix(),
        "statistics": {
            "calls": len(calls),
            "constructors": len(constructors),
            "fixedResourcePaths": len(fixed_paths),
            "dynamicLoads": len(dynamic_loads),
            "sourceFiles": len({item["source"] for item in calls}),
        },
        "fixedResourcePaths": sorted(fixed_paths, key=str.casefold),
        "dynamicLoads": dynamic_loads,
        "calls": calls,
    }
    if resource_root is not None:
        available = {
            path.relative_to(resource_root).with_suffix("").as_posix().casefold()
            for path in resource_root.rglob("*.ani")
        }
        # The shipped Lua spelling and ANI spelling differ; the converter preserves this
        # evidence-backed compatibility alias while keeping both original filenames intact.
        available.add("res2/fx/jieshourenwu")
        missing = [path for path in result["fixedResourcePaths"] if path.casefold() not in available]
        unpaired = [
            path.relative_to(resource_root).as_posix()
            for path in resource_root.rglob("*.ani")
            if not path.with_suffix(".png").is_file()
            and path.relative_to(resource_root).as_posix() != "res2/fx/jishourenwu.ani"
        ]
        result["resourceCoverage"] = {
            "availableAnimations": len(list(resource_root.rglob("*.ani"))),
            "fixedPathsAvailable": len(result["fixedResourcePaths"]) - len(missing),
            "fixedPathsMissing": len(missing),
            "missingFixedResourcePaths": missing,
            "unpairedAnimationPaths": sorted(unpaired, key=str.casefold),
        }
    return result


def render_markdown(result: dict[str, Any]) -> str:
    statistics = result["statistics"]
    coverage = result.get("resourceCoverage", {})
    lines = [
        "# ImodAnim Lua 调用清单",
        "",
        "> 由 `python tools/ui_migration/imod_usage.py` 生成；只统计去除 Lua 注释后的活动代码。",
        "",
        "## 汇总",
        "",
        "| 指标 | 数量 |",
        "|---|---:|",
        f"| 调用 | {statistics['calls']} |",
        f"| 构造入口 | {statistics['constructors']} |",
        f"| 源文件 | {statistics['sourceFiles']} |",
        f"| 固定资源路径 | {statistics['fixedResourcePaths']} |",
        f"| 动态加载表达式 | {statistics['dynamicLoads']} |",
        f"| 固定路径可解析 | {coverage.get('fixedPathsAvailable', 0)} |",
        f"| 固定路径缺资源 | {coverage.get('fixedPathsMissing', 0)} |",
        "",
        "## 固定资源路径",
        "",
        "| 路径 | 状态 |",
        "|---|---|",
    ]
    missing = {item.casefold() for item in coverage.get("missingFixedResourcePaths", [])}
    for path in result["fixedResourcePaths"]:
        lines.append(f"| `{path}` | {'缺 ANI/PNG' if path.casefold() in missing else '可解析'} |")
    lines.extend(["", "## 动态加载表达式", "", "| 位置 | 调用 |", "|---|---|"])
    for item in result["dynamicLoads"]:
        expression = item["expression"].replace("|", "\\|")
        lines.append(f"| `{item['source']}:{item['line']}` | `{expression}` |")
    lines.extend(["", "## 全部活动调用", "", "| 位置 | 接收者 | 方法 | 参数 |", "|---|---|---|---|"])
    for item in result["calls"]:
        arguments = ", ".join(item["arguments"]).replace("|", "\\|")
        lines.append(
            f"| `{item['source']}:{item['line']}` | `{item['receiver']}` | "
            f"`{item['method']}` | `{arguments}` |"
        )
    return "\n".join(lines) + "\n"


def main() -> int:
    parser = argparse.ArgumentParser(description="Audit legacy Lua ImodAnim usage.")
    parser.add_argument("--repo-root", type=Path, default=Path(__file__).resolve().parents[2])
    parser.add_argument("--source-root", type=Path)
    parser.add_argument("--output", type=Path)
    parser.add_argument("--markdown-output", type=Path)
    args = parser.parse_args()
    repo_root = args.repo_root.resolve()
    source_root = (args.source_root or repo_root / "client/ProjectX/src").resolve()
    resource_root = (repo_root / "client/ProjectX/res").resolve()
    output = (args.output or repo_root / "build/ui-migration/imod-usage.json").resolve()
    result = collect_imod_usage(source_root, resource_root)
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(json.dumps(result, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    if args.markdown_output:
        markdown_output = args.markdown_output.resolve()
        markdown_output.parent.mkdir(parents=True, exist_ok=True)
        markdown_output.write_text(render_markdown(result), encoding="utf-8")
    print(json.dumps(result["statistics"], ensure_ascii=False, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
