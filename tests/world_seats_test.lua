local level,blend,apparent=1,0,'down'
local player={cellX=3,cellY=11,px=48,py=176,facing='left'}
local occupied,walkable={},true
local world={player=player,map={id='GAME_CORNER',isWalkableCell=function()return walkable end,warpAtCell=function()end},
 refreshStandingOnWarp=function()end,npcAtCell=function(_,x,y)return occupied[x..':'..y]end}
local game={overworld=world}
package.loaded['src.core.Game']=game
package.loaded['src.render.Pipelines']={level=function()return level end}
local modules={VoxelItems={setting={get=function()return true end}},FreeMove={drop=function()end},
 FirstPerson={engaged=function()return false end,cardBlend=function()return blend end,apparentFacing=function()return apparent end},
 ShortcutToast={notify=function()end},VoxelFurniture={enabled=function()return true end,
 find=function()return{{kind='arcade_chair_left',tx=4,ty=22,claimed=true}}end}}
modules.KantoSeatGeometry=assert(loadfile('lib/KantoSeatGeometry.lua')){}
local exports={}
local M=assert(loadfile('lib/WorldSeats.lua')){require=function(n)return assert(modules[n],n)end,
 mod={exports=exports,options={get=function(_,key)return key=='apo_actor_voxel_grid'and 'off'or true end}}}
assert(M.viewRow(1,0,0)==1);blend=1
for name,row in pairs{down=0,left=1,up=2,right=3}do apparent=name;assert(M.viewRow(1,0,0)==row)end
blend=0;occupied['2:11']={};assert(not M.sit(world,2,11));occupied['2:11']=nil
player.inputLocked=true;assert(not M.sit(world,2,11));player.inputLocked=false
player.onBike=true;assert(not M.sit(world,2,11));player.onBike=false
world.runner={isRunning=function()return true end};assert(not M.sit(world,2,11));world.runner=nil
assert(not M.sit(world,2,13));assert(M.sit(world,2,11))
assert(player.cellX==2 and player.facing=='left'and M.cameraOffset()==-10)
walkable=false;assert(not M.stand(world)and M.current(world),'blocked exits should preserve sitting')
walkable=true;assert(M.stand(world)and player.cellX==3 and not M.current(world))
assert(M.sit(world,2,11));occupied['3:11']={};assert(M.stand(world))
assert(player.cellX~=3 or player.cellY~=11,'stand overlapped another actor');occupied={}
player.cellX,player.cellY,player.px,player.py=3,11,48,176
assert(M.sit(world,2,11));level=0;M.update(game);assert(not M.current(world)and player.cellX==3)
level=1
-- Ordinary movement cannot enter any seat, but NPC and scripted steps retain
-- their native ownership. A pressed-only direction also exits immediately.
local OW={interact=function()end,handleInput=function()end}
package.loaded['src.world.OverworldController']=OW
package.loaded['src.world.Collision']={target=function(x,y,dir)return x-1,y end,canMove=function()return true end}
game.input={isDown=function()return false end,wasPressed=function(_,key)return key=='left'end}
M.install()
assert(M.blocked(world,2,11))
assert(not package.loaded['src.world.Collision'].canMove(world.map,{},player,'left'))
local npc={cellX=3,cellY=11}
assert(package.loaded['src.world.Collision'].canMove(world.map,{},npc,'left'))
assert(M.sit(world,2,11));OW.handleInput(world)
assert(not M.current(world)and player.cellX==3,'pressed-only movement failed to stand')
-- Dialogues and minigames must not move the actor or discard its seat.
assert(M.sit(world,2,11));world.runner={isRunning=function()return true end}
M.update(game);assert(M.current(world)and player.cellX==2,'dialogue ejected seated actor')
world.runner=nil;player.inputLocked=true;M.update(game)
assert(M.current(world)and player.cellX==2,'locked minigame discarded seat')
player.inputLocked=false;assert(M.stand(world))
-- Reproduce a saved/minigame-return position on a stool with no active seat.
-- Every departure button uses the free aisle; no adjacent chair becomes walkable.
for _,key in ipairs{'up','down','left','right','b','start'}do
 player.cellX,player.cellY,player.px,player.py=2,11,32,176
 game.input.wasPressed=function(_,k)return k==key end
 OW.handleInput(world)
 assert(not M.current(world)and player.cellX==3 and player.cellY==11,'orphan stool trapped '..key)
 assert(M.blocked(world,2,11),'chair collision was disabled')
end
-- An occupied aisle is not a legal exit. Retry once the actor leaves.
player.cellX,player.cellY,player.px,player.py=2,11,32,176
occupied['3:11']={};occupied['1:11']={};occupied['2:10']={};occupied['2:12']={}
game.input.wasPressed=function(_,k)return k=='b'end;OW.handleInput(world)
assert(M.current(world)and player.cellX==2,'exit overlapped another actor')
occupied['3:11']=nil;OW.handleInput(world)
assert(not M.current(world)and player.cellX==3,'unblocked aisle did not recover');occupied={}
level=1;assert(M.sit(world,2,11));world.map={id='PALLET_TOWN'};M.update(game);assert(not M.current(world))
print('PASS fixed chair eligibility, occupancy, bounded distance, script/bike/lock gates, blocked exits, mode/map cleanup')

love={graphics={}}
local data=assert(loadfile('integrated/ascendant_pokemon_overworld/src/human_seat_profiles.lua'))()
local profile=data.byGeneration[1].GAME_CORNER[1]
local def={ascendantAtlasImage="mods/test/"..profile.path,ascendantRole=profile.role}
local sprite={def=def}
local actor={sprite=sprite,def={index=profile.index},cellX=profile.cellX,cellY=profile.cellY,px=profile.px,py=profile.py}
world={map={id='GAME_CORNER'},npcs={actor},player={px=profile.px+16,py=profile.py},talkNpc=actor};game.overworld=world
local view=1
local mod={options={get=function(_,key)
 if key=='actor_voxel_grid'then return'off'elseif key=='card_animation_mode'then return'natural'end;return true
end},worldSeats={viewRow=function()return view end,playerProfile=function()end}}
local seat=assert(loadfile('integrated/ascendant_pokemon_overworld/src/human_johto_seat.lua'))().new{
 mod=mod,generation=1,voxel={},profiles=data}
local record={sprite=sprite}
for row=0,3 do view=row;local p,look=seat:pose(game,record,{},row)
 assert(p.row==row and look==0,'rear visitor rotated head or wrong camera-relative view')
 assert(profile.row==1,'camera mutated world seat direction')
end
world.player.px=profile.px-16
local p,look
for i=1,100 do p,look=seat:pose(game,record,{},i+4)end
assert(look>.99 and p.row==3,'front-side conversation did not engage')
world.player.px=profile.px+16
for i=1,100 do p,look=seat:pose(game,record,{},i+104)end
assert(look==0,'head tracked player behind chair')
actor.moving=true;assert(not seat:pose(game,record,nil,210));actor.moving=false
actor.cellX=actor.cellX+1;assert(not seat:pose(game,record,nil,211))
print('PASS all four seated views, immutable world facing, rear head-turn exclusion and moving/displaced NPC ownership')
