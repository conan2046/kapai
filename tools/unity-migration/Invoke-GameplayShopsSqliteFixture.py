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

SOUL_VALUE = 134454
DETAIL_ITEM_ID = 851
DETAIL_ITEM_QUANTITY = 999
TYPE2_ITEM_IDS = (2024, 2044, 2148, 2363, 2474, 2680)


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


def deterministic_items(shop_config):
    with open(shop_config, "r", encoding="utf-8") as stream:
        rows = [row for row in json.load(stream) if int(row.get("type", 0)) == 2]
    by_id = {int(row["id"]): row for row in rows}
    selected = [by_id.get(item_id) for item_id in TYPE2_ITEM_IDS]
    if any(row is None for row in selected):
        raise RuntimeError("GameplayShops current Cocos type2 selection is absent from shop.json")
    for cell, row in enumerate(selected, 1):
        if int(row["cell"]) != cell or not all(0 <= value <= 0xFFFF for value in (
                int(row["id"]), int(row["itemid"][0]), int(row["itemid"][2]),
                int(row["price"][0][2]))):
            raise RuntimeError(
                f"GameplayShops current Cocos type2 selection is invalid at cell {cell}")
    return selected


def parse_mystery_shop(value):
    data = hero_fixture.expand(value)
    position = 0

    def take(fmt):
        nonlocal position
        size = struct.calcsize(fmt)
        if position + size > len(data):
            raise RuntimeError("GameplayShops mysteryShop payload is truncated")
        result = struct.unpack_from(fmt, data, position)
        position += size
        return result

    shops = {}
    for _ in range(take("<B")[0]):
        shop_type = take("<B")[0]
        refresh_times = take("<H")[0]
        free_times = take("<B")[0]
        deadline = take("<I")[0]
        items = []
        for _ in range(take("<B")[0]):
            grid, item_id, buy_count = take("<BHH")
            items.append([grid, item_id, buy_count])
        shops[shop_type] = {
            "refreshTimes": refresh_times,
            "freeTimes": free_times,
            "deadline": deadline,
            "items": items,
        }
    if position != len(data):
        raise RuntimeError(
            f"GameplayShops mysteryShop payload has trailing bytes: {len(data) - position}")
    return shops


def mystery_shop_blob(value, shop_config):
    shops = parse_mystery_shop(value)
    selected = deterministic_items(shop_config)
    shops[2] = {
        "refreshTimes": 0,
        "freeTimes": 10,
        "deadline": 0,
        "items": [
            [int(row["cell"]), int(row["id"]), 1 if index == 5 else 0]
            for index, row in enumerate(selected)
        ],
    }
    output = bytearray(struct.pack("<B", len(shops)))
    for shop_type, shop in sorted(shops.items()):
        output.extend(struct.pack(
            "<BHBIB",
            shop_type,
            shop["refreshTimes"],
            shop["freeTimes"],
            shop["deadline"],
            len(shop["items"]),
        ))
        for grid, item_id, buy_count in sorted(
                shop["items"], key=lambda item: item[1]):
            output.extend(struct.pack("<BHH", grid, item_id, buy_count))
    return hero_fixture.compress(output), [int(row["id"]) for row in selected]


def bank_item_blob(value):
    data = hero_fixture.expand(value)
    position = 0

    def take(fmt):
        nonlocal position
        size = struct.calcsize(fmt)
        if position + size > len(data):
            raise RuntimeError("GameplayShops bank_item payload is truncated")
        result = struct.unpack_from(fmt, data, position)
        position += size
        return result

    values8 = {take("<H")[0]: take("<B")[0] for _ in range(take("<H")[0])}
    values16 = {take("<H")[0]: take("<H")[0] for _ in range(take("<H")[0])}
    values32 = {take("<H")[0]: take("<I")[0] for _ in range(take("<H")[0])}
    tail = bytes(data[position:])
    values32[93] = SOUL_VALUE

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


def bank_item_soul(value):
    data = hero_fixture.expand(value)
    position = 0
    count8 = struct.unpack_from("<H", data, position)[0]
    position += 2 + count8 * struct.calcsize("<HB")
    count16 = struct.unpack_from("<H", data, position)[0]
    position += 2 + count16 * struct.calcsize("<HH")
    count32 = struct.unpack_from("<H", data, position)[0]
    position += 2
    for _ in range(count32):
        key, entry = struct.unpack_from("<HI", data, position)
        position += struct.calcsize("<HI")
        if key == 93:
            return entry
    return 0


def package_blob(value):
    records = hero_fixture.parse_package(value)
    matching = [index for index, (item_id, _) in enumerate(records) if item_id == DETAIL_ITEM_ID]
    empty = [index for index, (item_id, _) in enumerate(records) if not item_id]
    if matching:
        records[matching[0]] = [DETAIL_ITEM_ID, DETAIL_ITEM_QUANTITY]
        for index in matching[1:]:
            records[index] = [0, 0]
    else:
        if not empty:
            raise RuntimeError("GameplayShops SQLite package has no empty detail-item slot")
        records[empty[0]] = [DETAIL_ITEM_ID, DETAIL_ITEM_QUANTITY]
    output = bytearray()
    for item_id, quantity in records:
        output.extend(struct.pack("<H", item_id))
        if item_id:
            output.extend(struct.pack("<H", quantity))
    return hero_fixture.compress(output)


def package_quantity(value):
    return sum(quantity for item_id, quantity in hero_fixture.parse_package(value)
               if item_id == DETAIL_ITEM_ID)


