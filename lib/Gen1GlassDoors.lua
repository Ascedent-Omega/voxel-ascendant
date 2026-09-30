-- Presentation for recognised modern Gen1 entrance warps only. Native
-- collision, arrival movement, fades and destination resolution stay intact.
local V=...
local M={states={},clock=0}
local entrances={CELADON_MART_1F='CELADON_CITY',SILPH_CO_1F='SAFFRON_CITY'}
for _,town in ipairs{'VIRIDIAN','PEWTER','CERULEAN','VERMILION','LAVENDER','CELADON','FUCHSIA','SAFFRON','CINNABAR','MT_MOON','ROCK_TUNNEL'}do
 entrances[town..'_POKECENTER']=({CINNABAR='CINNABAR_ISLAND',LAVENDER='LAVENDER_TOWN',MT_MOON='ROUTE_4',ROCK_TUNNEL='ROUTE_10'})[town]or town..'_CITY'
end
for _,town in ipairs{'VIRIDIAN','PEWTER','CERULEAN','VERMILION','LAVENDER','FUCHSIA','SAFFRON','CINNABAR'}do
 entrances[town..'_MART']=entrances[town..'_POKECENTER']
end
M.entrances=entrances
local function modern(id)
 return id=='SILPH_CO_1F'or id=='CELADON_MART_1F'or id=='BIKE_SHOP'
  or id=='INDIGO_PLATEAU_LOBBY'or id:match('_POKECENTER$')~=nil or id:match('_MART$')~=nil
  or V.require('GateDoors').isGate(id)or V.require('Gen1GymInteriors').profiles[id]~=nil
end
local function exteriorMap(id,d)
 return d and d.generation~=2 and (d.tileset=='OVERWORLD'
  or id=='INDIGO_PLATEAU'and d.tileset=='PLATEAU'
  or id=='VIRIDIAN_FOREST'and d.tileset=='FOREST')
end
local catalogData,sources
function M.configure(data)
 if not data then local ok,game=pcall(require,'src.core.Game');data=ok and game.data end
 if not data or not data.maps or data==catalogData then return end
 catalogData=data;sources={}
 local profiles=V.require('Gen1InteriorPanoramas').profiles
 local gyms=V.require('Gen1GymInteriors')
 -- Use real reciprocal outdoor destinations, not room-name guesses. This
 -- covers only the approved public buildings and each side of a route gate.
 for city,d in pairs(data.maps)do
  if exteriorMap(city,d)
   and (city:match('_CITY$')or city:match('_TOWN$')or city:match('_ISLAND$')
    or city:match('^ROUTE_%d+$')or city:match('^SAFARI_ZONE_')or city=='INDIGO_PLATEAU'or city=='VIRIDIAN_FOREST')then
   for _,w in ipairs(d.warps or{})do
    local id=w.destMap;local room=data.maps[id]
    local gym=room and gyms.exitDoor({id=id,def=room})
    local p=profiles and profiles[id]or gym and gyms.profiles[id]
    if p and room and modern(id)and (not id:match('_%d+F$')or id:match('_1F$'))
      and room.tileset==p.tileset
      and room.width==p.width and room.height==p.height and not next(room.connections or{})then
     entrances[id]=entrances[id]or city
     sources[id]=sources[id]or{};sources[id][city]=true
    end
   end
  end
 end
end
function M.outViewKey(map,warp)
 local suffix=V.require('GateDoors').isGate(map.id)and (warp.destMap..'-')or ''
 if map.id=='ROUTE_22_GATE'then suffix=suffix..tostring(warp.y)..'-'end
 return map.id..'-out-'..suffix..tostring(warp.destWarp)
end
function M.inViewKey(id,warp)
 return id..'-in'..(V.require('GateDoors').isGate(id)and ('-'..tostring(warp))or '')
end
function M.wooden(map,dest)
 return map and map.def and map.def.generation~=2
  and V.require('Gen1InteriorPanoramas').profileFor(map)~=nil
  and not M.interior(map,dest)or false
end
function M.interior(map,dest)
 M.configure()
 local d=map and map.def
 return d and d.generation~=2 and entrances[map.id]~=nil
  and (dest==entrances[map.id]or dest=='LAST_MAP'or sources and sources[map.id]and sources[map.id][dest])
  and (V.require('Gen1InteriorPanoramas').profileFor(map)~=nil
    or V.require('Gen1GymInteriors').exitDoor(map)~=nil)or false
