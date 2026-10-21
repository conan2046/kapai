"""Formal 68-affix source, Chinese labels, cleanup and export rejection coverage."""
from pathlib import Path
import json,shutil,subprocess,unittest,uuid
from test_unity_owned_tables import patch_cell,workbook_rows
ROOT=Path(__file__).resolve().parents[3]
EXPORTER=ROOT/'unitydata/tools/Export-UnityOwnedTables.ps1'
BOOKS=['hero_combat.xlsx','fabao.xlsx','suit.xlsx','equipment_combat.xlsx']
class EquipmentMaintenanceTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.fixture=ROOT/'.local/gear-table-consolidation-20261020/tests'/uuid.uuid4().hex
        (cls.fixture/'unitydata/excel').mkdir(parents=True)
        for book in BOOKS:shutil.copy2(ROOT/'unitydata/excel'/book,cls.fixture/'unitydata/excel'/book)
        for folder in ['unityserver/config/json','unityserver/config/xml','unityserver/sql/sqlite']:shutil.copytree(ROOT/folder,cls.fixture/folder)
        cls.run_export()
        cls.outputs={p.relative_to(cls.fixture):p.read_bytes() for p in cls.fixture.rglob('*') if p.is_file() and p.suffix!='.xlsx'}
        cls.bookbytes={b:(ROOT/'unitydata/excel'/b).read_bytes() for b in BOOKS}
    @classmethod
    def run_export(cls,expected_error=None):
        run=subprocess.run(['pwsh.exe','-NoProfile','-File',str(EXPORTER),'-Root',str(cls.fixture),'-Group','HeroCombat','-Mode','Both'],capture_output=True,encoding='utf-8',errors='replace')
        output=run.stdout+run.stderr
        if expected_error is None:
            if run.returncode:raise AssertionError(output[-2500:])
        elif run.returncode==0 or expected_error not in output:raise AssertionError(output[-2500:])
    def reset(self):
        for book,content in self.bookbytes.items():(self.fixture/'unitydata/excel'/book).write_bytes(content)
        for rel,content in self.outputs.items():(self.fixture/rel).write_bytes(content)
    def setUp(self):self.reset()
    def current(self,name):return json.loads((self.fixture/f'unityserver/config/json/{name}.json').read_text(encoding='utf-8-sig'))
    def patch(self,address,value,sheet=1):patch_cell(self.fixture/'unitydata/excel/equipment_combat.xlsx',sheet,address,value)
    def unchanged(self):self.assertTrue(all((self.fixture/p).read_bytes()==v for p,v in self.outputs.items()))
    def test_01_complete_sources_and_cleanup(self):
        rows=workbook_rows(self.fixture/'unitydata/excel/equipment_combat.xlsx',1)
        self.assertEqual(len(rows),68);self.assertEqual(len(rows[0]),18)
        self.assertTrue(all(r['enabled']=='1' and r['config_status']=='已配置' for r in rows))
        self.assertTrue(all(len(json.loads(r['value1']))==3 and len(json.loads(r['value2']))==3 for r in rows))
        self.assertTrue(all('conflict_group' not in r and 'source_hero' not in r for r in rows))
        for name,count in [('equipment_affix',68),('combat_artifact',70),('combat_set',20),('combat_binding',118)]:
            self.assertEqual(len(self.current(name)),count)
            self.assertEqual(self.current(name),json.loads((ROOT/f'unityserver/config/json/{name}.json').read_text(encoding='utf-8-sig')))
        self.assertTrue(all('value1_type' not in r and 'conflict_group' not in r for r in self.current('equipment_affix')))
        self.assertEqual([r['id'] for r in self.current('equipment_affix')],list(range(1,69)))
    def test_02_type_explanations_do_not_change_runtime(self):
        self.patch('L53','仅改变维护说明');self.run_export();self.unchanged()
    def test_03_invalid_gate_and_duplicate_ids_reject_before_writes(self):
        for address,value,error in [('Q53','2','Invalid export gate'),('R53','待定数值','Unready row cannot be enabled'),('A53',1,'Duplicate gated identity'),('B53','SHIELD-01','Duplicate gated identity')]:
            with self.subTest(address=address):
                self.reset();self.patch(address,value);self.run_export(error);self.unchanged()
    def test_04_chinese_and_legacy_values_are_equivalent(self):
        self.patch('G5','shield_lost');self.patch('R5','ready');self.run_export();self.unchanged()
    def test_05_unknown_labels_and_duplicate_dictionary_reject(self):
        for address,value,error in [('G5','随意编造的触发','Unknown source label equipment_affix.event'),('R53','随便启用','Unknown source label equipment_affix.config_status')]:
            with self.subTest(address=address):
                self.reset();self.patch(address,value);self.run_export(error);self.unchanged()
        self.reset();self.patch('B55','同名事件',5);self.patch('B56','同名事件',5)
        self.run_export('Duplicate dictionary label equipment_affix.event');self.unchanged()
    def test_06_new_value_edit_reaches_both_clients_and_descriptions(self):
        self.patch('I53','[1,2,3]');self.run_export()
        self.assertEqual(self.current('equipment_affix')[48]['value1'],[1,2,3])
        self.assertIn('获得1战意',self.current('equipment_affix')[48]['combat_descriptions'][0])
        client=json.loads((self.fixture/'unityclient/Assets/Resources/ProjectXData/Configs/equipment_affix.json').read_text(encoding='utf-8-sig'))
        self.assertEqual(client,self.current('equipment_affix'))
    def test_07_three_tier_validation_rejects_before_writes(self):
        self.patch('I53','[1,2]');self.run_export('Invalid affix three-tier curve');self.unchanged()
if __name__=='__main__':unittest.main(verbosity=2)
