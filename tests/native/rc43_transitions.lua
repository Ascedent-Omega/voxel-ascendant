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
 fp.moveVector=function()return 0,0 end
 V.require('LocalLights').setting:setValue(true,game,true)
 V.require('Gen1PalletVillage').buildings:setValue(true,game,true)
 local trace,wrap=assert(loadfile(assert(os.getenv('QA_VASC_ROOT'))..'/tests/native/rc27_model_trace.lua'))()(V,game)
 local grid=V.require('LocalLightGrid');local prepare=grid.prepare;local instrumented
 grid.prepare=function(...)
  local vis=find(prepare,'visibility')
  if vis and vis~=instrumented then wrap(vis,'prepare','GridVisibility.prepare');instrumented=vis end
  return prepare(...)
 end
 game.save.flags.EVENT_FOLLOWED_OAK_INTO_LAB=true;game.save.flags.EVENT_GOT_STARTER=true
 game.save.flags.EVENT_BEAT_BROCK=true;game.save.flags.EVENT_BEAT_PEWTER_GYM_TRAINER_0=true
 V.require('CalendarEvents').setting:setValue('halloween',game)
 V.require('Weather').setting:setValue(os.getenv('QA_WEATHER')or'rain',game)
 V.require('VoxelGrid').setting:setValue(false,game,true)
 V.require('DayNight').setting:setValue('night',game,true)
 love.window.setMode(1710,958,{resizable=true,vsync=0})
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
 V.require('DayNight').setting:setValue('night',game,true)


 P.setLevel('tiltshift',0);P.setLevel('voxel',1)




 local Scene=V.require('VoxelScene');local H=V.require('HorizonWall');local Chunk=V.require('ChunkMesher')
 local R=V.require('RegionPreparation');local Atlas=V.require('TerrainAtlas');local Loader=require('src.world.MapLoader')
 local json=require('src.link.Json')
 local cached=R.cachedScene;local reused=0
 R.cachedScene=function(...)
  if os.getenv('QA_DISABLE_REGION_HOLD')then return end
  local canvas=cached(...);if canvas then reused=reused+1 end;return canvas
 end
 V.require('WorldResidency').setting:setValue(tonumber(os.getenv('QA_CACHE_MB'))or 512,game,true)
 P.setLevel('voxel',tonumber(os.getenv('QA_CAMERA_LEVEL'))or 6);V.require('SilphWindows').setting:setValue(true,game,true)
 V.require('AntiAlias').resolution:setValue('balanced',game,true)
 U.teleport(game,'SAFFRON_CITY',18,18,'down')
 game.overworld:startWarpTo('SAFFRON_CITY',15,15,'down')
 for i=1,15000 do if not game.overworld.transitioning then break end;U.wait(1)end
 assert(not game.overworld.transitioning and Scene.readyForReveal(game.overworld),'initial native arrival incomplete')
 assert(game.stack:top()==game.overworld)
 -- No fake region call: the installed native startWarpTo / reveal hooks own it.
 local warp
 for _,w in ipairs(game.data.maps.SAFFRON_CITY.warps)do if w.destMap=='SILPH_CO_1F'then warp=w;break end end
 assert(warp);local id,x,y=require('src.world.Warp').destination(game.data,warp,game.overworld.lastOutdoor)
 for floor=1,11 do Chunk.invalidate('SILPH_CO_'..floor..'F')end
 Chunk.invalidate('SILPH_CO_ELEVATOR')
 local callbacks=0;local start=love.timer.getTime();local frames=0;local shot=false
 game.overworld:startWarpTo(id,x,y,'up',function()callbacks=callbacks+1 end)
 while game.overworld.transitioning and frames<30000 and love.timer.getTime()-start<180 do
  U.wait(1);frames=frames+1
  if game.overworld.map.id==id and game.overworld.transitioning then
   local top=game.stack:top();assert(top~=game.overworld and top:alpha()==1,'building preparation exposed')
   if not shot and love.timer.getTime()-start>3 then
    assert(V.require('LoadingCompanion').status().visible);assert(U.shot(game,dir..'/building-loading.png'));shot=true
   end
  end
 end
 assert(not game.overworld.transitioning and callbacks==1,'building transition stuck/repeated')
 local status=assert(R.status());assert(status.root==id and status.scope=='building'and status.phase=='done')
 assert(not status.error,status.error);assert(status.prepared==12,'missing floor/elevator')
 for _,mid in ipairs(status.ids)do
  local m=assert(Loader.cached(mid));assert(Chunk.ready(m,H.preferBody(m))and Chunk.auxReady(m)and Atlas.prepared(m),'missing cached floor '..mid)
 end
 local elapsed=love.timer.getTime()-start
 local before=status.ids
 local floorWarp
 for _,w in ipairs(game.data.maps.SILPH_CO_1F.warps)do if w.destMap=='SILPH_CO_2F'then floorWarp=w;break end end
 assert(floorWarp)
 local fid,fx,fy=require('src.world.Warp').destination(game.data,floorWarp,game.overworld.lastOutdoor)
 game.overworld:startWarpTo(fid,fx,fy,'up',function()callbacks=callbacks+1 end)
 for i=1,5000 do if not game.overworld.transitioning then break end;U.wait(1)end
 assert(not game.overworld.transitioning and callbacks==2,'floor warp stuck')
 assert(R.status().root==id and R.status().ids==before,'internal floor repeated entire region')
 assert(Scene.readyForReveal(game.overworld));assert(U.shot(game,dir..'/building-floor-ready.png'))
 local segments={}
 local function sweep(label)
  local times={};for i=1,240 do fp.yaw=i/240*math.pi*2;fp.pitch=-.08
   local t=love.timer.getTime();U.wait(1);times[i]=(love.timer.getTime()-t)*1000
  end
  table.sort(times);segments[#segments+1]={label=label,maxMs=times[240],p95Ms=times[228]}
 end
 sweep('floor-after-entry')
 local eid,ex,ey
 for _,w in ipairs(game.data.maps.SILPH_CO_1F.warps)do
  local id,x,y=require('src.world.Warp').destination(game.data,w,game.overworld.lastOutdoor)
  if id=='SAFFRON_CITY'then eid,ex,ey=id,x,y;break end
 end
 assert(eid,'no outdoor exit')
 game.overworld:startWarpTo(eid,ex,ey,'down')
 for i=1,10000 do if not game.overworld.transitioning then break end;U.wait(1)end
 assert(not game.overworld.transitioning and game.overworld.map.id=='SAFFRON_CITY')
 if os.getenv('QA_CAMERA_LEVEL')then
  fp.yaw=0;fp.moveVector=function()return 0,1 end;U.wait(40);fp.moveVector=function()return 0,0 end
 end
 sweep('city-after-exit')
 assert(U.shot(game,dir..'/city-after-exit.png'))
 local result={hiddenSceneReuses=reused,region=status,entrySeconds=elapsed,frames=frames,callbacks=callbacks,segments=segments}
 local f=assert(io.open(dir..'/results.json','w'));f:write(assert(json.encode(result,{indent=true})));f:close()
 print('PASS_RC43_TRANSITIONS',assert(json.encode(result)));love.event.quit()
end
