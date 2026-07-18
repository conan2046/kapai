from __future__ import annotations

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
    _extract_frame,
    _normalize_node,
    _normalize_animation,
    _normalize_resource,
    _scale9_border,
    _select_copy_asset,
    _slice_variant_path,
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


if __name__ == "__main__":
    unittest.main()
