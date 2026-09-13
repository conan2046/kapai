import argparse
import hashlib
import importlib.util
import json
import os
import shutil
import sqlite3
import struct
from datetime import datetime, timezone


_hero_spec = importlib.util.spec_from_file_location(
    "hero_fixture", os.path.join(os.path.dirname(__file__), "Invoke-HeroSqliteFixture.py"))
hero_fixture = importlib.util.module_from_spec(_hero_spec)
_hero_spec.loader.exec_module(hero_fixture)

CURRENT_ID = 0
TARGET_ID = 1
MONEY_QUANTITY = 100000
MONEY_COST = 10000
POWER_QUANTITY = 100000
MINIMUM_POWER = 50000
MINIMUM_LEVEL = 10
EXT_DATA16_JINGJIE = 65


def sha256(path):
    digest = hashlib.sha256()
    with open(path, "rb") as stream:
        for block in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest().upper()


def remove_sidecars(path):
    for suffix in ("-wal", "-shm"):
        sidecar = path + suffix
        if os.path.isfile(sidecar):
            os.remove(sidecar)


def write_json(path, payload):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "w", encoding="utf-8", newline="\n") as stream:
        json.dump(payload, stream, ensure_ascii=False, indent=2)
        stream.write("\n")


def read_json(path):
    with open(path, "r", encoding="utf-8") as stream:
        return json.load(stream)


def parse_bank_item(value):
    data = hero_fixture.expand(value)
    position = 0

    def take(fmt):
        nonlocal position
        size = struct.calcsize(fmt)
        if position + size > len(data):
            raise RuntimeError("JingJie bank_item payload is truncated")
        result = struct.unpack_from(fmt, data, position)
        position += size
        return result

    values8 = {take("<H")[0]: take("<B")[0] for _ in range(take("<H")[0])}
    values16 = {take("<H")[0]: take("<H")[0] for _ in range(take("<H")[0])}
    values32 = {take("<H")[0]: take("<I")[0] for _ in range(take("<H")[0])}
    return values8, values16, values32, bytes(data[position:])


def bank_item_blob(value, jingjie_id):
    values8, values16, values32, tail = parse_bank_item(value)
    values16[EXT_DATA16_JINGJIE] = jingjie_id
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
    return hero_fixture.compress(output)


def bank_item_jingjie(value):
    _, values16, _, _ = parse_bank_item(value)
    return int(values16.get(EXT_DATA16_JINGJIE, 0))


def state(connection, user_id, role_id):
    row = connection.execute(
        "SELECT r.level,r.money,r.bank_item,r.zhanDouLi FROM role_info r "
        "JOIN user_info1 u ON u.id=? AND CAST(u.role0 AS INTEGER)=r.id WHERE r.id=?",
        (user_id, role_id),
    ).fetchone()
    if row is None:
        raise RuntimeError(f"JingJie SQLite identity mismatch: {user_id}/{role_id}")
    stable = {
        "level": int(row[0] or 0),
        "money": int(row[1] or 0),
        "jingJieId": bank_item_jingjie(row[2]),
        "savedPower": int(row[3] or 0),
    }
    stable_hash = hashlib.sha256(
        json.dumps(stable, sort_keys=True, separators=(",", ":")).encode("utf-8")).hexdigest().upper()
    return {
        **stable,
        "stableHash": stable_hash,
        "integrity": connection.execute("PRAGMA integrity_check").fetchone()[0],
    }


def assert_setup(connection, user_id, role_id):
    current = state(connection, user_id, role_id)
    hero_state = hero_fixture.fixture_state(connection, user_id, role_id)
    if (current["integrity"] != "ok" or current["level"] < MINIMUM_LEVEL
            or current["money"] != MONEY_QUANTITY or current["jingJieId"] != CURRENT_ID
            or current["savedPower"] < MINIMUM_POWER
            or hero_state["integrity"] != "ok"):
        raise RuntimeError(f"JingJie SQLite fixture assertion failed: {current}, hero={hero_state}")
    current["combatHeroes"] = hero_state["combatHeroes"]
    current["fixtureEquipment"] = hero_state["fixtureEquipment"]
    return current


