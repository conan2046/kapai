import argparse
import csv
import hashlib
import json
import os
import shutil
import sqlite3
import struct
import zlib
from datetime import date, datetime, timezone

ANSWER_DAILY_LEGACY = 6
ANSWER_QUESTION_COUNT = 35
ANSWER_CORRECT_COUNT = 683


def sha256(path):
    digest = hashlib.sha256()
    with open(path, "rb") as stream:
        for block in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest()


def expand(value):
    return zlib.decompress(bytes.fromhex(value or ""))


def compress(value):
    return zlib.compress(bytes(value)).hex()


def parse_bank_item(value):
    data = expand(value)
    position = 0

    def take(fmt):
        nonlocal position
        size = struct.calcsize(fmt)
        if position + size > len(data):
            raise RuntimeError("Answer bank_item payload is truncated")
        result = struct.unpack_from(fmt, data, position)
        position += size
        return result

    values8 = {take("<H")[0]: take("<B")[0] for _ in range(take("<H")[0])}
    values16 = {take("<H")[0]: take("<H")[0] for _ in range(take("<H")[0])}
    values32 = {take("<H")[0]: take("<I")[0] for _ in range(take("<H")[0])}
    return values8, values16, values32, bytes(data[position:])


def make_bank_item(value, answer_daily=0, questions=0, correct=0):
    values8, values16, values32, tail = parse_bank_item(value)
    values8[ANSWER_DAILY_LEGACY] = answer_daily
    values8[ANSWER_QUESTION_COUNT] = questions
    values8[ANSWER_CORRECT_COUNT] = correct
    output = bytearray(struct.pack("<H", len(values8)))
    for key, entry in sorted(values8.items()):
        output.extend(struct.pack("<HB", key, entry))
    output.extend(struct.pack("<H", len(values16)))
    for key, entry in sorted(values16.items()):
        output.extend(struct.pack("<HH", key, entry))
    output.extend(struct.pack("<H", len(values32)))
    for key, entry in sorted(values32.items()):
        output.extend(struct.pack("<HI", key, entry))
    output.extend(tail)
    return compress(output)


def load_settings(path):
    with open(path, "r", encoding="utf-8-sig", newline="") as stream:
        rows = list(csv.DictReader(stream))
    if len(rows) != 1 or int(rows[0]["id"]) != 1:
        raise RuntimeError("Answer settings must contain exactly id=1")
    settings = {
        "dailyAttemptLimit": int(rows[0]["daily_attempt_limit"]),
        "fallbackRewardType": int(rows[0]["fallback_reward_type"]),
        "fallbackRewardAmount": int(rows[0]["fallback_reward_amount"]),
    }
    if settings["dailyAttemptLimit"] < 1 or settings["fallbackRewardType"] != 60000 or settings["fallbackRewardAmount"] < 1:
        raise RuntimeError(f"Answer settings are invalid: {settings}")
    return settings


def table_exists(connection, table):
    return connection.execute(
        "SELECT 1 FROM sqlite_master WHERE type='table' AND name=?", (table,)
    ).fetchone() is not None


def business_state(connection, user_id, role_id):
    link = connection.execute("SELECT role0 FROM user_info1 WHERE id=?", (user_id,)).fetchone()
    role = connection.execute("SELECT level,money,bank_item FROM role_info WHERE id=?", (role_id,)).fetchone()
    if link is None or role is None:
        raise RuntimeError(f"Answer SQLite identity is missing: {user_id}/{role_id}")
    values8, _, _, _ = parse_bank_item(role[2])
    daily = None
    if table_exists(connection, "answer_daily_progress"):
        row = connection.execute(
            "SELECT used_count FROM answer_daily_progress WHERE role_id=? AND day_key=?",
            (role_id, date.today().isoformat()),
        ).fetchone()
        daily = 0 if row is None else int(row[0])
    settings = None
    if table_exists(connection, "answer_settings"):
        row = connection.execute(
            "SELECT daily_attempt_limit,fallback_reward_type,fallback_reward_amount FROM answer_settings WHERE id=1"
        ).fetchone()
        if row is not None:
            settings = {
                "dailyAttemptLimit": int(row[0]),
                "fallbackRewardType": int(row[1]),
                "fallbackRewardAmount": int(row[2]),
            }
    state = {
        "linkedRoleId": int(link[0]),
        "level": int(role[0] or 0),
        "money": int(role[1] or 0),
        "legacyDaily": int(values8.get(ANSWER_DAILY_LEGACY, 0)),
        "questionCount": int(values8.get(ANSWER_QUESTION_COUNT, 0)),
        "correctCount": int(values8.get(ANSWER_CORRECT_COUNT, 0)),
        "dailyUsed": daily,
        "settings": settings,
        "integrity": connection.execute("PRAGMA integrity_check").fetchone()[0],
    }
    payload = json.dumps(
        {key: state[key] for key in state if key != "integrity"},
        ensure_ascii=False,
        sort_keys=True,
        separators=(",", ":"),
    )
    state["businessSha256"] = hashlib.sha256(payload.encode("utf-8")).hexdigest()
    return state


