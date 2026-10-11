"""Verify the actual Unity build source graph and unchanged Cocos inputs."""
import hashlib
import json
import argparse
from pathlib import Path
import xml.etree.ElementTree as ET

root = Path(__file__).resolve().parents[2]
parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--cocos-baseline', type=Path, default=root / '.local/jingjie-rework/cocos-protected-baseline.json')
parser.add_argument('--prefab-baseline', type=Path, help='Explicit hash baseline for the current approved JingjieLayer layout.')
args = parser.parse_args()
build = root / '.local/unityserver-build/server-win'
source = (root / 'unityserver').resolve()
cache = (build / 'CMakeCache.txt').read_text(encoding='utf-8')
home = next(line.split('=', 1)[1] for line in cache.splitlines()
            if line.startswith('CMAKE_HOME_DIRECTORY:INTERNAL='))
assert Path(home).resolve() == source, f'Unexpected build source: {home}'
ns = {'ms': 'http://schemas.microsoft.com/developer/msbuild/2003'}
compiled = []
for project in ('kapai.vcxproj', 'kapai_database_smoke.vcxproj'):
    tree = ET.parse(build / project)
    for element in tree.findall('.//ms:ClCompile', ns):
        name = element.get('Include')
        if not name:
            continue
        path = (build / name).resolve()
        assert path.is_relative_to(source), f'Compiled input outside Unity source: {path}'
        assert path.is_file(), f'Missing compiled input: {path}'
        compiled.append(str(path.relative_to(root)))
    text = (build / project).read_text(encoding='utf-8-sig')
    if project == 'kapai.vcxproj':
        assert 'PROJECTX_UNITY_SERVER=1' in text, 'Unity target define is missing'
assert compiled, 'No compiled sources found'
baseline = json.loads(args.cocos_baseline.read_text(encoding='utf-8-sig')) if args.cocos_baseline.is_file() else {}
changed = [name for name, digest in baseline.items()
           if not (root / name).is_file()
           or hashlib.sha256((root / name).read_bytes()).hexdigest() != digest]
assert not changed, f'Protected Cocos files changed: {changed[:10]}'
prefab = root / 'unityclient/Assets/Prefabs/OneLevel/JingjieLayer.prefab'
prefab_unchanged = None
if args.prefab_baseline:
    digest = args.prefab_baseline.read_text(encoding='utf-8-sig').strip()
    assert hashlib.sha256(prefab.read_bytes()).hexdigest() == digest, 'Manual JingjieLayer changed'
    prefab_unchanged = True
report = {'sourceRoot': str(source), 'compiledSourceCount': len(compiled),
          'protectedCocosFileCount': len(baseline), 'changedCocosFiles': changed,
          'manualPrefabUnchanged': prefab_unchanged, 'compiledSources': compiled,
          'cocosBaselineChecked': bool(baseline), 'prefabBaselineChecked': bool(args.prefab_baseline)}
output = root / '.local/jingjie-rework/isolation-result.json'
output.parent.mkdir(parents=True, exist_ok=True)
output.write_text(
    json.dumps(report, indent=2), encoding='utf-8')
print(f'PASS: {len(compiled)} compiled inputs belong to Unity; '
      f'Cocos baseline checked={bool(baseline)} ({len(baseline)} files); '
      f'explicit current prefab baseline checked={bool(args.prefab_baseline)}.')
