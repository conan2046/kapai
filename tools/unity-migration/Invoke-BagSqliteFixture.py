import argparse
import hashlib
import json
import os
import shutil
import sqlite3
import struct
import time
import zlib
from datetime import datetime, timezone


FIXTURE_ITEMS = (
    (614, 1), (852, 1), (853, 1), (855, 1), (401, 20),
    (500, 10), (500, 10),
    (512, 2), (513, 2), (514, 2),
    (1112, 2), (1111, 3), (1114, 3),
    (610, 1), (611, 1), (612, 1), (613, 1),
    (851, 1), (854, 1), (1000, 1), (1001, 1),
    (3201, 1),
)
BOX_EXPECTED = {512: 2, 513: 2, 514: 2}
FIXTURE_SPIRIT = 50


def sha256(path):
    digest = hashlib.sha256()
    with open(path, "rb") as stream:
        for block in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest()


def parse_package(value):
    data = zlib.decompress(bytes.fromhex(value))
    position = 0
    records = []
    while position < len(data):
        if len(records) >= 500:
            raise RuntimeError("Bag package contains more than 500 slots")
        slot = len(records)
        if position + 2 > len(data):
            raise RuntimeError(f"Bag package truncated at slot {slot}")
        item_id = struct.unpack_from("<H", data, position)[0]
        position += 2
        quantity = 0
        if item_id:
            if position + 2 > len(data):
                raise RuntimeError(f"Bag item {item_id} quantity truncated")
            quantity = struct.unpack_from("<H", data, position)[0]
            position += 2
        records.append((item_id, quantity))
    # The local server zero-fills its 500-slot buffer before loading older
    # shorter payloads, so an omitted tail is semantically a run of empty slots.
    while len(records) < 500:
        records.append((0, 0))
    return records


def make_package():
    data = bytearray()
    for item_id, quantity in FIXTURE_ITEMS:
        data.extend(struct.pack("<HH", item_id, quantity))
    for _ in range(500 - len(FIXTURE_ITEMS)):
        data.extend(struct.pack("<H", 0))
    return zlib.compress(bytes(data), 9).hex()


def parse_user_spirit(value):
    data = zlib.decompress(bytes.fromhex(value))
    if len(data) < 6:
        raise RuntimeError("Bag user_spirit is truncated")
    return struct.unpack_from("<HI", data, 0)


def make_user_spirit(value):
    data = bytearray(zlib.decompress(bytes.fromhex(value)))
    if len(data) < 6:
        raise RuntimeError("Bag user_spirit is truncated")
    struct.pack_into("<HI", data, 0, FIXTURE_SPIRIT, int(time.time()))
    return zlib.compress(bytes(data), 9).hex()


def state(connection, user_id, role_id):
    link = connection.execute("SELECT role0 FROM user_info1 WHERE id=?", (user_id,)).fetchone()
    role = connection.execute("SELECT package,user_spirit FROM role_info WHERE id=?", (role_id,)).fetchone()
    if link is None or int(link[0]) != role_id:
        raise RuntimeError(f"SQLite user {user_id} is not linked to role {role_id}")
    if role is None:
        raise RuntimeError(f"SQLite role {role_id} is missing")
    counts = {}
    for item_id, quantity in parse_package(role[0]):
        if item_id:
            counts[item_id] = counts.get(item_id, 0) + quantity
    spirit, spirit_last_time = parse_user_spirit(role[1])
    return {
        "integrity": connection.execute("PRAGMA integrity_check").fetchone()[0],
        "packageSha256": hashlib.sha256(role[0].encode("ascii")).hexdigest(),
        "userSpiritSha256": hashlib.sha256(role[1].encode("ascii")).hexdigest(),
        "userSpirit": spirit,
        "userSpiritLastTime": spirit_last_time,
        "aggregateItem500": counts.get(500, 0),
        "boxes": {str(item_id): counts.get(item_id, 0) for item_id in BOX_EXPECTED},
        "itemCount": len(counts),
    }


