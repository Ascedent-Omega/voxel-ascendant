-- Keep native binocular dialogue/quest hooks, then look at the actual world.
local V=...
local M={};local pending,active,camera
local function enabled(world)
 return world and V.require('Gen1Rooftops').gate(world.map)
  and (require('src.render.Pipelines').level('voxel')or 0)>0
end
function M.current()return active end
-- Resolve only the named, static subject of the native Route 12 dialogue.
-- No outdoor controller, NPC update loop, encounters or scripts are started.
function M.subject(map,sign,bx,by)
 if map.id~='ROUTE_12_GATE_2F'or sign.text~='TEXT_ROUTE12GATE2F_LEFT_BINOCULARS'then return end
 local game=require('src.core.Game');local data=game.data
 local source=data and data.maps and data.maps.ROUTE_12
 if not source or not V.require('Gen1Rooftops').gate(map)then return end
 local city=require('src.world.Map').new(source,data.tilesets[source.tileset])
 local entry={map=map,w=map.def.width*32,h=map.def.height*32}
 local world=V.require('RooftopWorld')
 local anchor=world.anchor(entry,V.require('VoxelFurniture').findBuildings(city),V.require('VoxelItems').models)
 if not anchor then return end
 local eye={bx*16+8,35,by*16+12};local best,dist
 for _,obj in ipairs(source.objects or{})do
  if obj.trainerClass=='OPP_FISHER'and obj.movement=='STAY'and data.sprites[obj.sprite]then
   local x,y,z=world.point(anchor,obj.x*16+8,0,obj.y*16+8)
   local distance=(x-eye[1])^2+(z-eye[3])^2
   if distance>=1 and(not dist or distance<dist)then best={object=obj,x=x,y=y,z=z,anchor=anchor};dist=distance end
  end
 end
 if not best then return end
 local obj=best.object
 best.sprite=require('src.render.SpriteRenderer').new(data.sprites[obj.sprite],'ROUTE_12_obj_'..obj.index)
 local api=V.mod.exports.overworldPokemon
 local walking=api and api.walkingSprites
 if walking and walking.scenerySprite then best.sprite=walking.scenerySprite('ROUTE_12',obj,best.sprite)end
 best.map=city;best.eye=eye
 best.yaw=math.atan2(best.x-eye[1],-(best.z-eye[3]))
 best.slope=(best.y+9-eye[2])/math.sqrt(dist)
 local facing=({DOWN='down',UP='up',LEFT='left',RIGHT='right'})[obj.range]or 'down'
 if anchor.halfTurn then facing=({down='up',up='down',left='right',right='left'})[facing]end
 best.facing=facing
 return best
end
function M.poses(state,spriteColors)
 local s=active;local subject=s and s.subject
 if not subject or state.map~=s.map then return end
 return {{sprite=subject.sprite,px=subject.x-8,py=subject.z-8,
  gh=subject.y,lift=0,facing=subject.facing,phase=0,flip=false,
  colors=spriteColors(subject.map),mapId=subject.map.id}}
end
function M.close(keepLock)
 if active then
  if not keepLock then active.player.inputLocked=active.locked end
  V.require('FreeMove').drop()
 end
 if camera and V.require('Voxel3D').camera==camera then V.require('Voxel3D').camera=nil end
 camera=nil;active=nil;pending=nil
end
function M.update(dt,game)
 M.dt=math.min(dt or 1/60,.05)
 local s=active or pending;if not s then return end
 local world=game.overworld
 if world~=s.world or world.map~=s.map or world.player~=s.player or not enabled(world)then M.close();return end
 if active then
  if world.runner and world.runner:isRunning()then M.close(true);return end
  if game.stack:top()~=world or world.player.cellX~=s.x or world.player.cellY~=s.y then M.close()end
 elseif game.stack:top()==world and not world.player.inputLocked and not(world.runner and world.runner:isRunning())then
  active=pending;pending=nil;active.locked=world.player.inputLocked
  world.player.inputLocked=true;V.require('FreeMove').drop()
 end
end
function M.frame(state,cx,cz)
 local s=active;if not s or state.map~=s.map then return end
 local eye=s.subject and s.subject.eye or {s.bx*16+8,32,s.by*16+12}
 local dx,dz=math.sin(s.yaw),-math.cos(s.yaw)
 local rig={eye=eye,focus={eye[1]+dx*200,eye[2]+(s.slope or -.04)*200,eye[3]+dz*200},up={0,1,0},fov=2*math.atan(math.tan(.9/2)/s.zoom),near=.3,far=10000}
 camera=rig;V.require('Voxel3D').camera=rig
 return rig,eye[1],eye[3]
