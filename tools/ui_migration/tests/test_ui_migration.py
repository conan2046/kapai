from __future__ import annotations

import json
import plistlib
import struct
import sys
import tempfile
import unittest
from pathlib import Path

from PIL import Image


TOOLS_DIR = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(TOOLS_DIR))

from csd_ir import parse_csd  # noqa: E402
from ani_ir import AniFormatError, parse_ani_bytes  # noqa: E402
from convert_ui import duplicate_status  # noqa: E402
from convert_animations import convert as convert_animations  # noqa: E402
from imod_usage import collect_imod_usage  # noqa: E402
from ir_enrichment import (  # noqa: E402
    attach_paths_and_collect_resources,
    attach_unity_layout,
    validate_ir_contract,
)
from plist_ir import parse_plist  # noqa: E402
from runtime_usage import (  # noqa: E402
    build_runtime_usage,
    collect_timeline_csb_references,
    normalize_csb_path,
)
from prepare_unity_project import (  # noqa: E402
    prepare,
    _validate_scope,
    _extract_frame,
    _normalize_node,
    _normalize_animation,
    _normalize_resource,
    _scale9_border,
    _select_canonical_borders,
    _select_copy_asset,
    _slice_variant_path,
)
from consolidate_sliced_sprites import (  # noqa: E402
    _build_mapping,
    _rewrite_resource_paths,
)


SAMPLE_CSD = """<GameFile>
  <PropertyGroup Name="Sample" Type="Layer" ID="id-1" Version="3.10.0.0" />
  <Content ctype="GameProjectContent"><Content>
    <Animation Duration="10" Speed="1.0000">
      <Timeline ActionTag="2" Property="Position">
        <PointFrame FrameIndex="0" X="1.0" Y="2.0" />
      </Timeline>
    </Animation>
    <ObjectData Name="Layer" Tag="1" ctype="GameLayerObjectData">
      <Size X="1280" Y="720"/><Children>
        <AbstractNodeData Name="Start" ActionTag="2" Tag="3" TouchEnable="True" ctype="ButtonObjectData">
          <Size X="100" Y="40"/><AnchorPoint ScaleX="0.5" ScaleY="0.5"/>
          <NormalFileData Type="Normal" Path="res/start.png" Plist=""/>
        </AbstractNodeData>
      </Children>
    </ObjectData>
  </Content></Content>
</GameFile>"""


class AniParserTests(unittest.TestCase):
    def test_parses_legacy_modules_frames_actions_and_duration_compatibility(self) -> None:
        data = bytearray([1])
        data.extend(struct.pack("<hhhh", 0, 0, 10, 20))
        data.extend([1, 1])
        data.extend(struct.pack("<hh", -5, -10))
        data.extend([0, 3, 1, 1, 0, 1])

        result = parse_ani_bytes(bytes(data), "sample.ani")

        self.assertEqual(result["modules"][0]["height"], 20)
        self.assertEqual(result["frames"][0]["parts"][0]["x"], -5)
        self.assertEqual(result["frames"][0]["parts"][0]["flags"], 3)
        self.assertEqual(result["actions"][0]["frames"][0]["durationTicks"], 5)
        self.assertEqual(result["frameRate"], 30)

    def test_rejects_trailing_or_truncated_data(self) -> None:
        with self.assertRaises(AniFormatError):
            parse_ani_bytes(b"\x00\x00\x00\x99", "trailing.ani")
        with self.assertRaises(AniFormatError):
            parse_ani_bytes(b"\x01", "truncated.ani")


