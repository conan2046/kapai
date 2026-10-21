"""Offline save migration: native executable, isolated SQLite, full byte preservation."""
import argparse
import hashlib
import importlib.util
import json
import shutil
import sqlite3
import struct
import subprocess
import zlib
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
spec = importlib.util.spec_from_file_location('selection_protocol', Path(__file__).with_name('Test-HeroAffixSqliteProtocol.py'))
protocol = importlib.util.module_from_spec(spec)
spec.loader.exec_module(protocol)


def snapshot(path):
    with sqlite3.connect(path.as_uri()+'?mode=ro', uri=True) as db:
        schema = db.execute('SELECT type,name,tbl_name,sql FROM sqlite_master ORDER BY type,name').fetchall()
        tables = {name: sorted(db.execute('SELECT * FROM "'+name.replace('"','""')+'"').fetchall(), key=repr)
                  for kind, name, _, _ in schema if kind == 'table'}
        assert db.execute('PRAGMA integrity_check').fetchone()[0] == 'ok'
    return schema, tables


def normalize_blob(blob, heroes):
    if not blob:
        return blob, 0
    raw = bytearray(zlib.decompress(bytes.fromhex(blob)))
    count = struct.unpack_from('<H', raw)[0]
    assert 2+3*count <= len(raw)
    changed = 0
    for i in range(count):
        offset = 2+3*i
        key, value = struct.unpack_from('<HB', raw, offset)
        if key-61000 not in heroes:
            continue
        strategy = (value>>2)&7
        expected = (value&0xe0) | (strategy<<2 if strategy <= 5 else 0)
        if expected != value:
            raw[offset+2] = expected
            changed += 1
    return (zlib.compress(raw, 9).hex() if changed else blob), changed


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--executable', required=True)
    parser.add_argument('--evidence', required=True)
    args = parser.parse_args()
    binary = Path(args.executable).resolve()
    directory = Path(args.evidence).resolve()
    directory.mkdir(parents=True, exist_ok=False)
    heroes = sorted(int(row['hero_id']) for row in json.loads((ROOT/'unityserver/config/json/hero_skill_role.json').read_text(encoding='utf-8-sig')))
    seed = ROOT/'unityserver/sql/sqlite/fixtures/projectx-validation-base.db'
    seed_hash = hashlib.sha256(seed.read_bytes()).hexdigest()
    binary_hash = hashlib.sha256(binary.read_bytes()).hexdigest()
    db_path = directory/'matrix.db'
    shutil.copy2(seed, db_path)
    with sqlite3.connect(db_path) as db:
        blob = db.execute('SELECT bank_item FROM role_info WHERE id=?', (protocol.ROLE,)).fetchone()[0]
        original_state = protocol.decode_bank(blob)
        columns = [row[1] for row in db.execute('PRAGMA table_info(role_info)') if row[1] != 'id']
        quoted = ','.join('"'+name+'"' for name in columns)
        for batch in range((256+len(heroes)-1)//len(heroes)):
            role = 8000000+batch
            db.execute(f'INSERT INTO role_info (id,{quoted}) SELECT ?,{quoted} FROM role_info WHERE id=?', (role, protocol.ROLE))
            state = protocol.decode_bank(blob)
            state['8'] = {key: value for key, value in state['8'].items() if key-61000 not in heroes}
            state['8'][61001] = 255  # Unknown hero: preserve, despite being inside the key range.
            for index, hero in enumerate(heroes):
                value = batch*len(heroes)+index
                if value < 256:
                    state['8'][61000+hero] = value
            db.execute('UPDATE role_info SET bank_item=? WHERE id=?', (protocol.encode_bank(state), role))
        before_banks = dict(db.execute('SELECT id,bank_item FROM role_info'))
    before = snapshot(db_path)
    expected = {role: normalize_blob(blob, set(heroes)) for role, blob in before_banks.items()}
    checks = {}

    def run(path, name, success=True):
        result = subprocess.run([str(binary), '--migrate-hero-selections', str(path)],
                                cwd=ROOT/'unityserver/config', stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
                                timeout=90, creationflags=subprocess.CREATE_NO_WINDOW)
        (directory/(name+'.log')).write_bytes(result.stdout)
        assert (result.returncode == 0) == success, (name, result.returncode)

    run(db_path, 'matrix')
    after = snapshot(db_path)
    with sqlite3.connect(db_path) as db:
        actual = dict(db.execute('SELECT id,bank_item FROM role_info'))
        columns = [row[1] for row in db.execute('PRAGMA table_info(role_info)')]
    assert actual == {role: blob for role, (blob, _) in expected.items()}
    checks['all_256_packed_values_normalized'] = True
    # Compare every other column in every table, and the full schema.
    allowed = columns.index('bank_item')
    expected_tables = dict(before[1])
    expected_tables['role_info'] = sorted([tuple(expected[row[0]][0] if i == allowed else value
                                               for i, value in enumerate(row)) for row in before[1]['role_info']], key=repr)
    assert (before[0], expected_tables) == after
    checks['all_other_tables_columns_schema_preserved'] = True
    # Decompressed payload equals the old payload except for the relevant byte offsets.
    for role, blob in actual.items():
        if not blob:
            continue
        new = protocol.decode_bank(blob)
        old = protocol.decode_bank(before_banks[role])
        for name in ('16', '32', '64', 'tail'):
            assert old[name] == new[name]
        assert {k:v for k,v in old['8'].items() if k-61000 not in heroes} == {k:v for k,v in new['8'].items() if k-61000 not in heroes}
    checks['other_ext_maps_unknown_keys_and_tail_preserved'] = True
    backups = list(directory.glob(db_path.name+'.before-ab-retirement-*.db'))
    assert len(backups) == 1 and snapshot(backups[0]) == before
    checks['backup_matches_complete_before_image'] = True
    first_hash = hashlib.sha256(db_path.read_bytes()).hexdigest()
    run(db_path, 'repeat')
    assert snapshot(db_path) == after and hashlib.sha256(db_path.read_bytes()).hexdigest() == first_hash
    assert len(list(directory.glob(db_path.name+'.before-ab-retirement-*.db'))) == 1
    checks['repeat_is_no_write_and_no_extra_backup'] = True

    rollback = directory/'rollback.db'
    shutil.copy2(backups[0], rollback)
    with sqlite3.connect(rollback) as db:
        db.execute("CREATE TRIGGER reject_last_selection BEFORE UPDATE OF bank_item ON role_info WHEN NEW.id=8000004 BEGIN SELECT RAISE(ABORT,'injected late failure'); END")
    rollback_before = snapshot(rollback)
    run(rollback, 'rollback', success=False)
    assert snapshot(rollback) == rollback_before
    checks['late_failure_rolls_back_entire_batch'] = True

    corrupt = directory/'corrupt.db'
    shutil.copy2(backups[0], corrupt)
    with sqlite3.connect(corrupt) as db:
        db.execute('UPDATE role_info SET bank_item=? WHERE id=?', (zlib.compress(b'\xff\xff', 9).hex(), 8000004))
    corrupt_before = snapshot(corrupt)
    run(corrupt, 'corrupt', success=False)
    assert snapshot(corrupt) == corrupt_before and not list(directory.glob(corrupt.name+'.before-ab-retirement-*.db'))
    checks['malformed_payload_aborts_before_mutation'] = True
    missing = directory/'missing.db'
    run(missing, 'missing', success=False)
    assert not missing.exists()
    checks['missing_database_is_not_created'] = True
    assert hashlib.sha256(seed.read_bytes()).hexdigest() == seed_hash
    assert hashlib.sha256(binary.read_bytes()).hexdigest() == binary_hash
    checks['seed_and_binary_preserved'] = True
    report = dict(passed=all(checks.values()), checks=checks, selections_changed=sum(count for _, count in expected.values()),
                  packed_values=256, executable=str(binary), binary_sha256=binary_hash)
    (directory/'results.json').write_text(json.dumps(report, ensure_ascii=False, indent=2)+'\n', encoding='utf-8')
    print(json.dumps(report, ensure_ascii=False))


if __name__ == '__main__':
    main()
