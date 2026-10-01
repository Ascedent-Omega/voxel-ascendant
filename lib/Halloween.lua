-- October decorations and bounded Tower apparitions. Visual/audio only:
-- no game RNG, collision, encounters, actor identities or save mutations.
local V=...
local C=V.require('CalendarEvents')
local M={age=nil,wait=12,serial=0}
local registered=false
local source,building,audioFailed
local function active()return C.active('halloween')end
function M.tower(map)
 return map and map.def and map.def.generation~=2
  and map.def.tileset=='CEMETERY' and (map.id or ''):match('^POKEMON_TOWER_[1-7]F$')~=nil
end
local function gain(game)
 local value=game and game.save and game.save.options and tonumber(game.save.options.sfxVol)
 return math.max(0,math.min(7,value or 7))/7
end
local function stop()
 M.age=nil
 if source then pcall(source.stop,source)end
end
local function prepareAudio()
 if audioFailed or building or source or not(love and love.sound and love.audio)then return end
 building=coroutine.create(function()
  local rate,duration=11025,1.65
  local count=math.floor(rate*duration)
  local data=love.sound.newSoundData(count,rate,16,2)
  local phase,seed=0,19771
  for i=0,count-1 do
   local t=i/rate;local u=t/duration
   seed=seed*16807%2147483647
   phase=phase+2*math.pi*(590-290*u+27*math.sin(t*31))/rate
   local breath=(seed/1073741823.5-1)*.075
   local envelope=math.min(1,t/.16)*math.min(1,(duration-t)/.45)
   local cry=(math.sin(phase)+.28*math.sin(phase*2.04)+.15*math.sin(phase*3.01))*.38
   local s=math.max(-.8,math.min(.8,(cry+breath)*envelope))
   data:setSample(i,1,s);data:setSample(i,2,s)
   if i%768==767 then coroutine.yield()end
  end
  source=love.audio.newSource(data,'static');data:release()
 end)
end
function M.update(dt,game,level)
 C.update(dt)
 local world=game and game.overworld
 local id=world and M.tower(world.map) and world.map.id or nil
 local playable=active()and id and (level or 0)>0 and game.stack
  and game.stack:top()==world and not world.flyAnim and not world.emote and not world.script
  and not(world.runner and world.runner:isRunning())
 if not playable then stop();M.mapId=nil;M.wait=12;return end
 if M.mapId~=id then stop();M.mapId=id;M.wait=10+C.hash(id)%9 end
 if source then source:setVolume(.32*gain(game))end
 if gain(game)>0 then prepareAudio()end
 if building then
  local ok=coroutine.resume(building)
  if not ok or coroutine.status(building)=='dead'then building=nil;audioFailed=not ok end
 end
 dt=math.max(0,math.min(.1,tonumber(dt)or 0))
 if M.age then
  M.age=M.age+dt
  if M.age>=2.4 then M.age=nil end
 else
  M.wait=M.wait-dt
  if M.wait<=0 then
   M.serial=M.serial+1;M.age=0
   local h=C.hash(id..':'..M.serial)
   M.wait=18+h%17;M.side=(h%201-100)/100
   if source and gain(game)>0 then source:stop();source:setPitch(.88+(h%25)/100);source:play()end
  end
 end
