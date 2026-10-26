"""Function maintenance acceptance: real exporter, isolated workbooks, no game runtime."""
from pathlib import Path
import copy, hashlib, json, shutil, subprocess, unittest, uuid, zipfile
import xml.etree.ElementTree as ET

ROOT=Path(__file__).resolve().parents[3]
NS={'s':'http://schemas.openxmlformats.org/spreadsheetml/2006/main'}
GROUP=next(g for g in json.loads((ROOT/'unitydata/tools/unity-owned-tables.json').read_text(encoding='utf-8'))['groups'] if g['group']=='Function')
OUTPUTS=['unityserver/config/json/function.json','unitydata/export/server/generated/json_server/function.json']+[b+'/'+n for b in ['unitydata/export/client/source/Configs','unityclient/Assets/Resources/ProjectXData/Configs'] for n in ['function-unlocks.json','gameplay.json']]

def patch_row(path,ident,field,value=None,formula=None):
    with zipfile.ZipFile(path) as z: parts={n:z.read(n) for n in z.namelist()}
    strings=[]
    if 'xl/sharedStrings.xml' in parts:
        strings=[''.join(x.itertext()) for x in ET.fromstring(parts['xl/sharedStrings.xml']).findall('s:si',NS)]
    def val(c):
        if c.get('t')=='inlineStr':return ''.join(c.find('s:is',NS).itertext())
        v=c.findtext('s:v',default='',namespaces=NS)
        return strings[int(v)] if c.get('t')=='s' else v
    doc=ET.fromstring(parts['xl/worksheets/sheet1.xml']); rows=doc.findall('s:sheetData/s:row',NS)
    head={val(c):''.join(k for k in c.get('r') if k.isalpha()) for c in rows[0].findall('s:c',NS)}
    row=next(r for r in rows[4:] if val(next(c for c in r if c.get('r').startswith('A') and c.get('r')[1:].isdigit()))==str(ident))
    addr=head[field]+row.get('r'); cell=next(c for c in row if c.get('r')==addr)
    for c in list(cell):cell.remove(c)
    cell.attrib.pop('t',None)
    if formula is not None:ET.SubElement(cell,'{'+NS['s']+'}f').text=formula
    elif isinstance(value,str):
        cell.set('t','inlineStr');ET.SubElement(ET.SubElement(cell,'{'+NS['s']+'}is'),'{'+NS['s']+'}t').text=value
    else:ET.SubElement(cell,'{'+NS['s']+'}v').text=str(value)
    parts['xl/worksheets/sheet1.xml']=ET.tostring(doc,encoding='utf-8',xml_declaration=True)
    with zipfile.ZipFile(path,'w',zipfile.ZIP_DEFLATED) as z:
        for n,b in parts.items():z.writestr(n,b)

