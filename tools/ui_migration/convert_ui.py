from __future__ import annotations

import argparse
import hashlib
import html
import json
import shutil
import sys
from collections import Counter
from pathlib import Path
from typing import Any, Iterable

from asset_manifest import build_asset_manifest
from csb_ir import parse_csb
from csd_ir import UNITY_COMPONENT_HINTS, parse_csd
from ir_enrichment import (
    attach_paths_and_collect_resources,
    attach_unity_layout,
    build_binding_manifest,
    select_baselines,
    validate_ir_contract,
)
from plist_ir import parse_plist


TOOL_VERSION = "0.2.0"


def write_json(path: Path, data: Any) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(
        json.dumps(data, ensure_ascii=False, indent=2, sort_keys=True) + "\n",
        encoding="utf-8",
    )


def output_path(output_root: Path, category: str, relative_path: Path) -> Path:
    return output_root / category / relative_path.with_suffix(relative_path.suffix + ".json")


def discover_plists(project_root: Path) -> list[Path]:
    preferred_roots = [
        project_root / "cocosstudio" / "csd" / "Plist",
        project_root / "cocosstudio" / "res",
    ]
    paths: dict[str, Path] = {}
    for root in preferred_roots:
        if not root.exists():
            continue
        for path in root.rglob("*.plist"):
            paths[str(path.resolve()).casefold()] = path
    return sorted(paths.values(), key=lambda item: item.as_posix().casefold())


def build_asset_index(search_roots: Iterable[Path]) -> dict[str, list[Path]]:
    index: dict[str, list[Path]] = {}
    for root in search_roots:
        if not root.exists():
            continue
        for path in root.rglob("*"):
            if not path.is_file():
                continue
            try:
                relative = path.relative_to(root).as_posix().casefold()
            except ValueError:
                continue
            index.setdefault(relative, []).append(path)
    return index


def resolve_asset(reference: str, asset_index: dict[str, list[Path]]) -> list[Path]:
    key = reference.replace("\\", "/").lstrip("./").casefold()
    matches = list(asset_index.get(key, []))
    if matches:
        return matches
    # CSD paths sometimes carry an extra project-level res/ prefix.
    if key.startswith("res/"):
        matches.extend(asset_index.get(key[4:], []))
    else:
        matches.extend(asset_index.get("res/" + key, []))
    unique: dict[str, Path] = {}
    for match in matches:
        unique[str(match.resolve()).casefold()] = match
    return list(unique.values())


def file_digest(path: Path, cache: dict[str, str]) -> str:
    key = str(path.resolve()).casefold()
    if key not in cache:
        digest = hashlib.sha256()
        with path.open("rb") as stream:
            for block in iter(lambda: stream.read(1024 * 1024), b""):
                digest.update(block)
        cache[key] = digest.hexdigest()
    return cache[key]


def duplicate_status(matches: list[Path], digest_cache: dict[str, str]) -> str:
    if len(matches) <= 1:
        return "ok"
    digests = {file_digest(match, digest_cache) for match in matches}
    return "duplicate-identical" if len(digests) == 1 else "duplicate-conflict"


def validate_reference(
    reference: dict[str, Any],
    asset_index: dict[str, list[Path]],
    atlas_frames: dict[str, set[str]],
    digest_cache: dict[str, str],
) -> dict[str, Any]:
    path = str(reference.get("path") or "")
    plist = str(reference.get("plist") or "")
    resource_type = str(reference.get("type") or "")
    result = dict(reference)
    result["status"] = "ok"
    result["resolved"] = []
    result["message"] = ""

    if resource_type == "Default" or not path:
        result["status"] = "skipped"
        result["message"] = "Default or empty resource"
        return result

    if resource_type == "PlistSubImage":
        plist_matches = resolve_asset(plist, asset_index) if plist else []
        result["resolved"] = [item.as_posix() for item in plist_matches]
        if not plist_matches:
            result["status"] = "missing-plist"
            result["message"] = f"Atlas plist not found: {plist}"
            return result
        frame_names: set[str] = set()
        for match in plist_matches:
            frame_names.update(atlas_frames.get(str(match.resolve()).casefold(), set()))
        if path not in frame_names and Path(path).name not in frame_names:
            result["status"] = "missing-frame"
            result["message"] = f"Frame not found in atlas: {path}"
        else:
            result["status"] = duplicate_status(plist_matches, digest_cache)
            if result["status"] == "duplicate-identical":
                result["message"] = "Atlas has identical source/editor copies; first is canonical"
            elif result["status"] == "duplicate-conflict":
                result["message"] = "Atlas resolves to conflicting files"
        return result

    matches = resolve_asset(path, asset_index)
    result["resolved"] = [item.as_posix() for item in matches]
    if not matches:
        result["status"] = "missing-file"
        result["message"] = f"Resource file not found: {path}"
    elif len(matches) > 1:
        result["status"] = duplicate_status(matches, digest_cache)
        if result["status"] == "duplicate-identical":
            result["message"] = "Identical source/editor copies; first is canonical"
        elif result["status"] == "duplicate-conflict":
            result["message"] = f"Resource resolves to {len(matches)} conflicting files"
    return result