end
function M.transition(map,dest)
 M.configure()
 if M.interior(map,dest)then return true end
 return map and exteriorMap(map.id,map.def)
  and (entrances[dest]==map.id or sources and sources[dest]and sources[dest][map.id])or false
end
function M.enabled(game)
 return game and game.overworld and require('src.render.Pipelines').worldPipeline()=='voxel'
  and V.require('VoxelState').active() and V.require('VoxelItems').setting:get()
end
local viewTextures,viewMeshes={},{}
local viewsRegistered
local insideTint={1,1,1}
local function registerViews()
 if viewsRegistered then return end
 require('src.render.Assets').register(function()
  for _,image in pairs(viewTextures)do if image then image:release()end end
  for _,mesh in pairs(viewMeshes)do if mesh then mesh:release()end end
  viewTextures={};viewMeshes={}
 end)
 viewsRegistered=true
end
function M.texture(key)
 if viewTextures[key]~=nil then return viewTextures[key]or nil end
 registerViews()
 local ok,img=pcall(function()
  local img=V.require('CompactBackgroundAssets').newImage(V.path..'/assets/doors/'..key..'.png')
  img:setFilter('linear','linear');img:setWrap('clamp','clamp');return img
 end)
 viewTextures[key]=ok and img or false
 return ok and img or nil
end
function M.drawView(G,mesh,texture,mat,outside)
 G.drawTint(outside and V.require('DayNight').tint(true)or insideTint)
 G.draw(mesh,texture,mat,0)
 G.drawTint()
end
local function viewMesh(view)
 local mesh=viewMeshes[view]
 if mesh~=nil then return mesh or nil end
 registerViews()
 local a,b,y,h,at=view.from,view.upto,2,20,view.at
 -- Inner views are cropped to the narrower outer aperture, never stretched.
 local span=(b-a)/h/(4/3);local u0,u1=(1-span)/2,(1+span)/2
 local corners=view.horizontal and {{a,y,at},{b,y,at},{b,y+h,at},{a,y+h,at}}
  or {{at,y,a},{at,y,b},{at,y+h,b},{at,y+h,a}}
 if view.side=='north'or view.side=='east'then u0,u1=u1,u0 end
 local uv={{u0,1},{u1,1},{u1,0},{u0,0}};local vertices={}
 for i,p in ipairs(corners)do vertices[i]={p[1],p[2],p[3],uv[i][1],uv[i][2],1}end
 mesh=V.require('Voxel3D').newMesh(vertices,{1,2,3,1,3,4},true)
 viewMeshes[view]=mesh or false;return mesh
end
function M.prepareAudio()
 if not M.source and not M.failed then
  local ok,source=pcall(function()
   local file=love.filesystem.newFileData(assert(V.mod:read('assets/audio/glass-door.wav')),'glass-door.wav')
   local sound=love.sound.newSoundData(file);file:release()
   local source=love.audio.newSource(sound,'static');sound:release();return source
  end)
  if ok then M.source=source else M.failed=true end
  if not M.registered then
   require('src.render.Assets').register(function()
    if M.source then M.source:release()end
    M.source=nil;M.failed=nil;M.lastSound=nil
   end);M.registered=true
  end
 end
 return M.source~=nil
end
function M.play(game,closing)
 local options=game and game.save and game.save.options or{}
 local volume=math.max(0,math.min(7,tonumber(options.sfxVol)or 7))/7
 if volume==0 then return true end
 if M.lastSound and M.clock-M.lastSound<.35 then return true end
 M.prepareAudio()
 if not M.source then return false end
 M.source:stop();M.source:setVolume(volume*.50);M.source:setPitch(closing and .88 or 1)
 M.source:play();M.lastSound=M.clock;return true
