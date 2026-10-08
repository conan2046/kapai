from __future__ import annotations

import argparse
import hashlib
import json
import re
import shutil
from pathlib import Path
from typing import Any

from PIL import Image

from ani_ir import AniFormatError, parse_ani


WELFARE_ANI_PATHS = {"res2/fx/qiandao.ani"}
UNITY_EXCLUDED_ANI_PATHS = {
    "res2/fx/qiandao.ani": (
        "Sign uses UnityNativeRetained SignClaimAnimation Animator assets; no Unity Imod consumer remains."
    ),
    "res2/fx/loading.ani": (
        "Only client/ProjectX/src/Logic/LBattleLogic.lua loads this battle-unit "
        "appearance animation; Unity uses WorldBattlePlaybackPresenter and does not bundle LBattleLogic."
    ),
    "res2/animation/effect_chuangjue_1.ani": (
        "Login uses UnityNativeLogin Animator assets; no Unity runtime caller loads this legacy Imod path."
    ),
    "res2/create/create_4.ani": (
        "Role creation uses UnityNativeLogin Animator assets; no Unity runtime caller loads this legacy Imod path."
    ),
    "res2/create/create_5.ani": (
        "Role creation uses UnityNativeLogin Animator assets; no Unity runtime caller loads this legacy Imod path."
    ),
    "res2/animation/battle/quality2.ani": (
        "WorldBattlePlayback uses a Unity-native cropped Sprite for the single-frame pet quality effect."
    ),
    "res2/animation/battle/quality3.ani": (
        "WorldBattlePlayback uses a Unity-native cropped Sprite for the single-frame pet quality effect."
    ),
    "res2/animation/battle/quality7.ani": (
        "WorldBattlePlayback uses a Unity-native cropped Sprite for the single-frame pet quality effect."
    ),
    "res2/animation/battle/quality8.ani": (
        "WorldBattlePlayback uses a Unity-native cropped Sprite for the single-frame pet quality effect."
    ),
    "ui/shaizi.ani": (
        "Monopoly uses the UnityNativeMonopoly Sprite atlas and AnimationClip; Unity no longer loads this Imod animation."
    ),
}
TEXTURE_OVERRIDES = {
    "res2/fx/jishourenwu.ani": "res2/fx/jieshourenwu.png",
}

UNITY_NATIVE_MONSTER_ANIMATION_REASONS = {
    "_gj": (
        "WorldBattlePlayback model attack actions use UnityNativeWorld BattleModels AnimationClips and Controllers."
    ),
    "_sf1": (
        "WorldBattlePlayback model skill actions use UnityNativeWorld BattleModels AnimationClips and Controllers."
    ),
    "_sf2": (
        "WorldBattlePlayback model skill actions use UnityNativeWorld BattleModels AnimationClips and Controllers."
    ),
    "_sw": (
        "WorldBattlePlayback model death actions use UnityNativeWorld BattleModels AnimationClips and Controllers."
    ),
    "_bj": (
        "WorldBattlePlayback model hit actions use UnityNativeWorld BattleModels AnimationClips and Controllers."
    ),
    "_zd_show": (
        "Unity Hero, Draw, Rebirth, cultivation, and FengShenStory routes use "
        "UnityNativeHeroModels AnimationClips and Controllers."
    ),
    "_zd": (
        "Unity Formation and World stage preview routes use UnityNativeHeroModels "
        "AnimationClips and Controllers; Fish uses UnityNativeFish."
    ),
}
RESOURCE_ALIASES = {
    "res2/fx/jishourenwu.ani": ["res2/fx/jieshourenwu"],
}

UNITY_EXCLUDED_ANI_PREFIXES = {
    "skill/": (
        "WorldBattlePlayback skill effects use Unity-native Sprite/AnimationClip assets; "
        "no other Unity runtime path loads this legacy Imod family."
    ),
    "res2/skill/": (
        "WorldBattlePlayback animated Buffs use Unity-native Sprite/AnimationClip assets; "
        "other Unity Buffs use native icon Sprites."
    ),
}


def _write_json(path: Path, value: Any) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(
        json.dumps(value, ensure_ascii=False, indent=2, sort_keys=True) + "\n",
        encoding="utf-8",
    )


