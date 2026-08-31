import argparse
import hashlib
import importlib.util
import json
import os
import shutil
import sqlite3
import struct
from datetime import datetime, timezone


_spec = importlib.util.spec_from_file_location(
    "hero_fixture", os.path.join(os.path.dirname(__file__), "Invoke-HeroSqliteFixture.py"))
hero_fixture = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(hero_fixture)

SOURCE_UID = 2121072641
TARGET_UID = 2121073001
FABAO_UID = 2121073002
VISUAL_EQUIPMENT_UIDS = (SOURCE_UID, 2121072642, 2121072643, 2121072644)
VISUAL_EQUIPMENT_TEMPLATES = (1001, 1002, 1003, 1004)
VISUAL_FABAO_UIDS = (FABAO_UID, 2121073004)
DIVINE_UID = 2121073003
SCROLL_UIDS = tuple(range(2121073010, 2121073019))
RESERVED_EQUIPMENT_UIDS = {SOURCE_UID, TARGET_UID, DIVINE_UID, *SCROLL_UIDS, *VISUAL_EQUIPMENT_UIDS}
RESERVED_FABAO_UIDS = {*VISUAL_FABAO_UIDS}
PACKAGE_ITEMS = {4605: 5, 4621: 62, 4622: 2, 4629: 1, 610: 500, 854: 5}
FORMATION_HEROES = (57, 64)


def sha256(path):
    digest = hashlib.sha256()
    with open(path, "rb") as stream:
        for block in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest()


def write_json(path, payload):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "w", encoding="utf-8", newline="\n") as stream:
        json.dump(payload, stream, ensure_ascii=False, indent=2)
        stream.write("\n")


def read_json(path):
    with open(path, "r", encoding="utf-8") as stream:
        return json.load(stream)


def parse_package(value):
    return hero_fixture.parse_package(value)


def package_blob(value):
    records = parse_package(value)
    by_id = {item_id: index for index, (item_id, _) in enumerate(records) if item_id}
    empty = [index for index, (item_id, _) in enumerate(records) if not item_id]
    for item_id, quantity in PACKAGE_ITEMS.items():
        index = by_id.get(item_id)
        if index is None:
            if not empty:
                raise RuntimeError("HeroEquip SQLite package has no empty fixture slot")
            index = empty.pop(0)
        records[index] = [item_id, quantity]
    output = bytearray()
    for item_id, quantity in records:
        output.extend(struct.pack("<H", item_id))
        if item_id:
            output.extend(struct.pack("<H", quantity))
    return hero_fixture.compress(output)


def formation_blob(value):
    data = hero_fixture.expand(value)
    position = 0
    active = data[position]
    position += 1
    formation_count = data[position]
    position += 1
    formations = bytes(data[position:position + formation_count * 3])
    position += formation_count * 3
    member_count = data[position]
    position += 1 + member_count * 5
    combat_count = data[position]
    position += 1 + combat_count * 2
    if position != len(data) or member_count < 2 or combat_count != member_count:
        raise RuntimeError("HeroEquip SQLite formation layout is invalid")
    output = bytearray((active, formation_count))
    output.extend(formations)
    output.append(member_count)
    for index in range(member_count):
        hero_id = FORMATION_HEROES[index] if index < len(FORMATION_HEROES) else 0
        output.extend(struct.pack("<BI", 2 if hero_id else 0, hero_id))
    output.append(combat_count)
    output.extend(struct.pack("<" + "H" * combat_count,
                              *(list(FORMATION_HEROES) + [0] * (combat_count - 2))))
    return hero_fixture.compress(output)


