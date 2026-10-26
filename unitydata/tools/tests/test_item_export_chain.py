"""Item source/order regression through real exporters; isolated data, no game processes."""
from pathlib import Path
import json,os,shutil,subprocess,unittest,uuid
from test_function_maintenance import patch_row
ROOT=Path(__file__).resolve().parents[3]
REL=[
 'unitydata/export/server/generated/json_server/item.json',
 'unityserver/config/json/item.json',
 'unitydata/export/client/source/Configs/item.json',
 'unityclient/Assets/Resources/ProjectXData/Configs/item.json']
SNAP='unitydata/export/server/authoritative/json/item.json'
class ItemExportChainTests(unittest.TestCase):
    def setUp(self):
        self.case=ROOT/'.local/item-export-chain-tests'/uuid.uuid4().hex
        self.case.mkdir(parents=True)
        def cp(rel):
            p=self.case/rel;p.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(ROOT/rel,p)
        self.cp=cp
        for book in ['item.xlsx','dongfu_config.xlsx','jingjie_realm.xlsx','function.xlsx']:
            cp('unitydata/excel/'+book)
        tools=['Export-UnityOwnedTables.ps1','Export-UnityServerData.ps1','Export-UnityClientData.ps1','Read-UnityVisualExcel.ps1','ItemStackRules.ps1','UnityItemData.ps1','UnityFunctionData.ps1','Test-UnityDongFuTables.ps1','dongfu-schema.json']
        for name in tools:cp('unitydata/tools/'+name)
        manifest=json.loads((ROOT/'unitydata/tools/unity-owned-tables.json').read_text(encoding='utf-8'))
        manifest['groups']=[g for g in manifest['groups'] if g['group'] in ['DongFu','LibraryRealm','Function']]
        (self.case/'unitydata/tools/unity-owned-tables.json').write_text(json.dumps(manifest),encoding='utf-8')
        cp('unityserver/sql/sqlite/001_initial_schema.sql')
        cp('unityserver/config/json/function.json')
        cp('unitydata/export/server/generated/json_server/function.json')
        for base in ['unitydata/export/client/source/Configs','unityclient/Assets/Resources/ProjectXData/Configs']:
            for name in ['function-unlocks.json','gameplay.json']:cp(base+'/'+name)
        for rel in REL+[SNAP]:cp(rel)
        for crop in json.loads((ROOT/'unityserver/config/json/dongfu_crop.json').read_text(encoding='utf-8')):
            for key in ['initial_resource_key','middle_resource_key','mature_resource_key']:cp('unityclient/Assets/'+crop[key]+'.png')
        self.expected=self.keyed(ROOT/REL[1]);self.book=self.case/'unitydata/excel/item.xlsx'
    @staticmethod
    def keyed(p):return {r['id']:r for r in json.loads(p.read_text(encoding='utf-8-sig'))}
    def run_export(self,group='Items',mode='Both',validate=False,apply=True,entry='Export-UnityOwnedTables.ps1'):
        # Fixed script text keeps Boolean values typed; all paths are isolated, generated UUIDs.
        file=self.case/'unitydata/tools'/entry
        command="& '"+str(file)+"' -Root '"+str(self.case)+"'"
        if entry=='Export-UnityOwnedTables.ps1':
            command+=" -Group '"+group+"' -Mode '"+mode+"' -ApplyRuntime:$"+str(apply).lower()
            if validate:command+=' -ValidateOnly'
        elif entry=='Export-UnityServerData.ps1':
            if apply:command+=' -ApplyGeneratedJson'
        p=subprocess.run(['pwsh.exe','-NoProfile','-Command',command],capture_output=True,text=True,encoding='utf-8',errors='replace',timeout=100)
        return p
    def ok(self,p):self.assertEqual(p.returncode,0,(p.stdout+p.stderr)[-4500:])
    def digest(self):
        return {p.relative_to(self.case):p.read_bytes() for p in self.case.rglob('*') if p.is_file() and p.suffix not in ['.xlsx','.png']}
    def test_rebuild_ignores_stale_runtime_and_wrong_snapshot_path(self):
        snapshot=(self.case/SNAP).read_bytes()
        wrong=self.case/'unitydata/export/server/source/authoritative/json/item.json';wrong.parent.mkdir(parents=True);wrong.write_text('[{"id":99999,"name":"wrong input"}]',encoding='utf-8')
        for rel in REL:(self.case/rel).write_text('[]',encoding='utf-8')
        meta=self.case/(REL[3]+'.meta');meta.write_text('guid: preserved\n',encoding='utf-8')
        self.ok(self.run_export())
        for rel in REL:self.assertEqual(self.keyed(self.case/rel),self.expected)
        self.assertEqual((self.case/SNAP).read_bytes(),snapshot)
        self.assertEqual(json.loads(wrong.read_text(encoding='utf-8-sig'))[0]['id'],99999)
        self.assertEqual(meta.read_text(encoding='utf-8-sig'),'guid: preserved\n')
        self.assertTrue({6001,6004,11019,10001,11008,11458,11857,11936,41012}.issubset(self.expected))
    def test_full_all_server_dry_export_builds_items_before_reference_checks(self):
        for rel in REL[:2]:shutil.copy2(self.case/SNAP,self.case/rel)
        runtime=(self.case/REL[1]).read_bytes()
        self.ok(self.run_export(group='All',mode='Server',apply=False))
        self.assertEqual(self.keyed(self.case/REL[0]),self.expected)
        self.assertEqual((self.case/REL[1]).read_bytes(),runtime)
        self.assertEqual(json.loads((self.case/REL[2]).read_text(encoding='utf-8-sig')),json.loads((ROOT/REL[2]).read_text(encoding='utf-8-sig')))
    def test_client_mode_and_legacy_alias_respect_apply_runtime(self):
        patch_row(self.book,11019,'name','isolated-source-change')
        original={r:(self.case/r).read_bytes() for r in REL}
        self.ok(self.run_export(group='AlchemyItems',mode='Client',apply=False))
        self.assertEqual(self.keyed(self.case/REL[2])[11019]['name'],'isolated-source-change')
        for rel in [REL[0],REL[1],REL[3]]:self.assertEqual((self.case/rel).read_bytes(),original[rel])
    def test_idempotence_and_validate_only_detect_drift_without_writes(self):
        before=self.digest();self.ok(self.run_export());self.assertEqual(before,self.digest())
        self.ok(self.run_export(validate=True));self.assertEqual(before,self.digest())
        patch_row(self.book,11019,'name','isolated-source-change')
        self.assertNotEqual(self.run_export(validate=True).returncode,0);self.assertEqual(before,self.digest())
    def test_invalid_input_fails_before_any_json_is_written(self):
        before=self.digest();original=self.book.read_bytes()
        for field,value,formula in [('max_stack',65001,None),('id',60000,None),('name',None,'1+1')]:
            self.book.write_bytes(original);patch_row(self.book,11019,field,value,formula)
            with self.subTest(field=field):
                self.assertNotEqual(self.run_export().returncode,0);self.assertEqual(before,self.digest())
    def prepare_full_server_fixture(self):
        self.cp('unitydata/excel/daily.xlsx');self.cp('unitydata/tools/vendor/xl转表.exe')
        for p in (ROOT/'unitydata/export/server/authoritative/json').glob('*.json'):
            self.cp(str(p.relative_to(ROOT)))
        for p in (ROOT/'unitydata/export/server/authoritative/json').glob('*.json'):
            target=self.case/'unityserver/config/json'/p.name
            if p.name not in ['item.json','function.json']:shutil.copy2(ROOT/'unityserver/config/json'/p.name,target)
        # JingJie is outside this item-chain fixture; its exporter is a terminal independent call.
        (self.case/'unitydata/tools/Export-UnityJingJieData.ps1').write_text("param($Root,$Mode)\nWrite-Output 'Unrelated JingJie export omitted in item-chain fixture.'\n",encoding='utf-8')

    def test_full_server_drift_rejects_before_any_runtime_copy(self):
        self.prepare_full_server_fixture()
        (self.case/'unityserver/config/json/daily.json').write_text('[]',encoding='utf-8')
        shutil.copy2(self.case/SNAP,self.case/REL[1])
        folder=self.case/'unityserver/config/json'
        before={p.name:p.read_bytes() for p in folder.glob('*.json')}
        p=self.run_export(entry='Export-UnityServerData.ps1',apply=True)
        self.assertNotEqual(p.returncode,0)
        self.assertEqual(before,{p.name:p.read_bytes() for p in folder.glob('*.json')})
        report=json.loads((self.case/'.local/unityserver-export/latest.json').read_text(encoding='utf-8-sig'))
        self.assertFalse(report['applied'])
        self.assertGreater(report['unresolvedDriftCount'],0)

    def test_real_full_server_converter_then_typed_items_preserves_runtime(self):
        self.prepare_full_server_fixture()
        for rel in REL[:2]:shutil.copy2(self.case/SNAP,self.case/rel)
        before=(self.case/REL[1]).read_bytes()
        self.ok(self.run_export(entry='Export-UnityServerData.ps1',apply=False))
        self.assertEqual((self.case/REL[1]).read_bytes(),before)
        self.assertEqual(self.keyed(self.case/REL[0]),self.expected)
        self.ok(self.run_export(entry='Export-UnityServerData.ps1',apply=True))
        self.assertEqual(self.keyed(self.case/REL[1]),self.expected)
        report=json.loads((self.case/'.local/unityserver-export/latest.json').read_text(encoding='utf-8-sig'))
        self.assertTrue(report['applied'])
        self.assertNotIn('item.json',[r['path'] for r in report['authoritativeOverrides']])
        self.assertEqual(report['unresolvedDriftCount'],0)

    def test_client_late_equipment_copy_does_not_restore_stale_server_items(self):
        patch_row(self.book,11019,'name','isolated-new-client-item')
        original_server=(self.case/REL[1]).read_bytes()
        self.ok(self.run_export(group='All',mode='Client',apply=False))
        for table in ['equip','equip_qianghua','equip_jinglian','equip_juexing','equip_shenzhu','fabao','fabao_qianghua','fabao_jinglian','quality','hecheng']:
            for base in ['unityserver/config/json','unitydata/export/server/generated/json_server']:
                target=self.case/(base+'/'+table+'.json');target.parent.mkdir(parents=True,exist_ok=True);target.write_text('[]',encoding='utf-8')
        # Execute the actual downstream equipment loop and final source-to-Assets tail.
        # Unrelated equipment inputs are empty fixtures; item runtime data deliberately remains old.
        harness=self.case/'late-client-copy.ps1'
        harness.write_text("$ErrorActionPreference='Stop'\n"
            +"$Root='"+str(self.case)+"'\n"
            +"$source=Join-Path $Root 'unitydata/export/client/source'\n"
            +"$destination=Join-Path $Root 'unityclient/Assets/Resources/ProjectXData'\n"
            +"$equipmentVisuals=@{equip=@();fabao=@()};$CleanOutput=$false\n"
            +"$file=Join-Path $Root 'unitydata/tools/Export-UnityClientData.ps1'\n"
            +"$tokens=$null;$errors=$null;$ast=[Management.Automation.Language.Parser]::ParseFile($file,[ref]$tokens,[ref]$errors)\n"
            +"if($errors.Count){throw $errors[0]}\n"
            +"$fn=$ast.Find({param($n) $n -is [Management.Automation.Language.FunctionDefinitionAst] -and $n.Name -eq 'Write-Utf8IfChanged'},$true)\n"
            +"$loop=$ast.Find({param($n) $n -is [Management.Automation.Language.ForEachStatementAst] -and $n.Variable.VariablePath.UserPath -eq 'table' -and $n.Extent.Text.Contains('Formal equipment table differs')},$true)\n"
            +"if(-not $fn -or -not $loop){throw 'Client item consumer stage missing'}\n"
            +". ([scriptblock]::Create($fn.Extent.Text))\n"
            +". ([scriptblock]::Create($loop.Extent.Text))\n"
            +"$text=[IO.File]::ReadAllText($file);$anchor='New-Item -ItemType Directory -Force -Path $destination | Out-Null';$at=$text.IndexOf($anchor)\n"
            +"if($at -lt 0){throw 'Client final copy missing'}\n"
            +". ([scriptblock]::Create($text.Substring($at)))\n",encoding='utf-8')
        p=subprocess.run(['pwsh.exe','-NoProfile','-File',str(harness)],capture_output=True,text=True,encoding='utf-8',errors='replace',timeout=40)
        self.ok(p)
        self.assertEqual(self.keyed(self.case/REL[3])[11019]['name'],'isolated-new-client-item')
        self.assertEqual((self.case/REL[1]).read_bytes(),original_server)

if __name__=='__main__':unittest.main(verbosity=2)