class FunctionMaintenanceTests(unittest.TestCase):
    def setUp(self):
        self.case=ROOT/'.local/function-maintenance-tests'/uuid.uuid4().hex
        self.case.mkdir(parents=True)
        for rel in ['unitydata/excel/function.xlsx','unityserver/sql/sqlite/001_initial_schema.sql']+OUTPUTS:
            target=self.case/rel;target.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(ROOT/rel,target)
        tools=self.case/'unitydata/tools';tools.mkdir(parents=True,exist_ok=True)
        for n in ['Export-UnityOwnedTables.ps1','Export-UnityServerData.ps1','Export-UnityClientData.ps1','Read-UnityVisualExcel.ps1','ItemStackRules.ps1','UnityFunctionData.ps1']:
            shutil.copy2(ROOT/'unitydata/tools'/n,tools/n)
        (tools/'unity-owned-tables.json').write_text(json.dumps({'schemaVersion':1,'groups':[GROUP]}),encoding='utf-8')
        self.book=self.case/'unitydata/excel/function.xlsx'
    def run_export(self,*flags,entry='Export-UnityOwnedTables.ps1'):
        args=['pwsh.exe','-NoProfile','-File',str(self.case/'unitydata/tools'/entry),'-Root',str(self.case)]
        args+=['-Group','Function','-Mode','Both'] if entry=='Export-UnityOwnedTables.ps1' else ['-DataGroup','Function']
        p=subprocess.run(args+list(flags),capture_output=True,text=True,encoding='utf-8',errors='replace',timeout=40)
        return p
    def ok(self,p):self.assertEqual(p.returncode,0,p.stdout+'\n'+p.stderr)
    def outputs(self):return {p:(self.case/p).read_bytes() for p in OUTPUTS}
    def rows(self,rel,key):return {r[key]:r for r in json.loads((self.case/rel).read_text(encoding='utf-8-sig'))}
    def test_baseline_order_flags_and_idempotence(self):
        before=self.outputs();self.ok(self.run_export());self.assertEqual(before,self.outputs())
        self.ok(self.run_export());self.assertEqual(before,self.outputs())
        self.ok(self.run_export('-ValidateOnly'));self.assertEqual(before,self.outputs())
    def test_one_condition_updates_both_client_catalogs_and_server(self):
        patch_row(self.book,32,'open_condition','[[1,12]]');self.ok(self.run_export())
        self.assertEqual(self.rows(OUTPUTS[0],'function_id')[32]['open_condition'],[[1,12]])
        self.assertEqual(self.rows(OUTPUTS[2],'functionId')[32]['openLevel'],12)
        self.assertEqual(self.rows(OUTPUTS[3],'id')[32]['openLevel'],12)
    def test_duplicates_rejected_without_partial_writes(self):
        before=self.outputs();patch_row(self.book,32,'function_id',22)
        self.assertNotEqual(self.run_export().returncode,0);self.assertEqual(before,self.outputs())
    def test_invalid_condition_and_formula_rejected_without_writes(self):
        before=self.outputs();patch_row(self.book,32,'open_condition','[[1,-1]]')
        self.assertNotEqual(self.run_export().returncode,0);self.assertEqual(before,self.outputs())
        patch_row(self.book,32,'open_condition',formula='1+1')
        self.assertNotEqual(self.run_export().returncode,0);self.assertEqual(before,self.outputs())
    def test_duplicate_client_order_rejected_without_writes(self):
        before=self.outputs();patch_row(self.book,32,'unlock_order',1)
        self.assertNotEqual(self.run_export().returncode,0);self.assertEqual(before,self.outputs())
    def test_validate_only_reports_source_drift_without_writes(self):
        before=self.outputs();patch_row(self.book,32,'open_condition','[[1,12]]')
        self.assertNotEqual(self.run_export('-ValidateOnly').returncode,0);self.assertEqual(before,self.outputs())
    def test_client_and_server_entry_points_use_typed_function_source(self):
        patch_row(self.book,32,'open_condition','[[1,12]]')
        original=(self.case/OUTPUTS[0]).read_bytes()
        self.ok(self.run_export(entry='Export-UnityServerData.ps1'))
        self.assertEqual((self.case/OUTPUTS[0]).read_bytes(),original)
        self.assertEqual(self.rows(OUTPUTS[1],'function_id')[32]['open_condition'],[[1,12]])
        self.ok(self.run_export('-ApplyGeneratedJson',entry='Export-UnityServerData.ps1'))
        self.assertEqual(self.rows(OUTPUTS[0],'function_id')[32]['open_condition'],[[1,12]])
        self.ok(self.run_export(entry='Export-UnityClientData.ps1'))
        self.assertEqual(self.rows(OUTPUTS[3],'id')[32]['openLevel'],12)
    def test_old_snapshot_cannot_override_and_unrelated_item_untouched(self):
        old=self.case/'unitydata/export/server/authoritative/json/function.json';old.parent.mkdir(parents=True);old.write_text('[{"function_id":32,"open_condition":[[1,99]]}]',encoding='utf-8')
        item=self.case/'unityserver/config/json/item.json';item.write_text('{"sentinel":"untouched"}',encoding='utf-8')
        self.ok(self.run_export())
        self.assertEqual(self.rows(OUTPUTS[0],'function_id')[32]['open_condition'],[[1,10]])
        self.assertEqual(item.read_text(encoding='utf-8'),'{"sentinel":"untouched"}')

if __name__=='__main__':unittest.main(verbosity=2)
