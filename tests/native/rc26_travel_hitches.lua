return function(game)
 assert(os.getenv('POKEPORT_IDENTITY')=='vasc-video-polish-qa')
 love.audio.setVolume(0)
 io.stdout:setvbuf('no');love.window.hasFocus=function()return true end;love.window.isVisible=function()return true end
 local U=require('tests.drivers.util');game:startNewGame{intro=false}
 local ex=game.mods.exports.VOXEL_ASCENDANT;assert(not os.getenv('EXPECTED_VASC_VERSION')or ex.packageVersion==os.getenv('EXPECTED_VASC_VERSION'),'wrong packed version');ex.setupCard.suspended=true
 ex.ascendantContent.promptDisabled=true;ex.ascendantContent.onboardingShown=true
 local function find(fn,name,seen)
  if type(fn)~='function'then return end;seen=seen or{};if seen[fn]then return end;seen[fn]=true
  for i=1,100 do local k,v=debug.getupvalue(fn,i);if not k then break end;if k==name then return v end end
  for i=1,100 do local k,v=debug.getupvalue(fn,i);if not k then break end;local got=find(v,name,seen);if got then return got end end
 end
 local rawUpdate=game.update;game.update=function(self,dt)return require('src.mods.Runtime').call('core.update',rawUpdate,self,dt)end
 local V=assert(find(ex.lib.require('VoxelScene').render,'V'));local P=require('src.render.Pipelines')
 V.require('PokemonModelProvider').setting:setValue('cobblemon',game)
 local dir=assert(os.getenv('SHOT_DIR'));local fp=V.require('FirstPerson')
 if os.getenv('QA_STALL_TRACE')then assert(loadfile(assert(os.getenv('QA_VASC_ROOT'))..'/tests/native/rc26_travel_trace.lua'))()(V,game)end
 game.save.flags.EVENT_FOLLOWED_OAK_INTO_LAB=true;game.save.flags.EVENT_GOT_STARTER=true
 game.save.flags.EVENT_BEAT_BROCK=true;game.save.flags.EVENT_BEAT_PEWTER_GYM_TRAINER_0=true
 V.require('CalendarEvents').setting:setValue('halloween',game)
 V.require('Weather').setting:setValue(os.getenv('QA_WEATHER')or'rain',game)
 V.require('VoxelGrid').setting:setValue(false,game,true)
 V.require('DayNight').setting:setValue(os.getenv('QA_CLOCK')or'night',game,true)
 love.window.setMode(1200,800,{resizable=true,vsync=0})
 local Screens=require('src.ui.Screens')
 local menu=Screens.push(game,'VascSettings',{section='pokemon'})
 for _,r in ipairs(menu.items)do
  if r.settingKey=='apo_pokemon_model_source'or r.settingKey=='apo_follower_sprite_source'or r.settingKey=='modernDexSpriteSource'then
   local owner=find(r.descriptor.step,'self_');if owner then owner:setValue('cobblemon',game,true);print('SET',r.settingKey,owner:get())end
  end
 end
 game.stack:pop()

 ex.voxelCharacterCard.setting:setValue(true,game);assert(ex.voxelCharacterCard.select('voxel',game))
 V.require('CalendarEvents').setting:setValue('off',game)
 V.require('DayNight').setting:setValue('day',game,true)


 P.setLevel('tiltshift',0);P.setLevel('voxel',1)




 local json=require('src.link.Json')
 local Scene=V.require('VoxelScene');local Chunk=V.require('ChunkMesher');local LL=V.require('LocalLights')
 local water=V.require('Water');local weather=V.require('Weather')
 local diagnostics=assert(ex.runtimePerformanceDiagnostics)
 local results={};local count=tonumber(os.getenv('QA_FRAMES'))or 360
 love.window.setMode(1710,958,{resizable=true,vsync=0})
 V.require('AntiAlias').resolution:setValue('balanced',game,true)
 V.require('WorldResidency').setting:setValue(128,game,true)
 V.require('PerformanceOverlay').enabled:setValue(false,game,true)
 V.require('DayNight').setting:setValue(os.getenv('QA_CLOCK')or'night',game,true)
 P.setLevel('voxel',6);P.setLevel('tiltshift',3)

 local referencePath=os.getenv('QA_NATIVE_LIGHT_REFERENCE')
 if referencePath then
  V.require('NativeWindowLights').append=assert(loadfile(referencePath))(V).append
 end
 local Map=require('src.world.Map');local Residency=V.require('WorldResidency')
 local H=V.require('HorizonWall');local Atlas=V.require('TerrainAtlas')
 local now=love.timer.getTime;local phase='setup';local frames={};local changes={};local events={}
 local lastMap;local dx,dz=0,0
 fp.moveVector=function()return dx,dz end;fp.moveWorld=function(x,z)return x,z end
 game.save.flags.EVENT_GAVE_GUARDS_DRINK=true;game.save.repelSteps=100000
 for route=1,25 do for i=0,20 do game.save.flags['EVENT_BEAT_ROUTE_'..route..'_TRAINER_'..i]=true end end
 local function tick()
  local start=now();U.wait(1)
  local world=game.overworld;local id=world.map.id
  frames[#frames+1]={ms=(now()-start)*1000,map=id,phase=phase,x=world.player.px,y=world.player.py,
   covered=diagnostics.preparingCovered==true,stack=game.stack:top()==world and 'world' or 'overlay'}
  if id~=lastMap then changes[#changes+1]={frame=#frames,id=id,phase=phase};lastMap=id end
 end
 for _,spec in ipairs{{'WorldResidency','record'},{'ChunkMesher','invalidate'},{'TerrainAtlas','invalidate'}}do
  local owner=V.require(spec[1]);local fn=owner[spec[2]]
  if type(fn)=='function'then owner[spec[2]]=function(id,...)
   if phase~='setup' and #events<3000 then events[#events+1]={frame=#frames,phase=phase,op=table.concat(spec,'.'),id=type(id)=='table'and id.id or tostring(id)} end
   return fn(id,...)
  end end
 end
 local function write(status)
  local f=assert(io.open(dir..'/results.json','w'));f:write(assert(json.encode({status=status,frames=frames,changes=changes,events=events,
   recent=diagnostics.hitches,worst=diagnostics.worstHitches,residency=Residency.last,plan=Scene.planStatus()})));f:close()
 end
 local finalStatus
 local quit=love.event.quit;love.event.quit=function(...)write(finalStatus or 'exit');return quit(...)end
 local function ready()
  dx,dz=0,0
  -- This fixture starts by installing an overworld directly, not by a covered
  -- warp. Prop-batch preparation receipts belong to the covered reveal path.
  -- Wait for actual terrain readiness here; leave real transition gates intact.
  for i=1,1800 do
   local plan=Scene.planStatus();local active=plan and plan.active
   if V.require('VoxelState').ready and active and active.rootId==game.overworld.map.id
      and not Chunk.hasPriorityWork() and not game.overworld.transitioning and game.stack:top()==game.overworld then return end
   tick()
  end
  error('preparation timeout')
 end
 local dirs={{1,0,'east','right'},{-1,0,'west','left'},{0,1,'south','down'},{0,-1,'north','up'}}
 local function pathToExit(destination)
  local world=game.overworld;local map=world.map;local def=map.def
  local w,h=def.width*2,def.height*2
  local p=world.player;local start={p.cellX,p.cellY};local queue={start};local previous={};local visited={[start[2]*w+start[1]]=true}
  local probe=setmetatable({},{__index=p})
  local function pass(x,y,sx,sy)
   if x<0 or y<0 or x>=w or y>=h or map:warpAtCell(x,y)then return false end
   probe.cellX,probe.cellY=sx,sy;probe.px,probe.py=sx*16,sy*16
   return V.require('FreeMove')._blockedCell(world,probe,x,y)==nil
  end
  local found,exit
  for index=1,10000 do
   local cell=queue[index];if not cell then break end
   local x,y=cell[1],cell[2]
   for _,d in ipairs(dirs)do
    local nx,ny=x+d[1],y+d[2];local conn=def.connections and def.connections[d[3]]
    if conn and conn.map==destination and (nx<0 or ny<0 or nx>=w or ny>=h)then
     local dest=assert(game.data.maps[destination]);local dw,dh=dest.width*2,dest.height*2
     local tx,ty
     if d[1]~=0 then tx=d[1]>0 and 0 or dw-1;ty=y-conn.offset*2
     else tx=x-conn.offset*2;ty=d[2]>0 and 0 or dh-1 end
     if tx>=0 and tx<dw and ty>=0 and ty<dh and Map.defPassable(dest,game.data.tilesets[dest.tileset],tx,ty,false)then found=cell;exit=d;break end
    elseif not visited[ny*w+nx] and pass(nx,ny,x,y)then
     visited[ny*w+nx]=true;previous[ny*w+nx]=cell;queue[#queue+1]={nx,ny}
    end
   end
   if found then break end
  end
  assert(found,'no native walk route '..map.id..' -> '..destination)
  local path={};while found~=start do table.insert(path,1,found);found=assert(previous[found[2]*w+found[1]])end
  return path,exit
 end
 local function walk(destination)
  local source=game.overworld.map.id;phase=source..'->'..destination
  local exit
  local startFrame=#frames
  print('WALK_BEGIN',phase)
  for attempt=1,32 do
   local path;path,exit=pathToExit(destination)
   local stalled=false
   for _,cell in ipairs(path)do
    local arrived=false
    for i=1,120 do
     local p=game.overworld.player;local x,z=cell[1]*16-p.px,cell[2]*16-p.py
     if math.abs(x)<.25 and math.abs(z)<.25 then arrived=true;break end
     local speed=V.require('FreeMove').WALK
     dx=math.max(-1,math.min(1,x/speed));dz=math.max(-1,math.min(1,z/speed))
     if math.abs(x)>math.abs(z)then dz=0 else dx=0 end
     fp.yaw=math.atan2(-dx,-dz);fp.pitch=-.08
     tick()
     assert(game.overworld.map.id==source,'unexpected map during path')
     if i>20 and V.require('FreeMove')._blockedCell(game.overworld,p,cell[1],cell[2])then break end
    end
    if not arrived then
     dx,dz=0,0;stalled=true
     print('REPATH',source,cell[1],cell[2],attempt)
     break
    end
   end
   if not stalled then break end
   assert(attempt<32,'native path repeatedly blocked')
  end
  dx,dz=exit[1],exit[2]
  for i=1,600 do if game.overworld.map.id~=source then break end;tick()end
  dx,dz=0,0
  assert(game.overworld.map.id==destination,'connection did not cross')
  ready();for i=1,120 do fp.yaw=fp.yaw+.015;tick()end
  print('WALK_DONE',phase,#frames-startFrame,game.overworld.player.cellX,game.overworld.player.cellY)
 end
 U.teleport(game,'CELADON_CITY',24,23,'right');ready();for i=1,360 do fp.yaw=i/360*math.pi*2;tick()end
 frames={};changes={};events={};diagnostics.hitches={};diagnostics.worstHitches={};phase='walk'
 for round=1,tonumber(os.getenv('QA_ROUNDS'))or 2 do
  for _,dest in ipairs{'ROUTE_7','CELADON_CITY','ROUTE_16','CELADON_CITY'}do walk(dest)end
 end
 phase='settled';dx,dz=0,0;finalStatus='passed';write(finalStatus)
 print('PASS_NATIVE_TRAVEL');love.event.quit(0)
end
