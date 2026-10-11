"""Isolated source -> exporter -> JSON/XML/SQLite acceptance (stdlib only)."""
from pathlib import Path
import csv, hashlib, io, json, shutil, sqlite3, subprocess, unittest, uuid, zipfile
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[3]
EXPORTER = ROOT / 'unitydata/tools/Export-UnityOwnedTables.ps1'
MANIFEST = json.loads((ROOT/'unitydata/tools/unity-owned-tables.json').read_text(encoding='utf-8'))
NS={'s':'http://schemas.openxmlformats.org/spreadsheetml/2006/main'}

def workbook_rows(path, index):
    with zipfile.ZipFile(path) as z:
        strings=[]
        if 'xl/sharedStrings.xml' in z.namelist():
            strings=[''.join(si.itertext()) for si in ET.fromstring(z.read('xl/sharedStrings.xml')).findall('s:si',NS)]
        def value(c):
            if c.get('t')=='inlineStr':return ''.join(c.find('s:is',NS).itertext())
            v=c.findtext('s:v',default='',namespaces=NS)
            return strings[int(v)] if c.get('t')=='s' else v
        rows=ET.fromstring(z.read(f'xl/worksheets/sheet{index}.xml')).findall('s:sheetData/s:row',NS)
        headers={''.join(x for x in c.get('r') if x.isalpha()):value(c) for c in rows[0].findall('s:c',NS)}
        return [{headers[''.join(x for x in c.get('r') if x.isalpha())]:value(c) for c in r.findall('s:c',NS)} for r in rows if int(r.get('r'))>=5]

def patch_cell(path,index,address,value=None,formula=None,delete_row=None):
    with zipfile.ZipFile(path) as z:parts={n:z.read(n) for n in z.namelist()}
    name=f'xl/worksheets/sheet{index}.xml';doc=ET.fromstring(parts[name])
    if delete_row is not None:
        data=doc.find('s:sheetData',NS)
        for r in list(data):
            if int(r.get('r'))==delete_row:data.remove(r)
    else:
        cell=next(c for c in doc.findall('.//s:c',NS) if c.get('r')==address)
        for c in list(cell):cell.remove(c)
        cell.attrib.pop('t',None)
        if formula is not None:ET.SubElement(cell,'{'+NS['s']+'}f').text=formula
        if isinstance(value,str):
            cell.set('t','inlineStr');ET.SubElement(ET.SubElement(cell,'{'+NS['s']+'}is'),'{'+NS['s']+'}t').text=value
        else:ET.SubElement(cell,'{'+NS['s']+'}v').text=str(value)
    parts[name]=ET.tostring(doc,encoding='utf-8',xml_declaration=True)
    with zipfile.ZipFile(path,'w',zipfile.ZIP_DEFLATED) as z:
        for n,b in parts.items():z.writestr(n,b)

def fingerprint(root):
    return {p.relative_to(root).as_posix():hashlib.sha256(p.read_bytes()).hexdigest() for p in root.rglob('*') if p.is_file() and p.suffix!='.xlsx'}

def database(root):
    db=sqlite3.connect(':memory:')
    db.create_function('MD5',1,lambda s:hashlib.md5(str(s).encode()).hexdigest())
    schema=(root/'unityserver/sql/sqlite/001_initial_schema.sql').read_text(encoding='utf-8-sig')
    db.executescript(schema)
    db.execute('INSERT INTO fish_basket_slots(role_id,slot_index,item_id,quantity) VALUES(987654,0,580,3)')
    db.executescript(schema)
    assert db.execute('SELECT quantity FROM fish_basket_slots WHERE role_id=987654').fetchone()==(3,)
    return db

class UnityOwnedTablesTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.root=ROOT/'.local/unitydata-closure-tests'/uuid.uuid4().hex
        cls.root.mkdir(parents=True)
        (cls.root/'unitydata/excel').mkdir(parents=True)
        for g in MANIFEST['groups']:shutil.copy2(ROOT/'unitydata/excel'/g['workbook'],cls.root/'unitydata/excel'/g['workbook'])
        for rel in ['unityserver/config/json','unityserver/config/xml','unityserver/config/source','unityserver/sql/sqlite']:
            shutil.copytree(ROOT/rel,cls.root/rel)
        for rel in ['unitydata/export/client/source','unityclient/Assets/Resources/ProjectXData']:
            shutil.copytree(ROOT/rel,cls.root/rel)
        cls.run_export('All')
    @classmethod
    def run_export(cls,group,validate=False,success=True,mode='Both'):
        args=['pwsh.exe','-NoProfile','-File',str(EXPORTER),'-Root',str(cls.root),'-Group',group,'-Mode',mode]
        if validate:args.append('-ValidateOnly')
        r=subprocess.run(args,stdout=subprocess.PIPE,stderr=subprocess.STDOUT,encoding='utf-8',errors='replace')
        if (r.returncode==0)!=success:raise AssertionError(r.stdout)
        return r

    def test_01_all_tables_roundtrip(self):
        for g in MANIFEST['groups']:
            for s in g['sheets']:
                with self.subTest(group=g['group'],sheet=s['name']):
                    expected=workbook_rows(self.root/'unitydata/excel'/g['workbook'],s['sheetIndex'])
                    for r in expected:
                        for k,t in s['columns'].items():
                            if t=='number':r[k]=float(r[k])
                            elif t=='json':r[k]=json.loads(r[k])
                            elif t=='bool':r[k]=r[k] in ['1','true']
                    client_expected=expected
                    expected=[{k:v for k,v in r.items() if k not in s.get('clientOnlyColumns',[])} for r in expected]
                    kind=s['kind'];folder={'json':'json','xml':'xml','csv':'source'}[kind]
                    runtime=self.root/'unityserver/config'/folder/s['output']
                    generated=self.root/'unitydata/export/server/generated'/('json_server' if kind=='json' else folder)/s['output']
                    self.assertEqual(runtime.read_bytes(),generated.read_bytes())
                    if kind=='json':actual=json.loads(runtime.read_text(encoding='utf-8-sig'))
                    elif kind=='xml':actual=[dict(c.attrib) for c in ET.parse(runtime).getroot()]
                    else:
                        actual=list(csv.DictReader(io.StringIO(runtime.read_text(encoding='utf-8-sig'))))
                        for r in actual:
                            for k,t in s['columns'].items():
                                if t=='number':r[k]=float(r[k])
                    self.assertEqual(expected,actual)
                    if s['client']:
                        a=self.root/'unitydata/export/client/source/Configs'/s['output'];b=self.root/'unityclient/Assets/Resources/ProjectXData/Configs'/s['output']
                        self.assertEqual(a.read_bytes(),b.read_bytes())
                        if s.get('clientOnlyColumns'):self.assertEqual(json.loads(a.read_text(encoding='utf-8-sig')),client_expected)
                        else:self.assertEqual(a.read_bytes(),runtime.read_bytes())
        database(self.root).close()

    def test_02_idempotent_export(self):
        before=fingerprint(self.root);self.run_export('All',validate=True);self.run_export('All')
        self.assertEqual(before,fingerprint(self.root))

    def test_03_each_group_source_changes_reach_outputs(self):
        cases=[('Fish',1,'B5',137),('Answer',1,'B5',2),('HappyWheel',1,'E5',2),('FaBaoSearch',1,'C5',41),('HeroCombat',1,'D5',[3,2,1]),('Attributes',1,'B5','测试属性名称'),('CasualGameplay',1,'F5','8123'),('RoleBattle',1,'C5','1001')]
        for group,index,cell,value in cases:
            g=next(g for g in MANIFEST['groups'] if g['group']==group);s=g['sheets'][0]
            path=self.root/'unitydata/excel'/g['workbook'];backup=path.read_bytes();before=fingerprint(self.root)
            if isinstance(value,list):value=json.dumps(value)
            try:
                patch_cell(path,index,cell,value);self.run_export(group)
                after=fingerprint(self.root)
                self.assertNotEqual(before,after,group)
                folder={'json':'json','xml':'xml','csv':'source'}[s['kind']];output=self.root/'unityserver/config'/folder/s['output']
                field=list(s['columns'])[ord(cell[0])-ord('A')]
                if s['kind']=='json':actual=json.loads(output.read_text(encoding='utf-8-sig'))[0][field];expected=json.loads(value) if s['columns'][field]=='json' else value
                elif s['kind']=='xml':actual=list(ET.parse(output).getroot())[0].get(field);expected=str(value)
                else:actual=list(csv.DictReader(io.StringIO(output.read_text(encoding='utf-8-sig'))))[0][field];expected=str(value)
                self.assertEqual(actual,expected,group)
                if group=='Fish':self.assertEqual(database(self.root).execute('SELECT gold_cost FROM fish_settings').fetchone(),(137,))
                if group=='Answer':self.assertEqual(database(self.root).execute('SELECT daily_attempt_limit FROM answer_settings').fetchone(),(2,))
                if group=='HappyWheel':self.assertEqual(json.loads((self.root/'unityserver/config/json/happywheel.json').read_text())[0]['single_key_cost'],2)
            finally:path.write_bytes(backup);self.run_export(group)

    def test_04_invalid_sources_never_write(self):
        path=self.root/'unitydata/excel/fish_config.xlsx';backup=path.read_bytes()
        for index,cell,value,formula in [(3,'A6',1,None),(1,'B5',-1,None),(1,'B5',1.5,None),(1,'B5',137,'100+37')]:
            before=fingerprint(self.root)
            try:
                patch_cell(path,index,cell,value,formula);self.run_export('Fish',success=False)
                self.assertEqual(before,fingerprint(self.root))
            finally:path.write_bytes(backup)

    def test_05_removed_fish_reward_does_not_remain_in_database(self):
        path=self.root/'unitydata/excel/fish_config.xlsx';backup=path.read_bytes()
        db=database(self.root)
        try:
            patch_cell(path,3,None,delete_row=14);self.run_export('Fish')
            db.executescript((self.root/'unityserver/sql/sqlite/001_initial_schema.sql').read_text(encoding='utf-8-sig'))
            self.assertEqual(db.execute('SELECT COUNT(*) FROM fish_reward').fetchone(),(9,))
            self.assertEqual(db.execute('SELECT quantity FROM fish_basket_slots WHERE role_id=987654').fetchone(),(3,))
        finally:db.close();path.write_bytes(backup);self.run_export('Fish')

    def test_06_last_group_failure_keeps_all_outputs_unchanged(self):
        path=self.root/'unitydata/excel/role_battle.xlsx';backup=path.read_bytes();before=fingerprint(self.root)
        try:
            patch_cell(path,1,'C5','1001','1000+1');self.run_export('All',success=False)
            self.assertEqual(before,fingerprint(self.root))
        finally:path.write_bytes(backup)

    def test_07_client_metadata_and_xml_placeholder_are_preserved(self):
        client=json.loads((self.root/'unitydata/export/client/source/Configs/fish_position.json').read_text(encoding='utf-8-sig'))
        server=json.loads((self.root/'unityserver/config/json/fish_position.json').read_text(encoding='utf-8-sig'))
        self.assertEqual(client[0]['map_resource'],'Art/Fish/Map/map33');self.assertNotIn('map_resource',server[0])
        rows=list(ET.parse(self.root/'unityserver/config/xml/role_level_attr.xml').getroot())
        self.assertEqual(len(rows),601);self.assertTrue(all(v=='' for v in rows[0].attrib.values()))

if __name__=='__main__':unittest.main(verbosity=2)