def render_html(report: dict[str, Any]) -> str:
    summary = report["summary"]
    inventory = report["inventory"]
    rows = []
    for item in report["files"]:
        status = "OK" if not item.get("error") else "ERROR"
        rows.append(
            "<tr>"
            f"<td>{html.escape(status)}</td>"
            f"<td>{html.escape(item['source'])}</td>"
            f"<td>{item.get('nodeCount', 0)}</td>"
            f"<td>{item.get('resourceCount', 0)}</td>"
            f"<td>{item.get('issueCount', 0)}</td>"
            f"<td>{html.escape(', '.join(item.get('resourceIssueStatuses', {}).keys()))}</td>"
            f"<td>{html.escape(item.get('error', ''))}</td>"
            "</tr>"
        )
    return f"""<!doctype html>
<html lang="zh-CN"><head><meta charset="utf-8">
<title>CSD迁移扫描报告</title>
<style>
body{{font:14px/1.5 system-ui,sans-serif;margin:24px;color:#222}}
.cards{{display:flex;gap:12px;flex-wrap:wrap}}.card{{padding:12px 16px;background:#f4f6f8;border-radius:8px}}
table{{border-collapse:collapse;width:100%;margin-top:20px}}th,td{{border:1px solid #ddd;padding:6px 8px;text-align:left}}th{{background:#f4f6f8}}tr:nth-child(even){{background:#fafafa}}
</style></head><body>
<h1>CSD迁移扫描报告</h1>
<div class="cards">
<div class="card">CSD：{summary['csdFiles']}</div>
<div class="card">成功：{summary['csdParsed']}</div>
<div class="card">节点：{summary['nodes']}</div>
<div class="card">资源引用：{summary['resourceReferences']}</div>
<div class="card">资源问题：{summary['resourceIssues']}</div>
<div class="card">待美术恢复：{summary.get('artRecoveryRequired', 0)}</div>
<div class="card">PLIST：{summary['plistsParsed']}</div>
</div>
<p>运行时CSB：{inventory['csbFiles']}个；名称匹配：{inventory['matchedUniqueNames']}个；仅CSD：{len(inventory['csdOnlyNames'])}个；仅CSB：{len(inventory['csbOnlyNames'])}个。</p>
<details><summary>仅CSB、缺少CSD的界面</summary><pre>{html.escape(chr(10).join(inventory['csbOnlyNames']))}</pre></details>
<table><thead><tr><th>状态</th><th>CSD/CSB</th><th>节点</th><th>资源</th><th>原始差异</th><th>差异类型</th><th>错误</th></tr></thead>
<tbody>{''.join(rows)}</tbody></table>
</body></html>"""


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(
        description="Convert Cocos Studio CSD/PLIST files to an engine-neutral JSON IR."
    )
    parser.add_argument(
        "--project-root",
        type=Path,
        default=Path("UI_Editor/CocosProject"),
        help="CocosProject directory (default: UI_Editor/CocosProject)",
    )
    parser.add_argument(
        "--csb-root",
        type=Path,
        default=Path("client/ProjectX/res/csd"),
        help="Optional runtime CSB directory used for inventory comparison",
    )
    parser.add_argument(
        "--csb-dumper",
        type=Path,
        default=Path("build/ui-migration-native/Release/csb_dump.exe"),
        help="Native CSB decoder built by Build-CsbDump.ps1",
    )
    parser.add_argument(
        "--output",
        type=Path,
        default=Path("build/ui-migration"),
        help="Generated IR/report directory (default: build/ui-migration)",
    )
    parser.add_argument(
        "--clean", action="store_true", help="Remove the output directory before converting"
    )
    parser.add_argument(
        "--strict",
        action="store_true",
        help="Return a failure code when parse errors or missing resources are found",
    )
    args = parser.parse_args(argv)

    project_root = args.project_root.resolve()
    output_root = args.output.resolve()
    csd_root = project_root / "cocosstudio" / "csd"
    if not csd_root.is_dir():
        parser.error(f"CSD directory does not exist: {csd_root}")

    if args.clean and output_root.exists():
        shutil.rmtree(output_root)
    output_root.mkdir(parents=True, exist_ok=True)

    csb_root = args.csb_root.resolve()
    runtime_res_root = csb_root.parent
    android_runtime_res_root = (
        Path("client/ProjectX/frameworks/runtime-src/proj.android_ad1/assets/res").resolve()
    )
    asset_roots = [
        runtime_res_root,
        android_runtime_res_root,
        project_root / "cocosstudio",
        project_root / "res",
        project_root,
    ]
    asset_index = build_asset_index(asset_roots)
    digest_cache: dict[str, str] = {}

    plist_paths = discover_plists(project_root)
    atlas_frames: dict[str, set[str]] = {}
    plist_results: list[dict[str, Any]] = []
    plist_errors: list[dict[str, str]] = []
    for path in plist_paths:
        try:
            parsed = parse_plist(path, project_root)
            relative = path.relative_to(project_root)
            write_json(output_path(output_root, "plist", relative), parsed)
            plist_results.append(parsed)
            if parsed["kind"] == "SpriteAtlas":
                atlas_frames[str(path.resolve()).casefold()] = {
                    frame["name"] for frame in parsed["frames"]
                }
        except Exception as exc:  # Keep the batch useful and report the exact file.
            plist_errors.append({"source": path.as_posix(), "error": str(exc)})

    # Resource validation must see every runtime/editor copy, not only the
    # canonical PLIST IR files emitted above.
    all_indexed_plists: dict[str, Path] = {}
    for candidates in asset_index.values():
        for candidate in candidates:
            if candidate.suffix.casefold() == ".plist":
                all_indexed_plists[str(candidate.resolve()).casefold()] = candidate
    for key, path in all_indexed_plists.items():
        if key in atlas_frames:
            continue
        try:
            parsed = parse_plist(path)
            if parsed["kind"] == "SpriteAtlas":
                atlas_frames[key] = {frame["name"] for frame in parsed["frames"]}
        except Exception:
            pass

    csd_paths = sorted(csd_root.rglob("*.csd"), key=lambda item: item.as_posix().casefold())
    file_reports: list[dict[str, Any]] = []
    node_types: Counter[str] = Counter()
    resource_statuses: Counter[str] = Counter()
    csd_parse_errors = 0
    total_nodes = 0
    total_resources = 0
    all_references: list[dict[str, Any]] = []

    for path in csd_paths:
        relative = path.relative_to(project_root)
        item_report: dict[str, Any] = {"source": relative.as_posix()}
        try:
            parsed = parse_csd(path, project_root)
            attach_unity_layout(parsed["root"])
            parsed["resources"] = attach_paths_and_collect_resources(parsed["root"])
            validated = [
                validate_reference(reference, asset_index, atlas_frames, digest_cache)
                for reference in parsed["resources"]
            ]
            parsed["resourceValidation"] = validated
            contract_errors = validate_ir_contract(parsed)
            if contract_errors:
                raise ValueError("IR contract failed: " + "; ".join(contract_errors[:10]))
            ir_output = output_path(output_root, "csd", relative)
            write_json(ir_output, parsed)
            binding = build_binding_manifest(parsed)
            binding_output = output_root / "bindings" / relative.with_suffix(".bindings.json")
            write_json(binding_output, binding)
            all_references.extend(parsed["resources"])

            stats = parsed["statistics"]
            issues = [
                result
                for result in validated
                if result["status"] not in {"ok", "skipped", "duplicate-identical"}
            ]
            issue_statuses = Counter(result["status"] for result in issues)
            item_report.update(
                {
                    "name": parsed["source"]["metadata"].get("Name", path.stem),
                    "nodeCount": stats["nodeCount"],
                    "nodeTypes": stats["nodeTypes"],
                    "unsupportedNodeTypes": stats["unsupportedNodeTypes"],
                    "resourceCount": len(validated),
                    "issueCount": len(issues),
                    "resourceIssueStatuses": dict(sorted(issue_statuses.items())),
                    "issues": issues,
                    "format": "CSD XML",
                    "animationDuration": (
                        parsed.get("animation", {}).get("attributes", {}).get("Duration", 0)
                        if parsed.get("animation")
                        else 0
                    ),
                    "irPath": ir_output.relative_to(output_root).as_posix(),
                    "bindingPath": binding_output.relative_to(output_root).as_posix(),
                }
            )
            total_nodes += stats["nodeCount"]
            total_resources += len(validated)
            node_types.update(stats["nodeTypes"])
            resource_statuses.update(result["status"] for result in validated)
        except Exception as exc:
            csd_parse_errors += 1
            item_report["error"] = str(exc)
        file_reports.append(item_report)

    csb_paths = sorted(csb_root.rglob("*.csb")) if csb_root.is_dir() else []
    csd_names = {path.stem.casefold() for path in csd_paths}
    csb_names = {path.stem.casefold() for path in csb_paths}
    inventory = {
        "csdUniqueNames": len(csd_names),
        "csbFiles": len(csb_paths),
        "csbUniqueNames": len(csb_names),
        "matchedUniqueNames": len(csd_names & csb_names),
        "csdOnlyNames": sorted(csd_names - csb_names),
        "csbOnlyNames": sorted(csb_names - csd_names),
    }

    csb_dumper = args.csb_dumper.resolve()
    csb_errors: list[dict[str, str]] = []
    csb_converted = 0
    csb_by_name: dict[str, Path] = {}
    for path in csb_paths:
        csb_by_name.setdefault(path.stem.casefold(), path)
    temp_csb_root = output_root / ".tmp-csb"
    for name in inventory["csbOnlyNames"]:
        path = csb_by_name[name]
        relative = path.relative_to(csb_root)
        item_report: dict[str, Any] = {
            "source": path.relative_to(csb_root.parent.parent.parent).as_posix()
            if len(path.parents) >= 3
            else path.as_posix(),
            "format": "CSB FlatBuffers",
        }
        try:
            if not csb_dumper.is_file():
                raise FileNotFoundError(
                    f"CSB dumper not found: {csb_dumper}; run Build-CsbDump.ps1"
                )
            parsed = parse_csb(
                path,
                csb_dumper,
                temp_csb_root / relative.with_suffix(".raw.json"),
                csb_root,
            )
            validated = [
                validate_reference(reference, asset_index, atlas_frames, digest_cache)
                for reference in parsed["resources"]
            ]
            parsed["resourceValidation"] = validated
            contract_errors = validate_ir_contract(parsed)
            if contract_errors:
                raise ValueError("IR contract failed: " + "; ".join(contract_errors[:10]))
            ir_output = output_path(output_root, "csb", relative)
            write_json(ir_output, parsed)
            binding = build_binding_manifest(parsed)
            binding_output = output_root / "bindings-csb" / relative.with_suffix(
                ".bindings.json"
            )
            write_json(binding_output, binding)
            all_references.extend(parsed["resources"])

            stats = parsed["statistics"]
            issues = [
                result
                for result in validated
                if result["status"] not in {"ok", "skipped", "duplicate-identical"}
            ]
            issue_statuses = Counter(result["status"] for result in issues)
            item_report.update(
                {
                    "name": path.stem,
                    "nodeCount": stats["nodeCount"],
                    "nodeTypes": stats["nodeTypes"],
                    "unsupportedNodeTypes": stats["unsupportedNodeTypes"],
                    "unknownClasses": stats.get("unknownClasses", []),
                    "resourceCount": len(validated),
                    "issueCount": len(issues),
                    "resourceIssueStatuses": dict(sorted(issue_statuses.items())),
                    "issues": issues,
                    "animationDuration": parsed.get("animation", {}).get("duration", 0),
                    "irPath": ir_output.relative_to(output_root).as_posix(),
                    "bindingPath": binding_output.relative_to(output_root).as_posix(),
                }
            )
            total_nodes += stats["nodeCount"]
            total_resources += len(validated)
            node_types.update(stats["nodeTypes"])
            resource_statuses.update(result["status"] for result in validated)
            csb_converted += 1
        except Exception as exc:
            item_report["error"] = str(exc)
            csb_errors.append({"source": path.as_posix(), "error": str(exc)})
        file_reports.append(item_report)
    if temp_csb_root.exists():
        shutil.rmtree(temp_csb_root)

    def source_label(path: Path) -> tuple[int, str]:
        resolved = path.resolve()
        roots = [
            (runtime_res_root, "runtime-client"),
            (android_runtime_res_root, "runtime-android-export"),
            (project_root / "cocosstudio", "cocosstudio-source"),
            (project_root / "res", "cocosstudio-export"),
            (project_root, "cocos-project"),
        ]
        for priority, (root, label) in enumerate(roots):
            try:
                resolved.relative_to(root.resolve())
                return priority, label
            except ValueError:
                continue
        return len(roots), "external"

    asset_manifest, atlas_remap = build_asset_manifest(
        all_references,
        lambda reference: resolve_asset(reference, asset_index),
        atlas_frames,
        source_label,
    )
    write_json(output_root / "asset-manifest.json", asset_manifest)
    write_json(output_root / "atlas-remap.json", atlas_remap)

    baselines = select_baselines(
        [item for item in file_reports if item.get("format") == "CSD XML"], 10
    )
    baseline_covered_types = sorted(
        {node_type for item in baselines for node_type in item["nodeTypes"]}
    )
    all_observed_csd_types = sorted(
        {
            node_type
            for item in file_reports
            if item.get("format") == "CSD XML"
            for node_type in item.get("nodeTypes", {})
        }
    )
    baseline_manifest = {
        "schemaVersion": 1,
        "selection": "deterministic greedy node-type coverage",
        "count": len(baselines),
        "coveredNodeTypes": baseline_covered_types,
        "uncoveredNodeTypes": sorted(
            set(all_observed_csd_types) - set(baseline_covered_types)
        ),
        "coordinateValidation": {
            "policy": "cocos-bottom-left-v1",
            "nodesWithGeneratedUnityRect": sum(item["nodeCount"] for item in baselines),
            "contractErrors": 0,
        },
        "baselines": baselines,
    }
    write_json(output_root / "baselines" / "manifest.json", baseline_manifest)

    non_issue_statuses = {"ok", "skipped", "duplicate-identical"}
    raw_resource_differences = sum(
        count
        for status, count in resource_statuses.items()
        if status not in non_issue_statuses
    )
    actionable_resource_issues = (
        atlas_remap["statistics"]["unresolved"]
        + asset_manifest["statistics"]["decisions"].get("missing", 0)
    )
    summary = {
        "toolVersion": TOOL_VERSION,
        "projectRoot": project_root.as_posix(),
        "outputRoot": output_root.as_posix(),
        "csdFiles": len(csd_paths),
        "csdParsed": len(csd_paths) - csd_parse_errors,
        "csdParseErrors": csd_parse_errors,
        "csbOnlyConverted": csb_converted,
        "csbConversionErrors": len(csb_errors),
        "nodes": total_nodes,
        "nodeTypes": dict(sorted(node_types.items())),
        "supportedNodeTypes": sorted(UNITY_COMPONENT_HINTS),
        "resourceReferences": total_resources,
        "resourceStatuses": dict(sorted(resource_statuses.items())),
        "rawResourceDifferences": raw_resource_differences,
        "resourceIssues": actionable_resource_issues,
        "resourceWarnings": (
            atlas_remap["statistics"]["artRecoveryRequired"]
            + asset_manifest["statistics"]["decisions"].get(
                "selected-by-priority", 0
            )
        ),
        "plistsDiscovered": len(plist_paths),
        "plistsParsed": len(plist_results),
        "plistParseErrors": len(plist_errors),
        "atlasCount": sum(1 for item in plist_results if item["kind"] == "SpriteAtlas"),
        "particleConfigCount": sum(
            1 for item in plist_results if item["kind"] == "ParticleConfig"
        ),
        "uniqueLogicalAssets": asset_manifest["statistics"]["uniqueLogicalAssets"],
        "selectedPhysicalFiles": asset_manifest["statistics"]["selectedPhysicalFiles"],
        "atlasRemaps": atlas_remap["statistics"]["remapped"],
        "unresolvedAtlasFrames": atlas_remap["statistics"]["unresolved"],
        "artRecoveryRequired": atlas_remap["statistics"]["artRecoveryRequired"],
        "baselineCount": len(baselines),
        **{
            key: value
            for key, value in inventory.items()
            if key not in {"csdOnlyNames", "csbOnlyNames"}
        },
    }
    report = {
        "schemaVersion": 1,
        "summary": summary,
        "files": file_reports,
        "plistErrors": plist_errors,
        "csbErrors": csb_errors,
        "inventory": inventory,
        "assetManifest": asset_manifest["statistics"],
        "atlasRemap": atlas_remap["statistics"],
        "baselines": baseline_manifest,
    }
    write_json(output_root / "report.json", report)
    (output_root / "report.html").write_text(render_html(report), encoding="utf-8")

    print(json.dumps(summary, ensure_ascii=False, indent=2))
    failed = (
        csd_parse_errors
        or plist_errors
        or csb_errors
        or atlas_remap["statistics"]["unresolved"]
        or asset_manifest["statistics"]["decisions"].get("missing", 0)
    )
    return 1 if args.strict and failed else 0


if __name__ == "__main__":
    sys.exit(main())
