-- Fixed, native Kanto seats. Sitting is transient; scripts, saves,
-- NPC dialogue and the slot machines retain their engine-owned behavior.
local V=...
local M={}
local active
local facings={[0]='down',[1]='left',[2]='up',[3]='right'}
local rows={down=0,left=1,up=2,right=3}
local function enabled(world)
 return world and world.map and (not world.map.def or world.map.def.generation~=2)
  and (require('src.render.Pipelines').level('voxel')or 0)>0
  and V.require('VoxelItems').setting:get()
  and V.mod.options:get('apo_hd_walking_sprites')~=false
  and (V.mod.options:get('apo_actor_voxel_grid')or 'off')=='off'
end
function M.viewRow(row,x,z)
 local fp=V.require('FirstPerson')
 if fp.cardBlend()>.5 then return rows[fp.apparentFacing(facings[row],x,z)]end
 return row
end
-- The support planes follow the actual furniture, including seats embedded
-- in a desk or the roof terrace. They never infer seats from arbitrary tiles.
local specs=V.require('KantoSeatGeometry').specs
M.specs=specs
local function at(world,x,y,requireEnabled)
 if not world or not world.map or (world.map.def and world.map.def.generation==2)then return end
 if requireEnabled and not enabled(world)then return end
 local F=V.require('VoxelFurniture')
 for _,p in ipairs(F.find(world.map))do
  if (p.claimed or (not requireEnabled and p.claimed~=false)) and F.enabled(p)then
   local s=specs[p.kind]
   if s and p.tx*8+(s[6]or 0)==x*16 and p.ty*8+(s[7]or 0)==y*16 then return p,p.seatRow or s[1],s end
   if p.kind=='celadon_mart_terrace' then
    for _,tableAt in ipairs{{4,2},{8,4}}do
     for _,sx in ipairs{tableAt[1]-1,tableAt[1]+2}do for dy=0,1 do
      if x==sx and y==tableAt[2]+dy then
       local row=sx<tableAt[1]and 3 or 1
       local s=specs.terrace_stool;return p,row,{row,s[2],s[3],s[4],s[5]}
      end
     end end
    end
   end
  end
 end
end
function M.chairAt(world,x,y)return at(world,x,y,true)end
function M.blocked(world,x,y)return enabled(world)and at(world,x,y,false)~=nil end
local profileCache=setmetatable({},{__mode='k'})
function M.npcProfile(world,profile)
 local _,row,s=at(world,profile.cellX,profile.cellY,false)
 if not s then return profile end
 if s[5]==0 then row=profile.row end
 local cached=profileCache[profile]
 if not cached or cached.map~=world.map then
  local p={};for k,v in pairs(profile)do p[k]=v end
  p.row=row;p.contact={height=s[2],front=s[3],back=s[4],backTop=s[5]}
  p.sign=row==1 and -1 or 1;p.bendSign=row==1 and -1 or row==3 and 1 or 0
  p.legDepth=row==2 and -1 or row==0 and 1 or 0
  cached={map=world.map,profile=p};profileCache[profile]=cached
 end
 return cached.profile
end
-- Runtime visitor indices are allocated by the engine. Bind only her exact
-- identity on a real chair; floor fallback positions must stay standing.
local visitorProfiles=setmetatable({},{__mode='k'})
function M.visitorProfile(world,record)
 if not enabled(world) or world.map.id~='VIRIDIAN_NICKNAME_HOUSE' then return end
 local sprite=record and ((record.spriteRef and record.spriteRef[1])or record.sprite)
 for _,actor in pairs(world.npcs or{})do
  if actor.sprite==sprite and actor.def and actor.def.name=='KA_HOENN_VISITOR' then
   local _,row,s=M.chairAt(world,actor.cellX,actor.cellY)
   if not s then return end
   local p=visitorProfiles[actor]
   if not p or p.cellX~=actor.cellX or p.cellY~=actor.cellY or p.index~=actor.def.index then
    p={generation=1,alwaysSeated=true,mapId=world.map.id,index=actor.def.index,
     role='hoenn-visitor',path='assets/characters/npcs/hoenn-visitor-kasc-hd-4x3-walk-sheet-v1.png',
     cellX=actor.cellX,cellY=actor.cellY,px=actor.cellX*16,py=actor.cellY*16,row=row,
     sign=row==1 and -1 or 1,bendSign=row==1 and -1 or row==3 and 1 or 0,
     headFade={90,116},headCut={101,121},frontOffset=0,offsetY=-10}
    visitorProfiles[actor]=p
   end
   return p
  end
 end
end
function M.current(world)
 return active and active.world==world and active.map==world.map and active.player==world.player and active or nil
end
local function clear()active=nil;V.require('FreeMove').drop()end
local function place(p,x,y,facing)
 V.require('FreeMove').drop()
 p.cellX,p.cellY,p.px,p.py=x,y,x*16,y*16
 p.facing=facing;p.moving=false;p.progress=0;p.turnTimer=0
end
local function free(world,x,y)
 return world.map:isWalkableCell(x,y) and not world:npcAtCell(x,y)
  and not world.map:warpAtCell(x,y) and not at(world,x,y,false)
