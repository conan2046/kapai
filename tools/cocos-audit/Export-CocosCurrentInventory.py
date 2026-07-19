#!/usr/bin/env python3
"""Extract current-game Cocos routes and interactive-control candidates.

This is a candidate generator, not reachability proof. Runtime confirmation is
stored separately so regenerated static data never overwrites manual evidence.

Important: this checkout contains Lua left by older games. A file or AppDef
route is not considered part of the current product merely because it exists.
The current-product set is the static UI graph reachable from the shipped
MainUI via OpenFunction/InitUI. Everything else remains unqualified.
"""

from __future__ import annotations

import argparse
import json
import re
from dataclasses import asdict, dataclass
from pathlib import Path


MODULE_ID_RE = re.compile(r"^\s*(EMID_[A-Za-z0-9_]+)\s*=\s*(\d+)", re.M)
ROUTE_RE = re.compile(
    r"\[AppDef\.EModuleID\.(EMID_[A-Za-z0-9_]+)\]\s*=\s*\{([^\n}]*)\}", re.M
)
LUA_ROUTE_RE = re.compile(r"lua\s*=\s*[\"']([^\"']+)[\"']")
SUB_RE = re.compile(r"sub\s*=\s*([^,}]+)")
IND_RE = re.compile(r"ind\s*=\s*([^,}]+)")
CONST_RE = re.compile(r"^\s*local\s+(BTN_NAME_[A-Za-z0-9_]+)\s*=\s*[\"']([^\"']+)[\"']", re.M)
MAIN_MAP_ASSIGN_RE = re.compile(
    r"(?:local\s+)?([A-Za-z_][A-Za-z0-9_]*)\s*=\s*self\.m_buttonGroupMap\[(BTN_NAME_[A-Za-z0-9_]+)\]"
)
ASSIGN_RE = re.compile(
    r"(?:local\s+)?([A-Za-z_][A-Za-z0-9_\.]*)\s*=\s*[^\n]*?(?:getChildByName|findChildByName)\s*\(\s*[\"']([^\"']+)[\"']\s*\)"
)
EVENT_RE = re.compile(
    r"([A-Za-z_][A-Za-z0-9_\.]*)\s*:\s*(addClickEventListener|addTouchEventListener|registerScriptHandler)\s*\("
)
OPEN_FUNCTION_RE = re.compile(r"(?:Utils:)?OpenFunction\s*\(\s*AppDef\.EModuleID\.(EMID_[A-Za-z0-9_]+)")
INIT_UI_RE = re.compile(r"(?:Utils:)?InitUI\s*\(\s*[\"']([^\"']+)[\"']")
CSB_RE = re.compile(r"[\"']((?:csd/)?[^\"']+\.(?:csb|csd))[\"']", re.I)
PROTOCOL_SYMBOL_RE = re.compile(r"\b(?:PRO_[A-Z0-9_]+|Protocol\.[A-Z0-9_]+)\b")
FUNCTION_RE = re.compile(r"^\s*function\s+([A-Za-z_][A-Za-z0-9_\.:]*)\s*\(")
PRODUCT_NAME_RE = re.compile(r'"name"\s*:\s*"([^"]+)"')


@dataclass
class ControlCandidate:
    id: str
    source: str
    line: int
    function: str
    variable: str
    path: str
    event: str
    callback: str
    moduleTargets: list[str]
    uiTargets: list[str]
    protocolSymbols: list[str]
    csbRefs: list[str]
    reachability: str = "static-candidate"


def strip_comments_preserve_lines(text: str) -> str:
    def block(match: re.Match[str]) -> str:
        value = match.group(0)
        return "\n" * value.count("\n")

    text = re.sub(r"--\[\[.*?\]\]", block, text, flags=re.S)
    return re.sub(r"--[^\n]*", "", text)


def callback_window(lines: list[str], start: int, limit: int = 28) -> str:
    return "\n".join(lines[start : min(len(lines), start + limit)])


def compact(value: str, limit: int = 360) -> str:
    value = re.sub(r"\s+", " ", value).strip()
    return value[:limit]


