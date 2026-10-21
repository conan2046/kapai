"""Real equipment protocols and persistence against a new isolated SQLite seed."""
import argparse
import hashlib
import importlib.util
import json
import shutil
import socket
import sqlite3
import struct
import subprocess
import time
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
USER, ROLE, PORT = 7200057, 1000003, 8711
UID = 2121200001

def load(name, relative):
    spec = importlib.util.spec_from_file_location(name, ROOT/relative)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module

wire = load('login_wire', 'tools/unity-migration/Test-LoginNoticeSqliteProtocol.py')
equipment = load('equip_fixture', 'tools/unity-migration/Invoke-HeroEquipSqliteFixture.py')
codec = equipment.hero_fixture

class Reader:
    def __init__(self, data): self.data, self.pos = data, 0
    def number(self, fmt):
        value = struct.unpack_from('<'+fmt, self.data, self.pos)[0]
        self.pos += struct.calcsize('<'+fmt)
        return value
    def string(self):
        size = self.number('H')
        value = self.data[self.pos:self.pos+size].decode('utf-16le')
        self.pos += size
        return value
    def affix(self):
        row = [self.number(f) for f in ('I','I','H','B','B')]
        row += [self.string() for _ in range(3)]
        row += [self.number('i'), self.number('i')]
        return row
    def end(self): assert self.pos == len(self.data), (self.pos, len(self.data))

def login():
    sock = socket.create_connection(('127.0.0.1',PORT), timeout=5)
    body = struct.pack('<I',USER)+wire.pack_string('local')+wire.pack_string('102600')+struct.pack('<I',1)
    body += b''.join(wire.pack_string(s) for s in ('local_test','','',''))
    wire.send_packet(sock,1001,body)
    response = wire.receive_protocol(sock,1001,5)
    assert response[0] == 1 and struct.unpack_from('<II',response,2) == (USER,ROLE)
    wire.send_packet(sock,1004,struct.pack('<I',ROLE))
    assert wire.receive_protocol(sock,1004,5)[0] == 1
    return sock

def receive_op(sock, op):
    deadline = time.monotonic()+10
    while time.monotonic()<deadline:
        data = wire.receive_protocol(sock,319,max(.1,deadline-time.monotonic()))
        if data and data[0] == op: return Reader(data)
    raise TimeoutError(f'319/{op}')

def listing(sock):
    wire.send_packet(sock,319,b'\x28')
    rows, pages = {}, []
    while True:
        reader = receive_op(sock,40)
        assert reader.number('B') == 40
        total = reader.number('H')
        if total == 0:
            reader.end()
            return rows, [dict(total=0)]
        count, index, size = (reader.number('B') for _ in range(3))
        assert count == (total+19)//20 and size <= 20
        for _ in range(size):
            row = reader.affix()
            assert row[0] not in rows
            rows[row[0]] = row
        reader.end()
        pages.append(dict(total=total,count=count,index=index,size=size))
        if len(pages) == count:
            assert len(rows) == total and sorted(p['index'] for p in pages) == list(range(count))
            return rows, pages

def toggle(sock, uid, op=41):
    wire.send_packet(sock,319,bytes([op])+struct.pack('<I',uid))
    reader = receive_op(sock,op)
    assert reader.number('B') == op
    result, message, cost = reader.number('B'), reader.string(), reader.number('I')
    record = reader.affix() if result == 1 else None
    reader.end()
    return dict(result=result,message=message,next_cost=cost,record=record)

def database_state(db):
    with sqlite3.connect(db) as connection:
        blob, money = connection.execute('SELECT pet_equip,money FROM role_info WHERE id=?',(ROLE,)).fetchone()
    _, _, tail = equipment.parse_equipment_layout(blob)
    return dict(blob=blob,money=int(money),affixes=equipment.parse_affix_records(tail))

def equipment_operation(sock, op, uid):
    wire.send_packet(sock,319,bytes([op])+struct.pack('<BI',1,uid))
    reader=receive_op(sock,op)
    assert (reader.number('B'),reader.number('B'),reader.number('I')) == (op,1,uid)
    success,message=reader.number('B'),reader.string()
    reader.end()
    assert success == 1, f'319/{op} uid{uid}: {message}'

