import argparse
import hashlib
import importlib.util
import json
import os
import shutil
import sqlite3
import struct
import zlib
from datetime import datetime, timezone


_spec = importlib.util.spec_from_file_location(
    "hero_fixture", os.path.join(os.path.dirname(__file__), "Invoke-HeroSqliteFixture.py"))
hero_fixture = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(hero_fixture)

HEROES = ((57, "苏全忠"), (11, "接引道人"), (24, "姬发"), (64, "郑伦"), (60, "吕岳"))
ITEMS = {834: 50, 835: 20, 836: 10, 837: 5, 2450: 20, 2402: 100, 851: 20, 852: 1200, 853: 200}
ROLE_LEVEL = 99


def digest(value):
    return hashlib.sha256(value.encode("utf-8")).hexdigest()


def pet_blob(value):
    ext_num, records = hero_fixture.parse_pets(value)
    existing = {pet_id: record for pet_id, _, record in records}
    output = bytearray((len(HEROES), ext_num))
    for pet_id, name in HEROES:
        output.extend(existing.get(pet_id) or hero_fixture.make_pet(pet_id, name, ext_num))
    return hero_fixture.compress(output)


def package_blob(value):
    records = hero_fixture.parse_package(value)
    for item_id, quantity in ITEMS.items():
        matches = [record for record in records if record[0] == item_id]
        if matches:
            matches[0][1] = quantity
            for duplicate in matches[1:]:
                duplicate[:] = [0, 0]
        else:
            empty = next((record for record in records if record[0] == 0), None)
            if empty is None:
                raise RuntimeError(f"HeroCultivation package has no slot for item {item_id}")
            empty[:] = [item_id, quantity]
    output = bytearray()
    for item_id, quantity in records:
        output.extend(struct.pack("<H", item_id))
        if item_id:
            output.extend(struct.pack("<H", quantity))
    return hero_fixture.compress(output)


def formation_blob(value):
    data, position = hero_fixture.expand(value), 0
    use_index = data[position]
    position += 1
    formation_count = data[position]
    position += 1
    # SZhenFaData persists uint16 zhenfaId + uint8 zhenfaLevel.
    formations = bytes(data[position:position + formation_count * 3])
    position += formation_count * 3
    member_count = data[position]
    position += 1
    members = []
    for _ in range(member_count):
        members.append(list(struct.unpack_from("<BI", data, position)))
        position += 5
    combat_count = data[position]
    position += 1
    combat = list(struct.unpack_from("<" + "H" * combat_count, data, position))
    position += combat_count * 2
    if position != len(data) or member_count < 2 or combat_count < 2:
        raise RuntimeError("HeroCultivation formation cannot host two deployed heroes")
    members[0], members[1] = [2, 57], [2, 11]
    combat[0], combat[1] = 57, 11
    output = bytearray((use_index, formation_count))
    output.extend(formations)
    output.append(member_count)
    for member_type, pet_id in members:
        output.extend(struct.pack("<BI", member_type, pet_id))
    output.append(combat_count)
    output.extend(struct.pack("<" + "H" * combat_count, *combat))
    return hero_fixture.compress(output)


def state(connection, user_id, role_id):
    link = connection.execute("SELECT role0 FROM user_info1 WHERE id=?", (user_id,)).fetchone()
    role = connection.execute(
        "SELECT level,money,pet,package,zhenfa FROM role_info WHERE id=?", (role_id,)).fetchone()
    if link is None or role is None:
        raise RuntimeError(f"HeroCultivation SQLite identity is missing: {user_id}/{role_id}")
    _, pets = hero_fixture.parse_pets(role[2])
    quantities = {item_id: quantity for item_id, quantity in hero_fixture.parse_package(role[3]) if item_id}
    raw_formation = hero_fixture.expand(role[4])
    return {
        "linkedRoleId": int(link[0]),
        "level": int(role[0]),
        "money": int(role[1]),
        "petIds": [pet_id for pet_id, _, _ in pets],
        "items": {str(item_id): quantities.get(item_id, 0) for item_id in ITEMS},
        "formationHas57And11": (struct.pack("<H", 57) in raw_formation
                                and struct.pack("<H", 11) in raw_formation),
        "roleSemanticSha256": digest("|".join(str(value) for value in role)),
        "integrity": connection.execute("PRAGMA integrity_check").fetchone()[0],
    }


