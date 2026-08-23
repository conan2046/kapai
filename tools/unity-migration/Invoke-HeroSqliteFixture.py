import argparse
import hashlib
import json
import os
import shutil
import sqlite3
import struct
import zlib
from datetime import datetime, timezone


HEROES = ((24, "姬发"), (57, "苏全忠"), (64, "郑伦"), (60, "吕岳"), (62, "张奎"))
FORMATION_BOOK_IDS = tuple(range(2725, 2731))
FORMATION_BOOK_QUANTITY = 10
FORMATION_GOLD = 5_000_000
HERO_ROLE_LEVEL = 30
FORMATION_OPEN_LEVELS = (1, 6, 15, 25, 30)


def sha256(path):
    digest = hashlib.sha256()
    with open(path, "rb") as stream:
        for block in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest()


def expand(value):
    return bytearray(zlib.decompress(bytes.fromhex(value)))


def compress(value):
    return zlib.compress(bytes(value), 9).hex()


def parse_pets(value):
    data = expand(value)
    if len(data) < 2:
        raise RuntimeError("Hero SQLite pet payload is truncated")
    position = 2
    records = []
    for _ in range(data[0]):
        if position + 11 > len(data):
            raise RuntimeError("Hero SQLite pet record is truncated")
        start = position
        pet_id, level, _ = struct.unpack_from("<HHI", data, position)
        position += 8
        position += 2
        name_length = data[position]
        position += 1 + name_length
        if data[1] > 0:
            position += 1
            xiu_count = data[position]
            position += 1 + 3 * xiu_count
        if position > len(data):
            raise RuntimeError(f"Hero SQLite pet {pet_id} exceeds payload")
        records.append((pet_id, level, bytes(data[start:position])))
    if position != len(data):
        raise RuntimeError("Hero SQLite pet payload has trailing bytes")
    return data[1], records


def make_pet(pet_id, name, ext_num):
    name_bytes = name.encode("utf-8")
    value = bytearray(struct.pack("<HHIBBB", pet_id, 1, 0, 1, 0, len(name_bytes)))
    value.extend(name_bytes)
    if ext_num > 0:
        value.extend((0, 0))
    return bytes(value)


def five_pet_blob(value):
    ext_num, records = parse_pets(value)
    existing = {pet_id: record for pet_id, _, record in records}
    ordered = []
    for pet_id, name in HEROES:
        ordered.append(existing.get(pet_id) or make_pet(pet_id, name, ext_num))
    output = bytearray((len(ordered), ext_num))
    for record in ordered:
        output.extend(record)
    return compress(output)


def parse_package(value):
    data = expand(value)
    position = 0
    records = []
    for slot in range(500):
        if position + 2 > len(data):
            raise RuntimeError(f"Hero SQLite package payload is truncated at slot {slot}")
        item_id = struct.unpack_from("<H", data, position)[0]
        position += 2
        quantity = 0
        if item_id > 0:
            if position + 2 > len(data):
                raise RuntimeError(f"Hero SQLite package item {item_id} is truncated")
            quantity = struct.unpack_from("<H", data, position)[0]
            position += 2
        records.append([item_id, quantity])
    if position != len(data):
        raise RuntimeError("Hero SQLite package payload has trailing bytes")
    return records


def formation_package_blob(value):
    records = parse_package(value)
    for item_id in FORMATION_BOOK_IDS:
        record = next((item for item in records if item[0] == item_id), None)
        if record is None:
            record = next((item for item in records if item[0] == 0), None)
            if record is None:
                raise RuntimeError("Hero SQLite package has no empty slot for formation books")
            record[0] = item_id
        record[1] = max(record[1], FORMATION_BOOK_QUANTITY)
    output = bytearray()
    for item_id, quantity in records:
        output.extend(struct.pack("<H", item_id))
        if item_id > 0:
            output.extend(struct.pack("<H", quantity))
    return compress(output)


def formation_fixture_state(connection, role_id):
    row = connection.execute("SELECT money,package FROM role_info WHERE id=?", (role_id,)).fetchone()
    if row is None:
        raise RuntimeError(f"SQLite role {role_id} is missing")
    quantities = {item_id: quantity for item_id, quantity in parse_package(row[1]) if item_id > 0}
    state = {
        "money": int(row[0]),
        "formationBooks": {str(item_id): quantities.get(item_id, 0) for item_id in FORMATION_BOOK_IDS},
        "integrity": connection.execute("PRAGMA integrity_check").fetchone()[0],
    }
    return state


def assert_formation_setup(connection, role_id):
    state = formation_fixture_state(connection, role_id)
    if (state["money"] < FORMATION_GOLD or state["integrity"] != "ok"
            or any(quantity < FORMATION_BOOK_QUANTITY for quantity in state["formationBooks"].values())):
        raise RuntimeError(f"Hero formation SQLite fixture assertion failed: {state}")
    return state


def fixture_state(connection, user_id, role_id):
    link = connection.execute("SELECT role0 FROM user_info1 WHERE id=?", (user_id,)).fetchone()
    role = connection.execute("SELECT level,pet,zhenfa FROM role_info WHERE id=?", (role_id,)).fetchone()
    if link is None or int(link[0]) != role_id:
        raise RuntimeError(f"SQLite user {user_id} is not uniquely linked to role {role_id}")
    if role is None:
        raise RuntimeError(f"SQLite role {role_id} is missing")
    ext_num, records = parse_pets(role[1])
    ids = [pet_id for pet_id, _, _ in records]
    integrity = connection.execute("PRAGMA integrity_check").fetchone()[0]
    return {"level": int(role[0]), "petIds": ids, "petCount": len(ids), "integrity": integrity}


