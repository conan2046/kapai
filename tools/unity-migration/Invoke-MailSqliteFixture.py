import argparse
import hashlib
import json
import os
import shutil
import sqlite3
import struct
from datetime import datetime, timedelta, timezone


def sha256(path):
    digest = hashlib.sha256()
    with open(path, "rb") as stream:
        for block in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest()


def remove_sidecars(database):
    for suffix in ("-wal", "-shm"):
        path = database + suffix
        if os.path.isfile(path):
            os.remove(path)


def attachment(rewards):
    data = bytearray((len(rewards),))
    for reward_type, type_id, amount in rewards:
        data.extend(struct.pack("<iii", reward_type, type_id, amount))
    return data.hex()


ONE = attachment(((3201, 0, 10),))
TWO = attachment(((500, 0, 2), (613, 0, 5)))
NINE = attachment(((500, 0, 1), (613, 0, 3), (851, 0, 20), (853, 0, 2),
                   (854, 0, 4), (855, 0, 1), (861, 0, 2), (862, 0, 3), (863, 0, 4)))


def fixture_rows(role_id):
    now = datetime.now(timezone.utc).replace(microsecond=0)
    bodies = [
        ("", "系统", "邮件验证 无附件未读正文", 0),
        (ONE, "系统", "邮件验证 单附件可领取", 0),
        (NINE, "活动使者", "邮件验证 多附件滚动与详情", 0),
        (TWO, "系统", "邮件验证 一键领取 A", 0),
        (ONE, "系统", "邮件验证 一键领取 B", 0),
    ]
    for index in range(6, 13):
        bodies.append(("", "系统", f"邮件验证 列表滚动 {index:02d}", 0))
    bodies.append(("", "系统", "邮件验证 长正文：用于验证正文滚动、裁剪、重进、重连、切号隔离和数据库精确恢复。" * 12, 0))
    bodies.append((ONE, "系统", "邮件验证 列表滚动 14", 0))
    bodies.append((ONE, "系统", "邮件验证 已领取不可见行", 1))
    return [(0, 0, 0, attach, 0, role_id, 0,
             (now - timedelta(minutes=index + 1)).strftime("%Y-%m-%d %H:%M:%S"),
             0, deleted, sender, body)
            for index, (attach, sender, body, deleted) in enumerate(bodies)]


def state(connection, user_id, role_id):
    link = connection.execute("SELECT role0 FROM user_info1 WHERE id=?", (user_id,)).fetchone()
    if link is None or int(link[0]) != role_id:
        raise RuntimeError(f"SQLite user {user_id} is not linked to role {role_id}")
    rows = connection.execute(
        "SELECT attachment,deleted,from_name,message FROM xin_shi WHERE to_id=? ORDER BY id", (role_id,)
    ).fetchall()
    visible = [row for row in rows if int(row[1]) == 0 and str(row[3]).startswith("邮件验证 ")]
    hidden = [row for row in rows if int(row[1]) == 1 and row[3] == "邮件验证 已领取不可见行"]
    return {
        "integrity": connection.execute("PRAGMA integrity_check").fetchone()[0],
        "total": len(rows),
        "fixtureVisible": len(visible),
        "fixtureHidden": len(hidden),
        "plainVisible": sum(1 for row in visible if not row[0]),
        "attachmentVisible": sum(1 for row in visible if row[0]),
        "nineAttachmentVisible": sum(1 for row in visible if row[0] and str(row[0]).startswith("09")),
    }


def assert_setup(connection, user_id, role_id):
    current = state(connection, user_id, role_id)
    if (current["integrity"] != "ok" or current["fixtureVisible"] != 14
            or current["fixtureHidden"] != 1 or current["plainVisible"] < 5
            or current["attachmentVisible"] < 5 or current["nineAttachmentVisible"] != 1):
        raise RuntimeError(f"Mail SQLite fixture assertion failed: {current}")
    return current


def read_json(path):
    with open(path, "r", encoding="utf-8") as stream:
        return json.load(stream)


