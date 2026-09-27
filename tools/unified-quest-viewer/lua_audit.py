"""Static evidence ledger for server Lua quest migration.

Names and call sites are evidence, never proof that a branch ran in production.
"""

from __future__ import annotations

import re
from collections import Counter, defaultdict
from pathlib import Path


TASK_METHODS = {
    "HaveCMission": "任务状态查询", "IsCMissionFinished": "任务状态查询",
    "GetCMissionInts": "任务状态查询", "GetCMissionAcceptLevel": "任务状态查询",
    "GetMissionName": "任务状态查询", "CheckMissionHuoYueDu": "任务状态查询",
    "AcceptCMission": "任务接取", "UpdateCMissionState": "任务推进",
    "UpdateCMission": "任务推进", "UpdateDCMissionComplate": "旧目标推进",
    "DelCMission": "任务删除", "GetMission": "通用数据槽读取",
    "AddMission": "通用数据槽写入", "UpdateMission": "通用数据槽写入",
    "DelMission": "通用数据槽写入", "SendYaBiaoMissionState": "任务状态发送",
    "GetBossMissionStarInfo": "任务状态查询", "GetBossMissionStarNum": "任务状态查询",
    "GetBossMissionTotolStarNum": "任务状态查询", "SetBossMissionData": "任务状态写入",
}
METHOD_RE = re.compile(r"\b[A-Za-z_]\w*\s*[:.]\s*([A-Za-z_]\w*)\s*\(")
CONSTANT_RE = re.compile(r"\bMISSION_ID_[A-Za-z0-9_]+\b")
FUNCTION_RE = re.compile(r"^\s*(?:local\s+)?function\s+([A-Za-z_]\w*)\s*\(")
REQUIRE_RE = re.compile(r"^\s*require\s*\(?\s*['\"]([^'\"]+)['\"]")
CALLBACK_RE = re.compile(r"\bSetCallFun\s*\(\s*['\"]([A-Za-z_]\w*)['\"]")
SLOT_RE = re.compile(r"\b(?:GetMission|AddMission|UpdateMission|DelMission)\s*\(\s*(\d+)\b")
GLOBAL_ID_RE = re.compile(r"^\s*(MISSION_ID_[A-Za-z0-9_]+)\s*=\s*(\d+)\b")
CPP_SCRIPT_RE = re.compile(r"\b(?:FindScript|new\s+CCallScript)\s*\(\s*(\d+)\s*\)")
UNRESOLVED_ROLE_HINTS = {
    "21003.lua": "钓竿道具 Main；当前道具 JSON 未配该脚本",
    "22441.lua": "普通藏宝图道具 Main；当前道具 JSON 未配该脚本",
    "22442.lua": "高级藏宝图道具 Main；当前道具 JSON 未配该脚本",
    "229.lua": "旧任务大使 NpcMain；当前 NPC JSON 未配该脚本",
    "302.lua": "挖宝 NPC NpcMain/BattleOver；当前静态扫描未找到创建点",
    "303.lua": "挖宝 NPC NpcMain/BattleOver；当前静态扫描未找到创建点",
    "304.lua": "挖宝 NPC NpcMain/BattleOver；当前静态扫描未找到创建点",
    "305.lua": "挖宝 NPC NpcMain/BattleOver；当前静态扫描未找到创建点",
}


def _cpp_literals(root: Path):
    sites = defaultdict(list)
    for path in (root / "server/src").glob("*.cpp"):
        if path.name == "call_script.cpp":
            continue
        for number, line in enumerate(path.read_text(encoding="utf-8-sig", errors="replace").splitlines(), 1):
            if line.lstrip().startswith(("//", "*")):
                continue
            for match in CPP_SCRIPT_RE.finditer(line.split("//", 1)[0]):
                sites[match.group(1)].append({"path": str(path), "line": number, "text": line.strip()[:220]})
    return sites


