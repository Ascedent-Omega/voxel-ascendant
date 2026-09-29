local root=assert(arg[1]);local child=root..'/integrated/ascendant_pokemon_overworld'
package.loaded['src.core.Game']={};package.loaded['src.script.Commands']={}
package.loaded['src.render.SpriteRenderer']={new=function(def)return{def=def}end}
local mod={path=child,options={get=function()return 'hd'end}}
function mod:read(p)local f=assert(io.open(child..'/'..p,'rb'));local s=f:read('*a');f:close();return s end
local catalog=assert(loadfile(child..'/src/npc_catalog.lua'))().public(mod)
local binder=assert(loadfile(child..'/src/walking_sprites.lua'))().new{
  mod=mod,generation=1,compat={characterSources=function()return{}end},npcCatalog=catalog}
local function npc(x,y)return{def={sprite='SPRITE_MIDDLE_AGED_MAN',x=x,y=y,name='CINNABARGYM_BLAINE',trainerClass='OPP_BLAINE'}}end
local old,role=binder:_npcVisual('CINNABAR_GYM',npc(3,3),true)
local moved,newRole=binder:_npcVisual('KA_BLAINE_VOLCANO_GYM',npc(24,10),true)
assert(old and old:find('/blaine%-')and moved==old and newRole==role,'Blaine artwork follows the leader')
assert(not binder:_rowFor('KA_BLAINE_VOLCANO_GYM',npc(3,3)),'old position is not a new-map identity')
print('PASS Blaine native and relocated VASC identity')