def parse_equipment_layout(value):
    data = hero_fixture.expand(value)
    position = 0
    equipment_count = struct.unpack_from("<H", data, position)[0]
    position += 2
    equipment = []
    for _ in range(equipment_count):
        start = position
        if position + 16 > len(data):
            raise RuntimeError("HeroEquip SQLite equipment record is truncated")
        uid, template_id, _, _, formation_position, level_count = struct.unpack_from(
            "<IHIIBB", data, position)
        position += 16 + level_count * 3
        equipment.append((uid, template_id, formation_position, bytes(data[start:position])))
    fabao_count = struct.unpack_from("<H", data, position)[0]
    position += 2
    fabao = []
    for _ in range(fabao_count):
        start = position
        if position + 13 > len(data):
            raise RuntimeError("HeroEquip SQLite fabao record is truncated")
        uid, template_id = struct.unpack_from("<IH", data, position)
        level_count = data[position + 12]
        position += 13 + level_count * 2
        fabao.append((uid, template_id, bytes(data[start:position])))
    if len(data) - position != 6:
        raise RuntimeError("HeroEquip SQLite pet_equip tail is not uint32+uint16")
    return equipment, fabao, bytes(data[position:])


def fixture_equipment_blob(value):
    equipment, fabao, tail = parse_equipment_layout(value)
    equipment = [record for record in equipment if record[0] not in RESERVED_EQUIPMENT_UIDS]
    fabao = [record for record in fabao if record[0] not in RESERVED_FABAO_UIDS]
    fixture_equipment = [
        (SOURCE_UID, 1001, 1),
        (TARGET_UID, 1301, 0),
        (DIVINE_UID, 1401, 0),
        *[(uid, 1001, 0) for uid in SCROLL_UIDS],
    ]
    output = bytearray(struct.pack("<H", len(equipment) + len(fixture_equipment)))
    for _, _, _, raw in equipment:
        output.extend(raw)
    for uid, template_id, formation_position in fixture_equipment:
        output.extend(struct.pack("<IHIIBB", uid, template_id, 0, 0, formation_position, 0))
    output.extend(struct.pack("<H", len(fabao) + 1))
    for _, _, raw in fabao:
        output.extend(raw)
    output.extend(struct.pack("<IHI BBB", FABAO_UID, 1101, 0, 0, 0, 0))
    output.extend(tail)
    return hero_fixture.compress(output)


def visual_package_blob(value):
    records = parse_package(value)
    quantities = {item_id: 999 for item_id in PACKAGE_ITEMS}
    by_id = {item_id: index for index, (item_id, _) in enumerate(records) if item_id}
    empty = [index for index, (item_id, _) in enumerate(records) if not item_id]
    for item_id, quantity in quantities.items():
        index = by_id.get(item_id)
        if index is None:
            if not empty:
                raise RuntimeError("HeroEquip G5 visual package has no empty fixture slot")
            index = empty.pop(0)
        records[index] = [item_id, quantity]
    output = bytearray()
    for item_id, quantity in records:
        output.extend(struct.pack("<H", item_id))
        if item_id:
            output.extend(struct.pack("<H", quantity))
    return hero_fixture.compress(output)


def visual_equipment_blob(value):
    _, _, tail = parse_equipment_layout(value)
    equipment = [
        (VISUAL_EQUIPMENT_UIDS[0], VISUAL_EQUIPMENT_TEMPLATES[0], 1, ((1, 15),)),
        (VISUAL_EQUIPMENT_UIDS[1], VISUAL_EQUIPMENT_TEMPLATES[1], 1, ()),
        (VISUAL_EQUIPMENT_UIDS[2], VISUAL_EQUIPMENT_TEMPLATES[2], 1, ()),
        (VISUAL_EQUIPMENT_UIDS[3], VISUAL_EQUIPMENT_TEMPLATES[3], 1, ()),
    ]
    output = bytearray(struct.pack("<H", len(equipment)))
    for uid, template_id, formation_position, levels in equipment:
        output.extend(struct.pack("<IHIIBB", uid, template_id, 0, 0, formation_position, len(levels)))
        for level_type, level in levels:
            output.extend(struct.pack("<BH", level_type, level))
    output.extend(struct.pack("<H", len(VISUAL_FABAO_UIDS)))
    output.extend(struct.pack("<IHI BBB", VISUAL_FABAO_UIDS[0], 1001, 0, 1, 1, 0))
    output.extend(struct.pack("<IHI BBB", VISUAL_FABAO_UIDS[1], 1002, 0, 1, 2, 0))
    output.extend(tail)
    return hero_fixture.compress(output)