end
function M.update(dt,game)
 M.clock=M.clock+math.max(0,dt or 0);M.game=game
 local map=M.enabled(game)and game.overworld.map
 if M.map~=map then M.map=map;M.states={} end
 if not map then return end
 local ow=game.overworld
 if game.stack:top()~=ow then return end
 local player=ow.player
 local x,z=(player.px or player.cellX*16)+8,(player.py or player.cellY*16)+8
 for _,s in pairs(M.states)do
  local along=math.abs((s.horizontal and x or z)-s.center)
  local across=math.abs((s.horizontal and z or x)-s.at)
  local near=along<s.width*.5+12 and across<(s.open and 44 or 34)
  if near~=s.open then
   s.open=near
   if not ow.transitioning then s.audible=M.play(game,not near)end
  end
  local target=near and 1 or 0
  local step=math.min(.1,dt or 0)/.32
  s.amount=target>s.amount and math.min(target,s.amount+step)or math.max(target,s.amount-step)
 end
end
function M.offset(door)
 if not M.map or M.map.id~=door.mapId then return 0,0 end
 local key=door.stateKey
 if not key then key=door.edge..':'..door.at..':'..door.center;door.stateKey=key end
 local s=M.states[key]
 if not s then
  s={horizontal=door.horizontal,center=door.center,at=door.at,width=door.width,open=false,amount=0}
  M.states[key]=s
 end
 local t=s.amount;s.smooth=t*t*(3-2*t)
 local delta=door.sign*door.travel*s.smooth
 return door.horizontal and delta or 0,door.horizontal and 0 or delta
end
function M.viewVisible(door)
 if not door then return true end
 M.offset(door)
 local state=M.map and M.map.id==door.mapId and M.states[door.stateKey]
 return state and state.amount>0 or false
end
function M.call(ow,fn,...)
 local dest=select(1,...);local game=require('src.core.Game')
 if not ow.doorWarp or not M.enabled(game)or not M.transition(ow.map,dest)then return fn(ow,...)end
 local Sound=require('src.core.Sound');local original=Sound.play
 local wrapper=function(data,name,...)
  if name=='Go_Inside'or name=='Go_Outside'then
   for _,s in pairs(M.states)do if s.open and s.audible and s.amount>0 then return M.source end end
   if M.play(game,false)then return M.source end
  end
  return original(data,name,...)
 end
 Sound.play=wrapper
 local function finish(ok,...)
  if Sound.play==wrapper then Sound.play=original end
  if not ok then error((...),0)end
  return ...
 end
 return finish(pcall(fn,ow,...))
