-- luajit tests/hoenn_visitor_visuals_test.lua /absolute/vasc/root
local root=assert(arg[1]);local child=root..'/integrated/ascendant_pokemon_overworld'
package.loaded['src.core.Game']={}
package.loaded['src.script.Commands']={}
package.loaded['src.render.SpriteRenderer']={new=function(def)return{def=def}end}
local W=assert(loadfile(child..'/src/walking_sprites.lua'))()
local checks=0
local function check(v,m)checks=checks+1;assert(v,m)end
local handlers,values={}, {hd_walking_sprites=true,human_art_style='hd'}
local mod={id='VOXEL_ASCENDANT',path=child,
 options={get=function(_,k)return values[k]end},
 events={on=function(_,name,fn)handlers[name]=fn end}}
function mod:read(path)local f=io.open(child..'/'..path,'rb');if not f then return end;local s=f:read('*a');f:close();return s end
function mod:info(path)local f=io.open(child..'/'..path,'rb');if f then f:close();return{type='file'}end end
local binder=W.new{mod=mod,generation=1,compat={characterSources=function()return{}end},npcCatalog={inventory=function()return{}end}}
local function npc(id,name)
 local def={id=id,image='native.png'}
 return{id=name,def={sprite=id,name=name},sprite={def=def},spriteDef=def,cellX=3,cellY=4,facing='left'}
end
local visitor=npc('SPRITE_KA_HOENN_VISITOR','KA_HOENN_VISITOR')
local resident=npc('SPRITE_LITTLE_GIRL','HOUSE_RESIDENT')
local original,residentOriginal=visitor.sprite,resident.sprite
local save={inventory={HOENN_HONEY=1,HOENN_DEX=1},party={{species='MUDKIP'}},modData={kanto_ascendant={bank={sealed=true}}}}
local game={save=save,overworld={map={id='VIRIDIAN_NICKNAME_HOUSE'},npcs={visitor,resident}}}
for round=1,3 do
 for _,style in ipairs({'hd','voxel','cobble'})do
  values.human_art_style=style;binder:apply(game)
  local def=visitor.sprite.def
  local folder=style=='hd'and'npcs'or style=='voxel'and'voxel-npcs'or'cobble-npcs'
  check(def.ascendantRole=='hoenn-visitor','identity '..style)
  check(def.ascendantAtlasImage:find('/'..folder..'/',1,true),'correct atlas '..style)
  check(def.image:find('/runtime/'..folder..'/',1,true),'correct native fallback '..style)
  check((def.voxelSpriteDemo==true)==(style=='voxel'),'voxel marker only on voxel art')
  check(def.frames==6 and def.frameWidth==16 and def.frameHeight==16,'native geometry')
  check(def.ascendantScaleClass=='human_adult','adult scale')
  check(visitor.cellX==3 and visitor.cellY==4 and visitor.facing=='left','live placement preserved')
  check(resident.sprite==residentOriginal,'resident never rebound')
 end
 values.hd_walking_sprites=false;binder:apply(game)
 check(visitor.sprite==original,'original Gen1 renderer restored')
 values.hd_walking_sprites=true
end
check(game.save==save and save.inventory.HOENN_HONEY==1 and save.party[1].species=='MUDKIP' and save.modData.kanto_ascendant.bank.sealed,'no gameplay writes')
-- Visitor returning while standing inside the house binds via the engine's
-- actual runtime-NPC event before it is appended to the live NPC array.
binder:install();values.human_art_style='cobble'
local later=npc('SPRITE_KA_HOENN_VISITOR','KA_HOENN_VISITOR_RETURN')
game.overworld.npcPool={[later.id]=later}
handlers['world.npc_spawned']{game=game,mapId=game.overworld.map.id,npcId=later.id,runtime=true}
check(later.sprite.def.ascendantRole=='hoenn-visitor','returning visitor bound without map reload')
check(later.sprite.def.ascendantAtlasImage:find('/cobble-npcs/',1,true),'return uses selected style')
local other=npc('SPRITE_GIRL','OTHER');check(not binder:_npcVisual(game.overworld.map.id,other,false),'shared female sprite untouched')
local gen2=W.new{mod=mod,generation=2,compat={characterSources=function()return{}end},npcCatalog={inventory=function()return{}end}}
check(not gen2:_npcVisual(game.overworld.map.id,later,false),'Gen2 unaffected')
-- Missing enhanced assets degrade to the valid HD atlas, never an absent PNG.
values.human_art_style='cobble';local info=mod.info
function mod:info(p)if p:find('cobble-npcs',1,true)then return nil end;return info(self,p)end
binder:apply(game)
check(visitor.sprite.def.ascendantAtlasImage:find('/characters/npcs/',1,true),'missing optional style keeps HD')
print('PASS Hoenn visitor style binding: '..checks..' checks')