def role_state(connection, user_id, role_id):
    link = connection.execute("SELECT role0 FROM user_info1 WHERE id=?", (user_id,)).fetchone()
    row = connection.execute(
        "SELECT level,money,pet,package,zhenfa,pet_equip,zhanDouLi,mission,save_data,clientstring "
        "FROM role_info WHERE id=?", (role_id,)).fetchone()
    if link is None or int(link[0]) != role_id or row is None:
        raise RuntimeError(f"HeroEquip SQLite identity mismatch: {user_id}/{role_id}")
    _, pets = hero_fixture.parse_pets(row[2])
    quantities = {item_id: quantity for item_id, quantity in parse_package(row[3]) if item_id}
    _, _, combat = hero_fixture.parse_formation(row[4])
    equipment, fabao, _ = parse_equipment_layout(row[5])
    fields = [str(row[0]), str(row[1]), row[2], row[3], row[4], row[5], str(row[6]), row[8], row[9]]
    stable_hash = hashlib.sha256("\x1f".join(fields).encode("utf-8")).hexdigest()
    return {
        "level": int(row[0]), "money": int(row[1]),
        "petIds": [pet_id for pet_id, _, _ in pets], "combatHeroes": combat,
        "package": {str(item_id): quantities.get(item_id, 0) for item_id in PACKAGE_ITEMS},
        "equipment": [[uid, template_id, position] for uid, template_id, position, _ in equipment
                      if uid in RESERVED_EQUIPMENT_UIDS],
        "fabao": [[uid, template_id] for uid, template_id, _ in fabao if uid in RESERVED_FABAO_UIDS],
        "stableHash": stable_hash,
        "integrity": connection.execute("PRAGMA integrity_check").fetchone()[0],
    }


def assert_setup(connection, user_id, role_id):
    state = role_state(connection, user_id, role_id)
    expected_equipment = [[SOURCE_UID, 1001, 1], [TARGET_UID, 1301, 0], [DIVINE_UID, 1401, 0]] + [
        [uid, 1001, 0] for uid in SCROLL_UIDS]
    if (state["level"] != 70 or state["money"] < 5_000_000
            or not set(FORMATION_HEROES).issubset(state["petIds"])
            or state["combatHeroes"][:2] != list(FORMATION_HEROES)
            or state["equipment"] != expected_equipment
            or state["fabao"] != [[FABAO_UID, 1101]]
            or any(state["package"][str(item_id)] != quantity for item_id, quantity in PACKAGE_ITEMS.items())
            or state["integrity"] != "ok"):
        raise RuntimeError(f"HeroEquip SQLite fixture assertion failed: {state}")
    return state