end
-- Each exterior leaf is a tiny retained voxel model; only its transform
-- changes. Building meshes, texture atlases and shadows stay cached.
function M.addExterior(P,model,kind,door,depth,width,silph)
 M.configure()
 if not entrances[door.dest]then return false end
 model.slidingDoors=model.slidingDoors or{}
 local number=#model.slidingDoors+1
 local horizontal=door.side=='north'or door.side=='south'
 local at=door.at;local half=silph and 8 or door.width/2
 local plane=silph and 188 or door.side=='south'and depth-4 or door.side=='east'and width-1 or 1
 local C=P.decorColors
 model.doorViews=model.doorViews or{}
 model.doorViews[#model.doorViews+1]={key=M.inViewKey(door.dest,door.destWarp),side=door.side,horizontal=horizontal,
  center=at,plane=plane,edge='exterior_'..door.side,from=at-half,upto=at+half,at=plane+((door.side=='south'or door.side=='east')and -.1 or .9)}
 for leaf=1,2 do
  local name=kind..'_sliding_'..number..'_'..leaf
  local m={terrain=true,boxes={},step=1,frameW=model.frameW,frameH=model.frameH,
   depth=model.depth,offsetY=model.offsetY}
  P.models[name]=m
  local glass={terrain=true,boxes={},step=1,directBoxes=true,frameW=m.frameW,frameH=m.frameH,
   depth=m.depth,offsetY=m.offsetY}
  local glassKind=name..'_glass';P.models[glassKind]=glass
  local function box(x,y,w,h,color,pane)
   local along=at-half+(leaf-1)*half+x
   local boxes=pane and glass.boxes or m.boxes
   boxes[#boxes+1]=horizontal and {along,y,plane+(pane and (door.side=='south'and .1 or -.1)or 0),w,h,1,color}
    or {plane+(pane and (door.side=='east'and .1 or -.1)or 0),y,along,1,h,w,color}
  end
  box(0,2,half,20,C.silver or 4)
  box(1,3,half-2,7,C.silphGlass or 7,true)
  box(1,11,half-2,9,C.silphGlass or 7,true)
  box(1,5,half-2,1,7,true)
  box(1,10,half-2,1,4)
  box(1,17,math.max(1,half-3),1,7,true)
  model.slidingDoors[#model.slidingDoors+1]={kind=name,glassKind=glassKind,edge='exterior_'..door.side,
   horizontal=horizontal,at=plane,center=at,width=half*2,travel=half,sign=leaf==1 and -1 or 1}
 end
 return true
end
function M.prepareExterior(P,model)
 if model and model.slidingDoors then M.prepareAudio()end
 for _,view in ipairs(model and model.doorViews or{})do
  if M.texture(view.key)then viewMesh(view)end
 end
 for _,leaf in ipairs(model and model.slidingDoors or{})do
  if not P.resolveKind(leaf.kind)or not P.resolveKind(leaf.glassKind)then return false end
 end
 return true
end
local windowColor={1,.86,.6}
local exteriorLists=setmetatable({},{__mode='k'})
function M.drawExterior(state,F,P,G,Mat)
 if not P.setting:get()then return end
 local function draw(map,ox,oz)
  local props=F.find(map)
  local list=exteriorLists[props]
  if not list then
   list={};for _,p in ipairs(props)do
    if P.models[p.kind]and P.models[p.kind].slidingDoors then list[#list+1]=p end
   end
   exteriorLists[props]=list
  end
  for _,p in ipairs(list)do
   local model=P.models[p.kind]
   if p.claimed and F.enabled(p)and model and model.slidingDoors then
    local base=V.require('LedgeElevation').basisAtCell(map,
      math.floor((p.tx+p.w/2)/2),math.floor((p.ty+p.h-1)/2))
    for _,view in ipairs(model.doorViews or{})do
     local stateKey=view.stateKey
     if not stateKey then stateKey=view.edge..':'..(view.plane+(view.horizontal and p.ty or p.tx)*8)..':'..(view.center+(view.horizontal and p.tx or p.ty)*8);view.stateKey=stateKey end
     local motion=M.map==map and M.states[stateKey]
     local texture,mesh=viewTextures[view.key],viewMeshes[view]
     if motion and motion.amount>0 and texture and mesh then
      local mat=V.require('Mat4').translationFor(view,p.tx*8+ox,base,p.ty*8+oz)
      if V.require('PropVisibility').forView(G.vp,G.curveK,G.curveX,G.curveZ)(V.require('PropVisibility').known(mesh),mat)then M.drawView(G,mesh,texture,mat,false)end
     end
    end
    p.slidingRuntime=p.slidingRuntime or{}
    for i,leaf in ipairs(model.slidingDoors)do
     local door=p.slidingRuntime[i]
     if not door then
      door={};for k,v in pairs(leaf)do door[k]=v end
      door.mapId=map.id
      door.center=leaf.center+(leaf.horizontal and p.tx or p.ty)*8
      door.at=leaf.at+(leaf.horizontal and p.ty or p.tx)*8
      p.slidingRuntime[i]=door
     end
     local dx,dz=M.offset(door)
     local mesh,tex=P.resolveKind(leaf.kind)
     if mesh then
      local x,z=p.tx*8+ox+dx,p.ty*8+oz+dz
      local mat=door.matrix
      if not mat or mat[4]~=x or mat[8]~=base or mat[12]~=z then
       mat=Mat.translate(x,base,z);door.matrix=mat
      end
      G.draw(mesh,tex,mat,0)
      local pane,palette=P.resolveKind(leaf.glassKind)
      if pane then
       local glow=model.windowLight and model.windowLight()or V.require('Gen1PalletVillage').windowLight()
       G.flatten(windowColor,glow)
       G.draw(pane,palette,mat,0)
       G.flatten(nil)
      end
     end
    end
   end
  end
 end
 draw(state.map,0,0)
 for _,nb in ipairs(state.neighbors or{})do if nb.map and nb.map~=state.map then draw(nb.map,nb.ox or 0,nb.oy or 0)end end
end
function M.install()
 local OW=require('src.world.OverworldController')
 local bridge=OW.__vascGlassDoors
 if not bridge then
  bridge={original=OW.startWarpTo};OW.__vascGlassDoors=bridge
  OW.startWarpTo=function(self,...)return bridge.call(self,bridge.original,...)end
 end
 bridge.call=M.call
end
return M
