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

HEROES = (
    (57, "苏全忠"), (11, "接引道人"), (24, "姬发"), (64, "郑伦"), (60, "吕岳"),
    (10, "女娲娘娘"), (12, "准提道人"), (13, "孔宣"), (14, "多宝道人"),
    (15, "金灵圣母"), (16, "哪吒"), (17, "杨戬"), (18, "雷震子"), (19, "姜子牙"),
    (20, "申公豹"), (21, "闻仲"), (22, "李靖"), (23, "黄飞虎"), (25, "袁洪"),
    (26, "黄天化"),
)
ITEMS = {
    834: 50, 835: 20, 836: 10, 837: 5, 851: 20, 852: 1200, 853: 200,
    2401: 150, 2402: 100, 2403: 160, 2404: 80, 2405: 40,
    2406: 150, 2407: 75, 2408: 30, 2409: 120, 2410: 60, 2450: 20,
    610: 300, 611: 300, 612: 300, 613: 300, 614: 999,
    615: 100, 616: 100, 617: 100, 854: 300,
}
ROLE_LEVEL = 99
EQUIPMENT_SETS = (
    (2121092000, 1401, 1, ((1, 9), (2, 1))), (2121092001, 1402, 1, ((1, 10), (2, 1))),
    (2121092002, 1403, 1, ((1, 11), (2, 1))), (2121092003, 1404, 1, ((1, 12), (2, 1))),
    (2121092004, 1411, 2, ((1, 20), (2, 3), (3, 1), (4, 1))),
    (2121092005, 1412, 2, ((1, 21), (2, 3), (3, 1), (4, 1))),
    (2121092006, 1413, 2, ((1, 22), (2, 3), (3, 1), (4, 1))),
    (2121092007, 1414, 2, ((1, 23), (2, 3), (3, 1), (4, 1))),
    (2121092008, 1401, 3, ((1, 14), (2, 2))), (2121092009, 1402, 3, ((1, 15), (2, 2))),
    (2121092010, 1403, 3, ((1, 16), (2, 2))), (2121092011, 1404, 3, ((1, 17), (2, 2))),
    (2121092012, 1411, 4, ((1, 24), (2, 4), (3, 1), (4, 1))),
    (2121092013, 1412, 4, ((1, 25), (2, 4), (3, 1), (4, 1))),
    (2121092014, 1413, 4, ((1, 26), (2, 4), (3, 1), (4, 1))),
    (2121092015, 1414, 4, ((1, 27), (2, 4), (3, 1), (4, 1))),
    (2121092016, 1401, 5, ((1, 29), (2, 5), (3, 2), (4, 1))),
    (2121092017, 1402, 5, ((1, 30), (2, 5), (3, 2), (4, 1))),
    (2121092018, 1403, 5, ((1, 31), (2, 5), (3, 2), (4, 1))),
    (2121092019, 1404, 5, ((1, 32), (2, 5), (3, 2), (4, 1))),
)
FABAO_TARGETS = (
    (2121093000, 1201, 1, 5, ((5, 4), (6, 1))),
    (2121093001, 1202, 1, 6, ((5, 5), (6, 1))),
    (2121093002, 1301, 2, 5, ((5, 8), (6, 2))),
    (2121093003, 1302, 2, 6, ((5, 9), (6, 2))),
    (2121093004, 1303, 3, 5, ((5, 6), (6, 1))),
    (2121093005, 1304, 3, 6, ((5, 7), (6, 1))),
    (2121093006, 1305, 4, 5, ((5, 10), (6, 2))),
    (2121093007, 1306, 4, 6, ((5, 11), (6, 2))),
    (2121093008, 1307, 5, 5, ((5, 12), (6, 3))),
    (2121093009, 1308, 5, 6, ((5, 13), (6, 3))),
)
FABAO_MATERIALS = tuple((2121093100 + index, 1001 + index, 0, 0, ()) for index in range(12))


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
    records = parse_package_tolerant(value)
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


def parse_package_tolerant(value):
    """Accept the local server's trimmed trailing empty package slots, then pad to 500."""
    data = hero_fixture.expand(value)
    position, records = 0, []
    while position < len(data) and len(records) < 500:
        if position + 2 > len(data):
            raise RuntimeError("HeroCultivation package item id is truncated")
        item_id = struct.unpack_from("<H", data, position)[0]
        position += 2
        quantity = 0
        if item_id:
            if position + 2 > len(data):
                raise RuntimeError(f"HeroCultivation package item {item_id} is truncated")
            quantity = struct.unpack_from("<H", data, position)[0]
            position += 2
        records.append([item_id, quantity])
    if position != len(data):
        raise RuntimeError("HeroCultivation package payload has trailing bytes")
    records.extend([[0, 0] for _ in range(500 - len(records))])
    return records