def read_legacy_text(path: Path) -> str:
    data = path.read_bytes()
    for encoding in ("utf-8-sig", "gb18030"):
        try:
            return data.decode(encoding)
        except UnicodeDecodeError:
            pass
    return data.decode("utf-8", errors="replace")


def repair_gbk_mojibake(value: str) -> str:
    """Repair legacy config text that was once decoded as Latin-1 then saved UTF-8."""
    try:
        repaired = value.encode("latin1").decode("gb18030")
    except (UnicodeEncodeError, UnicodeDecodeError):
        return value
    return repaired if any("\u4e00" <= char <= "\u9fff" for char in repaired) else value


def extract_controls(root: Path, lua_files: list[Path]) -> list[ControlCandidate]:
    controls: list[ControlCandidate] = []
    for path in lua_files:
        raw = path.read_text(encoding="utf-8", errors="replace")
        text = strip_comments_preserve_lines(raw)
        lines = text.splitlines()
        assignments: dict[str, tuple[str, int]] = {}
        current_function = "<module>"
        for index, line in enumerate(lines):
            function_match = FUNCTION_RE.match(line)
            if function_match:
                current_function = function_match.group(1)
                assignments = {}
            for match in ASSIGN_RE.finditer(line):
                assignments[match.group(1)] = (match.group(2), index + 1)
            event_match = EVENT_RE.search(line)
            if not event_match:
                continue
            variable, event = event_match.groups()
            resolved = assignments.get(variable)
            control_path = resolved[0] if resolved else variable
            window = callback_window(lines, index)
            module_targets = sorted(set(OPEN_FUNCTION_RE.findall(window)))
            ui_targets = sorted(set(INIT_UI_RE.findall(window)))
            protocols = sorted(set(PROTOCOL_SYMBOL_RE.findall(window)))
            csb_refs = sorted(set(CSB_RE.findall(window)))
            relative = path.relative_to(root).as_posix()
            candidate_id = f"{relative}:{index + 1}:{variable}:{event}"
            controls.append(
                ControlCandidate(
                    id=candidate_id,
                    source=relative,
                    line=index + 1,
                    function=current_function,
                    variable=variable,
                    path=control_path,
                    event=event,
                    callback=compact(window),
                    moduleTargets=module_targets,
                    uiTargets=ui_targets,
                    protocolSymbols=protocols,
                    csbRefs=csb_refs,
                )
            )
    return controls


def view_source(root: Path, lua_module: str) -> Path:
    return root / "client/ProjectX/src/View" / Path(lua_module.replace(".", "/") + ".lua")