def assert_mutated(connection, user_id, role_id):
    current = state(connection, user_id, role_id)
    if (current["integrity"] != "ok" or current["jingJieId"] != TARGET_ID
            or current["money"] != MONEY_QUANTITY - MONEY_COST):
        raise RuntimeError(f"JingJie authoritative breakthrough assertion failed: {current}")
    return current


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--action", required=True)
    parser.add_argument("--database", required=True)
    parser.add_argument("--backup", required=True)
    parser.add_argument("--evidence", required=True)
    parser.add_argument("--user-id", type=int, required=True)
    parser.add_argument("--role-id", type=int, required=True)
    args = parser.parse_args()
    database, backup, evidence = map(os.path.abspath, (args.database, args.backup, args.evidence))

    if args.action == "Setup":
        if not os.path.isfile(database):
            raise RuntimeError(f"JingJie SQLite database is missing: {database}")
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
            row = connection.execute(
                "SELECT bank_item,level,pet,zhenfa,pet_equip FROM role_info WHERE id=?",
                (args.role_id,)).fetchone()
            if row is None:
                raise RuntimeError(f"JingJie SQLite role is missing: {args.role_id}")
            connection.execute(
                "UPDATE role_info SET bank_item=?,level=?,pet=?,zhenfa=?,pet_equip=?,money=?,zhanDouLi=? "
                "WHERE id=?",
                (bank_item_blob(row[0], CURRENT_ID), max(int(row[1]), hero_fixture.HERO_ROLE_LEVEL),
                 hero_fixture.five_pet_blob(row[2]), hero_fixture.two_occupied_formation_blob(row[3]),
                 hero_fixture.equipped_fixture_blob(row[4]), MONEY_QUANTITY, POWER_QUANTITY,
                 args.role_id))
            connection.commit()
            fixture = assert_setup(connection, args.user_id, args.role_id)
        finally:
            connection.close()
        write_json(evidence, {
            "schemaVersion": 1,
            "module": "JingJie",
            "action": "Setup",
            "backend": "sqlite",
            "database": database,
            "backup": backup,
            "userId": args.user_id,
            "roleId": args.role_id,
            "snapshotHash": sha256(backup),
            "fixtureHash": sha256(database),
            "before": before,
            "fixture": fixture,
            "expectedMutation": {
                "fromJingJieId": CURRENT_ID,
                "toJingJieId": TARGET_ID,
                "moneyCost": MONEY_COST,
            },
            "createdUtc": datetime.now(timezone.utc).isoformat(),
        })
        return

    snapshot = read_json(evidence)
    if snapshot.get("userId") != args.user_id or snapshot.get("roleId") != args.role_id:
        raise RuntimeError("JingJie SQLite evidence identity mismatch")
    if args.action == "AssertSetup":
        connection = sqlite3.connect("file:" + database + "?mode=ro", uri=True)
        try:
            assert_setup(connection, args.user_id, args.role_id)
        finally:
            connection.close()
        snapshot["setupAssertedUtc"] = datetime.now(timezone.utc).isoformat()
        write_json(evidence, snapshot)
    elif args.action == "AssertMutated":
        connection = sqlite3.connect("file:" + database + "?mode=ro", uri=True)
        try:
            mutated = assert_mutated(connection, args.user_id, args.role_id)
        finally:
            connection.close()
        snapshot["mutated"] = mutated
        snapshot["mutatedUtc"] = datetime.now(timezone.utc).isoformat()
        write_json(evidence, snapshot)
    elif args.action == "Restore":
        if sha256(backup) != snapshot["snapshotHash"]:
            raise RuntimeError("JingJie SQLite immutable backup hash changed")
        remove_sidecars(database)
        shutil.copy2(backup, database)
    elif args.action == "AssertRestored":
        if sha256(database) != snapshot["snapshotHash"]:
            raise RuntimeError("JingJie SQLite restored database hash mismatch")
        connection = sqlite3.connect("file:" + database + "?mode=ro", uri=True)
        try:
            if connection.execute("PRAGMA integrity_check").fetchone()[0] != "ok":
                raise RuntimeError("JingJie SQLite restored database integrity failed")
        finally:
            connection.close()
        snapshot["restoredHash"] = sha256(database)
        snapshot["restoredUtc"] = datetime.now(timezone.utc).isoformat()
        write_json(evidence, snapshot)
    elif args.action == "AssertReloginHash":
        connection = sqlite3.connect("file:" + database + "?mode=ro", uri=True)
        try:
            relogin = state(connection, args.user_id, args.role_id)
        finally:
            connection.close()
        if relogin["stableHash"] != snapshot["before"]["stableHash"]:
            raise RuntimeError(f"JingJie relogin stable business hash mismatch: {relogin}")
        snapshot["relogin"] = relogin
        snapshot["reloginUtc"] = datetime.now(timezone.utc).isoformat()
        write_json(evidence, snapshot)
    elif args.action == "Cleanup":
        if os.path.exists(backup):
            os.remove(backup)
    elif args.action == "AssertCleanup":
        if os.path.exists(backup):
            raise RuntimeError("JingJie SQLite fixture backup remains after cleanup")
        snapshot["cleanupVerified"] = True
        snapshot["cleanupUtc"] = datetime.now(timezone.utc).isoformat()
        write_json(evidence, snapshot)
    else:
        raise RuntimeError(f"Unsupported JingJie SQLite action: {args.action}")


if __name__ == "__main__":
    main()
