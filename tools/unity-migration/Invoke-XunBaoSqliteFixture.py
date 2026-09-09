import argparse
import hashlib
import importlib.util
import json
import os
import shutil
import sqlite3
import struct
import time
from datetime import datetime, timezone


_hero_spec = importlib.util.spec_from_file_location(
    "hero_fixture", os.path.join(os.path.dirname(__file__), "Invoke-HeroSqliteFixture.py"))
hero_fixture = importlib.util.module_from_spec(_hero_spec)
_hero_spec.loader.exec_module(hero_fixture)

_equip_spec = importlib.util.spec_from_file_location(
    "hero_equip_fixture", os.path.join(os.path.dirname(__file__), "Invoke-HeroEquipSqliteFixture.py"))
hero_equip_fixture = importlib.util.module_from_spec(_equip_spec)
_equip_spec.loader.exec_module(hero_equip_fixture)

SEARCH_COUNT = 20
TOKEN_QUANTITY = 2
TUTORIAL_BIT = 629
FORMAL_HECHENG_JSON = os.path.abspath(os.path.join(
    os.path.dirname(__file__), "..", "..", "server", "config", "json", "hecheng.json"))
FORMAL_DAILY_JSON = os.path.abspath(os.path.join(
    os.path.dirname(__file__), "..", "..", "server", "config", "json", "daily.json"))
SAVE_VAL_COUNT = 12
DAILY_MARKER_INDEX = SAVE_VAL_COUNT - 2


def load_formal_fragment_quantities():
    with open(FORMAL_HECHENG_JSON, "r", encoding="utf-8") as stream:
        definitions = json.load(stream)
    quantities = {4701: 0, 4702: 0, 4703: 0}
    expected_targets = set(range(1002, 1015))
    found_targets = set()
    for definition in definitions:
        target = definition.get("target") or []
        if definition.get("type") != 8 or len(target) < 2 or target[1] not in expected_targets:
            continue
        found_targets.add(target[1])
        for cost in definition.get("item") or []:
            if len(cost) >= 3:
                quantities[int(cost[0])] = int(cost[2])
    if found_targets != expected_targets:
        raise RuntimeError(
            f"Formal XunBao compose definitions missing: {sorted(expected_targets - found_targets)}")
    return quantities


FRAGMENT_QUANTITIES = load_formal_fragment_quantities()


def load_formal_xunbao_tasks():
    with open(FORMAL_DAILY_JSON, "r", encoding="utf-8") as stream:
        definitions = json.load(stream)
    tasks = [entry for entry in definitions if int(entry.get("type", -1)) == 3]
    if len(tasks) != 119 or [int(entry["id"]) for entry in tasks] != list(range(25, 144)):
        raise RuntimeError("Formal daily.json XunBao task range must remain ids 25..143")
    return tasks


FORMAL_XUNBAO_TASKS = load_formal_xunbao_tasks()


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


