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




 local Scene=V.require('VoxelScene');local H=V.require('HorizonWall');local Chunk=V.require('ChunkMesher')
 local R=V.require('RegionPreparation');local Atlas=V.require('TerrainAtlas');local Loader=require('src.world.MapLoader')
 local json=require('src.link.Json')
 V.require('WorldResidency').setting:setValue(tonumber(os.getenv('QA_CACHE_MB'))or 512,game,true)
 P.setLevel('voxel',6);V.require('SilphWindows').setting:setValue(true,game,true)
 V.require('AntiAlias').resolution:setValue('balanced',game,true)
 U.teleport(game,'SAFFRON_CITY',18,18,'down')
 for i=1,3000 do if Scene.readyForReveal(game.overworld)then break end;U.wait(1)end
 assert(Scene.readyForReveal(game.overworld))
 for i=1,60 do if game.stack:top()==game.overworld then break end;U.tap(game,'b');U.wait(2)end
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
 local result={region=status,entrySeconds=elapsed,frames=frames,callbacks=callbacks}
 local f=assert(io.open(dir..'/results.json','w'));f:write(assert(json.encode(result,{indent=true})));f:close()
 print('PASS_NATIVE_REGION_ENTRY',assert(json.encode(result)));love.event.quit()
end