class UnityAnimationPreparationTests(unittest.TestCase):
    def test_native_prefab_excludes_retired_document_and_legacy_resource_generation(self) -> None:
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            unity = root / "unity"
            native = unity / "Assets/Prefabs/Common/tanchuangjiangli.prefab"
            native.parent.mkdir(parents=True)
            native.write_text("authored Unity prefab", encoding="utf-8")
            migration = root / "output/migration"
            (migration / "baselines").mkdir(parents=True)
            font = root / "client/ProjectX/res/MicrosoftArial.ttf"
            font.parent.mkdir(parents=True)
            font.write_bytes(b"test font copy fixture")
            (migration / "baselines/manifest.json").write_text(json.dumps({"baselines": [{
                "name": "tanchuangjiangli", "source": "cocosstudio/csd/common/tanchuangjiangli.csd",
                "irPath": "reward.json"
            }]}), encoding="utf-8")
            (migration / "asset-manifest.json").write_text('{"assets": []}', encoding="utf-8")
            (migration / "reward.json").write_text(json.dumps({
                "root": {}, "resources": [{"path": "res/reward-exclusive.png", "type": "Normal"}]
            }), encoding="utf-8")
            result = prepare(unity, migration, "baseline")
            self.assertEqual(result["documents"], [])
            self.assertEqual(result["generatedAssets"], ["Assets/ProjectX/res/MicrosoftArial.ttf"])
            self.assertEqual(result["statistics"]["logicalResources"], 0)
            self.assertEqual(native.read_text(encoding="utf-8"), "authored Unity prefab")
            self.assertFalse((unity / "Assets/ProjectX/res/csd/UnityMigration/documents/common/tanchuangjiangli.json").exists())

    def test_unity_native_login_and_monster_animation_families_are_excluded(self) -> None:
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            resource_root = root / "client/ProjectX/res"
            data = bytearray([1])
            data.extend(struct.pack("<hhhh", 0, 0, 10, 20))
            data.extend([1, 1])
            data.extend(struct.pack("<hh", -5, -10))
            data.extend([0, 3, 1, 1, 0, 1])
            excluded_paths = (
                "res2/fx/loading",
                "res2/animation/effect_chuangjue_1",
                "res2/create/Create_4",
                "res2/create/Create_5",
                "res2/animation/battle/quality2",
                "res2/animation/battle/quality3",
                "res2/animation/battle/quality7",
                "res2/animation/battle/quality8",
                "Skill/skill_commen_shoot",
                "res2/Skill/buff_attackup",
                "UI/shaizi",
                "Monster/btm123_zd_show",
                "Monster/btm123_zd",
                "Monster/btm123_gj",
                "Monster/btm123_sf1",
                "Monster/btm123_sf2",
                "Monster/btm123_sw",
                "Monster/btm123_bj",
            )
            for relative in excluded_paths:
                source_ani = resource_root / f"{relative}.ani"
                source_ani.parent.mkdir(parents=True, exist_ok=True)
                source_ani.write_bytes(data)
                Image.new("RGBA", (10, 20), (255, 255, 255, 255)).save(
                    source_ani.with_suffix(".png")
                )

            unity_root = root / "unityclient"
            for relative in excluded_paths:
                unity_assets = unity_root / "Assets/ProjectX/Resources/ProjectXAnimation" / Path(relative).parent
                unity_assets.mkdir(parents=True, exist_ok=True)
                for suffix in (".json", ".png"):
                    asset = unity_assets / f"{Path(relative).name}{suffix}"
                    asset.write_bytes(b"stale generated asset")
                    Path(f"{asset}.meta").write_text("stale metadata", encoding="utf-8")

            manifest = convert_animations(resource_root, root / "build/ui-migration", "all", unity_root)
            entries = {entry["source"][:-4]: entry for entry in manifest["entries"]}
            catalog = (unity_root / "Assets/ProjectX/Resources/ProjectXAnimation/catalog.json").read_text(
                encoding="utf-8"
            )
            removed_assets = all(
                not (unity_root / "Assets/ProjectX/Resources/ProjectXAnimation" / Path(relative).parent / f"{Path(relative).name}{suffix}").exists()
                for relative in excluded_paths
                for suffix in (".json", ".json.meta", ".png", ".png.meta")
            )
            retained_ir = all(
                (root / "build/ui-migration/ani" / f"{relative}.ani.json").is_file()
                for relative in excluded_paths
            )
            cocos_sources_unchanged = all(
                (resource_root / f"{relative}.ani").read_bytes() == data
                for relative in excluded_paths
            )

        self.assertEqual(set(entries), set(excluded_paths))
        for entry in entries.values():
            self.assertIn("unityExcludedReason", entry)
            self.assertNotIn("unityResourceKey", entry)
        self.assertEqual(manifest["statistics"]["unityPrepared"], 0)
        self.assertEqual(manifest["statistics"]["unityExcluded"], len(excluded_paths))
        for relative in excluded_paths:
            self.assertNotIn(relative, catalog)
        self.assertTrue(removed_assets)
        self.assertTrue(retained_ir)
        self.assertTrue(cocos_sources_unchanged)