def clear_tutorial_bit(value):
    data = hero_fixture.expand(value)
    if len(data) != 1024:
        raise RuntimeError(f"XunBao bitset must be 1024 bytes, got {len(data)}")
    data[TUTORIAL_BIT // 8] &= ~(1 << (TUTORIAL_BIT % 8))
    return hero_fixture.compress(data)


def package_blob(value):
    records = hero_fixture.parse_package(value)
    desired = {402: TOKEN_QUANTITY, **FRAGMENT_QUANTITIES}
    by_id = {item_id: index for index, (item_id, _) in enumerate(records) if item_id}
    empty = [index for index, (item_id, _) in enumerate(records) if not item_id]
    for item_id, quantity in desired.items():
        index = by_id.get(item_id)
        if quantity == 0:
            if index is not None:
                records[index] = [0, 0]
                empty.append(index)
            continue
        if index is None:
            if not empty:
                raise RuntimeError("XunBao SQLite package has no empty fixture slot")
            index = empty.pop(0)
        records[index] = [item_id, quantity]
    output = bytearray()
    for item_id, quantity in records:
        output.extend(struct.pack("<H", item_id))
        if item_id:
            output.extend(struct.pack("<H", quantity))
    return hero_fixture.compress(output)


def equipment_blob(value):
    equipment, fabao, tail = hero_equip_fixture.parse_equipment_layout(value)
    tail = bytearray(tail)
    if len(tail) < 6:
        raise RuntimeError("XunBao pet_equip tail is shorter than uint32+uint16")
    struct.pack_into("<IH", tail, 0, int(time.time()), SEARCH_COUNT)
    output = bytearray(struct.pack("<H", len(equipment)))
    for _, _, _, raw in equipment:
        output.extend(raw)
    output.extend(struct.pack("<H", len(fabao)))
    for _, _, raw in fabao:
        output.extend(raw)
    output.extend(tail)
    return hero_fixture.compress(output)


def parse_mission(value):
    data = hero_fixture.expand(value)
    position = 0

    def take(fmt):
        nonlocal position
        size = struct.calcsize(fmt)
        if position + size > len(data):
            raise RuntimeError("XunBao mission payload is truncated")
        result = struct.unpack_from(fmt, data, position)
        position += size
        return result

    def take_records(count):
        return [list(take("<HIB")) for _ in range(count)]

    group_count, = take("<H")
    groups = []
    for _ in range(group_count):
        task_type, task_count = take("<BH")
        groups.append([task_type, take_records(task_count)])
    hd_count, = take("<H")
    hd_tasks = take_records(hd_count)
    fund_group_count, = take("<B")
    fund_groups = []
    for _ in range(fund_group_count):
        task_type, task_count = take("<BH")
        fund_groups.append([task_type, take_records(task_count)])
    buy_count, = take("<B")
    buys = [list(take("<BI")) for _ in range(buy_count)]
    if position != len(data):
        raise RuntimeError(f"XunBao mission payload has {len(data) - position} trailing bytes")
    return groups, hd_tasks, fund_groups, buys


def mission_blob(value):
    groups, hd_tasks, fund_groups, buys = parse_mission(value)
    task_records = [[int(entry["id"]), 0, 0] for entry in FORMAL_XUNBAO_TASKS]
    task_records[0] = [25, 2, 1]
    replaced = False
    for group in groups:
        if group[0] == 3:
            group[1] = task_records
            replaced = True
            break
    if not replaced:
        groups.append([3, task_records])

    output = bytearray(struct.pack("<H", len(groups)))
    for task_type, records in groups:
        output.extend(struct.pack("<BH", task_type, len(records)))
        for task_id, progress, state in records:
            output.extend(struct.pack("<HIB", task_id, progress, state))
    output.extend(struct.pack("<H", len(hd_tasks)))
    for task_id, progress, state in hd_tasks:
        output.extend(struct.pack("<HIB", task_id, progress, state))
    output.extend(struct.pack("<B", len(fund_groups)))
    for task_type, records in fund_groups:
        output.extend(struct.pack("<BH", task_type, len(records)))
        for task_id, progress, state in records:
            output.extend(struct.pack("<HIB", task_id, progress, state))
    output.extend(struct.pack("<B", len(buys)))
    for task_type, buy_time in buys:
        output.extend(struct.pack("<BI", task_type, buy_time))
    return hero_fixture.compress(output)


def save_val_blob(value):
    parts = str(value or "").split("|")
    values = []
    for index in range(SAVE_VAL_COUNT):
        try:
            values.append(int(parts[index]))
        except (IndexError, TypeError, ValueError):
            values.append(0)
    # C++ GetSysYDay uses tm_yday (0..365). Match the current authoritative
    # server day so login does not immediately ResetQuest and erase task 25.
    values[DAILY_MARKER_INDEX] = time.localtime().tm_yday - 1
    return "|".join(str(entry) for entry in values)


def role_state(connection, user_id, role_id):
    link = connection.execute("SELECT role0 FROM user_info1 WHERE id=?", (user_id,)).fetchone()
    row = connection.execute(
        "SELECT bitset,package,pet_equip,mission,save_val FROM role_info WHERE id=?", (role_id,)).fetchone()
    if link is None or int(link[0]) != role_id or row is None:
        raise RuntimeError(f"XunBao SQLite identity mismatch: {user_id}/{role_id}")
    bitset = hero_fixture.expand(row[0])
    package = {item_id: quantity for item_id, quantity in hero_fixture.parse_package(row[1]) if item_id}
    _, _, tail = hero_equip_fixture.parse_equipment_layout(row[2])
    mission_groups, _, _, _ = parse_mission(row[3])
    save_values = str(row[4] or "").split("|")
    daily_marker = int(save_values[DAILY_MARKER_INDEX]) if len(save_values) > DAILY_MARKER_INDEX else -1
    xunbao_tasks = next((records for task_type, records in mission_groups if task_type == 3), [])
    task25 = next((record for record in xunbao_tasks if record[0] == 25), [25, 0, 0])
    last_count_time, search_count = struct.unpack_from("<IH", tail, 0)
    relevant = {str(item_id): package.get(item_id, 0) for item_id in (402, *FRAGMENT_QUANTITIES)}
    stable = {
        "tutorialBit629": bool(bitset[TUTORIAL_BIT // 8] & (1 << (TUTORIAL_BIT % 8))),
        "searchCount": search_count,
        "lastCountTime": last_count_time,
        "package": relevant,
        "missionType3Count": len(xunbao_tasks),
        "missionTask25": {"progress": task25[1], "state": task25[2]},
        "dailyMarker": daily_marker,
    }
    stable_hash = hashlib.sha256(
        json.dumps(stable, sort_keys=True, separators=(",", ":")).encode("utf-8")).hexdigest()
    return {
        **stable,
        "stableHash": stable_hash,
        "integrity": connection.execute("PRAGMA integrity_check").fetchone()[0],
    }


def assert_setup(connection, user_id, role_id):
    state = role_state(connection, user_id, role_id)
    expected = {"402": TOKEN_QUANTITY, **{str(key): value for key, value in FRAGMENT_QUANTITIES.items()}}
    if (state["tutorialBit629"] or state["searchCount"] != SEARCH_COUNT
            or state["package"] != expected or state["lastCountTime"] <= 0
            or state["missionType3Count"] != 119
            or state["missionTask25"] != {"progress": 2, "state": 1}
            or state["dailyMarker"] != time.localtime().tm_yday - 1
            or state["integrity"] != "ok"):
        raise RuntimeError(f"XunBao SQLite fixture assertion failed: {state}")
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

    if args.action == "Setup":
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
                "SELECT bitset,package,pet_equip,mission,save_val FROM role_info WHERE id=?", (args.role_id,)).fetchone()
            if row is None:
                raise RuntimeError(f"XunBao SQLite role {args.role_id} is missing")
            connection.execute(
                "UPDATE role_info SET bitset=?,package=?,pet_equip=?,mission=?,save_val=? WHERE id=?",
                (clear_tutorial_bit(row[0]), package_blob(row[1]), equipment_blob(row[2]),
                 mission_blob(row[3]), save_val_blob(row[4]), args.role_id))
            connection.commit()
            fixture = assert_setup(connection, args.user_id, args.role_id)
        finally:
            connection.close()
        write_json(evidence, {
            "schemaVersion": 1,
            "action": args.action,
            "backend": "sqlite",
            "database": database,
            "backup": backup,
            "userId": args.user_id,
            "roleId": args.role_id,
            "snapshotHash": sha256(backup),
            "fixtureHash": sha256(database),
            "fixtureStableHash": fixture["stableHash"],
            "formalHeChengJson": FORMAL_HECHENG_JSON,
            "formalDailyJson": FORMAL_DAILY_JSON,
            "formalComposeTargets": list(range(1002, 1015)),
            "dailyMarkerIndex": DAILY_MARKER_INDEX,
            "before": before,
            "fixture": fixture,
            "createdUtc": datetime.now(timezone.utc).isoformat(),
        })
        return

    snapshot = read_json(evidence)
    if snapshot.get("userId") != args.user_id or snapshot.get("roleId") != args.role_id:
        raise RuntimeError("XunBao SQLite evidence identity mismatch")
    if args.action == "AssertSetup":
        connection = sqlite3.connect("file:" + database + "?mode=ro", uri=True)
        try:
            assert_setup(connection, args.user_id, args.role_id)
        finally:
            connection.close()
    elif args.action == "AssertMutated":
        connection = sqlite3.connect("file:" + database + "?mode=ro", uri=True)
        try:
            state = role_state(connection, args.user_id, args.role_id)
        finally:
            connection.close()
        if state["stableHash"] == snapshot["fixtureStableHash"]:
            raise RuntimeError("XunBao runtime did not mutate the authoritative fixture")
        snapshot["mutated"] = state
        snapshot["mutatedUtc"] = datetime.now(timezone.utc).isoformat()
        write_json(evidence, snapshot)
    elif args.action == "Restore":
        if sha256(backup) != snapshot["snapshotHash"]:
            raise RuntimeError("XunBao SQLite immutable backup hash changed")
        for suffix in ("-wal", "-shm"):
            sidecar = database + suffix
            if os.path.exists(sidecar):
                os.remove(sidecar)
        shutil.copy2(backup, database)
    elif args.action in ("AssertRestored", "AssertReloginHash"):
        if sha256(database) != snapshot["snapshotHash"]:
            raise RuntimeError("XunBao SQLite restored database hash mismatch")
        connection = sqlite3.connect("file:" + database + "?mode=ro", uri=True)
        try:
            if connection.execute("PRAGMA integrity_check").fetchone()[0] != "ok":
                raise RuntimeError("XunBao SQLite restored database integrity failed")
        finally:
            connection.close()
    elif args.action == "Cleanup":
        if os.path.exists(backup):
            os.remove(backup)
    elif args.action == "AssertCleanup":
        if os.path.exists(backup):
            raise RuntimeError("XunBao SQLite fixture backup remains after cleanup")
    else:
        raise RuntimeError(f"Unsupported XunBao SQLite action: {args.action}")


if __name__ == "__main__":
    main()
