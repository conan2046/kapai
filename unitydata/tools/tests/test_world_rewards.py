"""Isolated formal World exporter tests; no game, player save or Cocos input."""
from pathlib import Path
import json,shutil,subprocess,unittest,uuid,zipfile,xml.etree.ElementTree as E,hashlib
ROOT=Path(__file__).resolve().parents[3];NS={'s':'http://schemas.openxmlformats.org/spreadsheetml/2006/main'}
OUT=[f'{base}/{name}.json' for base in ['unitydata/export/server/generated/json_server','unityserver/config/json'] for name in ['reward','maplist','fight_config','monster_boss_basic']]+[f'{base}/{name}.txt' for base in ['unitydata/export/client/source/World','unityclient/Assets/Resources/ProjectXData/World'] for name in ['maplist_dat','main_dungeon_fight_dat','main_dungeon_monster_dat']]
OUT += [f'{base}/{name}.json' for base in ['unitydata/export/server/generated/json_server','unityserver/config/json'] for name in ['bigmap','reward_fixed']]+[f'{base}/{name}.txt' for base in ['unitydata/export/client/source/World','unityclient/Assets/Resources/ProjectXData/World'] for name in ['bigmap_dat','reward_fixed_dat']]
def read(path):
 with zipfile.ZipFile(path) as z:
  parts={n:z.read(n) for n in z.namelist()}
 ss=E.fromstring(parts['xl/sharedStrings.xml']) if 'xl/sharedStrings.xml' in parts else []
 strings=[''.join(x.itertext()) for x in ss]
 x=E.fromstring(parts['xl/worksheets/sheet1.xml']);rows={}
 for row in x.findall('s:sheetData/s:row',NS):
  vals={}
  for c in row.findall('s:c',NS):
   t=c.get('t');v=c.findtext('s:v',default='',namespaces=NS)
   if t=='s':v=strings[int(v)]
   if t=='inlineStr':v=''.join(c.find('s:is',NS).itertext())
   vals[''.join(filter(str.isalpha,c.get('r')))]=v
  rows[int(row.get('r'))]=vals
 return parts,x,rows
def save(path,parts,x):
 parts['xl/worksheets/sheet1.xml']=E.tostring(x,encoding='utf-8',xml_declaration=True)
 with zipfile.ZipFile(path,'w',zipfile.ZIP_DEFLATED) as z:
  for n,b in parts.items():z.writestr(n,b)
def trim(path,ids):
 parts,x,rows=read(path);data=x.find('s:sheetData',NS)
 for row in list(data):
  n=int(row.get('r'))
  if n>=5 and int(rows[n].get('A','0') or 0) not in ids:data.remove(row)
 save(path,parts,x)
def patch(path,address,value=None,formula=None,cached=None):
 parts,x,_=read(path)
 for c in x.findall('s:sheetData/s:row/s:c',NS):
  if c.get('r')!=address:continue
  for child in list(c):c.remove(child)
  c.attrib.pop('t',None)
  if formula:
   E.SubElement(c,'{'+NS['s']+'}f').text=formula;E.SubElement(c,'{'+NS['s']+'}v').text=str(cached)
  else:
   c.set('t','inlineStr');E.SubElement(E.SubElement(c,'{'+NS['s']+'}is'),'{'+NS['s']+'}t').text=str(value)
 save(path,parts,x)