def assert_setup(connection, user_id, role_id):
    current = state(connection, user_id, role_id)
    if (current["integrity"] != "ok" or current["aggregateItem500"] != 20
            or current["boxes"] != {str(key): value for key, value in BOX_EXPECTED.items()}
            or current["userSpirit"] != FIXTURE_SPIRIT):
        raise RuntimeError(f"Bag SQLite fixture assertion failed: {current}")
    return current


def read_json(path):
    with open(path, "r", encoding="utf-8") as stream:
        return json.load(stream)


def write_json(path, payload):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "w", encoding="utf-8", newline="\n") as stream:
        json.dump(payload, stream, ensure_ascii=False, indent=2)
        stream.write("\n")


def integrity(path):
    connection = sqlite3.connect(path)
    try:
        return connection.execute("PRAGMA integrity_check").fetchone()[0]
    finally:
        connection.close()


def remove_sqlite_sidecars(database):
    for suffix in ("-wal", "-shm"):
        sidecar = database + suffix
        if os.path.isfile(sidecar):
            os.remove(sidecar)


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
            raise RuntimeError(f"Bag SQLite database is missing: {database}")
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
            current_spirit = connection.execute(
                "SELECT user_spirit FROM role_info WHERE id=?", (args.role_id,)).fetchone()[0]
            connection.execute("UPDATE role_info SET package=?,user_spirit=? WHERE id=?",
                               (make_package(), make_user_spirit(current_spirit), args.role_id))
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
            current = assert_setup(connection, args.user_id, args.role_id)
        finally:
            connection.close()
        if sha256(backup) != snapshot["snapshotHash"]:
            raise RuntimeError("Bag SQLite immutable backup hash changed")
        snapshot["assertedFixture"] = current
        write_json(evidence, snapshot)
    elif args.action == "Restore":
        if sha256(backup) != snapshot["snapshotHash"]:
            raise RuntimeError("Bag SQLite backup hash changed before restore")
        # Unity's LocalServer uses WAL mode. Replacing only the main file can
        # replay a stale post-mutation WAL on the next open and silently undo
        # the restore. The PowerShell adapter already requires all runtime
        # processes to be stopped before this action.
        remove_sqlite_sidecars(database)
        shutil.copy2(backup, database)
    elif args.action == "AssertRestored":
        actual = sha256(database)
        if actual != snapshot["snapshotHash"] or integrity(database) != "ok":
            raise RuntimeError("Bag SQLite restored database hash or integrity mismatch")
        snapshot["restoredHash"] = actual
        write_json(evidence, snapshot)
    elif args.action == "AssertReloginHash":
        connection = sqlite3.connect(database)
        try:
            current = state(connection, args.user_id, args.role_id)
        finally:
            connection.close()
        expected = snapshot["before"]
        if (current["integrity"] != "ok"
                or current["packageSha256"] != expected["packageSha256"]
                or current["userSpiritSha256"] != expected["userSpiritSha256"]
                or current["userSpirit"] != expected["userSpirit"]
                or current["aggregateItem500"] != expected["aggregateItem500"]
                or current["boxes"] != expected["boxes"]
                or current["itemCount"] != expected["itemCount"]):
            raise RuntimeError(f"Bag SQLite relogin business-state mismatch: {current}")
        snapshot["postLoginBusinessStateVerified"] = current
        write_json(evidence, snapshot)
    elif args.action == "Cleanup":
        if os.path.isfile(backup):
            os.remove(backup)
    elif args.action == "AssertCleanup":
        if os.path.exists(backup):
            raise RuntimeError("Bag SQLite fixture backup remains after cleanup")
        snapshot["residualCount"] = 0
        write_json(evidence, snapshot)
    else:
        raise RuntimeError(f"Unsupported Bag SQLite fixture action: {args.action}")


if __name__ == "__main__":
    main()
