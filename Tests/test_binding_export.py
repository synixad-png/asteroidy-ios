import importlib.util,json,pathlib,struct,sys
p=pathlib.Path(__file__).resolve().parents[1]
spec=importlib.util.spec_from_file_location('binding',p/'Tools/export_boreas_morph_binding.py')
m=importlib.util.module_from_spec(spec);spec.loader.exec_module(m)
a=p/'ASTEROIDYiOS/Assets'
zip_path=pathlib.Path('/mnt/data/files/Asteroidy_v556_ZRODLA_Windows_SteamOS_BEZ_EXE_BEZ_HANGARU.zip')
if not zip_path.exists(): raise SystemExit('requires original v556 ZIP')
expected=json.loads((a/'BoreasMorphBinding556.json').read_text())
actual=m.export(zip_path,a)
assert actual==expected
assert actual['firstVertex']==4320 and actual['vertexCount']==27035
print('PASS: authentic morph/static binding and reproducible converter')