def ensure_answer_schema(connection, settings):
    connection.execute(
        "CREATE TABLE IF NOT EXISTS answer_settings (id INTEGER PRIMARY KEY,daily_attempt_limit INTEGER NOT NULL,fallback_reward_type INTEGER NOT NULL,fallback_reward_amount INTEGER NOT NULL)"
    )
    connection.execute(
        "CREATE TABLE IF NOT EXISTS answer_daily_progress (role_id INTEGER NOT NULL,day_key TEXT NOT NULL,used_count INTEGER NOT NULL DEFAULT 0,PRIMARY KEY(role_id,day_key))"
    )
    connection.execute(
        "INSERT INTO answer_settings(id,daily_attempt_limit,fallback_reward_type,fallback_reward_amount) VALUES(1,?,?,?) "
        "ON CONFLICT(id) DO UPDATE SET daily_attempt_limit=excluded.daily_attempt_limit,fallback_reward_type=excluded.fallback_reward_type,fallback_reward_amount=excluded.fallback_reward_amount",
        (settings["dailyAttemptLimit"], settings["fallbackRewardType"], settings["fallbackRewardAmount"]),
    )


def assert_setup(connection, user_id, role_id, expected):
    current = business_state(connection, user_id, role_id)
    if (
        current["linkedRoleId"] != role_id
        or current["level"] < 10
        or current["integrity"] != "ok"
        or current["legacyDaily"] != 0
        or current["questionCount"] != 0
        or current["correctCount"] != 0
        or current["dailyUsed"] != 0
        or current["settings"] != expected
    ):
        raise RuntimeError(f"Answer deterministic SQLite fixture assertion failed: {current}")
    return current


def read_json(path):
    with open(path, "r", encoding="utf-8") as stream:
        return json.load(stream)


def write_json(path, payload):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "w", encoding="utf-8", newline="\n") as stream:
        json.dump(payload, stream, ensure_ascii=False, indent=2)
        stream.write("\n")


