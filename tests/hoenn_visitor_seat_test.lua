local enabled=true
package.loaded['src.render.Pipelines']={level=function()return 1 end}
local geom=assert(loadfile('lib/KantoSeatGeometry.lua')){}
local mods={KantoSeatGeometry=geom,VoxelItems={setting={get=function()return true end}},VoxelFurniture={
 enabled=function()return true end,find=function()return{{kind='arcade_chair_left',tx=6,ty=8,claimed=true}}end}}
local V={require=function(n)return assert(mods[n],n)end,mod={exports={},options={get=function(_,k)return k=='apo_actor_voxel_grid'and 'off'or enabled end}}}
local seats=assert(loadfile('lib/WorldSeats.lua'))(V)
local sprite={def={ascendantRole='hoenn-visitor',ascendantAtlasImage='assets/characters/npcs/hoenn-visitor-kasc-hd-4x3-walk-sheet-v1.png'}}
local npc={sprite=sprite,def={index=17,name='KA_HOENN_VISITOR'},cellX=3,cellY=4,px=48,py=64}
local world={map={id='VIRIDIAN_NICKNAME_HOUSE',def={}},npcs={npc},player={px=16,py=64}}
local game={overworld=world};local record={sprite=sprite}
love={graphics={}}
local mod={worldSeats=seats,options={get=function(_,k)if k=='actor_voxel_grid'then return'off'elseif k=='hd_walking_sprites'then return enabled end end}}
seats.viewRow=function(row)return row end
local api=assert(loadfile('integrated/ascendant_pokemon_overworld/src/human_johto_seat.lua'))().new{mod=mod,generation=1,profiles={byGeneration={[1]={}}},voxel={}}
assert(seats.visitorProfile(world,record).index==17,'dynamic index lost')
local profile=assert(api:pose(game,record,nil,1));assert(profile.contact and profile.alwaysSeated,'no chair contact')
npc.moving=true;assert(not api:pose(game,record,nil,2));npc.moving=false
npc.cellX=2;npc.px=32;assert(not api:pose(game,record,nil,3),'floor fallback incorrectly seated');npc.cellX=3;npc.px=48
sprite.def.ascendantAtlasImage='assets/characters/npcs/unrelated.png';assert(not api:pose(game,record,nil,4),'wrong atlas admitted')
sprite.def.ascendantAtlasImage='assets/characters/npcs/hoenn-visitor-kasc-hd-4x3-walk-sheet-v1.png'
npc.def.name='RESIDENT';assert(not api:pose(game,record,nil,5),'resident changed');npc.def.name='KA_HOENN_VISITOR'
enabled=false;assert(not api:pose(game,record,nil,6),'HD off ignored')
print('PASS runtime visitor seat: chair, dynamic index, actor/source ownership, movement, floor and OFF fallback')
