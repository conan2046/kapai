import importlib.util
import struct
import unittest
import zlib
from pathlib import Path


FIXTURE_PATH = Path(__file__).parents[1] / "Invoke-BagSqliteFixture.py"
SPEC = importlib.util.spec_from_file_location("bag_sqlite_fixture", FIXTURE_PATH)
BAG_FIXTURE = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(BAG_FIXTURE)


class BagReloginSpiritTests(unittest.TestCase):
    def test_full_spirit_zero_timestamp_is_a_valid_normalized_sentinel(self):
        expected = {"userSpiritSha256": "before", "userSpirit": 31, "userSpiritLastTime": 1790516011}
        current = {"userSpiritSha256": "after", "userSpirit": 100, "userSpiritLastTime": 0}

        self.assertEqual(
            BAG_FIXTURE.relogin_spirit_matches(expected, current),
            (True, "normalized-full-sentinel"),
        )

    def test_zero_timestamp_below_full_spirit_remains_invalid(self):
        expected = {"userSpiritSha256": "before", "userSpirit": 31, "userSpiritLastTime": 1790516011}
        current = {"userSpiritSha256": "after", "userSpirit": 99, "userSpiritLastTime": 0}

        self.assertEqual(
            BAG_FIXTURE.relogin_spirit_matches(expected, current),
            (False, "invalid-clock"),
        )

    def test_identical_spirit_blob_uses_exact_match(self):
        expected = {"userSpiritSha256": "same", "userSpirit": 31, "userSpiritLastTime": 1790516011}
        current = {"userSpiritSha256": "same", "userSpirit": 31, "userSpiritLastTime": 1790516011}

        self.assertEqual(
            BAG_FIXTURE.relogin_spirit_matches(expected, current),
            (True, "exact"),
        )

    def test_inventory_totals_hash_ignores_compression_level(self):
        slots = struct.pack("<HHHH", 500, 29, 512, 2) + bytes(996)
        package_level_1 = zlib.compress(slots, 1).hex()
        package_level_9 = zlib.compress(slots, 9).hex()

        self.assertNotEqual(package_level_1, package_level_9)
        self.assertEqual(
            BAG_FIXTURE.package_item_totals_sha256(package_level_1),
            BAG_FIXTURE.package_item_totals_sha256(package_level_9),
        )


if __name__ == "__main__":
    unittest.main()