def remove_sidecars(database):
    for suffix in ("-wal", "-shm"):
        path = database + suffix
        if os.path.exists(path):
            os.remove(path)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--action", required=True)
    parser.add_argument("--database", required=True)
    parser.add_argument("--backup", required=True)
    parser.add_argument("--evidence", required=True)
    parser.add_argument("--settings", required=True)
    parser.add_argument("--user-id", type=int, required=True)
    parser.add_argument("--role-id", type=int, required=True)
    args = parser.parse_args()
    database, backup, evidence, settings_path = map(
        os.path.abspath, (args.database, args.backup, args.evidence, args.settings)
    )
    expected = load_settings(settings_path)

    if args.action == "Setup":
        if not os.path.isfile(database):
            raise RuntimeError(f"Answer SQLite database is missing: {database}")
        connection = sqlite3.connect(database)
        try:
            connection.execute("PRAGMA wal_checkpoint(TRUNCATE)")
            before = business_state(connection, args.user_id, args.role_id)
        finally:
            connection.close()
        os.makedirs(os.path.dirname(backup), exist_ok=True)
        shutil.copy2(database, backup)
        connection = sqlite3.connect(database)
        try:
            ensure_answer_schema(connection, expected)
            row = connection.execute("SELECT bank_item,level FROM role_info WHERE id=?", (args.role_id,)).fetchone()
            connection.execute("UPDATE user_info1 SET role0=? WHERE id=?", (args.role_id, args.user_id))
            connection.execute(
                "UPDATE role_info SET level=?,bank_item=? WHERE id=?",
                (max(10, int(row[1] or 0)), make_bank_item(row[0]), args.role_id),
            )
            connection.execute(
                "INSERT INTO answer_daily_progress(role_id,day_key,used_count) VALUES(?,?,0) "
                "ON CONFLICT(role_id,day_key) DO UPDATE SET used_count=0",
                (args.role_id, date.today().isoformat()),
            )
            connection.commit()
            fixture = assert_setup(connection, args.user_id, args.role_id, expected)
        finally:
            connection.close()
        write_json(
            evidence,
            {
                "schemaVersion": 1,
                "module": "Answer",
                "backend": "sqlite",
                "action": "Setup",
                "database": database,
                "backup": backup,
                "userId": args.user_id,
                "roleId": args.role_id,
                "snapshotHash": sha256(backup),
                "fixtureHash": sha256(database),
                "before": before,
                "fixture": fixture,
                "expected": expected,
                "restored": False,
                "reloginVerified": False,
                "databaseIntegrity": fixture["integrity"],
                "residualCount": 1,
                "createdUtc": datetime.now(timezone.utc).isoformat(),
            },
        )
        return

    snapshot = read_json(evidence)
    if snapshot.get("backend") != "sqlite" or snapshot.get("userId") != args.user_id or snapshot.get("roleId") != args.role_id:
        raise RuntimeError("Answer SQLite fixture evidence identity mismatch")
    if args.action == "AssertSetup":
        connection = sqlite3.connect("file:" + database + "?mode=ro", uri=True)
        try:
            assert_setup(connection, args.user_id, args.role_id, snapshot["expected"])
        finally:
            connection.close()
    elif args.action == "AssertMutated":
        connection = sqlite3.connect("file:" + database + "?mode=ro", uri=True)
        try:
            current = business_state(connection, args.user_id, args.role_id)
        finally:
            connection.close()
        if (
            current["dailyUsed"] < snapshot["expected"]["dailyAttemptLimit"]
            or current["questionCount"] < 10
            or current["integrity"] != "ok"
        ):
            raise RuntimeError(f"Answer completion mutation assertion failed: {current}")
        snapshot["mutated"] = current
        snapshot["mutatedUtc"] = datetime.now(timezone.utc).isoformat()
        write_json(evidence, snapshot)
    elif args.action == "Restore":
        if sha256(backup) != snapshot["snapshotHash"]:
            raise RuntimeError("Answer immutable SQLite backup hash changed")
        remove_sidecars(database)
        shutil.copy2(backup, database)
        snapshot["restored"] = True
        snapshot["restoredUtc"] = datetime.now(timezone.utc).isoformat()
        write_json(evidence, snapshot)
    elif args.action == "AssertRestored":
        if sha256(database) != snapshot["snapshotHash"]:
            raise RuntimeError("Answer restored SQLite database hash mismatch")
        connection = sqlite3.connect("file:" + database + "?mode=ro", uri=True)
        try:
            integrity = connection.execute("PRAGMA integrity_check").fetchone()[0]
        finally:
            connection.close()
        if integrity != "ok":
            raise RuntimeError("Answer restored SQLite integrity failed")
        snapshot["databaseIntegrity"] = integrity
        write_json(evidence, snapshot)
    elif args.action == "AssertReloginHash":
        connection = sqlite3.connect("file:" + database + "?mode=ro", uri=True)
        try:
            current = business_state(connection, args.user_id, args.role_id)
        finally:
            connection.close()
        if current["integrity"] != "ok" or current["businessSha256"] != snapshot["before"]["businessSha256"]:
            raise RuntimeError("Answer relogin business hash mismatch")
        snapshot["reloginVerified"] = True
        snapshot["reloginUtc"] = datetime.now(timezone.utc).isoformat()
        write_json(evidence, snapshot)
    elif args.action == "Cleanup":
        if os.path.exists(backup):
            os.remove(backup)
        snapshot["residualCount"] = 0
        write_json(evidence, snapshot)
    elif args.action == "AssertCleanup":
        if os.path.exists(backup) or snapshot.get("residualCount") != 0:
            raise RuntimeError("Answer SQLite fixture cleanup failed")
    else:
        raise RuntimeError(f"Unsupported Answer fixture action: {args.action}")


if __name__ == "__main__":
    main()
