#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""显式迁移已有 SQLite 存档的 GM 账号结构与口令。"""

import argparse
import hashlib
from datetime import datetime
from pathlib import Path
import sqlite3


DEFAULT_PWD = "gm123456"


def server_password_hash(password: str, mode: str) -> str:
    if mode == "standard-md5":
        return hashlib.md5(password.encode("utf-8")).hexdigest()

    # 当前 Windows LocalServer 未发现 OpenSSL 头时，gyu::util::MD5String
    # 使用 32 位 unsigned long djb2 回退。必须显式命名，避免误认为标准 MD5。
    value = 5381
    for byte in password.encode("utf-8"):
        value = ((value << 5) + value + byte) & 0xFFFFFFFF
    return "%032x" % value


def parse_args():
    parser = argparse.ArgumentParser(description="迁移 projectx.db 的 GM 管理表")
    parser.add_argument("database", type=Path, help="projectx.db 路径")
    parser.add_argument("password", nargs="?", default=DEFAULT_PWD, help="GM 口令")
    parser.add_argument(
        "--hash-mode",
        choices=("djb2-win32", "standard-md5"),
        default="djb2-win32",
        help="当前 Windows LocalServer 默认 djb2-win32；启用 OpenSSL 的构建使用 standard-md5",
    )
    return parser.parse_args()


def main():
    args = parse_args()
    db_path = args.database.resolve()
    if not db_path.is_file():
        raise SystemExit("数据库不存在: %s" % db_path)

    backup_path = db_path.with_name(
        "%s.gm-backup-%s%s"
        % (db_path.stem, datetime.now().strftime("%Y%m%d-%H%M%S"), db_path.suffix)
    )
    pwd_hash = server_password_hash(args.password, args.hash_mode)

    conn = sqlite3.connect(str(db_path), timeout=2.0)
    try:
        check = conn.execute("PRAGMA quick_check").fetchone()
        if not check or check[0] != "ok":
            raise RuntimeError("迁移前 quick_check 失败: %s" % (check[0] if check else "无结果"))

        backup = sqlite3.connect(str(backup_path))
        try:
            conn.backup(backup)
        finally:
            backup.close()

        with conn:
            conn.execute(
                "CREATE TABLE IF NOT EXISTS admin ("
                "id INTEGER PRIMARY KEY AUTOINCREMENT, "
                "userId INTEGER NOT NULL DEFAULT 0, "
                "name TEXT NOT NULL DEFAULT '', "
                "pwd TEXT NOT NULL DEFAULT '')"
            )
            columns = {row[1] for row in conn.execute("PRAGMA table_info(admin)")}
            for column, ddl in (
                ("userId", "INTEGER NOT NULL DEFAULT 0"),
                ("name", "TEXT NOT NULL DEFAULT ''"),
                ("pwd", "TEXT NOT NULL DEFAULT ''"),
            ):
                if column not in columns:
                    conn.execute("ALTER TABLE admin ADD COLUMN %s %s" % (column, ddl))

            row = conn.execute("SELECT id FROM admin WHERE name=? LIMIT 1", ("gm",)).fetchone()
            if row:
                conn.execute(
                    "UPDATE admin SET userId=?,pwd=? WHERE id=?",
                    (1, pwd_hash, row[0]),
                )
            else:
                conn.execute(
                    "INSERT INTO admin (userId,name,pwd) VALUES (?,?,?)",
                    (1, "gm", pwd_hash),
                )

            conn.execute(
                "CREATE TABLE IF NOT EXISTS admin_log ("
                "id INTEGER PRIMARY KEY AUTOINCREMENT, "
                "role_id INTEGER NOT NULL DEFAULT 0, "
                "msg TEXT, "
                "time TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP)"
            )

        check = conn.execute("PRAGMA quick_check").fetchone()
        if not check or check[0] != "ok":
            raise RuntimeError("迁移后 quick_check 失败: %s" % (check[0] if check else "无结果"))
    finally:
        conn.close()

    print("完成: %s" % db_path)
    print("备份: %s" % backup_path)
    print("哈希模式: %s（未输出明文口令）" % args.hash_mode)


if __name__ == "__main__":
    main()