def assert_setup(connection, user_id, role_id):
    state = fixture_state(connection, user_id, role_id)
    expected = [pet_id for pet_id, _ in HEROES]
    if (state["level"] < HERO_ROLE_LEVEL or state["petCount"] != len(expected)
            or set(state["petIds"]) != set(expected) or state["integrity"] != "ok"):
        raise RuntimeError(f"Hero SQLite fixture assertion failed: {state}")
    return state


def read_evidence(path):
    with open(path, "r", encoding="utf-8") as stream:
        return json.load(stream)


def write_evidence(path, payload):
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
    database = os.path.abspath(args.database)
    backup = os.path.abspath(args.backup)
    evidence = os.path.abspath(args.evidence)

    if args.action == "Setup":
        if not os.path.isfile(database):
            raise RuntimeError(f"Hero SQLite database is missing: {database}")
        connection = sqlite3.connect(database)
        try:
            connection.execute("PRAGMA wal_checkpoint(TRUNCATE)")
            before = fixture_state(connection, args.user_id, args.role_id)
        finally:
            connection.close()
        os.makedirs(os.path.dirname(backup), exist_ok=True)
        shutil.copy2(database, backup)
        snapshot_hash = sha256(backup)
        connection = sqlite3.connect(database)
        try:
            pet = connection.execute("SELECT pet FROM role_info WHERE id=?", (args.role_id,)).fetchone()[0]
            connection.execute("UPDATE role_info SET level=?,pet=? WHERE id=?",
                               (HERO_ROLE_LEVEL, five_pet_blob(pet), args.role_id))
            connection.commit()
            after = assert_setup(connection, args.user_id, args.role_id)
        finally:
            connection.close()
        write_evidence(evidence, {
            "schemaVersion": 1,
            "action": "Setup",
            "backend": "sqlite",
            "database": database,
            "backup": backup,
            "userId": args.user_id,
            "roleId": args.role_id,
            "snapshotHash": snapshot_hash,
            "fixtureHash": sha256(database),
            "before": before,
            "fixture": after,
            "formationOpenLevels": list(FORMATION_OPEN_LEVELS),
            "createdUtc": datetime.now(timezone.utc).isoformat(),
        })
        return

    if args.action == "SetupFormation":
        if not os.path.isfile(database):
            raise RuntimeError(f"Hero SQLite database is missing: {database}")
        connection = sqlite3.connect(database)
        try:
            connection.execute("PRAGMA wal_checkpoint(TRUNCATE)")
            before = formation_fixture_state(connection, args.role_id)
        finally:
            connection.close()
        os.makedirs(os.path.dirname(backup), exist_ok=True)
        shutil.copy2(database, backup)
        snapshot_hash = sha256(backup)
        connection = sqlite3.connect(database)
        try:
            package = connection.execute("SELECT package FROM role_info WHERE id=?", (args.role_id,)).fetchone()[0]
            connection.execute("UPDATE role_info SET money=?,package=? WHERE id=?",
                               (max(before["money"], FORMATION_GOLD), formation_package_blob(package), args.role_id))
            connection.commit()
            after = assert_formation_setup(connection, args.role_id)
        finally:
            connection.close()
        write_evidence(evidence, {
            "schemaVersion": 1,
            "action": "SetupFormation",
            "backend": "sqlite",
            "database": database,
            "backup": backup,
            "userId": args.user_id,
            "roleId": args.role_id,
            "snapshotHash": snapshot_hash,
            "fixtureHash": sha256(database),
            "before": before,
            "fixture": after,
            "createdUtc": datetime.now(timezone.utc).isoformat(),
        })
        return

    snapshot = read_evidence(evidence)
    if snapshot.get("backend") != "sqlite" or snapshot.get("userId") != args.user_id or snapshot.get("roleId") != args.role_id:
        raise RuntimeError("Hero SQLite fixture evidence identity mismatch")
    if args.action == "AssertSetup":
        connection = sqlite3.connect(database)
        try:
            assert_setup(connection, args.user_id, args.role_id)
        finally:
            connection.close()
    elif args.action == "AssertFormationSetup":
        connection = sqlite3.connect(database)
        try:
            assert_formation_setup(connection, args.role_id)
        finally:
            connection.close()
    elif args.action in ("CaptureMutationHash", "AssertMutationReloginHash"):
        if not os.path.isfile(database):
            raise RuntimeError("Hero SQLite database is missing during mutation hash assertion")
    elif args.action == "Restore":
        if sha256(backup) != snapshot["snapshotHash"]:
            raise RuntimeError("Hero SQLite immutable backup hash changed")
        for suffix in ("-wal", "-shm"):
            sidecar = database + suffix
            if os.path.exists(sidecar):
                os.remove(sidecar)
        shutil.copy2(backup, database)
    elif args.action in ("AssertRestored", "AssertReloginHash"):
        if sha256(database) != snapshot["snapshotHash"]:
            raise RuntimeError("Hero SQLite restored database hash mismatch")
        connection = sqlite3.connect("file:" + database + "?mode=ro", uri=True)
        try:
            if connection.execute("PRAGMA integrity_check").fetchone()[0] != "ok":
                raise RuntimeError("Hero SQLite restored database integrity failed")
        finally:
            connection.close()
    elif args.action == "Cleanup":
        if os.path.exists(backup):
            os.remove(backup)
    elif args.action == "AssertCleanup":
        if os.path.exists(backup):
            raise RuntimeError("Hero SQLite fixture backup remains after cleanup")
    else:
        raise RuntimeError(f"Unsupported Hero SQLite fixture action: {args.action}")


if __name__ == "__main__":
    main()