def pet_attributes(sock, hero=57):
    wire.send_packet(sock,51,struct.pack('<IH',ROLE,hero))
    body=wire.receive_protocol(sock,51,5)
    reader=Reader(body)
    assert (reader.number('I'),reader.number('H')) == (ROLE,hero)
    position,name=reader.number('B'),reader.string()
    star,break_level,level,experience,maximum_experience=(reader.number(fmt) for fmt in ('B','B','H','I','I'))
    power=reader.number('Q')
    names=('attack','physical_defense','magical_defense','maximum_hp','speed','hit','dodge','critical','critical_resistance',
           'damage_bonus','physical_reduction','magical_reduction','critical_damage','counter','counter_damage',
           'counter_resistance','combo','combo_damage','combo_resistance','reflection','reflection_damage','reflection_resistance',
           'debuff','debuff_resistance','attack_ratio','physical_defense_ratio','magical_defense_ratio','hp_ratio')
    attributes={key:reader.number('i') for key in names}
    return dict(hero=hero,position=position,name=name,level=level,power=power,attributes=attributes,
                packet_sha256=hashlib.sha256(body).hexdigest(),packet_hex=body.hex())

def decode_bank(blob):
    data=codec.expand(blob);position=0;state={}
    for name,fmt in (('8','HB'),('16','HH'),('32','HI'),('64','HQ')):
        count=struct.unpack_from('<H',data,position)[0];position+=2
        values={}
        for _ in range(count):
            key,value=struct.unpack_from('<'+fmt,data,position);position+=struct.calcsize('<'+fmt)
            assert key not in values
            values[key]=value
        state[name]=values
    state['tail']=bytes(data[position:]).hex()
    return state

def encode_bank(state):
    output=bytearray()
    for name,fmt in (('8','HB'),('16','HH'),('32','HI'),('64','HQ')):
        output.extend(struct.pack('<H',len(state[name])))
        for key,value in sorted(state[name].items()):output.extend(struct.pack('<'+fmt,key,value))
    output.extend(bytes.fromhex(state['tail']))
    return codec.compress(output)

def bank_snapshot(db):
    with sqlite3.connect(db) as connection:
        blob,money,save_data=connection.execute('SELECT bank_item,money,save_data FROM role_info WHERE id=?',(ROLE,)).fetchone()
    return dict(blob=blob,money=int(money),save_data=save_data,state=decode_bank(blob))

def build_selection(sock, hero=57, branch=None, strategy=None, payload=None, operation=None):
    op=operation or (43 if branch is None else 44)
    if payload is None:payload=struct.pack('<H',hero)+(b'' if op==43 else struct.pack('<BB',branch,strategy))
    wire.send_packet(sock,319,bytes([op])+payload)
    reader=receive_op(sock,op);assert reader.number('B')==op
    result=reader.number('B');hero=reader.number('H')
    branch,strategy,available,effective_branch,effective_strategy=(reader.number('B') for _ in range(5))
    message=reader.string();reader.end()
    return dict(result=result,hero=hero,branch=branch,strategy=strategy,available=available,
                effective_branch=effective_branch,effective_strategy=effective_strategy,message=message)

