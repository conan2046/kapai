import argparse
import hashlib
import json
import os
import shutil
import sqlite3
import struct
from datetime import datetime, timezone


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


def deterministic_blob(shop_config):
    with open(shop_config, "r", encoding="utf-8") as stream:
        rows = [row for row in json.load(stream) if int(row.get("type", 0)) == 2]
    selected = []
    for cell in range(1, 7):
        candidates = sorted(
            (
                row for row in rows
                if int(row.get("cell", 0)) == cell
                and all(0 <= value <= 0xFFFF for value in (
                    int(row["id"]),
                    int(row["itemid"][0]),
                    int(row["itemid"][2]),
                    int(row["price"][0][2]),
                ))
            ),
            key=lambda row: int(row["id"]),
        )
        if not candidates:
            raise RuntimeError(f"GameplayShops has no type2 candidate for cell {cell}")
        selected.append(candidates[0])
    # CUser::Set/GetShenhunShopData persists a direct lowercase hex string:
    # uint32 refresh boundary, uint8 count, then id/itemId/itemNum/price uint16 values.
    # UINT32_MAX keeps the deterministic list from being regenerated at login.
    data = bytearray(struct.pack("<IB", 0xFFFFFFFF, len(selected)))
    for row in selected:
        data.extend(struct.pack(
            "<HHHH",
            int(row["id"]),
            int(row["itemid"][0]),
            int(row["itemid"][2]),
            int(row["price"][0][2]),
        ))
    return bytes(data).hex(), [int(row["id"]) for row in selected]


def parse_blob(value):
    data = bytes.fromhex(value)
    if len(data) < 5:
        raise RuntimeError(f"GameplayShops shenhunShop payload is too short: {len(data)}")
    deadline, count = struct.unpack_from("<IB", data, 0)
    expected = 5 + count * struct.calcsize("<HHHH")
    if len(data) != expected:
        raise RuntimeError(f"GameplayShops shenhunShop payload size mismatch: actual={len(data)} expected={expected}")
    items = []
    offset = 5
    for _ in range(count):
        item = struct.unpack_from("<HHHH", data, offset)
        offset += struct.calcsize("<HHHH")
        items.append(item)
    return {"deadline": deadline, "items": items}


def state(connection, user_id, role_id):
    row = connection.execute(
        "SELECT r.shenhunShop,u.money,u.bd_money FROM role_info r "
        "JOIN user_info1 u ON u.id=? AND CAST(u.role0 AS INTEGER)=r.id WHERE r.id=?",
        (user_id, role_id),
    ).fetchone()
    if row is None:
        raise RuntimeError(f"GameplayShops SQLite identity mismatch: {user_id}/{role_id}")
    page = parse_blob(row[0])
    return {
        "integrity": connection.execute("PRAGMA integrity_check").fetchone()[0],
        "type2ItemIds": [item[0] for item in page["items"]],
        "refreshBoundary": page["deadline"],
        "premium": int(row[1] or 0),
        "boundPremium": int(row[2] or 0),
    }


def assert_setup(connection, user_id, role_id):
    current = state(connection, user_id, role_id)
    if current["integrity"] != "ok" or len(current["type2ItemIds"]) != 6:
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
        blob, item_ids = deterministic_blob(args.shop_config)
        connection = sqlite3.connect(database)
        try:
            connection.execute("UPDATE role_info SET shenhunShop=? WHERE id=?", (blob, args.role_id))
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
