"""Read-only inventory of legacy quest, dialogue, and Lua sources.

This is a migration preview, not the unified quest editor or a Lua interpreter.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import os
import re
import shutil
import subprocess
import tempfile
import threading
from collections import Counter, defaultdict
from datetime import datetime, timezone
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from urllib.parse import parse_qs, quote, urlparse
import xml.etree.ElementTree as ET

from openpyxl import load_workbook
from lua_audit import analyze_lua
import designer_model as quest_model


ROOT = Path(__file__).resolve().parents[2]
CONCEPT = ROOT.parent / "concept" / "data" / "excel"
HERE = Path(__file__).resolve().parent
SAVE_LOCK = threading.Lock()
LOCAL = ROOT / ".local/unified-quest-viewer"
NODE = Path(r"C:\Users\Admin\.cache\codex-runtimes\codex-primary-runtime\dependencies\node\bin\node.exe")


def excel_rows(path: Path, sheet: str, header: int = 1, start: int = 5):
    book = load_workbook(path, read_only=True, data_only=True)
    page = book[sheet]
    keys = [str(v).strip() if v is not None else "" for v in next(page.iter_rows(min_row=header, max_row=header, values_only=True))]
    if path.name == "daily.xlsx" and sheet == "Sheet2" and len(keys) >= 5:
        keys[4] = "参数说明"
    records = []
    for line, values in enumerate(page.iter_rows(min_row=start, values_only=True), start):
        if not any(value is not None and str(value).strip() for value in values):
            continue
        row = {key: value for key, value in zip(keys, values) if key and value is not None}
        if row:
            row["_line"] = line
            records.append(row)
    book.close()
    return records


def xml_rows(path: Path):
    return [dict(node.attrib, _line=i) for i, node in enumerate(ET.parse(path).getroot(), 1)]


def source(name, path, records, status, note, columns):
    return {
        "name": name, "path": str(path), "count": len(records), "status": status,
        "note": note, "columns": columns, "records": records,
    }


def daily_export_differences(source_rows, export_rows):
    """Compare authoring values with the JSON representation after export defaults."""
    fields = ("id", "type", "daily", "level", "show", "des", "condition", "reward", "jump")
    source_by_id = {int(row["id"]): row for row in source_rows}
    export_by_id = {int(row["id"]): row for row in export_rows}
    differences = []
    for row_id in sorted(source_by_id.keys() & export_by_id.keys()):
        source_row, export_row = source_by_id[row_id], export_by_id[row_id]
        for field in fields:
            value = source_row.get(field)
            if field == "condition":
                value = [int(part.strip()) for part in str(value).split(",") if part.strip()]
            elif field == "reward":
                value = json.loads("[" + str(value or "") + "]")
            elif field == "des":
                value = str(value or "")
            else:
                value = int(value or 0)
            if value != export_row.get(field):
                differences.append({"id": row_id, "field": field, "excel": value, "export": export_row.get(field)})
    return differences


def event_candidates(by_name, daily_usage, old_usage, lua):
    """Build a namespaced evidence index; never infer that matching IDs mean the same event."""
    header = ROOT / "server/src/mission_manager.h"
    definitions = {"EMQCT": {}, "EMISS_DC": {}}
    old_named = {"DIALOG": "对话完成", "KILL_MONSTER": "击杀怪物", "MONSTER_DROP": "怪物掉落",
                 "BUY_ITEM": "购买物品", "KILL_BOSS": "击杀首领", "COLLECT": "采集",
                 "COPY": "副本通关"}
    for line_no, line in enumerate(header.read_text(encoding="utf-8-sig", errors="replace").splitlines(), 1):
        if line.lstrip().startswith("//"):
            continue
        match = re.search(r"\b(EMQCT|EMISS_DC)_([A-Z_]+|\d+)\s*=\s*(\d+)", line)
        if match:
            definitions[match.group(1)][match.group(3)] = {
                "comment": line.split("//", 1)[1].strip() if "//" in line else old_named.get(match.group(2), ""),
                "path": str(header), "line": line_no,
            }

    producers = defaultdict(list)
    cpp_root = ROOT / "server/src"
    patterns = {
        "EMQCT": re.compile(r"\bUpdateQuestState\s*\([^;]{0,350}?\bEMQCT_(\d+)\b", re.S),
        "EMISS_DC": re.compile(r"\b(?:UpdateDCMissionComplate|VerifyNewBranchMissionFinish)\s*\([^;]{0,350}?\bEMISS_DC_(\d+)\b", re.S),
    }
    for path in cpp_root.glob("*.cpp"):
        content = path.read_text(encoding="utf-8-sig", errors="replace")
        for namespace, pattern in patterns.items():
            for match in pattern.finditer(content):
                line_no = content.count("\n", 0, match.start()) + 1
                snippet = content.splitlines()[line_no - 1].strip()
                if snippet.startswith("//") or snippet.startswith("/*"):
                    continue
                producers[(namespace, match.group(1))].append({
                    "path": str(path), "line": line_no, "text": " ".join(match.group(0).split())[:210],
                })

    lua_sites = defaultdict(list)
    for script in lua:
        for ref in script["task_refs"]:
            for match in re.finditer(r"\bMISSION_ID_DC_(\d+)\b", ref["text"]):
                lua_sites[match.group(1)].append({"path": script["path"], "line": ref["line"], "text": ref["text"]})

    daily_names = {str(row.get("类型")): str(row.get("条件类型", "")) for row in by_name["每日条件字典"]["records"]}
    daily_ids = set(daily_names) | set(daily_usage) | set(definitions["EMQCT"]) | {key for namespace, key in producers if namespace == "EMQCT"}
    old_ids = set(old_usage) | set(definitions["EMISS_DC"]) | {key for namespace, key in producers if namespace == "EMISS_DC"} | set(lua_sites)
    result = []
    for namespace, ids, usage in (("EMQCT", daily_ids, daily_usage), ("EMISS_DC", old_ids, old_usage)):
        for event_id in sorted(ids, key=int):
            definition = definitions[namespace].get(event_id, {})
            sites = producers.get((namespace, event_id), [])
            row = {
                "legacy_key": f"{namespace}_{event_id}", "namespace": namespace, "id": event_id,
                "description": daily_names.get(event_id, "") if namespace == "EMQCT" else definition.get("comment", ""),
                "task_count": usage.get(event_id, 0), "cpp_call_count": len(sites),
                "lua_ref_count": len(lua_sites.get(event_id, [])) if namespace == "EMISS_DC" else 0,
                "cpp_sites": sites, "lua_sites": lua_sites.get(event_id, []) if namespace == "EMISS_DC" else [],
                "definition": definition,
                "review_state": "有直接调用待核对" if sites else "未检出直接调用",
            }
            result.append(row)
    return result


def load_snapshot():
    definitions = [
        ("每日任务源表", CONCEPT / "xml配置表/新表/daily.xlsx", "Sheet1", 5, "现行候选", "148 条任务；以服务端导出核对", ["id", "type", "daily", "des", "condition"]),
        ("每日条件字典", CONCEPT / "xml配置表/新表/daily.xlsx", "Sheet2", 2, "设计说明", "条件编号说明；需要和代码产生点逐项核对", ["类型", "条件类型", "参数说明", "配置方式"]),
        ("旧任务源表", CONCEPT / "xml配置表/mission_config.xlsx", "Sheet1", 5, "历史休眠", "旧任务加载入口已注释；不能据此判断关联 Lua 是否可达", ["id", "name", "kind", "subtype", "doing_target"]),
        ("章节剧情源表", CONCEPT / "xml配置表/新表/mission_dialog.xlsx", "Sheet1", 5, "客户端来源", "当前章节剧情源；仍需核对客户端引用", ["dialogid", "order", "npcid", "dialog"]),
        ("旧剧情源表", CONCEPT / "xml配置表/mission_dialog.xlsx", "Sheet1", 5, "历史休眠", "旧服务端剧情链；加载入口已注释", ["dialogid", "order", "npcid", "dialog"]),
        ("帮派任务", CONCEPT / "常规配置/bang_pai_mission.xlsx", "bang_pai_mission", 5, "待归类", "需要区分任务、活动计数与展示数据", ["id", "name", "type", "value"]),
        ("帮派活跃", CONCEPT / "xml配置表/bang_pai_huoyue.xlsx", "bang_pai_mission", 5, "待归类", "需核对服务端活跃事件语义", ["id", "name", "param", "value"]),
        ("闯关事件", CONCEPT / "xml配置表/chuangguan_event.xlsx", "event", 5, "待归类", "玩法事件，不自动等同任务事件", ["type", "desc", "pic"]),
    ]
    sources = []
    for name, path, sheet, start, status, note, columns in definitions:
        try:
            rows = excel_rows(path, sheet, start=start)
            sources.append(source(name, path, rows, status, note, columns))
        except Exception as exc:
            sources.append(source(name, path, [], "读取失败", f"{type(exc).__name__}: {exc}", columns))

    generated = [
        ("每日任务服务端导出", ROOT / "server/config/json/daily.json", "导出核对", "运行端 JSON，不作为策划编辑源", ["id", "type", "condition"]),
        ("旧任务服务端导出", ROOT / "server/config/xml/mission_config.xml", "历史休眠", "旧服务端加载入口已注释", ["id", "name", "doing_target"]),
        ("旧剧情服务端导出", ROOT / "server/config/xml/mission_dialog.xml", "历史休眠", "旧服务端剧情 XML", ["dialogid", "order", "npcid", "dialog"]),
    ]
    for name, path, status, note, columns in generated:
        try:
            rows = xml_rows(path) if path.suffix == ".xml" else json.loads(path.read_text(encoding="utf-8-sig"))
            sources.append(source(name, path, rows, status, note, columns))
        except Exception as exc:
            sources.append(source(name, path, [], "读取失败", f"{type(exc).__name__}: {exc}", columns))

    by_name = {item["name"]: item for item in sources}
    daily = by_name["每日任务源表"]["records"]
    exported = by_name["每日任务服务端导出"]["records"]
    src_ids = {str(r.get("id")) for r in daily}
    dst_ids = {str(r.get("id")) for r in exported}
    condition_usage = Counter()
    for row in daily:
        condition = str(row.get("condition", ""))
        match = re.match(r"\s*(\d+)", condition)
        if match:
            condition_usage[match.group(1)] += 1
    old_targets = Counter()
    for row in by_name["旧任务源表"]["records"]:
        target = str(row.get("doing_target", ""))
        if target.strip():
            old_targets.update(re.findall(r"(?:^|[;|])\s*(\d+)\s*[-,]", target))

    npc_source_path = CONCEPT / "常规配置/npc_template.xlsx"
    npc_export_path = ROOT / "server/config/json/npc_template.json"
    npc_by_script = defaultdict(list)
    npc_source_ids = set()
    for npc in excel_rows(npc_source_path, "npc_template", start=5):
        script_id = str(npc.get("script") or "")
        if script_id and script_id != "0":
            npc_source_ids.add(script_id)
            npc_by_script[script_id].append({"id": npc.get("id"), "name": npc.get("name"), "source_excel": True, "export_json": False})
    npc_export_ids = set()
    for npc in json.loads(npc_export_path.read_text(encoding="utf-8-sig")):
        script_id = str(npc.get("script") or "")
        if script_id and script_id != "0":
            npc_export_ids.add(script_id)
            matched = next((item for item in npc_by_script[script_id] if str(item["id"]) == str(npc.get("id"))), None)
            if matched:
                matched["export_json"] = True
            else:
                npc_by_script[script_id].append({"id": npc.get("id"), "name": npc.get("name"), "source_excel": False, "export_json": True})

    item_source_path = CONCEPT / "xml配置表/新表/item.xlsx"
    item_export_path = ROOT / "server/config/json/item.json"
    item_by_script = defaultdict(list)
    item_source_ids = set()
    for item in excel_rows(item_source_path, "Sheet1", start=5):
        script_id = str(item.get("script") or "")
        if script_id and script_id != "0":
            item_source_ids.add(script_id)
            item_by_script[script_id].append({"id": item.get("id"), "name": item.get("name"), "source_excel": True, "export_json": False})
    item_export_ids = set()
    for item in json.loads(item_export_path.read_text(encoding="utf-8-sig")):
        script_id = str(item.get("script") or "")
        if script_id and script_id != "0":
            item_export_ids.add(script_id)
            matched = next((entry for entry in item_by_script[script_id] if str(entry["id"]) == str(item.get("id"))), None)
            if matched:
                matched["export_json"] = True
            else:
                item_by_script[script_id].append({"id": item.get("id"), "name": item.get("name"), "source_excel": False, "export_json": True})

    scene_source_path = CONCEPT / "常规配置/game_scene.xlsx"
    scene_by_script = defaultdict(list)
    for scene in excel_rows(scene_source_path, "game_scene", start=5):
        scene_id = scene.get("id")
        if isinstance(scene_id, int):
            scene_by_script[str(scene_id + 10000)].append({"id": scene_id, "name": scene.get("name")})

    old_task_ids = {str(row.get("id")) for row in by_name["旧任务源表"]["records"]}
    lua, lua_summary = analyze_lua(ROOT, npc_by_script, item_by_script, scene_by_script, old_task_ids)
    steam_scripts = ROOT / "unityserver/script"
    source_hashes = {path.name: hashlib.sha256(path.read_bytes()).hexdigest()
                     for path in (ROOT / "server/script").glob("*.lua")}
    steam_hashes = {path.name: hashlib.sha256(path.read_bytes()).hexdigest()
                    for path in steam_scripts.glob("*.lua")}
    steam_script_check = {
        "path": str(steam_scripts), "files": len(steam_hashes),
        "same_files": sum(source_hashes.get(name) == digest for name, digest in steam_hashes.items()),
        "source_only": sorted(source_hashes.keys() - steam_hashes.keys()),
        "steam_only": sorted(steam_hashes.keys() - source_hashes.keys()),
        "different": sorted(name for name in source_hashes.keys() & steam_hashes.keys()
                            if source_hashes[name] != steam_hashes[name]),
    }
    steam_flows = [
        {"feature": "每日任务", "client": "玩法大厅 Function_10 → TaskController → /37 type=2/0",
         "server": "GetMissionList → CUserMission；daily.json 条件由 UpdateQuestState 推进",
         "lua": "该 UI 请求链未见服务端 Lua 调用；旧 NPC 任务脚本不能据此算作现行每日任务"},
        {"feature": "每日答题", "client": "玩法大厅 Function_27 → AnswerController → /198 op=1/2",
         "server": "AnswerQuestionOption 的 op=1 调用 FindScript(200).GetQuestionAnswer",
         "lua": "200.lua 是 Steam 代码直达入口；不需要 NPC 交互"},
        {"feature": "法宝搜索（无 NPC）", "client": "玩法大厅 Function_9 直接打开 UI → XunBaoController → /319；任务列表 /37 type=3",
         "server": "DealPetEquipOperate / GetMissionList 分别处理操作与任务列表",
         "lua": "Steam 法宝搜索不走 NPC；旧 MISSION_ID_XUNBAO=102 的挖宝 NPC/寻路任务是另一条历史流程"},
        {"feature": "登录", "client": "选角进入游戏", "server": "SelectRole → GetScript(10000).Logon",
         "lua": "10000.lua 是服务端直接入口；与 NPC 无关"},
        {"feature": "旧 NPC 任务", "client": "Steam 客户端当前未检出 PRO_INTERACT 发送入口",
         "server": "原版 OpenNpcInteract → NpcMain；选项 → SetCallFun 指定回调",
         "lua": "服务端仍保留此链；Steam 的旧脚本战斗在范围文件中已排除"},
    ]

    dialogue_groups = {}
    for name in ("章节剧情源表", "旧剧情源表", "旧剧情服务端导出"):
        rows = by_name[name]["records"]
        groups = defaultdict(list)
        for row in rows:
            groups[str(row.get("dialogid", "?"))].append(row)
        dialogue_groups[name] = [{"id": key, "count": len(values), "first": str(values[0].get("dialog", ""))[:90]} for key, values in sorted(groups.items(), key=lambda item: int(item[0]) if item[0].isdigit() else 0)]

    warnings = [
        "Lua 已建立脚本入口候选、任务 API、回调与旧任务编号的静态台账；真实入口、分支及事件生效范围仍待运行验证。",
        "同一个数字在 EMQCT 与 EMISS_DC 中可能代表不同事件；不可按数字直接合并。",
        "章节剧情、旧服务端剧情和客户端导出必须分别核对；读取成功不等于运行时可达。",
    ]
    if npc_source_ids != npc_export_ids:
        warnings.insert(0, f"NPC 正式 Excel 比当前 JSON 导出多 {len(npc_source_ids-npc_export_ids)} 个脚本编号；需核对服务器实际数据库。")
    if item_source_ids != item_export_ids:
        warnings.insert(0, f"道具正式 Excel 有 {len(item_source_ids)} 个非零脚本编号，当前 JSON 导出为 {len(item_export_ids)} 个；需核对导出链和数据库。")
    if src_ids != dst_ids:
        warnings.insert(0, f"每日任务源表与服务端导出 ID 不一致：源表独有 {len(src_ids-dst_ids)}，导出独有 {len(dst_ids-src_ids)}。")
    candidates = event_candidates(by_name, condition_usage, old_targets, lua)
    daily_field_differences = daily_export_differences(daily, exported)
    if daily_field_differences:
        warnings.insert(0, f"每日任务源表与 JSON 导出存在 {len(daily_field_differences)} 处字段差异。")
    return {
        "generated_at": datetime.now(timezone.utc).isoformat(),
        "root": str(ROOT), "concept_root": str(CONCEPT),
        "sources": sources, "lua": lua, "lua_summary": lua_summary, "dialogue_groups": dialogue_groups,
        "steam_script_check": steam_script_check, "steam_flows": steam_flows,
        "lua_config_checks": {
            "npc_source_path": str(npc_source_path), "npc_export_path": str(npc_export_path),
            "npc_source_scripts": len(npc_source_ids), "npc_export_scripts": len(npc_export_ids),
            "npc_source_only": sorted(npc_source_ids-npc_export_ids, key=int),
            "npc_export_only": sorted(npc_export_ids-npc_source_ids, key=int),
            "item_source_path": str(item_source_path), "item_export_path": str(item_export_path),
            "item_source_scripts": len(item_source_ids), "item_export_scripts": len(item_export_ids),
            "item_source_only": sorted(item_source_ids-item_export_ids, key=int),
            "item_export_only": sorted(item_export_ids-item_source_ids, key=int),
            "scene_source_path": str(scene_source_path),
        },
        "event_candidates": candidates,
        "checks": {
            "daily_source_ids": len(src_ids), "daily_export_ids": len(dst_ids),
            "daily_only_ids": sorted(src_ids-dst_ids), "export_only_ids": sorted(dst_ids-src_ids),
            "daily_field_differences": daily_field_differences,
            "daily_condition_types": [{"id": k, "tasks": v} for k, v in sorted(condition_usage.items(), key=lambda x: int(x[0]))],
            "old_target_types_static": [{"id": k, "tasks": v} for k, v in sorted(old_targets.items(), key=lambda x: int(x[0]))],
            "lua_files": len(lua), "lua_files_with_task_refs": sum(bool(x["task_refs"]) for x in lua),
            "lua_task_ref_lines": sum(len(x["task_refs"]) for x in lua),
            "npc_script_ids_mapped": len(npc_by_script),
        },
        "warnings": warnings,
    }


class Handler(BaseHTTPRequestHandler):
    def log_message(self, format, *args):
        # A preview launched from a short-lived terminal must not depend on
        # that terminal's stderr still being connected after the turn ends.
        pass

    def do_GET(self):
        url = urlparse(self.path)
        route = url.path
        if route == "/api/snapshot":
            try:
                body = json.dumps(load_snapshot(), ensure_ascii=False, default=str).encode("utf-8")
                self.send_response(200)
                self.send_header("Content-Type", "application/json; charset=utf-8")
            except Exception as exc:
                body = json.dumps({"error": str(exc)}, ensure_ascii=False).encode("utf-8")
                self.send_response(500)
                self.send_header("Content-Type", "application/json; charset=utf-8")
        elif route == "/api/model":
            try:
                body = json.dumps({"schema": quest_model.SCHEMA, "records": quest_model.read_book(),
                    "workbook": str(quest_model.BOOK)}, ensure_ascii=False).encode("utf-8")
                self.send_response(200)
                self.send_header("Content-Type", "application/json; charset=utf-8")
            except Exception as exc:
                body = json.dumps({"error": str(exc)}, ensure_ascii=False).encode("utf-8")
                self.send_response(500)
                self.send_header("Content-Type", "application/json; charset=utf-8")
        elif route == "/api/coverage":
            try:
                daily = json.loads((ROOT / "server/config/json/daily.json").read_text(encoding="utf-8-sig"))
                counts = Counter(int(row["condition"][0]) for row in daily if row.get("condition"))
                mappings = {int(row["legacy_id"]): row for row in quest_model.read_book()["LegacyMap"]
                            if row.get("source") == "EMQCT" and row.get("record_kind") == "事件"}
                reasons = {
                    1: "道具类型 500 与购买范围待核对", 3: "血战到底已从 Steam 排除",
                    5: "好友赠送已从 Steam 排除", 6: "帮派已从 Steam 排除，且未定位直接产生点",
                    9: "竞技场已从 Steam 排除", 10: "游历三界保留，尚未定位事件产生点",
                    13: "主线胜利的模式参数仍需核对", 55: "封神试炼的计数时机和 Steam 入口待核对",
                    56: "决战昆仑已从 Steam 排除", 60: "帮派副本已从 Steam 排除",
                }
                rows = []
                for legacy_id, count in sorted(counts.items()):
                    mapped = mappings.get(legacy_id, {})
                    target = mapped.get("new_id", "")
                    rows.append({"legacy_id": legacy_id, "name": str(mapped.get("note", "")).split("；", 1)[0],
                        "task_count": count, "event_key": target,
                        "state": "已定义" if target else ("Steam 排除" if legacy_id in (3, 5, 6, 9, 56, 60) else "待核对"),
                        "reason": "" if target else reasons.get(legacy_id, "待核对")})
                body = json.dumps({"rows": rows, "total": len(rows)}, ensure_ascii=False).encode("utf-8")
                self.send_response(200)
                self.send_header("Content-Type", "application/json; charset=utf-8")
            except Exception as exc:
                body = json.dumps({"error": str(exc)}, ensure_ascii=False).encode("utf-8")
                self.send_response(500)
                self.send_header("Content-Type", "application/json; charset=utf-8")
        elif route == "/api/event-summary":
            try:
                snapshot = load_snapshot()
                daily = json.loads((ROOT / "server/config/json/daily.json").read_text(encoding="utf-8-sig"))
                seven_days = json.loads((ROOT / "server/config/json/sevendays.json").read_text(encoding="utf-8-sig"))
                current = defaultdict(list)
                seven_day_usage = Counter()
                for row in daily:
                    if row.get("condition"):
                        current[int(row["condition"][0])].append(row)
                for row in seven_days:
                    if row.get("condition"):
                        seven_day_usage[int(row["condition"][0])] += 1
                mappings = {(row.get("source"), str(row.get("legacy_id"))): row
                            for row in quest_model.read_book()["LegacyMap"] if row.get("record_kind") == "事件"}
                definitions = {row["event_key"]: row for row in quest_model.read_book()["EventType"]}
                pending = {1: "道具类型 500 与购买范围待核对", 10: "游历三界事件产生点待追踪",
                           13: "主线胜利的模式参数待核对", 55: "封神试炼计数时机与 Steam 入口待核对"}
                rows = []
                for event in snapshot["event_candidates"]:
                    if event["namespace"] != "EMQCT":
                        continue
                    namespace, old_id = event["namespace"], str(event["id"])
                    mapped = mappings.get((namespace, old_id), {})
                    number = int(old_id)
                    uses = current.get(number, []) if namespace == "EMQCT" else []
                    target = mapped.get("new_id", "")
                    definition = definitions.get(event["legacy_key"], {})
                    state = definition.get("publish_state", "待定义")
                    if definition.get("steam_scope") == "屏蔽":
                        reason = f"Steam 已屏蔽：{definition.get('scope_reason', '')}；旧事件保留核对"
                    elif definition.get("steam_scope") == "待核对":
                        reason = definition.get("scope_reason", "Steam 入口待核对")
                    elif state in ("草稿", "已验收"):
                        reason = ""
                    elif uses or seven_day_usage[number]:
                        reason = pending.get(number, "产生点与参数待核对")
                    else:
                        reason = "当前 daily 与七日表均未引用；产生点与参数待核对"
                    rows.append({"legacy_key": event["legacy_key"], "namespace": namespace,
                        "legacy_id": old_id, "name": event["description"], "event_key": target,
                        "state": state, "reason": reason, "source_task_count": event["task_count"],
                        "current_task_count": len(uses), "seven_task_count": seven_day_usage[number],
                        "cpp_call_count": event["cpp_call_count"],
                        "lua_ref_count": event["lua_ref_count"],
                        "current_examples": [{"id": row["id"], "name": row.get("des", ""),
                            "condition": row["condition"]} for row in uses[:8]],
                        "cpp_sites": event["cpp_sites"][:3], "lua_sites": event["lua_sites"][:3]})
                body = json.dumps({"rows": rows, "total": len(rows),
                    "current_type_count": len(current), "seven_type_count": len(seven_day_usage),
                    "used_type_count": len(set(current) | set(seven_day_usage))}, ensure_ascii=False).encode("utf-8")
                self.send_response(200)
                self.send_header("Content-Type", "application/json; charset=utf-8")
            except Exception as exc:
                body = json.dumps({"error": str(exc)}, ensure_ascii=False).encode("utf-8")
                self.send_response(500)
                self.send_header("Content-Type", "application/json; charset=utf-8")
        elif route == "/api/export":
            try:
                preview = parse_qs(url.query).get("preview", ["0"])[0] == "1"
                result = quest_model.export(quest_model.read_book(),
                    quest_model.EXPORT_DIR / "preview" if preview else quest_model.EXPORT_DIR, preview=preview)
                body = json.dumps(result, ensure_ascii=False).encode("utf-8")
                self.send_response(200)
                self.send_header("Content-Type", "application/json; charset=utf-8")
            except Exception as exc:
                body = json.dumps({"error": str(exc)}, ensure_ascii=False).encode("utf-8")
                self.send_response(400)
                self.send_header("Content-Type", "application/json; charset=utf-8")
        elif route == "/api/download":
            key = parse_qs(url.query).get("file", [""])[0]
            planner = ROOT / "outputs/unified-quest/任务策划核对表.xlsx"
            if key == "planner":
                try:
                    with SAVE_LOCK:
                        LOCAL.mkdir(parents=True, exist_ok=True)
                        writer = LOCAL / "write_planner_workbook.mjs"
                        shutil.copy2(HERE / "write_planner_workbook.mjs", writer)
                        if not (LOCAL / "node_modules").exists():
                            raise RuntimeError("缺少 Excel 写入运行时连接")
                        node = NODE if NODE.exists() else shutil.which("node")
                        if not node:
                            raise RuntimeError("未找到 Node.js")
                        with tempfile.NamedTemporaryFile(mode="w", suffix=".json", dir=LOCAL,
                                encoding="utf-8", delete=False) as stream:
                            json.dump({"records": quest_model.read_book()}, stream, ensure_ascii=False)
                            staging = Path(stream.name)
                        pending = LOCAL / "任务策划核对表.pending.xlsx"
                        try:
                            process = subprocess.run([str(node), str(writer), str(staging), str(pending)],
                                capture_output=True, text=True, timeout=120, check=False)
                            if process.returncode:
                                raise RuntimeError(process.stderr[-1200:] or process.stdout[-1200:])
                            planner.parent.mkdir(parents=True, exist_ok=True)
                            os.replace(pending, planner)
                        finally:
                            staging.unlink(missing_ok=True)
                            pending.unlink(missing_ok=True)
                except Exception as exc:
                    self.send_error(500, str(exc))
                    return
            files = {
                "workbook": quest_model.BOOK,
                "planner": planner,
                "server": quest_model.EXPORT_DIR / "server_quests.json",
                "client": quest_model.EXPORT_DIR / "client_quests.json",
                "preview_server": quest_model.EXPORT_DIR / "preview/server_quests.json",
                "preview_client": quest_model.EXPORT_DIR / "preview/client_quests.json",
            }
            target = files.get(key)
            if not target or not target.exists():
                self.send_error(404)
                return
            body = target.read_bytes()
            self.send_response(200)
            self.send_header("Content-Type", "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet" if key in ("workbook", "planner") else "application/json; charset=utf-8")
            ascii_name = "planner.xlsx" if key == "planner" else target.name
            disposition = f'attachment; filename="{ascii_name}"'
            if key == "planner":
                disposition += f"; filename*=UTF-8''{quote(target.name)}"
            self.send_header("Content-Disposition", disposition)
        elif route == "/editor":
            body = (HERE / "editor_v2.html").read_bytes()
            self.send_response(200)
            self.send_header("Content-Type", "text/html; charset=utf-8")
        elif route == "/editor.js":
            body = (HERE / "editor.js").read_bytes()
            self.send_response(200)
            self.send_header("Content-Type", "application/javascript; charset=utf-8")
        elif route == "/":
            body = (HERE / "index.html").read_bytes()
            self.send_response(200)
            self.send_header("Content-Type", "text/html; charset=utf-8")
        else:
            self.send_error(404)
            return
        self.send_header("Content-Length", str(len(body)))
        self.send_header("Cache-Control", "no-store")
        self.end_headers()
        self.wfile.write(body)

    def do_POST(self):
        route = urlparse(self.path).path
        if route not in ("/api/model", "/api/validate"):
            self.send_error(404)
            return
        origin = self.headers.get("Origin", "")
        if origin and origin not in (f"http://127.0.0.1:{self.server.server_port}", f"http://localhost:{self.server.server_port}"):
            self.send_error(403)
            return
        size = int(self.headers.get("Content-Length", "0"))
        if size < 1 or size > 8_000_000:
            self.send_error(413)
            return
        try:
            payload = json.loads(self.rfile.read(size))
            records = payload["records"]
            errors = quest_model.validate(records)
            if errors:
                raise ValueError("；".join(errors[:12]))
            if route == "/api/validate":
                body = json.dumps({"valid": True, "errors": []}, ensure_ascii=False).encode("utf-8")
                self.send_response(200)
                self.send_header("Content-Type", "application/json; charset=utf-8")
                self.send_header("Content-Length", str(len(body)))
                self.end_headers()
                self.wfile.write(body)
                return
            with SAVE_LOCK:
                LOCAL.mkdir(parents=True, exist_ok=True)
                quest_model.BOOK.parent.mkdir(parents=True, exist_ok=True)
                writer = LOCAL / "write_workbook.mjs"
                shutil.copy2(HERE / "write_workbook.mjs", writer)
                if not (LOCAL / "node_modules").exists():
                    raise RuntimeError("缺少 .local/unified-quest-viewer/node_modules 运行时连接，请按 README 初始化")
                node = NODE if NODE.exists() else shutil.which("node")
                if not node:
                    raise RuntimeError("未找到 Node.js")
                with tempfile.NamedTemporaryFile(mode="w", suffix=".json", dir=LOCAL,
                        encoding="utf-8", delete=False) as stream:
                    json.dump({"schema": quest_model.SCHEMA, "records": records}, stream, ensure_ascii=False)
                    staging = Path(stream.name)
                temporary_book = LOCAL / "UnifiedQuest.pending.xlsx"
                try:
                    process = subprocess.run([str(node), str(writer), str(staging), str(temporary_book)],
                        capture_output=True, text=True, timeout=120, check=False)
                    if process.returncode:
                        raise RuntimeError(process.stderr[-1200:] or process.stdout[-1200:])
                    generated_errors = quest_model.validate(quest_model.read_book(temporary_book))
                    if generated_errors:
                        raise RuntimeError("写入后复核失败：" + "；".join(generated_errors[:5]))
                    if quest_model.BOOK.exists():
                        backup = ROOT / "outputs/unified-quest/backups/UnifiedQuest.backup.xlsx"
                        backup.parent.mkdir(parents=True, exist_ok=True)
                        shutil.copy2(quest_model.BOOK, backup)
                    os.replace(temporary_book, quest_model.BOOK)
                finally:
                    staging.unlink(missing_ok=True)
                    temporary_book.unlink(missing_ok=True)
            body = json.dumps({"saved": True, "workbook": str(quest_model.BOOK)}, ensure_ascii=False).encode("utf-8")
            self.send_response(200)
        except Exception as exc:
            body = json.dumps({"error": str(exc)}, ensure_ascii=False).encode("utf-8")
            self.send_response(400)
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.send_header("Content-Length", str(len(body)))
        self.send_header("Cache-Control", "no-store")
        self.end_headers()
        self.wfile.write(body)


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--port", type=int, default=8765)
    args = parser.parse_args()
    print(f"http://127.0.0.1:{args.port}/", flush=True)
    ThreadingHTTPServer(("127.0.0.1", args.port), Handler).serve_forever()
