"""Exercise the real SQLite adapter against a disposable database."""
import hashlib
import json
import pathlib
import sqlite3
import subprocess
import sys
import tempfile
import unittest
from contextlib import closing


class MailVisualFixtureTest(unittest.TestCase):
    def test_currency_content_backup_guard_and_exact_restore(self):
        with tempfile.TemporaryDirectory(prefix="mail-visual-") as temporary:
            root = pathlib.Path(temporary)
            database, backup, evidence = (root / name for name in ("projectx.db", "snapshot.bak", "evidence.json"))
            with closing(sqlite3.connect(database)) as connection:
                connection.executescript("""
                    CREATE TABLE user_info1(id INTEGER,role0 INTEGER,money INTEGER,bd_money INTEGER);
                    INSERT INTO user_info1 VALUES(7200057,1000003,71,83);
                    CREATE TABLE role_info(id INTEGER,money INTEGER);
                    INSERT INTO role_info VALUES(1000003,97);
                    CREATE TABLE xin_shi(id INTEGER PRIMARY KEY,money INTEGER,YB INTEGER,bdYB INTEGER,
                        attachment TEXT,from_id INTEGER,to_id INTEGER,gmtime INTEGER,time TEXT,
                        shenhun INTEGER,deleted INTEGER,from_name TEXT,message TEXT);
                    INSERT INTO xin_shi VALUES(1,0,0,0,'',0,1000003,0,'2020-01-01 00:00:00',0,0,'原发件人','原邮件');
                """)
            original_hash = hashlib.sha256(database.read_bytes()).hexdigest()

            def run(action, success=True):
                result = subprocess.run([
                    sys.executable, "-X", "utf8", str(pathlib.Path(__file__).with_name("Invoke-MailSqliteFixture.py")),
                    "--action", action, "--database", str(database), "--backup", str(backup),
                    "--evidence", str(evidence), "--user-id", "7200057", "--role-id", "1000003",
                ], capture_output=True, text=True, encoding="utf-8")
                self.assertEqual(result.returncode == 0, success, result.stderr)

            run("Setup")
            run("AssertSetup")
            immutable = backup.read_bytes()
            run("Setup", success=False)
            self.assertEqual(backup.read_bytes(), immutable)
            with closing(sqlite3.connect(database)) as connection:
                self.assertEqual(connection.execute("SELECT money,bd_money FROM user_info1").fetchone(), (100000, 100000))
                self.assertEqual(connection.execute("SELECT money FROM role_info").fetchone()[0], 1000000)
                self.assertEqual(connection.execute("SELECT COUNT(*) FROM xin_shi WHERE deleted=0").fetchone()[0], 14)
                connection.execute("UPDATE role_info SET money=1")
                connection.commit()
            run("AssertSetup", success=False)
            run("Restore")
            run("AssertRestored")
            self.assertEqual(hashlib.sha256(database.read_bytes()).hexdigest(), original_hash)
            run("Cleanup")
            run("AssertCleanup")
            self.assertFalse(backup.exists())
            self.assertEqual(json.loads(evidence.read_text(encoding="utf-8"))["residualCount"], 0)


if __name__ == "__main__":
    unittest.main()
