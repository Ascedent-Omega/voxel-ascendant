return function(game)
 assert(os.getenv('POKEPORT_IDENTITY')=='vasc-video-polish-qa')
 love.audio.setVolume(0)
 io.stdout:setvbuf('no');love.window.hasFocus=function()return true end;love.window.isVisible=function()return true end
 local rows={};local original=love.graphics.newImage
 love.graphics.newImage=function(input,...)
  local t=love.timer.getTime();local result=original(input,...);local ms=(love.timer.getTime()-t)*1000
  if ms>0 then rows[#rows+1]={path=type(input)=='string'and input or '<pixels>',ms=ms,w=result:getWidth(),h=result:getHeight()}end
  return result
 end
 local quitOriginal=love.event.quit;love.event.quit=function(...)
  local f=assert(io.open(assert(os.getenv('SHOT_DIR'))..'/images.json','w'));f:write(require('src.link.Json').encode(rows));f:close();return quitOriginal(...)
 end
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
 -- Never inherit the original-building setting from a lighting comparison.
 local buildings=V.require('Gen1PalletVillage').buildings
 buildings:setValue(true,game,true);assert(buildings:get()==true,'voxel buildings must be enabled')
 print('QA_VOXEL_BUILDINGS',tostring(buildings:get()))
 V.require('SilphWindows').setting:setValue(true,game,true)
 local instrument
 if os.getenv('QA_STALL_TRACE')then
  local trace;trace,instrument=assert(loadfile(assert(os.getenv('QA_VASC_ROOT'))..'/tests/native/rc27_model_trace.lua'))()(V,game)
 end
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
  local f=assert(io.open(dir..'/results.json','w'));f:write(assert(json.encode({status=status,voxelBuildings=buildings:get(),frames=frames,changes=changes,events=events,
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

 local slices={};local hooked={}
 local function probe(fn)
  if type(fn)~='function'or hooked[fn]then return end;hooked[fn]=true
  for i=1,100 do local n,v=debug.getupvalue(fn,i);if not n then break end
   if n=='advanceJob'and type(v)=='function'then
    debug.setupvalue(fn,i,function(job,...)
     local t=love.timer.getTime();local a,b=v(job,...);local ms=(love.timer.getTime()-t)*1000
     if ms>4 then slices[#slices+1]={ms=ms,map=game.overworld.map.id,stack=job.co and debug.traceback(job.co)or'finished'}end
     return a,b
    end)
   else probe(v)end
  end
 end
 probe(H.meshes)
 local quitSlices=love.event.quit;love.event.quit=function(...)
  local f=assert(io.open(dir..'/slices.json','w'));f:write(json.encode(slices));f:close();return quitSlices(...)
 end
 local grid=V.require('LocalLightGrid');local wrappedVisibility={}
 local function instrumentVisibility()
  local visibility=find(grid.prepare,'visibility')
  if instrument and type(visibility)=='table'and not wrappedVisibility[visibility]then
   wrappedVisibility[visibility]=true;instrument(visibility,'prepare','GridVisibility.prepare')
  end
 end
 for _,id in ipairs{'SAFFRON_CITY','SILPH_CO_1F','SILPH_CO_6F','SAFFRON_CITY','SILPH_CO_1F','SAFFRON_CITY'}do
  phase='load:'..id
  U.teleport(game,id,id=='SAFFRON_CITY'and 24 or 10,id=='SAFFRON_CITY'and 23 or 15,'right')
  ready();phase='view:'..id
  for i=1,360 do fp.yaw=i/360*math.pi*2;fp.pitch=-.08;tick();instrumentVisibility()end
  assert(U.shot(game,dir..'/'..id..'-'..#changes..'.png'))
 end
 finalStatus='passed';write(finalStatus);print('PASS_SILPH_STRESS');love.event.quit(0)
end