def state(connection, user_id, role_id):
    row = connection.execute(
        "SELECT r.mysteryShop,u.money,u.bd_money,r.bank_item,r.package FROM role_info r "
        "JOIN user_info1 u ON u.id=? AND CAST(u.role0 AS INTEGER)=r.id WHERE r.id=?",
        (user_id, role_id),
    ).fetchone()
    if row is None:
        raise RuntimeError(f"GameplayShops SQLite identity mismatch: {user_id}/{role_id}")
    shops = parse_mystery_shop(row[0])
    page = shops.get(2, {"refreshTimes": 0, "freeTimes": 0, "deadline": 0, "items": []})
    return {
        "integrity": connection.execute("PRAGMA integrity_check").fetchone()[0],
        "type2ItemIds": [item[1] for item in sorted(page["items"])],
        "type2BuyCounts": [item[2] for item in sorted(page["items"])],
        "refreshTimes": page["refreshTimes"],
        "freeTimes": page["freeTimes"],
        "refreshBoundary": page["deadline"],
        "premium": int(row[1] or 0),
        "boundPremium": int(row[2] or 0),
        "soul": bank_item_soul(row[3]),
        "sixthItemSoldOut": len(page["items"]) == 6
            and sorted(page["items"])[5][2] == 1,
        "detailItemQuantity": package_quantity(row[4]),
    }


def assert_setup(connection, user_id, role_id):
    current = state(connection, user_id, role_id)
    if (current["integrity"] != "ok" or len(current["type2ItemIds"]) != 6
            or current["type2BuyCounts"] != [0, 0, 0, 0, 0, 1]
            or current["refreshTimes"] != 0 or current["freeTimes"] != 10
            or current["soul"] != SOUL_VALUE or not current["sixthItemSoldOut"]
            or current["detailItemQuantity"] != DETAIL_ITEM_QUANTITY):
        raise RuntimeError(f"GameplayShops SQLite fixture assertion failed: {current}")
    return current


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--action", required=True)
    parser.add_argument("--database", required=True)
    parser.add_argument("--backup", required=True)
    parser.add_argument("--evidence", required=True)
    parser.add_argument("--shop-config", required=True)
    parser.add_argument("--user-id", required=True, type=int)
    parser.add_argument("--role-id", required=True, type=int)
    args = parser.parse_args()
    database, backup, evidence = map(os.path.abspath, (args.database, args.backup, args.evidence))

    if args.action == "Setup":
        if not os.path.isfile(database):
            raise RuntimeError(f"GameplayShops SQLite database is missing: {database}")
        connection = sqlite3.connect(database)
        try:
            connection.execute("PRAGMA wal_checkpoint(TRUNCATE)")
        finally:
            connection.close()
        os.makedirs(os.path.dirname(backup), exist_ok=True)
        shutil.copy2(database, backup)
        connection = sqlite3.connect(database)
        try:
            row = connection.execute(
                "SELECT mysteryShop,bank_item,package FROM role_info WHERE id=?", (args.role_id,)).fetchone()
            if row is None:
                raise RuntimeError(f"GameplayShops SQLite role is missing: {args.role_id}")
            blob, item_ids = mystery_shop_blob(row[0], args.shop_config)
            connection.execute(
                "UPDATE role_info SET mysteryShop=?,bank_item=?,package=? WHERE id=?",
                (blob, bank_item_blob(row[1]), package_blob(row[2]), args.role_id))
            connection.execute("UPDATE user_info1 SET money='999999',bd_money='999999' WHERE id=?", (args.user_id,))
            connection.commit()
            fixture = assert_setup(connection, args.user_id, args.role_id)
        finally:
            connection.close()
        write_json(evidence, {
            "schemaVersion": 1, "module": "GameplayShops", "action": "Setup", "backend": "sqlite",
            "database": database, "backup": backup, "userId": args.user_id, "roleId": args.role_id,
            "snapshotHash": sha256(backup), "fixtureHash": sha256(database),
            "deterministicItemIds": item_ids, "fixture": fixture,
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
            raise RuntimeError("GameplayShops immutable backup hash changed")
        write_json(evidence, snapshot)
    elif args.action == "Restore":
        if sha256(backup) != snapshot["snapshotHash"]:
            raise RuntimeError("GameplayShops backup hash changed before restore")
        remove_sidecars(database)
        shutil.copy2(backup, database)
    elif args.action in ("AssertRestored", "AssertReloginHash"):
        actual = sha256(database)
        if actual != snapshot["snapshotHash"]:
            raise RuntimeError("GameplayShops restored database hash mismatch")
        connection = sqlite3.connect(database)
        try:
            if connection.execute("PRAGMA integrity_check").fetchone()[0] != "ok":
                raise RuntimeError("GameplayShops restored database integrity failed")
        finally:
            connection.close()
        snapshot["restoredHash"] = actual
        write_json(evidence, snapshot)
    elif args.action == "Cleanup":
        if os.path.isfile(backup):
            os.remove(backup)
    elif args.action == "AssertCleanup":
        if os.path.exists(backup):
            raise RuntimeError("GameplayShops fixture backup remains after cleanup")
        snapshot["residualCount"] = 0
        write_json(evidence, snapshot)
    else:
        raise RuntimeError(f"Unsupported GameplayShops SQLite fixture action: {args.action}")


if __name__ == "__main__":
    main()