def write_json(path, payload):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "w", encoding="utf-8", newline="\n") as stream:
        json.dump(payload, stream, ensure_ascii=False, indent=2)
        stream.write("\n")


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--action", required=True)
    parser.add_argument("--database", required=True)
    parser.add_argument("--backup", required=True)
    parser.add_argument("--evidence", required=True)
    parser.add_argument("--user-id", required=True, type=int)
    parser.add_argument("--role-id", required=True, type=int)
    args = parser.parse_args()
    database, backup, evidence = map(os.path.abspath, (args.database, args.backup, args.evidence))

    if args.action == "Setup":
        if not os.path.isfile(database):
            raise RuntimeError(f"Mail SQLite database is missing: {database}")
        connection = sqlite3.connect(database)
        try:
            connection.execute("PRAGMA wal_checkpoint(TRUNCATE)")
            before = state(connection, args.user_id, args.role_id)
        finally:
            connection.close()
        os.makedirs(os.path.dirname(backup), exist_ok=True)
        shutil.copy2(database, backup)
        connection = sqlite3.connect(database)
        try:
            connection.execute("DELETE FROM xin_shi WHERE to_id=?", (args.role_id,))
            connection.executemany(
                "INSERT INTO xin_shi(money,YB,bdYB,attachment,from_id,to_id,gmtime,time,shenhun,deleted,from_name,message) "
                "VALUES(?,?,?,?,?,?,?,?,?,?,?,?)", fixture_rows(args.role_id))
            connection.commit()
            fixture = assert_setup(connection, args.user_id, args.role_id)
        finally:
            connection.close()
        write_json(evidence, {
            "schemaVersion": 1, "action": "Setup", "backend": "sqlite",
            "database": database, "backup": backup, "userId": args.user_id,
            "roleId": args.role_id, "snapshotHash": sha256(backup),
            "fixtureHash": sha256(database), "before": before, "fixture": fixture,
            "createdUtc": datetime.now(timezone.utc).isoformat(),
        })
        return

    snapshot = read_json(evidence)
    if args.action == "AssertSetup":
        connection = sqlite3.connect(database)
        try:
            snapshot["assertedFixture"] = assert_setup(connection, args.user_id, args.role_id)
        finally:
            connection.close()
        if sha256(backup) != snapshot["snapshotHash"]:
            raise RuntimeError("Mail SQLite immutable backup hash changed")
        write_json(evidence, snapshot)
    elif args.action == "Restore":
        if sha256(backup) != snapshot["snapshotHash"]:
            raise RuntimeError("Mail SQLite backup hash changed before restore")
        remove_sidecars(database)
        shutil.copy2(backup, database)
    elif args.action == "AssertRestored":
        actual = sha256(database)
        if actual != snapshot["snapshotHash"]:
            raise RuntimeError("Mail SQLite restored database hash mismatch")
        connection = sqlite3.connect(database)
        try:
            current = state(connection, args.user_id, args.role_id)
        finally:
            connection.close()
        if current != snapshot["before"]:
            raise RuntimeError(f"Mail SQLite restored state mismatch: {current}")
        snapshot["restoredHash"] = actual
        snapshot["restored"] = current
        write_json(evidence, snapshot)
    elif args.action == "AssertReloginHash":
        connection = sqlite3.connect(database)
        try:
            current = state(connection, args.user_id, args.role_id)
        finally:
            connection.close()
        if current != snapshot["before"]:
            raise RuntimeError(f"Mail SQLite relogin business-state mismatch: {current}")
        snapshot["postLoginBusinessStateVerified"] = current
        snapshot["postLoginDatabaseHash"] = sha256(database)
        write_json(evidence, snapshot)
    elif args.action == "Cleanup":
        if os.path.isfile(backup):
            os.remove(backup)
    elif args.action == "AssertCleanup":
        if os.path.exists(backup):
            raise RuntimeError("Mail SQLite fixture backup remains after cleanup")
        snapshot["residualCount"] = 0
        write_json(evidence, snapshot)
    else:
        raise RuntimeError(f"Unsupported action: {args.action}")


if __name__ == "__main__":
    main()