def equipment_layout(value):
    data, position = hero_fixture.expand(value), 0
    if len(data) < 2:
        raise RuntimeError("HeroCultivation pet_equip payload is truncated")
    equipment_count = struct.unpack_from("<H", data, position)[0]
    position += 2
    equipment = []
    for _ in range(equipment_count):
        if position + 16 > len(data):
            raise RuntimeError("HeroCultivation equipment record is truncated")
        uid, template_id, _, _, formation_position, level_count = struct.unpack_from(
            "<IHIIBB", data, position)
        position += 16
        if position + level_count * 3 > len(data):
            raise RuntimeError("HeroCultivation equipment level data is truncated")
        position += level_count * 3
        equipment.append({"uid": uid, "templateId": template_id,
                          "formationPosition": formation_position})
    equipment_end = position
    if position + 2 > len(data):
        raise RuntimeError("HeroCultivation FaBao count is missing")
    fabao_count = struct.unpack_from("<H", data, position)[0]
    position += 2
    for _ in range(fabao_count):
        if position + 13 > len(data):
            raise RuntimeError("HeroCultivation FaBao record is truncated")
        level_count = data[position + 12]
        position += 13
        if position + level_count * 2 > len(data):
            raise RuntimeError("HeroCultivation FaBao level data is truncated")
        position += level_count * 2
    tail = bytes(data[position:])
    if len(tail) < 6:
        raise RuntimeError("HeroCultivation pet_equip tail is shorter than uint32+uint16")
    extension = tail[6:]
    if extension:
        if len(extension) < 7 or extension[:4] != b"PXA1":
            raise RuntimeError("HeroCultivation pet_equip tail has an unknown extension")
        version = extension[4]
        affix_count = struct.unpack_from("<H", extension, 5)[0]
        expected_length = 7 + affix_count * 12
        if version != 1 or len(extension) != expected_length:
            raise RuntimeError("HeroCultivation PXA1 extension is malformed")
    return data, equipment_end, equipment


def equipment_blob(value):
    data, equipment_end, equipment = equipment_layout(value)
    reserved = {uid: (template_id, formation_position)
                for uid, template_id, formation_position, _ in EQUIPMENT_SETS}
    present = {item["uid"]: item for item in equipment if item["uid"] in reserved}
    if present:
        if len(present) != len(reserved) or any(
                (item["templateId"], item["formationPosition"]) != reserved[uid]
                for uid, item in present.items()):
            raise RuntimeError("HeroCultivation reserved equipment UID set is partially occupied")
        output = bytearray(data[:equipment_end])
        output.extend(inject_fabao_segment(data[equipment_end:]))
        return hero_fixture.compress(output)
    output = bytearray(struct.pack("<H", len(equipment) + len(EQUIPMENT_SETS)))
    output.extend(data[2:equipment_end])
    for uid, template_id, formation_position, levels in EQUIPMENT_SETS:
        output.extend(struct.pack("<IHIIBB", uid, template_id, 0, 0, formation_position, len(levels)))
        for level_type, level in levels:
            output.extend(struct.pack("<BH", level_type, level))
    output.extend(inject_fabao_segment(data[equipment_end:]))
    return hero_fixture.compress(output)


def inject_fabao_segment(segment):
    data = bytearray(segment)
    count = struct.unpack_from("<H", data, 0)[0]
    position = 2
    existing = {}
    for _ in range(count):
        start = position
        uid, template_id, _, formation_position, slot, level_count = struct.unpack_from("<IHIBBB", data, position)
        position += 13 + level_count * 2
        existing[uid] = (template_id, formation_position, slot, bytes(data[start:position]))
    desired = FABAO_TARGETS + FABAO_MATERIALS
    reserved = {entry[0]: entry[1:4] for entry in desired}
    present = {uid: value for uid, value in existing.items() if uid in reserved}
    if present:
        if len(present) != len(reserved) or any(value[:3] != reserved[uid] for uid, value in present.items()):
            raise RuntimeError("HeroCultivation reserved FaBao UID set is partially occupied")
        return data
    output = bytearray(struct.pack("<H", count + len(desired)))
    output.extend(data[2:position])
    for uid, template_id, formation_position, slot, levels in desired:
        output.extend(struct.pack("<IHIBBB", uid, template_id, 0, formation_position, slot, len(levels)))
        for level_type, level in levels:
            output.extend(struct.pack("<BB", level_type, level))
    output.extend(data[position:])
    return output


