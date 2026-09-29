return function(game)
 assert(os.getenv('POKEPORT_IDENTITY')=='vasc-video-polish-qa')
 love.audio.setVolume(0)
 game.save.flags.EVENT_GAVE_GUARDS_DRINK=true
 game.save.inventory.BICYCLE=1
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
 if os.getenv('QA_STALL_TRACE')then require('tests.native.rc21_stall_trace')(V,game)end
 game.save.flags.EVENT_FOLLOWED_OAK_INTO_LAB=true;game.save.flags.EVENT_GOT_STARTER=true
 game.save.flags.EVENT_BEAT_BROCK=true;game.save.flags.EVENT_BEAT_PEWTER_GYM_TRAINER_0=true
 V.require('CalendarEvents').setting:setValue('halloween',game)
 V.require('Weather').setting:setValue(os.getenv('QA_WEATHER')or'rain',game)
 V.require('VoxelGrid').setting:setValue(false,game,true)
 V.require('DayNight').setting:setValue('night',game,true)
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




 local H=V.require('HorizonWall');local Chunk=V.require('ChunkMesher');local Gate=V.require('GatePrefetch')
 local Scene=V.require('VoxelScene');local Warp=require('src.world.Warp');local json=require('src.link.Json')
 love.audio.setVolume(0)
 game.save.flags.EVENT_GAVE_GUARDS_DRINK=true
 game.save.inventory.BICYCLE=1
 P.setLevel('voxel',6);V.require('AntiAlias').resolution:setValue('balanced',game,true)
 V.require('Weather').setting:setValue('clear',game,true)
 local driveX,driveZ=0,0;local oldMove,oldWorld=fp.moveVector,fp.moveWorld
 fp.moveVector=function()return driveX,driveZ end;fp.moveWorld=function(x,z)return x,z end
 if os.getenv('QA_CACHE_MB')then V.require('WorldResidency').setting:setValue(tonumber(os.getenv('QA_CACHE_MB')),game,true)end
 local results={}
 local dwell=tonumber(os.getenv('QA_GATE_DWELL'))
 if os.getenv('QA_DISABLE_GATE')then Gate.update=function()end;Gate.status=function()return nil end end
 for _,id in ipairs(os.getenv('QA_GATE_ID')and{os.getenv('QA_GATE_ID')}or{'ROUTE_7_GATE','ROUTE_16_GATE_1F'})do
  local def=assert(game.data.maps[id]);print('GATE_DEF',id,assert(json.encode(def.warps)))
  local exits={}
  for _,w in ipairs(def.warps)do
   local d=game.data.maps[w.destMap]
   if w.destMap=='LAST_MAP' or d and d.tileset=='OVERWORLD'then exits[#exits+1]=w end
  end
  for direction=1,2 do
   local entry=exits[direction==1 and 1 or 3]
   local other,far
   for _,w in ipairs(exits)do
    local distance=math.abs(w.x-entry.x)+math.abs(w.y-entry.y)
    if w.y==entry.y and (not far or distance>far)then other,far=w,distance end
   end
   local dx=other.x==entry.x and 0 or(other.x>entry.x and 1 or -1)
   local dy=other.y==entry.y and 0 or(other.y>entry.y and 1 or -1)
   if dx~=0 then dy=0 end
   game.save.lastOutdoor={id=entry.destMap=='LAST_MAP'and id:match('ROUTE_%d+')or entry.destMap,x=0,y=0}
   local exitOnly=os.getenv('QA_GATE_EXIT_ONLY')
   U.teleport(game,id,exitOnly and other.x-dx or entry.x+dx,exitOnly and other.y-dy or entry.y+dy,dx>0 and 'right'or dx<0 and 'left'or dy>0 and 'down'or 'up')
   local dest=Warp.destination(game.data,other,game.overworld.lastOutdoor)
   Chunk.invalidate(dest);H.invalidate()
   local start=love.timer.getTime();local status;local lastPhase
   if dwell then
    for frame=1,3600 do
     if V.require('VoxelState').ready and H.cacheStatus(game.overworld).ready then break end
     U.wait(1)
    end
    assert(V.require('VoxelState').ready,'gatehouse itself not ready')
    U.wait(dwell)
    status=Gate.status()or{phase='disabled',maps=0,destination=dest}
   else
   for frame=1,3600 do
    U.wait(1);status=Gate.status()
    if status and status.failed then error('gate prep failed '..tostring(status.failed))end
    if status and status.phase~=lastPhase then lastPhase=status.phase;print('GATE_PHASE',id,direction,lastPhase,love.timer.getTime()-start)end
    if status and status.phase=='ready'and V.require('VoxelState').ready and Chunk.ready(require('src.world.MapLoader').load(game.data,dest),H.preferBody(require('src.world.MapLoader').load(game.data,dest)))then break end
   end
   end
   assert(dwell or status and status.phase=='ready','preparation timeout '..id..' '..assert(json.encode(status or{})))
   assert(status.destination==dest,'wrong future destination')
   local prep=love.timer.getTime()-start;print('GATE_PREPARATION_SAMPLE',id,direction,prep,status.maps)
   for i=1,60 do
    if game.stack:top()==game.overworld then break end
    local top=game.stack:top();print('QA_DISMISS',tostring(top and top.name),tostring(top and top.title))
    U.tap(game,'b');U.wait(2)
   end
   assert(game.stack:top()==game.overworld,'unexpected QA modal')
   assert(U.shot(game,dir..'/'..id..'-'..direction..'.png'))
   local delay=tonumber(os.getenv('QA_GATE_COLD_EXIT'))
   local rawAux=Chunk.auxReady
   local delayedUntil
   if delay then
    -- Start with an entirely cold destination ring at the last possible
    -- moment. Delay the final bundle to exercise waits longer than 3s.
    Chunk.invalidate(dest)
    for _,row in ipairs(require('src.world.OverworldController').computeNeighbors(game.data.maps,dest,1))do Chunk.invalidate(row.id)end
    H.invalidate()
    Chunk.auxReady=function(map)
     if game.overworld.map.id==dest then
      delayedUntil=delayedUntil or love.timer.getTime()+delay
      if map.id==dest and love.timer.getTime()<delayedUntil then return false end
     end
     return rawAux(map)
    end
   end
   -- Actual native movement, including door collision and warp resolution.
   driveX,driveZ=dx,dy;local crossed=love.timer.getTime();local frames=0
   while game.overworld.map.id==id and frames<600 do
    U.wait(1);frames=frames+1
    if game.stack:top()~=game.overworld then U.tap(game,'b')end
   end
   driveX,driveZ=0,0
   print('CROSS_STATE',game.stack:top()==game.overworld,game.overworld.transitioning,game.overworld.player.inputLocked)
   assert(game.overworld.map.id==dest,'native crossing failed '..id..' '..game.overworld.player.cellX..','..game.overworld.player.cellY)
   local arrival=love.timer.getTime()
   local cachedOnArrival=H.cacheStatus(V.require('VisibleNeighborhood').apply(game.overworld)).ready
   local heldFrames,loaderFrames,shot=0,0,false
   for i=1,30000 do
    if Scene.readyForReveal(game.overworld)and not game.overworld.transitioning then break end
    local top=game.stack:top()
    assert(top~=game.overworld and type(top.alpha)=='function'and top:alpha()==1,'unfinished destination exposed')
    assert(game.overworld.transitioning,'input unlocked before destination was ready')
    heldFrames=heldFrames+1
    local indicator=V.require('LoadingCompanion').status()
    if indicator and indicator.visible then loaderFrames=loaderFrames+1 end
    if delay and not shot and love.timer.getTime()-arrival>3.2 then
     assert(indicator and indicator.visible,'long wait lost loading animation')
     assert(U.shot(game,dir..'/'..id..'-loading-'..direction..'.png'));shot=true
    end
    U.wait(1)
   end
   Chunk.auxReady=rawAux
   if delay then assert(shot and loaderFrames>0,'long covered wait not exercised')end
   local view=V.require('VisibleNeighborhood').apply(game.overworld)
   for _,nb in ipairs(view.neighbors or{})do
    assert(Chunk.ready(nb.map,true)and Chunk.auxReady(nb.map)and V.require('TerrainAtlas').prepared(nb.map),'neighbour incomplete at release '..nb.map.id)
   end
   assert(Scene.readyForReveal(game.overworld)and not game.overworld.transitioning,'destination did not reveal')
   local region=V.require('RegionPreparation').status()
   if region and region.root==dest and id=='ROUTE_7_GATE'then
    local seen={};for _,mid in ipairs(region.ids)do seen[mid]=true end
    assert(not region.error,region.error)
    assert(not(seen.SAFFRON_CITY and seen.CELADON_CITY),'gate joined both regions')
    if not os.getenv('QA_CACHE_MB')or tonumber(os.getenv('QA_CACHE_MB'))>=512 then assert(seen[direction==1 and 'SAFFRON_CITY'or'CELADON_CITY'],'wrong gate-side region')end
   end
   results[#results+1]={region=region,heldFrames=heldFrames,loaderFrames=loaderFrames,forcedDelaySeconds=delay,gate=id,direction=direction,destination=dest,preparationSeconds=prep,crossAndRevealSeconds=love.timer.getTime()-crossed,maps=status.maps,phase=status.phase,cachedOnArrival=cachedOnArrival,revealAfterArrivalSeconds=love.timer.getTime()-arrival}
   print('PASS_GATE_NATIVE',assert(json.encode(results[#results])))
   U.wait(120)
  end
 end
 fp.moveVector,fp.moveWorld=oldMove,oldWorld
 local f=assert(io.open(dir..'/results.json','w'));f:write(assert(json.encode(results,{indent=true})));f:close()
 print('PASS_GATE_PREFETCH_NATIVE');love.event.quit()
end