end
function M.stand(world)
 local s=M.current(world);if not s then return false end
 -- Leave arcade rows through the aisle behind the seat, never along the
 -- neighbouring stools. A valid original approach remains a fallback.
 local behind=({[0]={0,-1},[1]={1,0},[2]={0,1},[3]={-1,0}})[s.row]
 local exits={{s.seatX+behind[1],s.seatY+behind[2]},{s.x,s.y}}
 for _,v in ipairs{{0,1},{-1,0},{0,-1},{1,0}}do exits[#exits+1]={s.seatX+v[1],s.seatY+v[2]}end
 for _,xy in ipairs(exits)do
  if (xy[1]~=s.seatX or xy[2]~=s.seatY) and free(world,xy[1],xy[2])then
   place(world.player,xy[1],xy[2],s.facing);clear();world:refreshStandingOnWarp();return true
  end
 end
 return false -- never displace another actor when every exit is occupied
end
function M.sit(world,x,y)
 local p=world.player
 if M.current(world)or not enabled(world)or p.moving or p.inputLocked or p.scriptedMoving
  or p.surfing or p.onBike or #(world.scriptMoves or{})>0
  or (world.runner and world.runner:isRunning()) then return false end
 local chair,row,spec=M.chairAt(world,x,y)
 if not chair or world:npcAtCell(x,y) or math.abs(p.cellX-x)+math.abs(p.cellY-y)>1 then return false end
 active={world=world,map=world.map,player=p,x=p.cellX,y=p.cellY,facing=p.facing,seatX=x,seatY=y,row=row,contact={height=spec[2],front=spec[3],back=spec[4],backTop=spec[5]}}
 place(p,x,y,facings[row]);world:refreshStandingOnWarp()
 local fp=V.require('FirstPerson')
 if fp.engaged()then
  local yaw=({[0]=0,[1]=-math.pi/2,[2]=math.pi,[3]=math.pi/2})[row]
  fp.lookBy(yaw-fp.yaw,(row==0 and 0 or -.55)-fp.pitch)
 end
 V.require('ShortcutToast').notify('Sitzplatz',world.map.id=='GAME_CORNER' and 'A: Automat · Bewegung/B: aufstehen' or 'Bewegung/B: aufstehen')
 return true
end
function M.playerProfile(game,record)
 local world=game and game.overworld;local s=world and M.current(world)
 local sprite=record and ((record.spriteRef and record.spriteRef[1])or record.sprite)
 if not s or sprite~=world.player.sprite then return end
 local def=sprite.def
 if def.ascendantCharacterAction then return end
 if not s.profile or s.profile.role~=def.ascendantRole then
  s.profile={generation=1,alwaysSeated=true,mapId=world.map.id,index=0,row=s.row,contact=s.contact,
   role=def.ascendantRole,px=s.seatX*16,py=s.seatY*16,cellX=s.seatX,cellY=s.seatY,
   sign=s.row==1 and -1 or 1,bendSign=s.row==1 and -1 or s.row==3 and 1 or 0,
   headFade={90,116},headCut={101,121},frontOffset=0,offsetY=-10}
 end
 return s.profile
end
function M.cameraOffset()
 local game=require('src.core.Game');local s=game.overworld and M.current(game.overworld)
 return s and s.contact.height-15 or 0
end
-- Native minigames/saves may return to the chair cell without our transient
-- sitting record. Restore input ownership there before free movement can try
-- to squeeze through the neighbouring blocked chair cells.
local function recover(world)
 if M.current(world)or not enabled(world)then return end
 local p=world.player
 if not p or p.moving or p.inputLocked or p.scriptedMoving or p.surfing or p.onBike
  or #(world.scriptMoves or{})>0 or(world.runner and world.runner:isRunning())then return end
 local chair,row,spec=M.chairAt(world,p.cellX,p.cellY)
 if not chair then return end
 active={world=world,map=world.map,player=p,x=p.cellX,y=p.cellY,facing=p.facing,
  seatX=p.cellX,seatY=p.cellY,row=row,
  contact={height=spec[2],front=spec[3],back=spec[4],backTop=spec[5]}}
 V.require('FreeMove').drop()
end
function M.update(game)
 if not active then return end
 local world=game and game.overworld
 if not world or not M.current(world)then clear();return end
 local p=world.player
 if p.cellX~=active.seatX or p.cellY~=active.seatY then clear();return end
 -- Dialogue/minigames own the player until they return. Moving the player
 -- here used to discard sitting state during slot-machine interactions.
 if p.moving or p.inputLocked or p.scriptedMoving or #(world.scriptMoves or{})>0
  or(world.runner and world.runner:isRunning())then return end
 if not enabled(world)or p.onBike or p.surfing then
  if not M.stand(world)then clear()end
 end
end
function M.install()
 local OW=require('src.world.OverworldController')
 if OW._vascWorldSeats then return end
 local interact,input=OW.interact,OW.handleInput
 function OW:interact(...)
  if not M.current(self)then
   local x,y=self.player:facingCell()
   -- Exact NPC ownership always wins; an occupied chair is a conversation.
   if not self:npcAtCell(x,y)and (M.sit(self,x,y)or M.sit(self,self.player.cellX,self.player.cellY))then return end
  end
  return interact(self,...)
 end
 function OW:handleInput(...)
  recover(self)
  if M.current(self)then
   local keys=require('src.core.Game').input
   for _,dir in ipairs{'up','down','left','right'}do
    if keys:isDown(dir)or keys:wasPressed(dir)then M.stand(self);return end
   end
   if keys:wasPressed('b')then M.stand(self);return end
   if keys:wasPressed('a')then return interact(self)end
   if keys:wasPressed('start')then if not M.stand(self)then return end
   else return end
  end
  return input(self,...)
 end
 local Collision=require('src.world.Collision');local canMove=Collision.canMove
 function Collision.canMove(map,entities,mover,dir)
  local world=require('src.core.Game').overworld
  if world and world.map==map and world.player==mover and not mover.scriptedMoving and not mover.inputLocked then
   local x,y=Collision.target(mover.cellX,mover.cellY,dir)
   if M.blocked(world,x,y)then return false,'tile' end
  end
  return canMove(map,entities,mover,dir)
 end
 OW._vascWorldSeats=true
end
V.mod.exports.worldSeats=M
return M
