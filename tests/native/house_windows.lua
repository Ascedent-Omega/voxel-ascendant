return function(game)
 assert(os.getenv('POKEPORT_IDENTITY')=='vasc-video-polish-qa')
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
 game.save.flags.EVENT_FOLLOWED_OAK_INTO_LAB=true;game.save.flags.EVENT_GOT_STARTER=true
 game.save.flags.EVENT_BEAT_BROCK=true;game.save.flags.EVENT_BEAT_PEWTER_GYM_TRAINER_0=true
 V.require('CalendarEvents').setting:setValue('halloween',game)
 V.require('Weather').setting:setValue('clear',game)
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




 local H=V.require('HorizonWall');local W=V.require('SilphWindows');local LL=V.require('LocalLights');local Scene=V.require('VoxelScene')
 local Chunk=V.require('ChunkMesher');local Neighborhood=V.require('VisibleNeighborhood')
 local json=require('src.link.Json')
 local renderedStats;local rawDraw=love.draw
 love.draw=function(...)rawDraw(...);renderedStats=love.graphics.getStats()end
 local rows={};local config={};local started=love.timer.getTime()
 local function emit(row)
  rows[#rows+1]=row
  print('RESULT_JSON '..assert(json.encode(row)))
  local f=assert(io.open(dir..'/results.json','w'));f:write(assert(json.encode({config=config,rows=rows},{indent=true})));f:close()
 end
 local function ready()
  for i=1,1000 do
   local plan=Scene.planStatus();local active=plan and plan.active
   if V.require('VoxelState').ready and active and active.rootId==game.overworld.map.id and not Chunk.hasPriorityWork()then return end
   U.wait(1)
  end
  error('readiness timeout '..game.overworld.map.id)
 end
 P.setLevel('voxel',7);LL.setting:setValue(true,game,true)
 V.require('PerformanceOverlay').enabled:setValue(false,game,true)
 local positions={PALLET_TOWN={8,8},SAFFRON_CITY={18,22},CINNABAR_ISLAND={8,8},ROUTE_12={10,15},SILPH_CO_1F={15,12},SILPH_CO_5F={24,14},SILPH_CO_11F={3,5},REDS_HOUSE_1F={3,5}}
 local function percentile(a,q)table.sort(a);return a[math.max(1,math.ceil(#a*q))]end
 local function metrics(seconds)
  local times={};local late33,late50=0,0;local draws,meshes=0,0
  local begin=love.timer.getTime();local prev=begin;local cpu=os.clock()
  repeat
   U.wait(1);local now=love.timer.getTime();local ms=(now-prev)*1000;prev=now
   times[#times+1]=ms;if ms>33.333 then late33=late33+1 end;if ms>50 then late50=late50+1 end
   local stats=assert(renderedStats);draws=draws+stats.drawcalls;meshes=stats.meshes
  until prev-begin>=seconds and #times>=120
  local elapsed=prev-begin;local stats=love.graphics.getStats()
  local r={frames=#times,seconds=elapsed,fps=#times/elapsed,mean_ms=elapsed*1000/#times,cpu_ms=(os.clock()-cpu)*1000/#times,
   p50_ms=percentile(times,.5),p95_ms=percentile(times,.95),p99_ms=percentile(times,.99),max_ms=times[#times],over33_pct=late33*100/#times,over50_pct=late50*100/#times,
   drawcalls=draws/#times,meshes=meshes,textures_mb=stats.texturememory/1048576,lua_mb=collectgarbage('count')/1024,
   chunks_pending=Chunk.pending(),horizons=H.buildStatus()}
  return r
 end
 local function scenario(label,map,on,round,seconds,shot)
  local t=love.timer.getTime();local same=game.overworld.map.id==map;W.setting:setValue(on,game,true)
  if not same then local p=assert(positions[map]);U.teleport(game,map,p[1],p[2],'up')end
  ready();local readyTime=love.timer.getTime()-t;U.wait(120)
  local r=metrics(seconds or 5);r.label=label;r.map=map;r.windows=on;r.round=round;r.ready_seconds=readyTime
  r.width,r.height=love.graphics.getPixelDimensions();r.tiltshift=P.level('tiltshift');r.same_map=same
  emit(r)
  if shot then assert(U.shot(game,dir..'/'..label..'.png'))end
 end
 config={version=ex.packageVersion,identity=os.getenv('POKEPORT_IDENTITY'),camera='third-person',day='day',weather='clear',dynamic_lights=true,vsync=0,
  measurement='frame-to-frame wall time; CPU is process CPU including threads; texture memory excludes mesh memory',warmup_frames=120,gameplay='native Red + KASC QA save'}

 local HW=V.require('HouseWindows');local G=V.require('Voxel3D')
 V.require('WorldCurve').setting:setValue(3,game,true)
 local count=0
 for id,profile in pairs(V.require('Gen1InteriorPanoramas').profiles)do
  local d=game.data.maps[id]
  if d then
   local map=require('src.world.Map').new(d,game.data.tilesets[d.tileset])
   local source=HW.source(map)
   if source then
    local h=HW.describe(map);print('HOUSE '..json.encode({map=id,source=source,description=h}))
    if h then count=count+1 end
   end
  end
 end
 print('HOUSE_COUNT '..count)
 for _,id in ipairs{'SILPH_CO_1F','REDS_HOUSE_1F','REDS_HOUSE_2F','BLUES_HOUSE','VERMILION_TRADE_HOUSE','MR_PSYCHICS_HOUSE','ROUTE_12_GATE_2F'}do
  U.teleport(game,id,5,6,'up');ready();U.wait(150)
  assert(G.curveK==0,'curved interior '..id..' '..tostring(G.curveK))
  print('CURVE_FLAT '..id..' '..tostring(G.curveK))
  assert(U.shot(game,dir..'/'..id..'-third.png'))
  P.setLevel('voxel',6);U.wait(120);assert(G.curveK==0)
  assert(U.shot(game,dir..'/'..id..'-first.png'))
  P.setLevel('voxel',5);U.wait(120);assert(G.curveK==0)
  assert(U.shot(game,dir..'/'..id..'-orbit.png'))
  P.setLevel('voxel',7);U.wait(120)
  fp.yaw=0;fp.pitch=0;U.wait(90)
  assert(U.shot(game,dir..'/'..id..'-front.png'))
  W.setting:setValue(false,game);ready();U.wait(90);assert(G.curveK==0)
  assert(U.shot(game,dir..'/'..id..'-off.png'))
  W.setting:setValue(true,game)
 end
 U.teleport(game,'PALLET_TOWN',8,8,'up');ready();U.wait(120)
 assert(G.curveK>0,'outdoor curvature lost')
 print('PASS_HOUSE_WINDOWS_NATIVE');love.event.quit(0)
end
