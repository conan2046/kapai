"""Global event maintenance: real exporter in isolated roots; no gameplay/database."""
from pathlib import Path
import json,shutil,subprocess,unittest,uuid
from test_function_maintenance import patch_row
ROOT=Path(__file__).resolve().parents[3]
GROUP=next(g for g in json.loads((ROOT/'unitydata/tools/unity-owned-tables.json').read_text(encoding='utf-8'))['groups'] if g['group']=='GlobalEvents')
OUTPUTS=[p+'/'+n+'.json' for p in ['unitydata/export/server/generated/json_server','unityserver/config/json','unitydata/export/client/source/Configs','unityclient/Assets/Resources/ProjectXData/Configs'] for n in ['event','daily']]+[p+'/daily_tasks.json' for p in ['unitydata/export/client/source/Tasks','unityclient/Assets/Resources/ProjectXData/Tasks']]
TOOLS=['Export-UnityOwnedTables.ps1','Export-UnityServerData.ps1','Export-UnityClientData.ps1','Read-UnityVisualExcel.ps1','ItemStackRules.ps1','UnityFunctionData.ps1','UnityGlobalEventData.ps1']

class GlobalEventExportTests(unittest.TestCase):
 def setUp(self):
  self.case=ROOT/'.local/global-event-tests'/uuid.uuid4().hex;self.case.mkdir(parents=True)
  for rel in ['unitydata/excel/event_config.xlsx','unitydata/excel/daily.xlsx','unityserver/sql/sqlite/001_initial_schema.sql']+OUTPUTS:
   d=self.case/rel;d.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(ROOT/rel,d)
  shutil.copy2(ROOT/'unityserver/config/json/sevendays.json',self.case/'unityserver/config/json/sevendays.json')
  d=self.case/'unitydata/tools';d.mkdir(parents=True,exist_ok=True)
  for n in TOOLS:shutil.copy2(ROOT/'unitydata/tools'/n,d/n)
  (d/'unity-owned-tables.json').write_text(json.dumps({'schemaVersion':1,'groups':[GROUP]}),encoding='utf-8')
  self.events=self.case/'unitydata/excel/event_config.xlsx';self.tasks=self.case/'unitydata/excel/daily.xlsx'
 def run_export(self,*args,entry='Export-UnityOwnedTables.ps1'):
  cmd=['pwsh.exe','-NoProfile','-File',str(self.case/'unitydata/tools'/entry),'-Root',str(self.case)]
  cmd+=['-Group','GlobalEvents','-Mode','Both'] if entry=='Export-UnityOwnedTables.ps1' else ['-DataGroup','GlobalEvents']
  return subprocess.run(cmd+list(args),capture_output=True,text=True,encoding='utf-8',errors='replace',timeout=60)
 def ok(self,p):self.assertEqual(p.returncode,0,p.stdout+'\n'+p.stderr)
 def outputs(self):return {p:(self.case/p).read_bytes() for p in OUTPUTS}
 def rows(self,n,scope='unityserver/config/json'):return {r['id']:r for r in json.loads((self.case/scope/(n+'.json')).read_text(encoding='utf-8-sig'))}
 def test_baseline_idempotence_and_no_inline_conditions(self):
  before=self.outputs();self.ok(self.run_export());self.assertEqual(before,self.outputs());self.ok(self.run_export('-ValidateOnly'))
  self.assertEqual(len(self.rows('daily')),148);self.assertEqual(len(self.rows('event')),162)
  self.assertTrue(all('condition' not in t and t['event_id'] in self.rows('event') for t in self.rows('daily').values()))
 def test_changed_shared_goal_propagates_and_real_native_loader_reads_it(self):
  old=self.rows('daily')[10];patch_row(self.events,1001,'num',4);patch_row(self.tasks,10,'event_id',1001);self.ok(self.run_export())
  for scope in ['unityserver/config/json','unitydata/export/server/generated/json_server','unitydata/export/client/source/Configs','unityclient/Assets/Resources/ProjectXData/Configs']:
   self.assertEqual(self.rows('event',scope)[1001]['num'],4);self.assertEqual(self.rows('daily',scope)[10]['event_id'],1001)
  self.assertEqual(old['reward'],self.rows('daily')[10]['reward'])
  exe=ROOT/'.local/unityserver-build/server-win/Debug/kapai.exe'
  self.assertTrue(exe.is_file(),'Build native server before running this integration test')
  p=subprocess.run([str(exe),'--validate-global-events'],cwd=self.case/'unityserver/config',capture_output=True,text=True,encoding='utf-8',errors='replace',timeout=20)
  self.assertEqual(p.returncode,0,p.stdout+p.stderr);report=json.loads(next(x for x in p.stdout.splitlines() if x.startswith('{')))
  self.assertEqual(report['sample_1001_target'],4);self.assertEqual(report['tasks'],148)
 def test_missing_or_disabled_event_is_rejected_without_writes(self):
  before=self.outputs();patch_row(self.tasks,10,'event_id',1015);self.assertNotEqual(self.run_export().returncode,0);self.assertEqual(before,self.outputs())
 def test_unimplemented_event_cannot_be_enabled(self):
  before=self.outputs();patch_row(self.events,1015,'enabled',1);self.assertNotEqual(self.run_export().returncode,0);self.assertEqual(before,self.outputs())
 def test_unsupported_period_and_duplicate_id_are_rejected(self):
  before=self.outputs();patch_row(self.events,1001,'cycle',2);self.assertNotEqual(self.run_export().returncode,0);self.assertEqual(before,self.outputs())
  patch_row(self.events,1001,'cycle',0);patch_row(self.events,1001,'id',1002);self.assertNotEqual(self.run_export().returncode,0);self.assertEqual(before,self.outputs())
 def test_formula_cannot_hide_a_condition_value(self):
  before=self.outputs();patch_row(self.events,1001,'num',formula='2+2');self.assertNotEqual(self.run_export().returncode,0);self.assertEqual(before,self.outputs())
 def test_client_and_server_entrypoints_respect_mode(self):
  patch_row(self.events,1001,'num',4);before=self.outputs();self.ok(self.run_export(entry='Export-UnityClientData.ps1'))
  for p in OUTPUTS[:4]:self.assertEqual(before[p],self.outputs()[p])
  self.assertEqual(self.rows('event','unityclient/Assets/Resources/ProjectXData/Configs')[1001]['num'],4)
  self.ok(self.run_export('-ApplyGeneratedJson',entry='Export-UnityServerData.ps1'));self.assertEqual(self.rows('event')[1001]['num'],4)

if __name__=='__main__':unittest.main(verbosity=2)
