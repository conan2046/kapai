#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import struct
import sys
from pathlib import Path
import sqlite3
import tempfile
import unittest
from unittest import mock


HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))
sys.path.insert(0, str(HERE.parent.parent / "docs" / "gm-backend"))

import gm_client as gc  # noqa: E402
import gm_web as gw  # noqa: E402
import migrate_admin as migration  # noqa: E402


class FakeSocket:
    def close(self):
        pass


class ProtocolValidationTests(unittest.TestCase):
    def test_level_rejects_negative_instead_of_wrapping(self):
        with self.assertRaises(ValueError):
            gc.build_set_level_body(1, -1)

    def test_item_count_rejects_uint8_overflow(self):
        with self.assertRaises(ValueError):
            gc.build_add_item_body(1, 1, 256, 0)

    def test_currency_rejects_invalid_binding_flag(self):
        with self.assertRaises(ValueError):
            gc.build_add_currency_body(1, 1000, 2)

    def test_raw_sql_api_is_not_available(self):
        self.assertFalse(hasattr(gc, "build_raw_sql_body"))
        self.assertFalse(hasattr(gc, "do_gm_raw_sql"))
        self.assertFalse(hasattr(gc, "ensure_admin"))

    def test_active_role_query_body_uses_read_only_op(self):
        self.assertEqual(struct.pack("<H", 21), gc.build_active_role_body())

    def run_action_with_reply(self, msg_type, op, result_text):
        body = struct.pack("<H", op) + gc.pack_string(result_text)
        with mock.patch.object(gc, "_connect", return_value=FakeSocket()), \
             mock.patch.object(gc, "_login_and_gm", return_value=(True, "ok", {})), \
             mock.patch.object(gc, "send_recv", return_value=(msg_type, body)):
            return gc.do_gm_action({}, lambda: gc.build_set_level_body(1, 10))

    def test_action_accepts_matching_verified_success(self):
        ok, info = self.run_action_with_reply(gc.MSG_MGR, 5, "OK|等级已修改")
        self.assertTrue(ok)
        self.assertIn("等级已修改", info["info"])

    def test_action_rejects_wrong_message_type(self):
        ok, info = self.run_action_with_reply(1001, 5, "OK|等级已修改")
        self.assertFalse(ok)
        self.assertIn("响应类型不匹配", info["error"])

    def test_action_rejects_wrong_op(self):
        ok, info = self.run_action_with_reply(gc.MSG_MGR, 1, "OK|等级已修改")
        self.assertFalse(ok)
        self.assertIn("响应 op 不匹配", info["error"])

    def test_action_rejects_unverified_legacy_text(self):
        ok, info = self.run_action_with_reply(gc.MSG_MGR, 5, "修改成功")
        self.assertFalse(ok)
        self.assertIn("未返回可验证结果", info["error"])


class WebSafetyTests(unittest.TestCase):
    def test_action_selector_does_not_submit_on_change(self):
        rendered = gw.page()
        self.assertNotIn('onchange="this.form.submit()"', rendered)

    def test_selftest_does_not_require_role_id_field(self):
        with mock.patch.object(gw.gc, "do_gm_selftest", return_value=(True, {"info": "ok"})):
            ok, info = gw.perform("selftest", {"action": "selftest"})
        self.assertTrue(ok)
        self.assertEqual("ok", info["info"])

    def test_web_rejects_negative_level_before_network(self):
        ok, info = gw.perform("level", {"role_id": "1", "level": "-1"})
        self.assertFalse(ok)
        self.assertIn("1~255", info["error"])

    def test_web_rejects_item_count_overflow_before_network(self):
        ok, info = gw.perform(
            "item",
            {"role_id": "1", "tmpl_id": "1", "num": "256", "item_level": "0"},
        )
        self.assertFalse(ok)
        self.assertIn("1~255", info["error"])

    def test_web_rejects_target_that_is_not_current_online_save(self):
        with mock.patch.object(
            gw.gc,
            "do_gm_whoami",
            return_value=(True, {"login": {"role_id": 1000001, "role_name": "007"}}),
        ), mock.patch.object(gw.gc, "do_gm_action") as action:
            ok, info = gw.perform("level", {"role_id": "1000002", "level": "100"})
        self.assertFalse(ok)
        self.assertIn("已拦截", info["error"])
        action.assert_not_called()


class MigrationTests(unittest.TestCase):
    def test_current_windows_fallback_hash(self):
        self.assertEqual(
            migration.server_password_hash("gm123456", "djb2-win32"),
            "000000000000000000000000c6ae3a4e",
        )

    def test_standard_md5_mode(self):
        self.assertEqual(
            migration.server_password_hash("gm123456", "standard-md5"),
            "b4c61ebb7d5e8038bbbe415d5e12b8db",
        )

    def test_migration_backs_up_and_updates_stub_schema(self):
        with tempfile.TemporaryDirectory() as temp_dir:
            db_path = Path(temp_dir) / "projectx.db"
            conn = sqlite3.connect(str(db_path))
            try:
                conn.execute("CREATE TABLE admin (id INTEGER PRIMARY KEY AUTOINCREMENT)")
                conn.commit()
            finally:
                conn.close()

            argv = ["migrate_admin.py", str(db_path)]
            with mock.patch.object(sys, "argv", argv):
                migration.main()

            backups = list(db_path.parent.glob("projectx.gm-backup-*.db"))
            self.assertEqual(1, len(backups))
            conn = sqlite3.connect(str(db_path))
            try:
                columns = {row[1] for row in conn.execute("PRAGMA table_info(admin)")}
                self.assertTrue({"userId", "name", "pwd"}.issubset(columns))
                row = conn.execute(
                    "SELECT userId,pwd FROM admin WHERE name='gm'"
                ).fetchone()
                self.assertEqual((1, "000000000000000000000000c6ae3a4e"), row)
                self.assertEqual("ok", conn.execute("PRAGMA quick_check").fetchone()[0])
            finally:
                conn.close()


if __name__ == "__main__":
    unittest.main()