def run_build_selection(db,start,stop,report,directory):
    def same_other_data(before,after,keys):
        for name in ('16','32','64','tail'):assert before['state'][name]==after['state'][name],name
        assert {k:v for k,v in before['state']['8'].items() if k not in keys} == {k:v for k,v in after['state']['8'].items() if k not in keys}
        assert before['money']==after['money'] and before['save_data']==after['save_data']
    def reject_updates(enabled):
        with sqlite3.connect(db) as connection:
            if enabled:connection.execute(f"CREATE TRIGGER reject_hero_build BEFORE UPDATE OF bank_item ON role_info WHEN NEW.id={ROLE} BEGIN SELECT RAISE(ABORT,'hero build injected rejection'); END")
            else:connection.execute('DROP TRIGGER reject_hero_build')
    checks={};responses=[]
    with login() as sock:
        original=bank_snapshot(db)
        old=build_selection(sock);responses.append(old)
        checks['legacy_ab_retired_strategy_preserved']=(old['result']==1 and old['branch']==0 and old['strategy']==3
            and old['available']==1 and old['effective_branch']==0 and old['effective_strategy']==3
            and original['state']['8'][61057]==0xac and original['state']['8'][61010]==0xb0
            and bank_snapshot(db)['blob']==original['blob'])
        backups=list(db.parent.glob(db.name+'.before-ab-retirement-*.db'))
        assert len(backups)==1
        checks['startup_backup_preserves_legacy_selections']=(bank_snapshot(backups[0])['state']['8'][61057]==0xad
            and bank_snapshot(backups[0])['state']['8'][61010]==0xb2)
        normal=build_selection(sock,57,0,1);responses.append(normal)
        baseline=bank_snapshot(db)
        checks['normal_branch_strategy_active']=(normal['result']==1 and normal['effective_branch']==0 and normal['effective_strategy']==1
            and baseline['state']['8'][61057]==0xa4)
        for hero,branch,strategy in ((10,0,1),(65535,0,1),(57,1,1),(57,2,1),(57,3,1),(57,0,6),(57,255,255)):
            reply=build_selection(sock,hero,branch,strategy);responses.append(reply)
            assert reply['result']==0 and reply['message'] and bank_snapshot(db)['blob']==baseline['blob']
        for op,payload in ((43,b''),(43,struct.pack('<HB',57,0)),(44,struct.pack('<H',57))):
            reply=build_selection(sock,payload=payload,operation=op);responses.append(reply)
            assert reply['result']==0 and bank_snapshot(db)['blob']==baseline['blob']
        checks['ownership_retired_ab_range_and_length_rejections']=True
        reject_updates(True)
        assert build_selection(sock,57,0,2)['result']==0
        failed=build_selection(sock);assert (failed['branch'],failed['strategy'])==(0,1)
        assert build_selection(sock,64,0,4)['result']==0
        failed_absent=build_selection(sock,64);assert (failed_absent['branch'],failed_absent['strategy'])==(0,0)
        checks['failed_memory_and_database_rollback']=bank_snapshot(db)['blob']==baseline['blob']
        reject_updates(False)
        selected=build_selection(sock,57,0,2);responses.append(selected)
        committed=bank_snapshot(db)
        checks['immediate_commit_and_reserved_bits']=(selected['result']==1 and selected['effective_branch']==0
            and selected['effective_strategy']==2 and committed['state']['8'][61057]==0xa8)
        checks['failed_absent_key_removed']=61064 not in committed['state']['8']
        same_other_data(baseline,committed,{61057})
        second=build_selection(sock,64,0,4);responses.append(second)
        assert second['result']==1 and (second['effective_branch'],second['effective_strategy'])==(0,4)
        assert bank_snapshot(db)['state']['8'][61064]==16
        for strategy in range(6):
            reply=build_selection(sock,57,0,strategy)
            assert reply['result']==1 and (reply['effective_branch'],reply['effective_strategy'])==(0,strategy)
            assert bank_snapshot(db)['state']['8'][61057]==(0xa0|(strategy<<2))
        checks['original_skills_and_all_six_strategies']=True
        reject_updates(True)
        unchanged=bank_snapshot(db)['blob']
        assert build_selection(sock,57,0,5)['result']==1 and bank_snapshot(db)['blob']==unchanged
        reject_updates(False);checks['idempotent_selection_no_write']=True
        assert build_selection(sock,57,0,0)['result']==1 and bank_snapshot(db)['state']['8'][61057]==0xa0
        assert build_selection(sock,57,0,5)['result']==1
        final=bank_snapshot(db);same_other_data(baseline,final,{61057,61064})
        checks['other_ext_maps_tail_money_fixed_save_data_preserved']=True
    stop();start()
    with login() as sock:
        first,second=build_selection(sock,57),build_selection(sock,64);responses.extend((first,second))
        checks['restart_saved_and_effective_choices']=(first['branch'],first['strategy'],first['effective_branch'],first['effective_strategy'])==(0,5,0,5) and (second['branch'],second['strategy'],second['effective_branch'],second['effective_strategy'])==(0,4,0,4)
        checks['repeat_startup_does_not_migrate_again']=len(list(db.parent.glob(db.name+'.before-ab-retirement-*.db')))==1
    report['hero_build_checks']=checks;report['passed']=all(checks.values())
    (directory/'hero-build-responses.json').write_text(json.dumps(responses,ensure_ascii=False,indent=2),encoding='utf-8')
    print(json.dumps(dict(passed=report['passed'],checks=checks),ensure_ascii=False))
    return report['passed']

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--executable',required=True)
    parser.add_argument('--evidence',required=True)
    parser.add_argument('--probe',action='store_true')
    parser.add_argument('--empty',action='store_true')
    parser.add_argument('--equipment-cycle',action='store_true')
    parser.add_argument('--hero-build',action='store_true')
    args = parser.parse_args()
    executable=Path(args.executable).resolve()
    binary_hash=hashlib.sha256(executable.read_bytes()).hexdigest()
    formal_paths=[ROOT/'unitydata/excel'/name for name in ('hero_combat.xlsx','fabao.xlsx','suit.xlsx')]
    formal_paths += sorted((ROOT/'unityserver/config/json').glob('*.json'))
    formal_paths += sorted((ROOT/'unityserver/config/xml').glob('*.xml'))
    formal_paths += sorted((ROOT/'unityserver/config').glob('*.ini'))
    formal_hashes={str(path.relative_to(ROOT)):hashlib.sha256(path.read_bytes()).hexdigest() for path in formal_paths}
    directory = Path(args.evidence).resolve()
    directory.mkdir(parents=True,exist_ok=False)
    config_root=ROOT/'unityserver/config'
    runtime_hashes={}
    if args.hero_build:
        assert not args.empty and not args.equipment_cycle
        config_root=directory/'runtime-config';shutil.copytree(ROOT/'unityserver/config',config_root)
        binding_path=config_root/'json/combat_binding.json'
        bindings=json.loads(binding_path.read_text(encoding='utf-8-sig'))
        for binding in bindings:
            # Keep rejection/legacy fallback checks independent of formal release state.
            binding['enabled']=0
            if (binding['hero_id'],binding['branch']) in ((57,1),(64,2)):
                binding['enabled']=1;binding['status']='complete'
        binding_path.write_text(json.dumps(bindings,ensure_ascii=False,separators=(',',':'))+'\n',encoding='utf-8')
        runtime_hashes={str(p.relative_to(config_root)):hashlib.sha256(p.read_bytes()).hexdigest() for p in sorted(config_root.rglob('*')) if p.is_file()}
    db = directory/'isolated.db'
    seed = ROOT/'unityserver/sql/sqlite/fixtures/projectx-validation-base.db'
    manifest = json.loads(seed.with_suffix('.manifest.json').read_text(encoding='utf-8-sig'))
    seed_hash = hashlib.sha256(seed.read_bytes()).hexdigest().upper()
    assert seed_hash == manifest['sha256']
    shutil.copy2(seed,db)
    templates = json.loads((ROOT/'unityserver/config/json/equip.json').read_text(encoding='utf-8-sig'))
    red = int(next(x['id'] for x in templates if int(x['quality']) == 6 and int(x['part']) == 1))
    blue = int(next(x['id'] for x in templates if int(x['quality']) == 4))
    records = [(UID+i,red) for i in range(21)]+[(UID+100,blue)]
    if args.equipment_cycle:
        assert not args.empty
        records=[(UID+(suit-1)*4+part-1,int(next(x['id'] for x in templates if int(x['suit'])==suit and int(x['part'])==part)))
                 for suit in (1,2) for part in range(1,5)]
    if args.empty:records = []
    legacy = struct.pack('<H',len(records))+b''.join(struct.pack('<IHIIBB',uid,template,0,0,0,0) for uid,template in records)
    parameters = json.loads((ROOT/'unityserver/config/json/config.json').read_text(encoding='utf-8-sig'))
    search_max = json.loads(next(x['value'] for x in parameters if x['name'] == 'fabao_counts'))[2]
    # Keep the unrelated timed-search subsystem at its formal full state.
    legacy += struct.pack('<HIH',0,0,search_max)
    blob = codec.compress(legacy)
    with sqlite3.connect(db) as connection:
        assert connection.execute('SELECT CAST(role0 AS INTEGER) FROM user_info1 WHERE id=?',(USER,)).fetchone()[0] == ROLE
        connection.execute('UPDATE role_info SET pet_equip=?,money=5000000 WHERE id=?',(blob,ROLE))
        if args.equipment_cycle:
            pets,formation=connection.execute('SELECT pet,zhenfa FROM role_info WHERE id=?',(ROLE,)).fetchone()
            assert {57,64}.issubset({r[0] for r in codec.parse_pets(pets)[1]})
            connection.execute('UPDATE role_info SET zhenfa=? WHERE id=?',(equipment.formation_blob(formation),ROLE))
        if args.hero_build:
            bank=connection.execute('SELECT bank_item FROM role_info WHERE id=?',(ROLE,)).fetchone()[0]
            state=decode_bank(bank);assert bytes(codec.expand(encode_bank(state)))==bytes(codec.expand(bank))
            state['8'][61057]=0xad;state['8'][61010]=0xb2;state['8'].pop(61064,None)
            connection.execute('UPDATE role_info SET bank_item=? WHERE id=?',(encode_bank(state),ROLE))
    with socket.socket() as check:
        assert check.connect_ex(('127.0.0.1',PORT)) != 0, '8711 already occupied'
    process = None
    logs = []
    report = dict(backend='new-isolated-sqlite',database=str(db),seed_sha256=seed_hash,
                  executable=str(executable),binary_sha256=binary_hash,formal_input_sha256=formal_hashes,passed=False)
    if args.hero_build:report.update(runtime_fixture_root=str(config_root),runtime_fixture_sha256=runtime_hashes,
                                    fixture_enabled_bindings=[[57,1],[64,2]],production_bindings_changed=False)
    def start():
        nonlocal process
        log = open(directory/f'server-{len(logs)}.log','wb'); logs.append(log)
        process = subprocess.Popen([str(executable),'--sqlite',str(db),'--sqlite-schema',str(ROOT/'unityserver/sql/sqlite/001_initial_schema.sql')],cwd=config_root,stdout=log,stderr=subprocess.STDOUT,creationflags=subprocess.CREATE_NO_WINDOW)
        for _ in range(150):
            if process.poll() is not None: raise RuntimeError(f'server exited {process.returncode}; see {log.name}')
            with socket.socket() as check:
                if check.connect_ex(('127.0.0.1',PORT)) == 0:return
            time.sleep(.1)
        raise TimeoutError('isolated server startup')
    def stop():
        nonlocal process
        if process and process.poll() is None:process.terminate();process.wait(timeout=10)
        process = None
    try:
        start()
        if args.hero_build:
            passed=run_build_selection(db,start,stop,report,directory)
            return 0 if args.probe or passed else 1
        if args.equipment_cycle:
            with login() as sock:
                states={'baseline':pet_attributes(sock)}
                for uid,_ in records[:4]:equipment_operation(sock,2,uid)
                states['first_suit']=pet_attributes(sock)
                for uid,_ in records[4:]:equipment_operation(sock,2,uid)
                states['second_suit']=pet_attributes(sock)
                for uid,_ in records[4:]:equipment_operation(sock,3,uid)
                states['restored']=pet_attributes(sock)
                report['real_operations']=dict(protocol=319,wear=8,takeoff=4,pet_query=51)
                report['first_suit_changes_stats']=states['first_suit']['attributes'] != states['baseline']['attributes']
                report['second_suit_changes_stats']=states['second_suit']['attributes'] != states['first_suit']['attributes']
                report['restored_attributes']=states['restored']['attributes'] == states['baseline']['attributes']
                report['restored_power']=states['restored']['power'] == states['baseline']['power']
                report['restored_full_pet_packet']=states['restored']['packet_sha256'] == states['baseline']['packet_sha256']
                report['passed']=all(report[k] for k in ('first_suit_changes_stats','second_suit_changes_stats',
                    'restored_attributes','restored_power','restored_full_pet_packet'))
                (directory/'equipment-cycle-states.json').write_text(json.dumps(states,ensure_ascii=False,indent=2),encoding='utf-8')
            print(json.dumps({k:report[k] for k in ('passed','restored_attributes','restored_power','restored_full_pet_packet')}))
            return 0 if args.probe or report['passed'] else 1
        with login() as sock:
            rows, pages = listing(sock)
            report['pages'] = pages
            if args.empty:
                assert not rows and pages == [dict(total=0)]
                assert toggle(sock,UID)['result'] == 0
                report['empty_list_and_missing_uid'] = True
                report['passed'] = True
                print('{"empty_list_and_missing_uid": true, "passed": true}')
                return 0
            assert len(rows) == 21 and UID+100 not in rows
            formal = {x['id']:x for x in json.loads((ROOT/'unityserver/config/json/equipment_affix.json').read_text(encoding='utf-8-sig'))}
            report['formal_tier_descriptions'] = all(row[7] == formal[row[2]]['combat_descriptions'][row[3]-1] for row in rows.values())
            assert toggle(sock,UID+999)['result'] == 0
            assert toggle(sock,UID+100)['result'] == 0
            original = rows[UID]
            result = toggle(sock,UID)
            assert result['result'] == 1 and result['record'][4] == (original[4]^1)
            refreshed,_ = listing(sock)
            assert refreshed[UID] == result['record']
            state = database_state(db)
            saved = {x[0]:x for x in state['affixes']}
            report['immediate_persistence'] = UID in saved and saved[UID][1:] == result['record'][1:5]
            report['legacy_old_body_preserved'] = bytes(codec.expand(state['blob']))[:len(legacy)] == legacy
            with sqlite3.connect(db) as connection:
                connection.execute("CREATE TRIGGER affix_save_failure BEFORE UPDATE OF pet_equip ON role_info WHEN NEW.id=1000003 BEGIN SELECT RAISE(ABORT,'intentional isolated affix save failure'); END")
            failed = toggle(sock,UID)
            after,_ = listing(sock)
            report['failure_response'] = failed
            report['failed_memory_rollback'] = failed['result'] == 0 and after[UID] == result['record']
            report['failed_database_rollback'] = database_state(db) == state
            failed_reroll = toggle(sock,UID,42)
            after_reroll,_ = listing(sock)
            report['failed_reroll_response'] = failed_reroll
            report['failed_reroll_rollback'] = failed_reroll['result'] == 0 and after_reroll[UID] == result['record'] and database_state(db) == state
            with sqlite3.connect(db) as connection:connection.execute('DROP TRIGGER affix_save_failure')
            rerolled = toggle(sock,UID,42)
            assert rerolled['result'] == 1
            saved_reroll = database_state(db)
            report['reroll_money_equipment_commit'] = (saved_reroll['money'] == state['money']-result['next_cost']
                and {x[0]:x for x in saved_reroll['affixes']}.get(UID) == rerolled['record'][:5]
                and rerolled['record'][2] == result['record'][2] and rerolled['record'][4] == result['record'][4]
                and rerolled['record'][3] != result['record'][3])
            result = rerolled
            report['passed'] = all(report[k] for k in ('formal_tier_descriptions','immediate_persistence','legacy_old_body_preserved','failed_memory_rollback','failed_database_rollback','failed_reroll_rollback','reroll_money_equipment_commit'))
        stop()
        start()
        with login() as sock:
            relogged,_ = listing(sock)
            report['restart_affix_roundtrip'] = relogged[UID] == result['record']
        report['passed'] &= report['restart_affix_roundtrip']
    except Exception as error:
        report['error'] = repr(error)
        raise
    finally:
        stop()
        for log in logs:log.close()
        with sqlite3.connect(db) as connection:report['integrity_check'] = connection.execute('PRAGMA integrity_check').fetchone()[0]
        report['seed_unchanged'] = hashlib.sha256(seed.read_bytes()).hexdigest().upper() == seed_hash
        report['process_stopped'] = process is None
        report['binary_unchanged']=hashlib.sha256(executable.read_bytes()).hexdigest() == binary_hash
        report['formal_inputs_unchanged']=all(hashlib.sha256((ROOT/path).read_bytes()).hexdigest() == value for path,value in formal_hashes.items())
        report['runtime_fixture_unchanged']=all(hashlib.sha256((config_root/path).read_bytes()).hexdigest() == value for path,value in runtime_hashes.items())
        preserved=(report['integrity_check']=='ok' and report['seed_unchanged'] and report['process_stopped']
                   and report['binary_unchanged'] and report['formal_inputs_unchanged'] and report['runtime_fixture_unchanged'])
        report['passed'] &= preserved
        (directory/'results.json').write_text(json.dumps(report,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
        if not preserved:raise RuntimeError('Protocol input preservation or cleanup failed; inspect results.json')
    print(json.dumps({k:report[k] for k in ('passed','immediate_persistence','failed_memory_rollback','failed_database_rollback','restart_affix_roundtrip')},ensure_ascii=False))
    return 0 if args.probe or report['passed'] else 1

if __name__ == '__main__':raise SystemExit(main())
