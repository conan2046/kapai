from pathlib import Path
import json,re,shutil,subprocess,unittest,uuid
from test_function_maintenance import patch_row
ROOT=Path(__file__).resolve().parents[3]
SCOPES=['unitydata/export/server/generated/json_server','unityserver/config/json','unitydata/export/client/source/Configs','unityclient/Assets/Resources/ProjectXData/Configs']
OUTPUTS=[f'{s}/{n}.json' for s in SCOPES for n in ['event','daily','story_event','story_dialog']]+[f'{s}/daily_tasks.json' for s in ['unitydata/export/client/source/Tasks','unityclient/Assets/Resources/ProjectXData/Tasks']]
TOOLS=['Export-UnityOwnedTables.ps1','Read-UnityVisualExcel.ps1','ItemStackRules.ps1','UnityFunctionData.ps1','UnityGlobalEventData.ps1','UnityStoryData.ps1']
class StoryExportTests(unittest.TestCase):
 def setUp(self):
  self.case=ROOT/'.local/story-export-tests'/uuid.uuid4().hex
  for p in ['unitydata/excel/event_config.xlsx','unitydata/excel/daily.xlsx','unitydata/excel/story_config.xlsx','unitydata/excel/reward_fixed.xlsx','unityserver/sql/sqlite/001_initial_schema.sql']+OUTPUTS:
   dst=self.case/p;dst.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(ROOT/p,dst)
  # Placement export resolves formal native Prefab roots and descendants.
  for key in ['UImainLayer_new','JingjieLayer']:
   catalog=Path('unityclient/Assets/Prefabs/Catalog')/(key+'.asset')
   guid=re.search(r'prefab:.*guid: ([a-f0-9]+)',(ROOT/catalog).read_text(encoding='utf-8')).group(1)
   for source in (ROOT/'unityclient/Assets/Prefabs').rglob(key+'.prefab.meta'):
    if not re.search(r'^guid: '+guid+r'\s*$',source.read_text(encoding='utf-8'),re.M):continue
    for file in [source,source.with_suffix(''),ROOT/catalog]:
     dst=self.case/file.relative_to(ROOT);dst.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(file,dst)
  (self.case/'unitydata/tools').mkdir(parents=True,exist_ok=True)
  for n in TOOLS:shutil.copy2(ROOT/'unitydata/tools'/n,self.case/'unitydata/tools'/n)
  groups=json.loads((ROOT/'unitydata/tools/unity-owned-tables.json').read_text(encoding='utf-8'))['groups']
  (self.case/'unitydata/tools/unity-owned-tables.json').write_text(json.dumps({'schemaVersion':1,'groups':[g for g in groups if g['group'] in ['Story','GlobalEvents']]}),encoding='utf-8')
 def export(self,*args):
  return subprocess.run(['pwsh.exe','-NoProfile','-File',str(self.case/'unitydata/tools/Export-UnityOwnedTables.ps1'),'-Root',str(self.case),'-Group','Story','-Mode','Both',*args],capture_output=True,text=True,encoding='utf-8',errors='replace',timeout=60)
 def data(self):return {p:(self.case/p).read_bytes() for p in OUTPUTS}
 def patch_story(self,ident,field,value):
  # The story_event worksheet is sheet2 in the retained workbook.
  import zipfile
  book=self.case/'unitydata/excel/story_config.xlsx'
  with zipfile.ZipFile(book) as z: parts={n:z.read(n) for n in z.namelist()}
  a,b='xl/worksheets/sheet1.xml','xl/worksheets/sheet2.xml';parts[a],parts[b]=parts[b],parts[a]
  with zipfile.ZipFile(book,'w',zipfile.ZIP_DEFLATED) as z:
   for n,v in parts.items():z.writestr(n,v)
  patch_row(book,ident,field,value)
  with zipfile.ZipFile(book) as z:parts={n:z.read(n) for n in z.namelist()}
  parts[a],parts[b]=parts[b],parts[a]
  with zipfile.ZipFile(book,'w',zipfile.ZIP_DEFLATED) as z:
   for n,v in parts.items():z.writestr(n,v)
 def test_formal_baseline_idempotent_and_all_scopes_share_it(self):
  before=self.data();p=self.export();self.assertEqual(p.returncode,0,p.stdout+p.stderr);self.assertEqual(before,self.data());self.assertEqual(self.export('-ValidateOnly').returncode,0)
  for name in ['story_event','story_dialog']:
   self.assertEqual(len({(self.case/s/(name+'.json')).read_bytes() for s in SCOPES}),1)
 def test_dialogue_text_edit_reaches_every_runtime_copy(self):
  patch_row(self.case/'unitydata/excel/story_config.xlsx',100001,'dialog','测试修订：请先打开境界。')
  p=self.export();self.assertEqual(p.returncode,0,p.stdout+p.stderr)
  for s in SCOPES:self.assertEqual(json.loads((self.case/s/'story_dialog.json').read_text(encoding='utf-8-sig'))[0]['dialog'],'测试修订：请先打开境界。')
 def test_disabled_dialogue_rejected_without_partial_outputs(self):
  before=self.data();patch_row(self.case/'unitydata/excel/story_config.xlsx',100001,'enabled',0)
  self.assertNotEqual(self.export().returncode,0);self.assertEqual(before,self.data())
 def test_disabled_event_and_broken_sequence_rejected(self):
  before=self.data();self.patch_story(1,'trigger_event_id',1015)
  self.assertNotEqual(self.export().returncode,0);self.assertEqual(before,self.data())
 def test_reward_package_reference_cannot_be_missing(self):
  before=self.data();self.patch_story(4,'action_id',65530)
  self.assertNotEqual(self.export().returncode,0);self.assertEqual(before,self.data())
 def test_mismatched_reward_type_rejected_before_outputs(self):
  before=self.data();self.patch_story(4,'action_id',40005)
  self.assertNotEqual(self.export().returncode,0);self.assertEqual(before,self.data())
 def test_broken_predecessor_rejected_before_outputs(self):
  before=self.data();self.patch_story(11,'pre_id',9)
  self.assertNotEqual(self.export().returncode,0);self.assertEqual(before,self.data())

 def test_dialogue_parent_and_signed_offsets_reach_all_runtime_copies(self):
  book=self.case/'unitydata/excel/story_config.xlsx'
  patch_row(book,100001,'parent_node','UImainLayer_new')
  patch_row(book,100001,'offset_x',-35.5)
  patch_row(book,100001,'offset_y',42.25)
  p=self.export();self.assertEqual(p.returncode,0,p.stdout+p.stderr)
  for s in SCOPES:
   r=json.loads((self.case/s/'story_dialog.json').read_text(encoding='utf-8-sig'))[0]
   self.assertEqual((r['parent_node'],r['offset_x'],r['offset_y']),('UImainLayer_new',-35.5,42.25))
 def test_unknown_parent_rejected_without_partial_outputs(self):
  before=self.data();self.patch_story(3,'parent_node','MissingStoryUi/NoNode')
  self.assertNotEqual(self.export().returncode,0);self.assertEqual(before,self.data())
 def test_missing_child_rejected_without_partial_outputs(self):
  before=self.data();self.patch_story(3,'parent_node','JingjieLayer/JingjieUI/MissingUpgradeButton')
  self.assertNotEqual(self.export().returncode,0);self.assertEqual(before,self.data())
 def test_nonfinite_offset_rejected_without_partial_outputs(self):
  before=self.data();self.patch_story(3,'offset_y','NaN')
  self.assertNotEqual(self.export().returncode,0);self.assertEqual(before,self.data())
 def test_parent_traversal_rejected_without_partial_outputs(self):
  before=self.data();self.patch_story(3,'parent_node','JingjieLayer/../NoNode')
  self.assertNotEqual(self.export().returncode,0);self.assertEqual(before,self.data())
 def test_guide_effect_side_and_offsets_reach_all_runtime_copies(self):
  values={'select_visible':1,'select_offset_x':-18.5,'select_offset_y':27.25,'hint_side':2,'hint_offset_x':33.75,'hint_offset_y':-44.5}
  for field,value in values.items():self.patch_story(2,field,value)
  p=self.export();self.assertEqual(p.returncode,0,p.stdout+p.stderr)
  for scope in SCOPES:
   row=next(r for r in json.loads((self.case/scope/'story_event.json').read_text(encoding='utf-8-sig')) if r['id']==2)
   for field,value in values.items():self.assertEqual(row[field],value)
 def test_invalid_effect_flag_rejected_without_partial_outputs(self):
  before=self.data();self.patch_story(2,'select_visible',2)
  self.assertNotEqual(self.export().returncode,0);self.assertEqual(before,self.data())
 def test_invalid_hint_side_rejected_without_partial_outputs(self):
  before=self.data();self.patch_story(2,'hint_side',3)
  self.assertNotEqual(self.export().returncode,0);self.assertEqual(before,self.data())
 def test_nonfinite_child_offset_rejected_without_partial_outputs(self):
  before=self.data();self.patch_story(3,'hint_offset_x','Infinity')
  self.assertNotEqual(self.export().returncode,0);self.assertEqual(before,self.data())
 def test_native_story_accumulates_three_separate_strengthens(self):
  self.patch_story(1,'trigger_event_id',1001)
  p=self.export();self.assertEqual(p.returncode,0,p.stdout+p.stderr)
  shutil.copy2(ROOT/'unitydata/export/server/generated/json_server/reward_fixed.json',self.case/'unityserver/config/json/reward_fixed.json')
  p=subprocess.run([str(ROOT/'.local/unityserver-build/server-win/Debug/kapai.exe'),'--validate-story-counters'],cwd=self.case/'unityserver/config',capture_output=True,text=True,encoding='utf-8',errors='replace',timeout=20)
  self.assertEqual(p.returncode,0,p.stdout+p.stderr)
  report=json.loads(next(x for x in p.stdout.splitlines() if x.startswith('{')))
  self.assertEqual(report['trigger_increments'],3);self.assertTrue(report['dialogue_started']);self.assertTrue(report['wrong_filter_rejected'])
if __name__=='__main__':unittest.main(verbosity=2)
