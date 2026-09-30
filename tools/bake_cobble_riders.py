#!/usr/bin/env python3
"""Bake bundled Biker/Cue Ball rigs with the existing Cobble bicycle rig.
Usage: python3 tools/bake_cobble_riders.py /path/to/love
Requires Pillow. Does not change gameplay definitions or walking artwork.
"""
import json, subprocess, sys, tempfile
from pathlib import Path
from PIL import Image
root=Path(__file__).resolve().parents[1]
assets=root/'integrated/cobble_characters/assets'
def lua(v):
    if isinstance(v,dict): return '{'+','.join('['+json.dumps(k)+']='+lua(x) for k,x in v.items())+'}'
    if isinstance(v,list): return '{'+','.join(map(lua,v))+'}'
    if isinstance(v,str): return json.dumps(v)
    if isinstance(v,bool): return str(v).lower()
    return str(v)
models={}
for role in ('biker','cue-ball'):
    bones=json.loads((assets/role/'model/model.geo.json').read_text())['minecraft:geometry'][0]['bones']
    palette=Image.open(assets/role/'model/palette.png').convert('RGB')
    for bone in bones:
        for cube in bone.get('cubes',[]):
            u,v=cube.pop('uv');cube['color']='%02x%02x%02x'%palette.getpixel((u+4,v+4))
    models[role]={'bones':bones,'colors':{'ink':'20212a','gray':'9babb3','red':'d64b42'}}
with tempfile.TemporaryDirectory(prefix='ascendant-riders-') as folder:
    job=Path(folder)
    (job/'models.lua').write_text('return '+lua(models))
    (job/'conf.lua').write_text("function love.conf(t)t.window.width=320;t.window.height=240;t.modules.audio=false end")
    (job/'main.lua').write_text('''function love.load()
 local root='''+lua(str(root))+'''
 local models=dofile(love.filesystem.getSource()..'/models.lua')
 local baker=dofile(root..'/integrated/cobble_characters/src/cube_baker.lua')
 local equipment=dofile(root..'/integrated/cobble_characters/src/field_equipment.lua')
 for role,model in pairs(models)do
  print('REFERENCE',role,baker.referenceHeight(model))
  model=equipment.add(model,'bicycle')
  for _,spec in ipairs{{'idle',1},{'walk',12},{'blink',4},{'preview',3}}do
   local data=baker.render(model,spec[2],spec[1],'bicycle')
   local png=data:encode('png');data:release()
   local file=assert(io.open(root..'/integrated/cobble_characters/assets/'..role..'/cobble/bicycle-'..spec[1]..'.png','wb'))
   file:write(png:getString());file:close();png:release()
  end
 end
 love.event.quit()
end
''')
    subprocess.run([sys.argv[1],str(job)],check=True)