def build_current_product_graph(
    root: Path, route_by_name: dict[str, dict[str, object]]
) -> tuple[list[Path], set[str]]:
    """Return files statically reachable from the current shipped MainUI.

    This deliberately does not use every AppDef route as a root. Routes are
    followed only when reachable code names them. InitUI targets are followed
    directly because many popups do not have module IDs.
    """
    entry = root / "client/ProjectX/src/View/MainUI.lua"
    queue = [entry]
    visited: set[Path] = set()
    reached_routes: set[str] = set()
    while queue:
        path = queue.pop(0)
        path = path.resolve()
        if path in visited or not path.is_file():
            continue
        visited.add(path)
        text = strip_comments_preserve_lines(path.read_text(encoding="utf-8", errors="replace"))
        for module_name in OPEN_FUNCTION_RE.findall(text):
            route = route_by_name.get(module_name)
            if not route:
                continue
            reached_routes.add(module_name)
            source = root / str(route["source"])
            if source.is_file() and source.resolve() not in visited:
                queue.append(source)
        for ui_module in INIT_UI_RE.findall(text):
            source = view_source(root, ui_module)
            if source.is_file() and source.resolve() not in visited:
                queue.append(source)
    return sorted(visited), reached_routes


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--root", type=Path, default=Path(__file__).resolve().parents[2])
    parser.add_argument("--output", type=Path, default=Path("build/cocos-audit"))
    args = parser.parse_args()
    root = args.root.resolve()
    output = args.output if args.output.is_absolute() else root / args.output
    output.mkdir(parents=True, exist_ok=True)

    app_def_path = root / "client/ProjectX/src/core/AppDef.lua"
    app_def = strip_comments_preserve_lines(app_def_path.read_text(encoding="utf-8", errors="replace"))
    module_ids = {name: int(value) for name, value in MODULE_ID_RE.findall(app_def)}
    routes = []
    for name, body in ROUTE_RE.findall(app_def):
        lua_match = LUA_ROUTE_RE.search(body)
        if not lua_match:
            continue
        sub_match, ind_match = SUB_RE.search(body), IND_RE.search(body)
        lua_module = lua_match.group(1)
        source = view_source(root, lua_module)
        routes.append(
            {
                "moduleIdName": name,
                "moduleId": module_ids.get(name),
                "lua": lua_module,
                "sub": compact(sub_match.group(1)) if sub_match else None,
                "uiType": compact(ind_match.group(1)) if ind_match else None,
                "source": source.relative_to(root).as_posix(),
                "sourceExists": source.is_file(),
                "productQualification": "unqualified-configured-route",
                "reachability": "not-runtime-verified",
            }
        )

    route_by_name = {str(route["moduleIdName"]): route for route in routes}
    current_files, reached_route_names = build_current_product_graph(root, route_by_name)
    for route in routes:
        if route["moduleIdName"] in reached_route_names:
            route["productQualification"] = "current-static-reachable"
    controls = extract_controls(root, current_files)

    main_ui_path = root / "client/ProjectX/src/View/MainUI.lua"
    main_text = strip_comments_preserve_lines(main_ui_path.read_text(encoding="utf-8", errors="replace"))
    constants = dict(CONST_RE.findall(main_text))
    main_variable_paths = {
        variable: constants.get(constant, constant)
        for variable, constant in MAIN_MAP_ASSIGN_RE.findall(main_text)
    }
    main_controls = [asdict(c) for c in controls if c.source.endswith("/View/MainUI.lua")]
    for control in main_controls:
        if control["variable"] in main_variable_paths:
            control["path"] = main_variable_paths[control["variable"]]
        elif control["path"] in constants:
            control["path"] = constants[control["path"]]
        control["reachability"] = "main-ui-static-candidate"

    config_path = root / "client/ProjectX/simulator/win32/config.json"
    config_text = read_legacy_text(config_path)
    product_match = PRODUCT_NAME_RE.search(config_text)
    product_name = repair_gbk_mojibake(product_match.group(1)) if product_match else "unknown"
    current_routes = [r for r in routes if r["productQualification"] == "current-static-reachable"]
    unqualified_routes = [r for r in routes if r["productQualification"] != "current-static-reachable"]

    route_payload = {
        "schemaVersion": 2,
        "product": product_name,
        "qualificationRule": "static graph reachable from current MainUI through OpenFunction/InitUI; runtime proof remains separate",
        "generatedFrom": [
            "client/ProjectX/simulator/win32/config.json",
            "client/ProjectX/src/core/AppDef.lua",
            "client/ProjectX/src/View/MainUI.lua",
        ],
        "configuredRouteCount": len(routes),
        "currentStaticRouteCount": len(current_routes),
        "unqualifiedConfiguredRouteCount": len(unqualified_routes),
        "mainControlCount": len(main_controls),
        "currentRoutes": current_routes,
        "unqualifiedConfiguredRoutes": unqualified_routes,
        "mainControls": main_controls,
    }
    control_payload = {
        "schemaVersion": 2,
        "product": product_name,
        "sourceVersion": "current-product static UI graph candidates",
        "qualificationRule": "source file must be reachable from current MainUI through OpenFunction/InitUI",
        "candidateCount": len(controls),
        "qualifiedFilesScanned": len(current_files),
        "qualifiedFiles": [path.relative_to(root).as_posix() for path in current_files],
        "controls": [asdict(control) for control in controls],
    }
    (output / "cocos-current-entry-inventory.json").write_text(
        json.dumps(route_payload, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
    )
    (output / "cocos-control-candidates.json").write_text(
        json.dumps(control_payload, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
    )
    print(
        f"Cocos inventory exported: product={product_name}, configuredRoutes={len(routes)}, "
        f"currentRoutes={len(current_routes)}, mainControls={len(main_controls)}, "
        f"controls={len(controls)}, qualifiedFiles={len(current_files)}, output={output}"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