def fabao_records(value):
    data, equipment_end, _ = equipment_layout(value)
    count = struct.unpack_from("<H", data, equipment_end)[0]
    position = equipment_end + 2
    result = []
    for _ in range(count):
        uid, template_id, experience, formation_position, slot, level_count = struct.unpack_from(
            "<IHIBBB", data, position)
        position += 13
        levels = []
        for _ in range(level_count):
            levels.append(struct.unpack_from("<BB", data, position))
            position += 2
        result.append({"uid": uid, "templateId": template_id,
                       "formationPosition": formation_position, "slot": slot,
                       "experience": experience, "levels": levels})
    return result


def state(connection, user_id, role_id):
    link = connection.execute("SELECT role0 FROM user_info1 WHERE id=?", (user_id,)).fetchone()
    role = connection.execute(
        "SELECT level,money,pet,package,zhenfa,pet_equip FROM role_info WHERE id=?", (role_id,)).fetchone()
    if link is None or role is None:
        raise RuntimeError(f"HeroCultivation SQLite identity is missing: {user_id}/{role_id}")
    _, pets = hero_fixture.parse_pets(role[2])
    quantities = {item_id: quantity for item_id, quantity in parse_package_tolerant(role[3]) if item_id}
    raw_formation = hero_fixture.expand(role[4])
    _, _, equipment = equipment_layout(role[5])
    fixture_equipment = [item for item in equipment
                         if item["uid"] in {entry[0] for entry in EQUIPMENT_SETS}]
    expected_fabao_uids = {entry[0] for entry in FABAO_TARGETS + FABAO_MATERIALS}
    fixture_fabao = [item for item in fabao_records(role[5]) if item["uid"] in expected_fabao_uids]
    return {
        "linkedRoleId": int(link[0]),
        "level": int(role[0]),
        "money": int(role[1]),
        "petIds": [pet_id for pet_id, _, _ in pets],
        "items": {str(item_id): quantities.get(item_id, 0) for item_id in ITEMS},
        "formationHas57And11": (struct.pack("<H", 57) in raw_formation
                                and struct.pack("<H", 11) in raw_formation),
        "equipmentSets": fixture_equipment,
        "faBaoTargetsAndMaterials": fixture_fabao,
        "roleSemanticSha256": digest("|".join(str(value) for value in role)),
        "integrity": connection.execute("PRAGMA integrity_check").fetchone()[0],
    }


def assert_setup(connection, user_id, role_id):
    current = state(connection, user_id, role_id)
    if (current["linkedRoleId"] != role_id or current["level"] < ROLE_LEVEL
            or set(current["petIds"]) != {item[0] for item in HEROES}
            or not current["formationHas57And11"] or current["integrity"] != "ok"
            or {(item["uid"], item["templateId"], item["formationPosition"])
                for item in current["equipmentSets"]} != {
                    (uid, template_id, formation_position)
                    for uid, template_id, formation_position, _ in EQUIPMENT_SETS}
            or {(item["uid"], item["templateId"], item["formationPosition"], item["slot"])
                for item in current["faBaoTargetsAndMaterials"]} != {
                    (uid, template_id, formation_position, slot)
                    for uid, template_id, formation_position, slot, _ in FABAO_TARGETS + FABAO_MATERIALS}
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
                "SELECT pet,package,zhenfa,money,pet_equip FROM role_info WHERE id=?", (args.role_id,)).fetchone()
            connection.execute("UPDATE user_info1 SET role0=? WHERE id=?", (args.role_id, args.user_id))
            connection.execute(
                "UPDATE role_info SET level=?,money=?,pet=?,package=?,zhenfa=?,pet_equip=? WHERE id=?",
                (ROLE_LEVEL, max(int(role[3]), 1_000_000), pet_blob(role[0]), package_blob(role[1]),
                 formation_blob(role[2]), equipment_blob(role[4]), args.role_id))
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
    elif args.action == "AddEquipmentSets":
        connection = sqlite3.connect(database)
        try:
            connection.execute("PRAGMA wal_checkpoint(TRUNCATE)")
            row = connection.execute(
                "SELECT pet_equip FROM role_info WHERE id=?", (args.role_id,)).fetchone()
            if row is None:
                raise RuntimeError(f"HeroCultivation role is missing: {args.role_id}")
            connection.execute("UPDATE role_info SET pet_equip=? WHERE id=?",
                               (equipment_blob(row[0]), args.role_id))
            connection.commit()
            fixture = assert_setup(connection, args.user_id, args.role_id)
        finally:
            connection.close()
        snapshot["fixture"] = fixture
        snapshot["fixtureHash"] = hero_fixture.sha256(database)
        snapshot["equipmentSetsAddedUtc"] = datetime.now(timezone.utc).isoformat()
        write_json(evidence, snapshot)
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