class RuntimeUsageTests(unittest.TestCase):
    def test_uses_full_relative_paths_and_ignores_lua_comments(self) -> None:
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            source = root / "src/View/Welfare"
            runtime = root / "runtime"
            editor = root / "editor"
            source.mkdir(parents=True)
            (runtime / "huodong").mkdir(parents=True)
            (editor / "huodong").mkdir(parents=True)
            (runtime / "LevelGiftLayer.csb").write_bytes(b"root")
            (runtime / "huodong/LevelGiftLayer.csb").write_bytes(b"event")
            (editor / "huodong/LevelGiftLayer.csd").write_text("<xml/>", encoding="utf-8")
            (source / "Sample.lua").write_text(
                '-- ignored = "csd/huodong/LevelGiftLayer.csb"\n'
                'local active = "csd/LevelGiftLayer.csb"\n',
                encoding="utf-8",
            )

            usage = build_runtime_usage(root / "src", runtime, editor)

        self.assertEqual(normalize_csb_path("csd/LevelGiftLayer.csb"), "levelgiftlayer.csb")
        self.assertEqual(usage["sets"]["referenced"], ["levelgiftlayer.csb"])
        self.assertEqual(usage["sets"]["welfare"], ["levelgiftlayer.csb"])
        self.assertIn("levelgiftlayer.csb", usage["sets"]["referencedMissingEditorCsd"])
        self.assertEqual(
            usage["duplicateBasenames"]["levelgiftlayer.csb"],
            ["huodong/levelgiftlayer.csb", "levelgiftlayer.csb"],
        )

    def test_resolves_active_timeline_variables_and_play_action_targets(self) -> None:
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            root.mkdir(exist_ok=True)
            (root / "Sample.lua").write_text(
                'local CsbFilePath = "csd/role/LevelUp.csb"\n'
                'cc.CSLoader:createTimeline(CsbFilePath)\n'
                '-- cc.CSLoader:createTimeline("csd/ignored.csb")\n'
                'Utils:PlayAction("csd/map/Cloud.csb", 0, 10)\n',
                encoding="utf-8",
            )
            references = collect_timeline_csb_references(root)

        self.assertEqual(sorted(references), ["map/cloud.csb", "role/levelup.csb"])

    def test_collects_imod_calls_and_distinguishes_dynamic_paths(self) -> None:
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            (root / "Sample.lua").write_text(
                'local effect = ImodAnim:createWithFileSync("res2/fx/fixed")\n'
                'effect:PlayActionRepeat(0)\n'
                'local dynamic = ImodAnim:create()\n'
                'dynamic:initAnimWithName(path .. ".png", path .. ".ani")\n'
                '-- local ignored = ImodAnim:createWithFileSync("ignored")\n'
                'other:PlayAction(0)\n',
                encoding="utf-8",
            )
            usage = collect_imod_usage(root)

        self.assertEqual(usage["statistics"]["constructors"], 2)
        self.assertEqual(usage["statistics"]["calls"], 4)
        self.assertEqual(usage["fixedResourcePaths"], ["res2/fx/fixed"])
        self.assertEqual(usage["statistics"]["dynamicLoads"], 1)