def analyze_lua(root: Path, npc_by_script: dict, item_by_script: dict, scene_by_script: dict, old_task_ids: set[str]):
    directory = root / "server/script"
    paths = sorted(directory.glob("*.lua"))
    cpp_sites = _cpp_literals(root)
    global_ids = {}
    global_file = directory / "global.lua"
    if global_file.exists():
        for line in global_file.read_text(encoding="utf-8-sig", errors="replace").splitlines():
            match = GLOBAL_ID_RE.match(line)
            if match:
                global_ids[match.group(1)] = match.group(2)

    raw = []
    required_by = defaultdict(list)
    for path in paths:
        lines = path.read_text(encoding="utf-8-sig", errors="replace").splitlines()
        functions, requires, callbacks, refs, calls, constants, slots = [], [], [], [], [], set(), set()
        current_function = "文件初始化"
        for number, line in enumerate(lines, 1):
            clean = line.split("--", 1)[0]
            if not clean.strip():
                continue
            if match := FUNCTION_RE.match(clean):
                functions.append({"name": match.group(1), "line": number})
                current_function = match.group(1)
            if match := REQUIRE_RE.match(clean):
                requires.append(match.group(1))
                required_by[match.group(1)].append(path.name)
            callbacks += [{"name": m.group(1), "line": number} for m in CALLBACK_RE.finditer(clean)]
            found = [m.group(1) for m in METHOD_RE.finditer(clean) if m.group(1) in TASK_METHODS]
            named = [] if path.name == "global.lua" and GLOBAL_ID_RE.match(clean) else CONSTANT_RE.findall(clean)
            constants.update(named)
            slots.update(SLOT_RE.findall(clean))
            if found or named:
                refs.append({"line": number, "function_hint": current_function, "text": line.strip()[:260]})
                calls += [{"line": number, "function_hint": current_function, "method": method, "kind": TASK_METHODS[method], "text": line.strip()[:260]} for method in found]
        raw.append({"file": path.name, "path": str(path), "lines": len(lines), "functions": functions,
                    "requires": sorted(set(requires)), "callbacks": callbacks, "task_refs": refs,
                    "task_calls": calls, "constants": sorted(constants), "data_slots": sorted(slots, key=int)})

    result = []
    for script in raw:
        file_name = script["file"]
        stem = Path(file_name).stem
        names = {entry["name"] for entry in script["functions"]}
        routes = []
        if npc_by_script.get(stem):
            routes.append("NPC 配置引用" + ("，有 NpcMain" if "NpcMain" in names else "，未发现 NpcMain"))
        if item_by_script.get(stem):
            routes.append("道具源表引用")
        if scene_by_script.get(stem):
            routes.append("场景源表编号候选：" + "、".join(str(scene.get("name") or scene["id"]) for scene in scene_by_script[stem]))
        if cpp_sites.get(stem):
            routes.append("C++ 固定编号调用")
        if required_by.get(stem):
            routes.append("被其他 Lua 引用")
        if not routes:
            routes.append("未解析到静态入口")

        task_ids = []
        event_ids = []
        for name in script["constants"]:
            value = global_ids.get(name)
            record = {"constant": name, "value": value, "defined_in_global": value is not None}
            if name.startswith("MISSION_ID_DC_"):
                event_ids.append(record)
            else:
                record["in_old_task_table"] = value in old_task_ids if value is not None else None
                task_ids.append(record)
        unresolved = [entry for entry in script["callbacks"] if entry["name"] not in names]
        counts = Counter(call["kind"] for call in script["task_calls"])
        script.update({
            "npcs": npc_by_script.get(stem, []), "items": item_by_script.get(stem, []), "scenes": scene_by_script.get(stem, []),
            "cpp_sites": cpp_sites.get(stem, []), "required_by": sorted(set(required_by.get(stem, []))),
            "entry_routes": routes, "entry_summary": "；".join(routes), "scope": "静态入口候选，未运行验证",
            "role_hint": UNRESOLVED_ROLE_HINTS.get(file_name, ""),
            "task_ids": task_ids, "event_ids": event_ids, "unresolved_callbacks": unresolved,
            "action_counts": dict(counts), "task_call_count": len(script["task_calls"]),
        })
        result.append(script)

    summary = {
        "files": len(result),
        "task_related_files": sum(bool(s["task_refs"]) for s in result),
        "task_api_call_sites": sum(s["task_call_count"] for s in result),
        "npc_config_files": sum(bool(s["npcs"]) for s in result),
        "npc_config_task_files": sum(bool(s["npcs"] and s["task_refs"]) for s in result),
        "item_config_files": sum(bool(s["items"]) for s in result),
        "scene_config_files": sum(bool(s["scenes"]) for s in result),
        "cpp_literal_files": sum(bool(s["cpp_sites"]) for s in result),
        "files_without_static_entry": sum(s["entry_routes"] == ["未解析到静态入口"] for s in result),
        "old_target_emit_files": sum(any(c["kind"] == "旧目标推进" for c in s["task_calls"]) for s in result),
        "legacy_storage_files": sum(any(c["kind"].startswith("通用数据槽") for c in s["task_calls"]) for s in result),
        "unresolved_callback_files": sum(bool(s["unresolved_callbacks"]) for s in result),
    }
    return result, summary