def assert_visual_setup(connection, user_id, role_id):
    state = role_state(connection, user_id, role_id)
    expected_equipment = [
        [uid, template_id, 1]
        for uid, template_id in zip(VISUAL_EQUIPMENT_UIDS, VISUAL_EQUIPMENT_TEMPLATES)
    ]
    expected_fabao = [[VISUAL_FABAO_UIDS[0], 1001], [VISUAL_FABAO_UIDS[1], 1002]]
    if (state["level"] != 99 or state["money"] != 1_000_000
            or not set(FORMATION_HEROES).issubset(state["petIds"])
            or state["combatHeroes"][:2] != list(FORMATION_HEROES)
            or state["equipment"] != expected_equipment
            or state["fabao"] != expected_fabao
            or any(state["package"][str(item_id)] != 999 for item_id in PACKAGE_ITEMS)
            or state["integrity"] != "ok"):
        raise RuntimeError(f"HeroEquip G5 visual fixture assertion failed: {state}")
    return state


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

    if args.action in ("Setup", "SetupG5Visual"):
        connection = sqlite3.connect(database)
        try:
            connection.execute("PRAGMA wal_checkpoint(TRUNCATE)")
            before = role_state(connection, args.user_id, args.role_id)
        finally:
            connection.close()
        os.makedirs(os.path.dirname(backup), exist_ok=True)
        shutil.copy2(database, backup)
        connection = sqlite3.connect(database)
        try:
            row = connection.execute(
                "SELECT package,zhenfa,pet_equip,money FROM role_info WHERE id=?", (args.role_id,)).fetchone()
            visual = args.action == "SetupG5Visual"
            connection.execute(
                "UPDATE role_info SET level=?,money=?,package=?,zhenfa=?,pet_equip=? WHERE id=?",
                (99 if visual else 70,
                 1_000_000 if visual else max(int(row[3]), 5_000_000),
                 visual_package_blob(row[0]) if visual else package_blob(row[0]),
                 formation_blob(row[1]),
                 visual_equipment_blob(row[2]) if visual else fixture_equipment_blob(row[2]),
                 args.role_id))
            connection.commit()
            fixture = (assert_visual_setup if visual else assert_setup)(connection, args.user_id, args.role_id)
        finally:
            connection.close()
        write_json(evidence, {
            "schemaVersion": 1, "action": args.action, "backend": "sqlite",
            "database": database, "backup": backup, "userId": args.user_id, "roleId": args.role_id,
            "snapshotHash": sha256(backup), "fixtureHash": sha256(database),
            "fixtureStableHash": fixture["stableHash"], "before": before, "fixture": fixture,
            "createdUtc": datetime.now(timezone.utc).isoformat(),
        })
        return

    snapshot = read_json(evidence)
    if snapshot.get("userId") != args.user_id or snapshot.get("roleId") != args.role_id:
        raise RuntimeError("HeroEquip SQLite evidence identity mismatch")
    if args.action == "AssertSetup":
        connection = sqlite3.connect("file:" + database + "?mode=ro", uri=True)
        try:
            assert_setup(connection, args.user_id, args.role_id)
        finally:
            connection.close()
    elif args.action == "AssertG5Visual":
        connection = sqlite3.connect("file:" + database + "?mode=ro", uri=True)
        try:
            assert_visual_setup(connection, args.user_id, args.role_id)
        finally:
            connection.close()
    elif args.action == "CaptureMutationHash":
        connection = sqlite3.connect("file:" + database + "?mode=ro", uri=True)
        try:
            state = role_state(connection, args.user_id, args.role_id)
        finally:
            connection.close()
        if state["stableHash"] == snapshot["fixtureStableHash"]:
            raise RuntimeError("HeroEquip SQLite transaction did not change the authoritative role state")
        snapshot["mutationStableHash"] = state["stableHash"]
        snapshot["mutationCapturedUtc"] = datetime.now(timezone.utc).isoformat()
        write_json(evidence, snapshot)
    elif args.action == "AssertMutationReloginHash":
        connection = sqlite3.connect("file:" + database + "?mode=ro", uri=True)
        try:
            state = role_state(connection, args.user_id, args.role_id)
        finally:
            connection.close()
        if state["stableHash"] != snapshot.get("mutationStableHash"):
            raise RuntimeError("HeroEquip SQLite post-transaction relogin stable hash mismatch")
        snapshot["mutationReloginAssertedUtc"] = datetime.now(timezone.utc).isoformat()
        write_json(evidence, snapshot)
    elif args.action == "Restore":
        if sha256(backup) != snapshot["snapshotHash"]:
            raise RuntimeError("HeroEquip SQLite immutable backup hash changed")
        for suffix in ("-wal", "-shm"):
            sidecar = database + suffix
            if os.path.exists(sidecar):
                os.remove(sidecar)
        shutil.copy2(backup, database)
    elif args.action in ("AssertRestored", "AssertReloginHash"):
        if sha256(database) != snapshot["snapshotHash"]:
            raise RuntimeError("HeroEquip SQLite restored database hash mismatch")
        connection = sqlite3.connect("file:" + database + "?mode=ro", uri=True)
        try:
            if connection.execute("PRAGMA integrity_check").fetchone()[0] != "ok":
                raise RuntimeError("HeroEquip SQLite restored database integrity failed")
        finally:
            connection.close()
    elif args.action == "Cleanup":
        if os.path.exists(backup):
            os.remove(backup)
    elif args.action == "AssertCleanup":
        if os.path.exists(backup):
            raise RuntimeError("HeroEquip SQLite fixture backup remains after cleanup")
    else:
        raise RuntimeError(f"Unsupported HeroEquip SQLite action: {args.action}")


if __name__ == "__main__":
    main()