class TimelineNormalizationTests(unittest.TestCase):
    def test_cocos_timeline_prefab_generation_scope_is_retired(self) -> None:
        with self.assertRaisesRegex(ValueError, "Cocos Timeline Prefab generation is retired"):
            _validate_scope("timeline")

    def test_preserves_named_clips_events_tween_and_effective_duration(self) -> None:
        animation = {
            "attributes": {"Duration": 0, "Speed": 1, "ActivedAnimationName": "open"},
            "children": [
                {
                    "tag": "Timeline",
                    "attributes": {"ActionTag": 7, "Property": "FrameEvent"},
                    "children": [
                        {
                            "tag": "EventFrame",
                            "attributes": {
                                "FrameIndex": 12,
                                "Tween": False,
                                "Value": "close",
                            },
                        }
                    ],
                }
            ],
        }
        animation_list = {
            "children": [
                {
                    "tag": "AnimationInfo",
                    "attributes": {"Name": "open", "StartIndex": 3, "EndIndex": 20},
                }
            ]
        }

        result = _normalize_animation(animation, animation_list)

        self.assertEqual(result["duration"], 20)
        self.assertEqual(result["currentAnimationName"], "open")
        self.assertEqual(result["clips"][0]["startFrame"], 3)
        self.assertEqual(result["timelines"][0]["frames"][0]["eventName"], "close")
        self.assertFalse(result["timelines"][0]["frames"][0]["tween"])


class CsdParserTests(unittest.TestCase):
    def test_parses_nodes_resources_and_animation_without_losing_attributes(self) -> None:
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            path = root / "Sample.csd"
            path.write_text(SAMPLE_CSD, encoding="utf-8")
            result = parse_csd(path, root)

        self.assertEqual(result["source"]["metadata"]["Name"], "Sample")
        self.assertEqual(result["statistics"]["nodeCount"], 2)
        button = result["root"]["children"][0]
        self.assertEqual(button["sourceType"], "ButtonObjectData")
        self.assertTrue(button["attributes"]["TouchEnable"])
        self.assertEqual(result["resources"][0]["path"], "res/start.png")
        timeline = result["animation"]["children"][0]
        self.assertEqual(timeline["attributes"]["Property"], "Position")

    def test_enriched_csd_satisfies_frozen_ir_contract(self) -> None:
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            path = root / "Sample.csd"
            path.write_text(SAMPLE_CSD, encoding="utf-8")
            result = parse_csd(path, root)
            attach_unity_layout(result["root"])
            result["resources"] = attach_paths_and_collect_resources(result["root"])

        self.assertEqual(validate_ir_contract(result), [])
        button = result["root"]["children"][0]
        self.assertEqual(button["unityRect"]["pivot"], {"x": 0.5, "y": 0.5})


class PlistParserTests(unittest.TestCase):
    def test_parses_texture_packer_atlas(self) -> None:
        atlas = {
            "frames": {
                "res/icon.png": {
                    "frame": "{{1,2},{30,40}}",
                    "offset": "{3,4}",
                    "sourceSize": "{32,44}",
                    "rotated": False,
                }
            },
            "metadata": {"textureFileName": "atlas.png"},
        }
        with tempfile.TemporaryDirectory() as temp:
            path = Path(temp) / "atlas.plist"
            with path.open("wb") as stream:
                plistlib.dump(atlas, stream)
            result = parse_plist(path, Path(temp))

        self.assertEqual(result["kind"], "SpriteAtlas")
        self.assertEqual(result["texture"], "atlas.png")
        self.assertEqual(result["frames"][0]["rect"]["width"], 30.0)

    def test_extracts_rotated_frame_with_swapped_packed_dimensions(self) -> None:
        atlas = {
            "frames": {
                "res/rotated.png": {
                    "frame": "{{1,1},{4,2}}",
                    "offset": "{0,0}",
                    "sourceSize": "{4,2}",
                    "rotated": True,
                }
            },
            "metadata": {"textureFileName": "atlas.png"},
        }
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            plist_path = root / "atlas.plist"
            with plist_path.open("wb") as stream:
                plistlib.dump(atlas, stream)
            image = Image.new("RGBA", (8, 8), (0, 0, 0, 0))
            for x in range(1, 3):
                for y in range(1, 5):
                    image.putpixel((x, y), (255, 0, 0, 255))
            image.save(root / "atlas.png")
            output = root / "frame.png"
            _extract_frame(plist_path, "res/rotated.png", output)
            with Image.open(output) as extracted:
                self.assertEqual(extracted.size, (4, 2))
                pixels = {
                    extracted.getpixel((x, y))
                    for x in range(extracted.width)
                    for y in range(extracted.height)
                }
                self.assertEqual(pixels, {(255, 0, 0, 255)})

    def test_parses_particle_config(self) -> None:
        with tempfile.TemporaryDirectory() as temp:
            path = Path(temp) / "particle.plist"
            with path.open("wb") as stream:
                plistlib.dump({"maxParticles": 100, "emitterType": 0}, stream)
            result = parse_plist(path, Path(temp))

        self.assertEqual(result["kind"], "ParticleConfig")