def assert_setup(connection, user_id, role_id):
    current = state(connection, user_id, role_id)
    if (current["linkedRoleId"] != role_id or current["level"] < ROLE_LEVEL
            or set(current["petIds"]) != {item[0] for item in HEROES}
            or not current["formationHas57And11"] or current["integrity"] != "ok"
            or any(current["items"][str(item_id)] < quantity for item_id, quantity in ITEMS.items())):
        raise RuntimeError(f"HeroCultivation SQLite fixture assertion failed: {current}")
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
    parser.add_argument("--user-id", type=int, required=True)
    parser.add_argument("--role-id", type=int, required=True)
    args = parser.parse_args()
    database, backup, evidence = map(os.path.abspath, (args.database, args.backup, args.evidence))

    if args.action == "Setup":
        if not os.path.isfile(database):
            raise RuntimeError(f"HeroCultivation SQLite database is missing: {database}")
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
            role = connection.execute(
                "SELECT pet,package,zhenfa,money FROM role_info WHERE id=?", (args.role_id,)).fetchone()
            connection.execute("UPDATE user_info1 SET role0=? WHERE id=?", (args.role_id, args.user_id))
            connection.execute(
                "UPDATE role_info SET level=?,money=?,pet=?,package=?,zhenfa=? WHERE id=?",
                (ROLE_LEVEL, max(int(role[3]), 1_000_000), pet_blob(role[0]), package_blob(role[1]),
                 formation_blob(role[2]), args.role_id))
            connection.commit()
            fixture = assert_setup(connection, args.user_id, args.role_id)
        finally:
            connection.close()
        write_json(evidence, {"schemaVersion": 1, "action": "Setup", "backend": "sqlite",
            "database": database, "backup": backup, "userId": args.user_id, "roleId": args.role_id,
            "snapshotHash": hero_fixture.sha256(backup), "fixtureHash": hero_fixture.sha256(database),
            "before": before, "fixture": fixture, "createdUtc": datetime.now(timezone.utc).isoformat()})
        return

    snapshot = read_json(evidence)
    if (snapshot.get("backend") != "sqlite" or snapshot.get("userId") != args.user_id
            or snapshot.get("roleId") != args.role_id):
        raise RuntimeError("HeroCultivation SQLite fixture evidence identity mismatch")
    if args.action == "AssertSetup":
        connection = sqlite3.connect("file:" + database + "?mode=ro", uri=True)
        try: assert_setup(connection, args.user_id, args.role_id)
        finally: connection.close()
    elif args.action == "CaptureMutationHash":
        connection = sqlite3.connect("file:" + database + "?mode=ro", uri=True)
        try: snapshot["mutation"] = state(connection, args.user_id, args.role_id)
        finally: connection.close()
        snapshot["mutationHash"] = snapshot["mutation"]["roleSemanticSha256"]
        write_json(evidence, snapshot)
    elif args.action == "AssertMutationReloginHash":
        connection = sqlite3.connect("file:" + database + "?mode=ro", uri=True)
        try: current = state(connection, args.user_id, args.role_id)
        finally: connection.close()
        if current["roleSemanticSha256"] != snapshot.get("mutationHash"):
            raise RuntimeError("HeroCultivation mutation did not persist across relogin")
    elif args.action == "Restore":
        if hero_fixture.sha256(backup) != snapshot["snapshotHash"]:
            raise RuntimeError("HeroCultivation immutable SQLite backup hash changed")
        for suffix in ("-wal", "-shm"):
            if os.path.exists(database + suffix): os.remove(database + suffix)
        shutil.copy2(backup, database)
    elif args.action in ("AssertRestored", "AssertReloginHash"):
        if hero_fixture.sha256(database) != snapshot["snapshotHash"]:
            raise RuntimeError("HeroCultivation restored SQLite database hash mismatch")
        connection = sqlite3.connect("file:" + database + "?mode=ro", uri=True)
        try:
            if connection.execute("PRAGMA integrity_check").fetchone()[0] != "ok":
                raise RuntimeError("HeroCultivation restored SQLite integrity failed")
        finally:
            connection.close()
    elif args.action == "Cleanup":
        if os.path.exists(backup): os.remove(backup)
    elif args.action == "AssertCleanup":
        if os.path.exists(backup):
            raise RuntimeError("HeroCultivation SQLite fixture backup remains after cleanup")
    else:
        raise RuntimeError(f"Unsupported HeroCultivation SQLite fixture action: {args.action}")


if __name__ == "__main__":
    main()
