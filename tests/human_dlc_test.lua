local root='mods/VASC';local addon;local reads=0
local files={['people.png']='voxel.png',['trainer.png']=false}
local Assets={resolve=function(path)return path end,image=function(path)return {path=Assets and path or path}end}
package.loaded['src.render.Assets']=Assets
local mod={path=root,exports={},find=function()return addon end,assets={path=function(_,p)return root..'/'..p end,image=function(_,p)return p end},
 read=function(_,p)reads=reads+1;if p=='lib/HumanDlcAssets.lua'then return "return {['people.png']='voxel.png',['trainer.png']=false}"end;return 'base:'..p end,
 info=function(_,p)return {type='file',path=p}end}
local api=assert(loadfile('lib/HumanDlc.lua'))().install(mod)
assert(not api.available());assert(api.style('hd')=='voxel');assert(api.style('cobble')=='cobble')
assert(mod:read('people.png')=='base:voxel.png');assert(mod:read('trainer.png')==nil)
assert(Assets.resolve(root..'/people.png')==root..'/voxel.png')
assert(Assets.resolve('mods/OTHER/people.png')=='mods/OTHER/people.png')
assert(not api.has('trainer.png'));assert(api.has('people.png'))
addon={exports={humanArt={schema='ascendant.human-art/v1',path=function(p)return 'mods/DLC/'..p end,read=function(p)return 'HD:'..p end,info=function(p)return{path=p}end}}}
assert(api.available()and api.style('hd')=='hd');assert(mod:read('trainer.png')=='HD:trainer.png')
assert(mod.assets:path('people.png')=='mods/DLC/people.png')
assert(Assets.resolve(root..'/people.png')=='mods/DLC/people.png')
addon=nil;assert(api.style('hd')=='voxel' and not api.has('trainer.png'))
assert(Assets.resolve(root..'/people.png')==root..'/voxel.png')
print('PASS human DLC absent/present/removed; scoped paths, saved HD fallback')