def _unity_exclusion_reason(relative_key: str) -> str | None:
    key = relative_key.casefold()
    exact = UNITY_EXCLUDED_ANI_PATHS.get(key)
    if exact is not None:
        return exact
    for prefix, reason in UNITY_EXCLUDED_ANI_PREFIXES.items():
        if key.startswith(prefix):
            return reason
    if not key.startswith("monster/"):
        return None
    for suffix, reason in UNITY_NATIVE_MONSTER_ANIMATION_REASONS.items():
        if re.fullmatch(rf"monster/btm\d+{re.escape(suffix)}\.ani", key):
            return reason
    return None


def _digest(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def _required_texture_size(parsed: dict[str, Any]) -> tuple[int, int]:
    width = max((item["x"] + item["width"] for item in parsed["modules"]), default=0)
    height = max((item["y"] + item["height"] for item in parsed["modules"]), default=0)
    return width, height


def _prepare_texture(source: Path, target: Path, required: tuple[int, int]) -> dict[str, Any]:
    with Image.open(source) as image:
        source_size = image.size
        if required[0] <= image.width and required[1] <= image.height:
            target.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(source, target)
            return {"sourceSize": list(source_size), "preparedSize": list(source_size), "padded": False}
        width = max(image.width, required[0])
        height = max(image.height, required[1])
        padded = Image.new("RGBA", (width, height), (0, 0, 0, 0))
        padded.paste(image.convert("RGBA"), (0, 0))
        target.parent.mkdir(parents=True, exist_ok=True)
        padded.save(target)
        return {"sourceSize": list(source_size), "preparedSize": [width, height], "padded": True}


def _remove_prepared_unity_animation(
    unity_project: Path,
    relative: Path,
    texture_relative: Path,
    remove_texture: bool,
) -> None:
    resources = unity_project / "Assets/ProjectX/Resources/ProjectXAnimation"
    generated = [resources / relative.with_suffix(".json")]
    if remove_texture:
        generated.append(resources / texture_relative)
    for asset in generated:
        for path in (asset, Path(f"{asset}.meta")):
            if path.is_file():
                path.unlink()


def convert(
    resource_root: Path,
    output_root: Path,
    scope: str,
    unity_project: Path | None = None,
) -> dict[str, Any]:
    if unity_project is not None:
        mode_path = unity_project / "Assets/ProjectX/res/csd/UnityMigration/unity-import-manifest.json"
        settings_path = unity_project / "ProjectSettings/ProjectXUiMaintenance.json"
        settings_mode = json.loads(settings_path.read_text(encoding="utf-8-sig")).get("maintenanceMode") if settings_path.exists() else None
        if settings_mode == "unity-native-only" or (mode_path.exists() and json.loads(mode_path.read_text(encoding="utf-8-sig")).get("maintenanceMode") == "unity-native-only"):
            return {
                "maintenanceMode": "unity-native-only",
                "entries": [],
                "errors": [],
                "statistics": {"animations": 0, "errors": 0, "unityPrepared": 0, "unityExcluded": 0},
            }
    paths = sorted(resource_root.rglob("*.ani"), key=lambda item: item.as_posix().casefold())
    if scope == "welfare":
        paths = [
            path
            for path in paths
            if path.relative_to(resource_root).as_posix().casefold() in WELFARE_ANI_PATHS
        ]

    texture_use_count: dict[str, int] = {}
    for path in paths:
        relative = path.relative_to(resource_root)
        texture_relative = Path(
            TEXTURE_OVERRIDES.get(relative.as_posix(), relative.with_suffix(".png").as_posix())
        )
        texture_key = texture_relative.as_posix().casefold()
        texture_use_count[texture_key] = texture_use_count.get(texture_key, 0) + 1

    entries = []
    errors = []
    for path in paths:
        relative = path.relative_to(resource_root)
        relative_key = relative.as_posix()
        texture_relative = Path(TEXTURE_OVERRIDES.get(relative_key, relative.with_suffix(".png").as_posix()))
        texture = resource_root / texture_relative
        try:
            parsed = parse_ani(path, resource_root)
            ir_path = output_root / "ani" / relative.with_suffix(".ani.json")
            _write_json(ir_path, parsed)
            entry = {
                "source": relative.as_posix(),
                "texture": texture_relative.as_posix(),
                "textureExists": texture.is_file(),
                "aliases": RESOURCE_ALIASES.get(relative_key, []),
                "ir": ir_path.relative_to(output_root).as_posix(),
                "sourceSha256": _digest(path),
                "statistics": parsed["statistics"],
            }
            entries.append(entry)
            if unity_project is not None:
                exclusion = _unity_exclusion_reason(relative_key)
                if exclusion is not None:
                    entry["unityExcludedReason"] = exclusion
                    _remove_prepared_unity_animation(
                        unity_project,
                        relative,
                        texture_relative,
                        texture_use_count[texture_relative.as_posix().casefold()] == 1,
                    )
                else:
                    unity_data = (
                        unity_project
                        / "Assets/ProjectX/Resources/ProjectXAnimation"
                        / relative.with_suffix(".json")
                    )
                    _write_json(unity_data, parsed)
                    if texture.is_file():
                        unity_texture = (
                            unity_project
                            / "Assets/ProjectX/Resources/ProjectXAnimation"
                            / texture_relative
                        )
                        entry["texturePreparation"] = _prepare_texture(
                            texture, unity_texture, _required_texture_size(parsed)
                        )
                    entry["unityResourceKey"] = (
                        "ProjectXAnimation/" + relative.with_suffix("").as_posix()
                    )
                    entry["unityTextureResourceKey"] = (
                        "ProjectXAnimation/" + texture_relative.with_suffix("").as_posix()
                    )
        except (AniFormatError, OSError, ValueError) as exc:
            errors.append({"source": relative.as_posix(), "error": str(exc)})

    manifest = {
        "schemaVersion": 1,
        "scope": scope,
        "resourceRoot": resource_root.as_posix(),
        "entries": entries,
        "errors": errors,
        "statistics": {
            "animations": len(entries),
            "errors": len(errors),
            "texturesPresent": sum(1 for item in entries if item["textureExists"]),
            "unityPrepared": sum(1 for item in entries if "unityResourceKey" in item),
            "unityExcluded": sum(1 for item in entries if "unityExcludedReason" in item),
        },
    }
    _write_json(output_root / "ani-manifest.json", manifest)
    if unity_project is not None:
        catalog = {
            "schemaVersion": 1,
            "entries": [
                {
                    "legacyPath": item["source"][:-4],
                    "animationResourceKey": item["unityResourceKey"],
                    "textureResourceKey": item["unityTextureResourceKey"],
                    "aliases": item["aliases"],
                    "playable": item["textureExists"],
                    "texturePadded": item.get("texturePreparation", {}).get("padded", False),
                }
                for item in entries
                if "unityResourceKey" in item
            ],
        }
        _write_json(
            unity_project / "Assets/ProjectX/Resources/ProjectXAnimation/catalog.json", catalog
        )
    return manifest


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Convert ProjectX ImodAnim .ani files to engine-neutral JSON and prepare Unity runtime assets."
    )
    parser.add_argument("--repo-root", type=Path, default=Path(__file__).resolve().parents[2])
    parser.add_argument("--resource-root", type=Path)
    parser.add_argument("--output", type=Path)
    parser.add_argument("--scope", choices=("all", "welfare"), default="all")
    parser.add_argument(
        "--prepare-unity",
        action="store_true",
        help="Prepare Unity runtime assets; known Cocos-only animation paths are excluded.",
    )
    args = parser.parse_args()
    repo_root = args.repo_root.resolve()
    resource_root = (args.resource_root or repo_root / "client/ProjectX/res").resolve()
    output_root = (args.output or repo_root / "build/ui-migration").resolve()
    unity_project = repo_root / "unityclient" if args.prepare_unity else None
    manifest = convert(resource_root, output_root, args.scope, unity_project)
    print(json.dumps(manifest["statistics"], ensure_ascii=False, indent=2))
    return 1 if manifest["errors"] else 0


if __name__ == "__main__":
    raise SystemExit(main())