class ResourceValidationTests(unittest.TestCase):
    def test_prefers_decodable_editor_image_over_encrypted_runtime_copy(self) -> None:
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            encrypted = root / "runtime.png"
            editor = root / "editor.png"
            encrypted.write_bytes(b"xcres-encrypted")
            Image.new("RGBA", (2, 2), (255, 255, 255, 255)).save(editor)
            selected = _select_copy_asset(
                {
                    "selected": {"path": str(encrypted)},
                    "candidates": [
                        {"path": str(encrypted)},
                        {"path": str(editor)},
                    ],
                },
                "res/UI/image.png",
            )
        self.assertEqual(selected["path"], str(editor))

    def test_marked_subimage_keeps_its_standalone_asset_path(self) -> None:
        resource = _normalize_resource(
            {
                "property": "FileData",
                "path": "res/UI/ui_common/red_dot.png",
                "plist": "csd/Plist/ui_common.plist",
                "type": "MarkedSubImage",
            }
        )
        self.assertEqual(
            resource["assetPath"],
            "Assets/ProjectX/res/csd/UnityMigration/Marked/res/UI/ui_common/red_dot.png",
        )

    def test_distinguishes_identical_and_conflicting_asset_copies(self) -> None:
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            first = root / "first.png"
            second = root / "second.png"
            first.write_bytes(b"same")
            second.write_bytes(b"same")
            cache: dict[str, str] = {}
            self.assertEqual(
                duplicate_status([first, second], cache), "duplicate-identical"
            )
            second.write_bytes(b"different")
            cache.clear()
            self.assertEqual(
                duplicate_status([first, second], cache), "duplicate-conflict"
            )

    def test_scale9_border_falls_back_to_origin_when_edges_exceed_sprite(self) -> None:
        node = {
            "nodePath": "Layer/Lock",
            "attributes": {
                "LeftEage": 19,
                "BottomEage": 19,
                "RightEage": 19,
                "TopEage": 19,
                "Scale9OriginX": 14,
                "Scale9OriginY": 19,
                "Scale9Width": 5,
                "Scale9Height": 3,
            },
        }
        with tempfile.TemporaryDirectory() as temp:
            image_path = Path(temp) / "lock.png"
            Image.new("RGBA", (33, 41), (255, 255, 255, 255)).save(image_path)
            border = _scale9_border(node, image_path)

        self.assertEqual(border, (14, 19, 14, 19))
        self.assertEqual(
            _slice_variant_path("Assets/ProjectX/res/res/lock.png", border),
            "Assets/ProjectX/res/csd/UnityMigration/Sliced/res/lock__L14_B19_R14_T19.png",
        )

    def test_selects_most_used_scale9_border_as_canonical(self) -> None:
        source = "Assets/ProjectX/res/res/button.png"
        selected = _select_canonical_borders(
            {
                source: {
                    (15, 11, 15, 11): 9,
                    (80, 20, 80, 20): 2,
                    (0, 0, 163, 56): 1,
                }
            }
        )

        self.assertEqual(selected[source], (15, 11, 15, 11))

    def test_selects_scale9_border_deterministically_when_counts_tie(self) -> None:
        source = "Assets/ProjectX/res/res/panel.png"
        selected = _select_canonical_borders(
            {source: {(20, 10, 20, 10): 1, (10, 10, 10, 10): 1}}
        )

        self.assertEqual(selected[source], (10, 10, 10, 10))

    def test_canonical_scale9_border_reuses_source_texture(self) -> None:
        source = "Assets/ProjectX/res/res/button.png"
        node = {
            "name": "Button",
            "sourceType": "ButtonObjectData",
            "attributes": {
                "Scale9Enable": True,
                "LeftEage": 15,
                "BottomEage": 11,
                "RightEage": 15,
                "TopEage": 11,
            },
            "resources": [
                {"property": "NormalFileData", "path": "res/button.png", "type": "Normal"}
            ],
        }
        with tempfile.TemporaryDirectory() as temp:
            unity_project = Path(temp)
            image_path = unity_project / source
            image_path.parent.mkdir(parents=True)
            Image.new("RGBA", (164, 57), (255, 255, 255, 255)).save(image_path)
            variants: dict[str, dict] = {}
            borders: dict[str, dict] = {}

            normalized = _normalize_node(
                node,
                unity_project,
                variants,
                borders,
                {source: (15, 11, 15, 11)},
            )

        self.assertEqual(normalized["resources"][0]["assetPath"], source)
        self.assertEqual(variants, {})
        self.assertEqual(borders[source]["border"], {"x": 15, "y": 11, "z": 15, "w": 11})

    def test_multiple_scale9_borders_share_one_texture_with_named_sprites(self) -> None:
        source = "Assets/ProjectX/res/res/panel.png"
        node = {
            "name": "Panel",
            "sourceType": "ImageViewObjectData",
            "attributes": {
                "Scale9Enable": True,
                "LeftEage": 20,
                "BottomEage": 10,
                "RightEage": 20,
                "TopEage": 10,
            },
            "resources": [
                {"property": "FileData", "path": "res/panel.png", "type": "Normal"}
            ],
        }
        with tempfile.TemporaryDirectory() as temp:
            unity_project = Path(temp)
            image_path = unity_project / source
            image_path.parent.mkdir(parents=True)
            Image.new("RGBA", (100, 60), (255, 255, 255, 255)).save(image_path)
            borders: dict[str, dict] = {}
            normalized = _normalize_node(
                node,
                unity_project,
                {},
                borders,
                {source: (10, 10, 10, 10)},
                {source},
            )

        resource = normalized["resources"][0]
        self.assertEqual(resource["assetPath"], source)
        self.assertEqual(resource["spriteName"], "panel__L20_B10_R20_T10")
        self.assertEqual(len(borders), 1)
        self.assertEqual(next(iter(borders.values()))["assetPath"], source)

    def test_consolidation_maps_legacy_variant_to_sprite_sub_asset(self) -> None:
        source = "Assets/ProjectX/res/res/panel.png"
        variant = (
            "Assets/ProjectX/res/csd/UnityMigration/Sliced/res/"
            "panel__L20_B10_R20_T10.png"
        )
        definitions = [
            {
                "assetPath": source,
                "sourceAssetPath": source,
                "border": {"x": 10, "y": 10, "z": 10, "w": 10},
            },
            {
                "assetPath": variant,
                "sourceAssetPath": source,
                "border": {"x": 20, "y": 10, "z": 20, "w": 10},
            },
        ]

        mapping, converted, plan = _build_mapping(definitions)
        document = {"resources": [{"assetPath": variant}]}
        changes = _rewrite_resource_paths(document, mapping)

        self.assertEqual(changes, 2)
        self.assertEqual(document["resources"][0]["assetPath"], source)
        self.assertEqual(
            document["resources"][0]["spriteName"],
            "panel__L20_B10_R20_T10",
        )
        self.assertEqual({item["assetPath"] for item in converted}, {source})
        self.assertEqual(len(plan), 2)

    def test_normalizes_text_font_color_outline_and_shadow(self) -> None:
        node = {
            "name": "Title",
            "nodePath": "Layer/Title",
            "sourceType": "TextObjectData",
            "attributes": {
                "FontSize": 30,
                "LabelText": "标题",
                "OutlineEnabled": True,
                "OutlineSize": 2,
                "ShadowEnabled": True,
                "ShadowOffsetX": 3,
                "ShadowOffsetY": -4,
            },
            "properties": {
                "CColor": {"attributes": {"R": 255, "G": 128, "B": 0, "A": 255}},
                "OutlineColor": {"attributes": {"R": 1, "G": 2, "B": 3, "A": 255}},
                "ShadowColor": {"attributes": {"R": 4, "G": 5, "B": 6, "A": 128}},
            },
            "resources": [
                {
                    "property": "FontResource",
                    "path": "xiaokaiSJ2.ttf",
                    "plist": "",
                    "type": "Normal",
                }
            ],
            "children": [],
        }
        normalized = _normalize_node(node, Path("D:/unity"), {})

        self.assertEqual(normalized["fontAssetPath"], "Assets/ProjectX/res/xiaokaiSJ2.ttf")
        self.assertEqual(normalized["fontSize"], 30)
        self.assertEqual(normalized["color"]["g"], 128 / 255)
        self.assertTrue(normalized["outlineEnabled"])
        self.assertEqual(normalized["outlineSize"], 2.0)
        self.assertTrue(normalized["shadowEnabled"])
        self.assertEqual(normalized["shadowOffset"], {"x": 3.0, "y": -4.0})