end
-- Work in presentation pixels, independently of the world's adaptive scale.
local helpFont,helpFontSize
function M.helpLayout(w,h,font,zoom)
 local locale=V.require('SetupLocale')
 local title=locale.text('BINOCULARS','FERNGLAS')..string.format('  %.1fx',zoom or 1)
 local hints={locale.text('Up / Down: zoom','Hoch / Runter: Zoom'),
  locale.text('Left / Right: look around','Links / Rechts: Blick drehen'),
  locale.text('A / B: close','A / B: Beenden')}
 local pad=math.max(8,math.floor(math.min(w,h)*.02))
 local width=math.max(1,w-pad*4);local lines={title}
 local row=''
 for _,hint in ipairs(hints)do
  local joined=row==''and hint or row..'   |   '..hint
  if row~=''and font:getWidth(joined)>width then lines[#lines+1]=row;row=hint else row=joined end
 end
 if row~=''then lines[#lines+1]=row end
 local wrapped={}
 for _,line in ipairs(lines)do local _,rows=font:getWrap(line,width)
  for _,text in ipairs(rows)do wrapped[#wrapped+1]=text end
 end
 local lineHeight=math.ceil(font:getHeight()*1.25)
 local height=#wrapped*lineHeight+pad*2
 return {x=pad,y=math.max(0,h-height-pad),w=w-pad*2,h=height,
  pad=pad,lineHeight=lineHeight,lines=wrapped}
end
function M.hud(out,w,h)
 if not active then return V.require('MewSky').hud(out,w,h) end
 local g=love.graphics;g.push('all');g.setCanvas(out)
 -- Final presentation pixels already include the iOS world reflection.
 g.origin()
 local size=math.max(14,math.min(32,math.floor(h*.032)))
 if helpFontSize~=size then
  if helpFont then helpFont:release()end
  helpFont=g.newFont(size);helpFontSize=size
 end
 g.setFont(helpFont)
 local p=M.helpLayout(w,h,helpFont,active.zoom)
 g.setColor(.035,.055,.08,.94);g.rectangle('fill',p.x,p.y,p.w,p.h,8,8)
 g.setColor(1,1,1,1)
 for i,line in ipairs(p.lines)do
  g.printf(line,p.x+p.pad,p.y+p.pad+(i-1)*p.lineHeight,p.w-p.pad*2,'center')
 end
 g.pop();return out
end
function M.install()
 local OW=require('src.world.OverworldController');if OW._vascBinoculars then return end
 local interact,input=OW.interact,OW.handleInput
 function OW:interact(...)
  local p=self.player;local x,y=p:facingCell();local sign=self.map:signAtCell(x,y)
  local candidate=enabled(self)and not p.moving and not p.inputLocked and not self:npcAtCell(x,y)
   and sign and tostring(sign.text):find('BINOCULAR',1,true)
  local result=interact(self,...)
  if candidate then
   local subject=M.subject(self.map,sign,x,y)
   pending={world=self,map=self.map,player=p,x=p.cellX,y=p.cellY,bx=x,by=y,
    yaw=subject and subject.yaw or (self.map.id=='ROUTE_12_GATE_2F'and sign.text=='TEXT_ROUTE12GATE2F_RIGHT_BINOCULARS'and math.pi or 0),slope=subject and subject.slope,
    zoom=subject and 4 or 2,subject=subject}
  end
  return result
 end
 function OW:handleInput(...)
  local s=active
  if s and s.world==self then
   local keys=require('src.core.Game').input
   if keys:wasPressed('a')or keys:wasPressed('b')then M.close();return end
   if keys:wasPressed('start')then M.close();return input(self,...)end
   if keys:wasPressed('up')then s.zoom=math.min(8,s.zoom+.5)end
   if keys:wasPressed('down')then s.zoom=math.max(1,s.zoom-.5)end
   if keys:isDown('left')or keys:wasPressed('left')then s.yaw=s.yaw-(M.dt or 1/60)*1.2 end
   if keys:isDown('right')or keys:wasPressed('right')then s.yaw=s.yaw+(M.dt or 1/60)*1.2 end
   return
  end
  return input(self,...)
 end
 OW._vascBinoculars=true
end
return M