end
local function register()
 if registered then return end
 registered=true
 local P=V.require('VoxelItems')
 local orange=P.decorColors.pumpkin or P.decorColors.clay
 local rib=P.decorColors.pumpkinRib or orange
 local function model(name,boxes)
  P.models[name]={boxes=boxes,directBoxes=true,frameW=16,frameH=24,depth=16,offsetY=-8}
 end
 local pumpkin={
  {-2,0,-2,4,1,4,rib},{-3,1,-3,6,1,6,orange},
  {-4,2,-3,8,4,6,orange},{-3,2,-4,6,4,8,orange},
  {-3,6,-3,6,1,6,orange},{-2,7,-2,4,1,4,rib},
  {-1,8,-1,2,2,2,12},
  {-1,2,4.05,2,4,.15,rib},
  {-2.7,4,4.03,1.7,1.6,.25,3},{1,4,4.03,1.7,1.6,.25,3},
  {-2,2,4.03,4,1,.25,3},{-1.5,2,4.31,1,1,.15,11},{.5,2,4.31,1,1,.15,11},
  {-2.4,4.2,4.31,1.1,1,.15,11},{1.3,4.2,4.31,1.1,1,.15,11}}
 model('october_pumpkin',pumpkin)
 model('october_pumpkin_glow',{{-1.5,2,4.5,1,1,.1,11},{.5,2,4.5,1,1,.1,11},
  {-2.4,4.2,4.5,1.1,1,.1,11},{1.3,4.2,4.5,1.1,1,.1,11}})
 model('october_witch_hat',{{2,14,-1.5,12,1.3,3,3},{4,15,-1,8,2,2,3},
  {5,17,-.7,6,2,1.4,3},{6,19,-.5,4,2,1,3},{7,21,-.4,2,1.5,.8,3},
  {4,16,1.05,8,1,.3,orange},{7,15.8,1.4,2,1.5,.3,11}})
 model('october_bat_cape',{{2,4,-1.5,12,8,1,3},{0,5,-1.5,3,5,1,3},
  {13,5,-1.5,3,5,1,3},{3,11,.35,3,2,.5,13},{10,11,.35,3,2,.5,13}})
 local eyes={}
 for _,sign in ipairs{-1,1}do
  for i=0,4 do
   local h=.3+(.8-math.abs(i-2)*.22)
   eyes[#eyes+1]={sign*(1.1+i*.48)-(sign<0 and .48 or 0),i*.10,.0,.48,h,.16,5}
  end
 end
 model('october_eyes',eyes)
end
function M.costume(def,seed)
 if not active()or not def or def.ascendantPokemonDex or def.pokemonDex then return nil end
 local role=def.ascendantRole
 if type(role)~='string' or role:match('^pokemon_')or role:match('^player')
  or role:match('^red$')or role:match('^gold$')then return nil end
 local h=C.hash(tostring(seed or '')..':'..role)
 if h%4~=0 then return nil end
 return h%8==0 and 'october_witch_hat'or 'october_bat_cape'
end
-- The native card is 16px tall. HD cards publish their actual, posed
-- bounds: their height, breathing, lean, seat and walk offsets can differ.
function M.costumeMatrix(kind,mat,pose)
 local Mat=V.require('Mat4')
 if pose then mat=pose.model end
 if kind=='october_witch_hat' then
  local top=pose and pose.top or 16
  local width=math.max(4,math.min(9,(pose and pose.width or 8)*.95))
  local sx,sy=width/12,width/12*.8
  -- Seat the brim around the upper hair, rather than tangent to its
  -- highest pixel. The fitted width also determines insertion depth;
  -- its upper face remains inside the crown even on a large HD head.
  local seatDepth=width*.18
  mat=Mat.mul(mat,Mat.translate(pose and pose.x or 8,top-seatDepth,0))
  mat=Mat.mul(mat,Mat.scale(sx,sy,sx))
  return Mat.mul(mat,Mat.translate(-8,-14,0))
 end
 if pose then
  local scale=pose.height/16
  mat=Mat.mul(mat,Mat.translate(pose.x-8*scale,pose.top-pose.height,0))
  mat=Mat.mul(mat,Mat.scale(scale,scale,scale))
 end
 return mat
end
function M.drawCostume(def,seed,mat,pull,pose)
 local kind=M.costume(def,seed);if not kind then return end
 if pose and pose.def~=def then pose=nil end
 register();local mesh,tex=V.require('VoxelItems').resolveKind(kind)
 if mesh then
  V.require('Voxel3D').draw(mesh,tex,M.costumeMatrix(kind,mat,pose),pose and pose.pull or pull)
 end
end
-- Decorations occupy existing non-walkable tree/rock footprints. Their
-- number is capped and selection is stable across camera moves and re-entry.
function M.eachPumpkin(state,visit,event)
 if not (event and C.active(event) or not event and active())or not state or not state.map then return end
 register()
 local P=V.require('VoxelItems');local F=V.require('VoxelFurniture')
 local seen={}
 local function inMap(map,ox,oz)
  if seen[map]then return end;seen[map]=true
  local outdoor=V.require('Weather').isOutdoor(map)
  if not outdoor and (event or not M.tower(map))then return end
  local count=0
  for _,p in ipairs(F.find(map))do
   local model=P.models[p.kind]
   if p.claimed and F.enabled(p)and model then
    local natural=outdoor and (p.kind:find('tree',1,true)or p.kind:find('rock',1,true))
     or not outdoor and p.kind:match('^memorial_stone')
    local x,z
    if natural and C.hash(map.id..':'..p.tx..':'..p.ty)%3==0 then
     x,z=p.tx*8+4,p.ty*8+math.max(4,p.h*8-5)
    elseif outdoor and map.id=='PALLET_TOWN' and
      (p.kind=='pallet_red_house'or p.kind=='pallet_blue_house'or p.kind=='pallet_oak_lab')then
     -- These three authored village façades predate nativeDoors metadata.
     -- Place left of their known door cell, still inside the solid frontage.
     x,z=p.tx*8+(p.kind=='pallet_oak_lab'and 24 or 8),p.ty*8+p.h*8-5
    elseif outdoor and model.nativeDoors then
     -- A single lantern beside a south-facing entrance, within the building
     -- footprint. Never cover the actual door/warp or the walking lane.
     for _,door in ipairs(model.nativeDoors)do
      if door.side=='south'and door.at>=16 and p.w*8>=door.at+16 then
       x,z=p.tx*8+door.at-12,p.ty*8+p.h*8-5;break
      end
     end
    end
    if x then
     local y=V.require('LedgeElevation').basisAtCell(map,math.floor(x/16),math.floor(z/16))or 0
     local eye=V.require('Voxel3D').eye
     if not eye or (x+ox-eye[1])^2+(z+oz-eye[3])^2<260^2 then
      visit(x+ox,y,z+oz,p,map)
      count=count+1;if count>=64 then break end
     end
    end
   end
  end
 end
 inMap(state.map,0,0)
 if not state.sightFurniture then
  for _,nb in ipairs(state.neighbors or{})do if nb.map then inMap(nb.map,nb.ox or 0,nb.oy or 0)end end
 end
end
function M.flame(x,z)
 local clock=V.require('Sky').clock or 0
 return .9+.06*math.sin(clock*4.3+x)+.04*math.sin(clock*7.1+z)
end
function M.appendLights(state,sources)
 M.eachPumpkin(state,function(x,y,z,p,map)
  local night=M.tower(map)and 1 or V.require('DayNight').windowLight()
  sources[#sources+1]={x=x,y=y+5,z=z+5,normal={0,0,1},radius=34,
   power=(.18+.72*night)*M.flame(x,z),color={1,.36,.055},owner=p,kind='pumpkin'}
 end)
end
function M.drawProps(state)
 if not active()then return end
 register();local P=V.require('VoxelItems');local G=V.require('Voxel3D');local Mat=V.require('Mat4')
 local mesh,tex=P.resolveKind('october_pumpkin');if not mesh then return end
 local glow,glowTex=P.resolveKind('october_pumpkin_glow')
 M.eachPumpkin(state,function(x,y,z)
  local eye=G.eye or{0,0,0}
  if (x-eye[1])^2+(z-eye[3])^2<260^2 then
   local mat=Mat.translate(x,y,z);G.draw(mesh,tex,mat,0)
   if glow then
    G.flatten({1,.5,.08},M.flame(x,z))
    local ok=pcall(G.draw,glow,glowTex,mat,0);G.flatten(nil)
   end
  end
 end)
end
function M.drawEyes(state)
 if not active()or not M.age or not state or not M.tower(state.map)then return end
 local G=V.require('Voxel3D');local eye,focus=G.eye,G.focus
 if not eye or not focus then return end
 register();local mesh,tex=V.require('VoxelItems').resolveKind('october_eyes');if not mesh then return end
 local dx,dy,dz=focus[1]-eye[1],focus[2]-eye[2],focus[3]-eye[3]
 local length=math.sqrt(dx*dx+dy*dy+dz*dz);if length<.001 then return end
 dx,dy,dz=dx/length,dy/length,dz/length
 local t=M.age/2.4;local distance=65*(1-t)^2+5
 local offset=(M.side or 0)*12*(1-t)
 local Mat=V.require('Mat4')
 local mat=Mat.mul(Mat.translate(eye[1]+dx*distance-dz*offset,
  eye[2]+dy*distance+math.sin(t*5)*1.2,eye[3]+dz*distance+dx*offset),Mat.rotateY(math.atan2(dx,dz)))
 local g=love.graphics;local mode,write=g.getDepthMode()
 g.setDepthMode('always',false);G.flatten({1,.035,.02},.82)
 local ok,err=pcall(G.draw,mesh,tex,mat,0)
 G.flatten(nil);g.setDepthMode(mode,write)
 if not ok then M.age=nil end
end
return M