class NativeMaintenanceTests(unittest.TestCase):
    def test_native_project_settings_survive_legacy_cache_removal(self):
        with tempfile.TemporaryDirectory() as temporary:
            project = Path(temporary) / "unity"
            settings = project / "ProjectSettings/ProjectXUiMaintenance.json"
            settings.parent.mkdir(parents=True)
            settings.write_text('{"maintenanceMode":"unity-native-only"}', encoding="utf-8")
            missing = Path(temporary) / "missing-cocos-sources"
            self.assertEqual(prepare(project, missing)["statistics"]["documents"], 0)
            self.assertEqual(convert_animations(missing, Path(temporary) / "output", "all", project)["statistics"]["unityPrepared"], 0)
            self.assertFalse((project / "Assets").exists())

    def test_native_mode_never_reads_or_recreates_cocos_sources(self):
        with tempfile.TemporaryDirectory() as temporary:
            project = Path(temporary) / "unity"
            manifest_path = project / "Assets/ProjectX/res/csd/UnityMigration/unity-import-manifest.json"
            manifest_path.parent.mkdir(parents=True)
            manifest = {"maintenanceMode": "unity-native-only", "documents": [], "statistics": {"documents": 0}}
            manifest_path.write_text(json.dumps(manifest), encoding="utf-8")
            before = manifest_path.read_bytes()
            missing_sources = Path(temporary) / "missing-cocos-sources"
            self.assertEqual(prepare(project, missing_sources), manifest)
            report = convert_animations(missing_sources, Path(temporary) / "output", "all", project)
            self.assertEqual(report["statistics"]["unityPrepared"], 0)
            self.assertEqual(manifest_path.read_bytes(), before)
            self.assertFalse((project / "Assets/ProjectX/Resources/ProjectXAnimation").exists())

    def test_native_mode_rejects_old_import_rows(self):
        with tempfile.TemporaryDirectory() as temporary:
            project = Path(temporary)
            manifest_path = project / "Assets/ProjectX/res/csd/UnityMigration/unity-import-manifest.json"
            manifest_path.parent.mkdir(parents=True)
            manifest_path.write_text(json.dumps({
                "maintenanceMode": "unity-native-only", "documents": [{"name": "Legacy"}]
            }), encoding="utf-8")
            with self.assertRaises(ValueError):
                prepare(project, project / "missing-cocos-sources")


if __name__ == "__main__":
    unittest.main()