class WorldRewardTests(unittest.TestCase):
 def setUp(self):
  self.root=ROOT/'.local/world-reward-tests'/uuid.uuid4().hex;self.root.mkdir(parents=True)
  for name in ['reward','maplist','fight_config','monster_boss_basic','bigmap','reward_fixed']:self.cp('unitydata/excel/'+name+'.xlsx')
  tools=self.root/'unitydata/tools';tools.mkdir(parents=True)
  for p in (ROOT/'unitydata/tools').glob('*.ps1'):shutil.copy2(p,tools/p.name)
  manifest=json.loads((ROOT/'unitydata/tools/unity-owned-tables.json').read_text(encoding='utf-8-sig'));manifest['groups']=[g for g in manifest['groups'] if g['group']=='WorldRewards']
  (tools/'unity-owned-tables.json').write_text(json.dumps(manifest),encoding='utf-8')
  for rel in ['unityserver/sql/sqlite/001_initial_schema.sql','unitydata/export/server/authoritative/json/reward.json','unityserver/config/xml/skill_basic.xml','unityserver/config/xml/zhenfa_config.xml']:self.cp(rel)
  # Reference-only reduced fixture: two actual main stages and one actual stage
  # from each other chapter type. No combat or new balancing values.
  _,_,chapters=read(self.root/'unitydata/excel/bigmap.xlsx')
  kinds={int(r['A']):int(r['B']) for n,r in chapters.items() if n>=5 and r.get('A')}
  _,_,maps=read(self.root/'unitydata/excel/maplist.xlsx')
  keep=set(range(10001,10007));seen=set()
  for n,r in maps.items():
   if n<5 or not r.get('A'):continue
   kind=kinds[int(r['B'])]
   if kind!=1 and kind not in seen:keep.add(int(r['A']));seen.add(kind)
  trim(self.root/'unitydata/excel/maplist.xlsx',keep);self.mapCount=len(keep)
  trim(self.root/'unitydata/excel/bigmap.xlsx',{int(r['B']) for n,r in maps.items() if n>=5 and r.get('A') and int(r['A']) in keep})
  trim(self.root/'unitydata/excel/fight_config.xlsx',set(range(22001,22007)))
  _,_,fights=read(self.root/'unitydata/excel/fight_config.xlsx')
  enemies={int(r[k]) for n,r in fights.items() if n>=5 for k in ['G','H','I','J','K','L'] if r.get(k) and int(r[k])}
  trim(self.root/'unitydata/excel/monster_boss_basic.xlsx',enemies)
  self.battleMonsterIds=enemies
  for name in ['reward','maplist','fight_config','monster_boss_basic','bigmap']:(self.root/f'unitydata/excel/{name}.fixture.xlsx').write_bytes((self.root/f'unitydata/excel/{name}.xlsx').read_bytes())
  for rel in OUT:
   p=self.root/rel;p.parent.mkdir(parents=True,exist_ok=True);p.write_text('sentinel',encoding='utf-8')
 def cp(self,rel):
  p=self.root/rel;p.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(ROOT/rel,p)
 def restore(self,name):
  p=self.root/f'unitydata/excel/{name}.xlsx';p.write_bytes(p.with_name(name+'.fixture.xlsx').read_bytes())
 def run_export(self,mode='Server',apply=False,entry='Export-UnityOwnedTables.ps1',validate=False):
  p=self.root/'unitydata/tools'/entry;cmd=f"& '{p}' -Root '{self.root}'"
  if entry=='Export-UnityOwnedTables.ps1':cmd+=f" -Group WorldRewards -Mode {mode} -ApplyRuntime:$"+str(apply).lower()+(' -ValidateOnly' if validate else '')
  elif entry=='Export-UnityServerData.ps1':cmd+=' -ApplyGeneratedJson'
  return subprocess.run(['pwsh.exe','-NoProfile','-Command',cmd],capture_output=True,text=True,encoding='utf-8',errors='replace',timeout=150)
 def ok(self,p):self.assertEqual(p.returncode,0,p.stdout+'\n'+p.stderr)
 def hashes(self):return {n:hashlib.sha256((self.root/n).read_bytes()).hexdigest() for n in OUT}
 def rows(self):return json.loads((self.root/OUT[0]).read_text(encoding='utf-8'))
 def test_formal_generated_and_compatibility(self):
  before=self.hashes();self.ok(self.run_export());r=self.rows()
  self.assertEqual(len(r),1735);self.assertTrue(all(x['reward'] for x in r))
  self.assertEqual([x for x in r if x['rewardid']==1010001],[{'rewardid':1010001,'drop_type':1,'reward':[[60000,0,1000],[60006,0,100]],'weight':0}])
  maps=json.loads((self.root/OUT[1]).read_text(encoding='utf-8'));self.assertEqual(len(maps),self.mapCount)
  for x in maps:self.assertFalse({'first_reward','add_reward','money','exp_pet','AttackCount'}&x.keys())
  for n in OUT:
   if n not in OUT[:4]+OUT[14:16]:self.assertEqual(before[n],self.hashes()[n])
  chapter=json.loads((self.root/OUT[14]).read_text(encoding='utf-8'))[0]
  self.assertEqual(chapter['boss_reward'],20013);self.assertNotIn('star_reward',chapter)
 def test_range_and_formal_group_replaces_compatibility_whole_group(self):
  patch(self.root/'unitydata/excel/reward.xlsx','C121','[60000,0,10,100]')
  p=self.root/'unitydata/export/server/authoritative/json/reward.json';r=json.loads(p.read_text(encoding='utf-8-sig'))
  r.append({'rewardid':1010001,'reward':[[611,0,999]],'weight':999});p.write_text(json.dumps(r),encoding='utf-8')
  self.ok(self.run_export());first=[x for x in self.rows() if x['rewardid']==1010001]
  self.assertEqual(len(first),1);self.assertEqual(first[0]['reward'],[[60000,0,10,100]])
 def test_invalid_inputs_never_write_outputs(self):
  for book,addr,value in [('reward','C121',''),('reward','C121','[60000,0,100,10]'),('reward','C121','[60000,0,1.5]'),('reward','B121','0'),('reward','D15','0'),('maplist','J5','2140000000')]:
   with self.subTest(book=book,cell=addr,value=value):
    self.restore('reward');self.restore('maplist')
    patch(self.root/f'unitydata/excel/{book}.xlsx',addr,value)
    before=self.hashes();p=self.run_export();self.assertNotEqual(p.returncode,0,p.stdout);self.assertEqual(before,self.hashes())
 def test_integer_formulas_recompute_reject_unsupported_and_cycles(self):
  p=self.root/'unitydata/excel/reward.xlsx';patch(p,'A71',formula='A65+10',cached=1999999999)
  self.ok(self.run_export());self.assertNotIn(1999999999,{x['rewardid'] for x in self.rows()})
  for formula in ['SUM(A65:A66)','A71']:
   patch(p,'A71',formula=formula,cached=80501)
   before=self.hashes();bad=self.run_export();self.assertNotEqual(bad.returncode,0);self.assertEqual(before,self.hashes())
 def test_runtime_scope_and_projection_match(self):
  self.ok(self.run_export(mode='Both',apply=True))
  for a,b in [(0,4),(1,5),(2,6),(3,7),(8,11),(9,12),(10,13),(14,16),(15,17),(18,20),(19,21)]:self.assertEqual((self.root/OUT[a]).read_bytes(),(self.root/OUT[b]).read_bytes())
  fights=json.loads((self.root/OUT[2]).read_text(encoding='utf-8'));self.assertEqual({r['id'] for r in fights},set(range(22001,22007)))
  client=(self.root/OUT[9]).read_text(encoding='utf-8')
  for f in fights:self.assertIn('id = '+str(f['id'])+',show = '+str(f['show']),client)
  self.ok(self.run_export(mode='Both',apply=True,validate=True))
 def test_final_boss_package_contract_rejects_bad_source_without_writes(self):
  for book,cell,value in [('bigmap','H5',0),('bigmap','H5',2140000000),('bigmap','H5','[18,20013]'),('maplist','E5',3),('maplist','E10',1)]:
   with self.subTest(book=book,cell=cell):
    self.restore('bigmap');self.restore('maplist');patch(self.root/f'unitydata/excel/{book}.xlsx',cell,value)
    before=self.hashes();self.assertNotEqual(self.run_export(mode='Both',apply=True).returncode,0);self.assertEqual(before,self.hashes())
 def test_missing_main_refs_block_all_entrypoints(self):
  patch(self.root/'unitydata/excel/maplist.xlsx','F5',2140000000)
  for entry in ['Export-UnityOwnedTables.ps1','Export-UnityServerData.ps1','Export-UnityClientData.ps1']:
   before=self.hashes();p=self.run_export(mode='Both',apply=True,entry=entry)
   self.assertNotEqual(p.returncode,0);self.assertIn('World runtime sync blocked',p.stdout+p.stderr);self.assertEqual(before,self.hashes())
 def test_missing_main_monster_blocks_runtime(self):
  trim(self.root/'unitydata/excel/monster_boss_basic.xlsx',self.battleMonsterIds-{100011})
  before=self.hashes();p=self.run_export(mode='Both',apply=True)
  self.assertNotEqual(p.returncode,0);self.assertIn('monsterIDs=1',p.stdout+p.stderr);self.assertEqual(before,self.hashes())
 def test_monster_shared_string_formula_recomputed(self):
  p=self.root/'unitydata/excel/monster_boss_basic.xlsx';parts,x,rows=read(p)
  targets=[(n,r) for n,r in rows.items() if n>=5][:2]
  base=targets[0][0]
  for i,(n,r) in enumerate(targets):
   c=next(c for c in x.findall('s:sheetData/s:row/s:c',NS) if c.get('r')=='J'+str(n))
   for child in list(c):c.remove(child)
   c.attrib.pop('t',None)
   f=E.SubElement(c,'{'+NS['s']+'}f',{'t':'shared','si':'777'})
   if i==0:f.text=f'"["&(A{base}*0+451)&",1]"';f.set('ref',f'J{base}:J{targets[1][0]}')
   E.SubElement(c,'{'+NS['s']+'}v').text='[199999,1]'
  save(p,parts,x);self.ok(self.run_export())
  monsters=json.loads((self.root/OUT[3]).read_text(encoding='utf-8'))
  for _,r in targets:self.assertEqual(next(m for m in monsters if m['id']==int(r['A']))['skill_basic'],[[451,1]])
if __name__=='__main__':unittest.main(verbosity=2,failfast=True)
