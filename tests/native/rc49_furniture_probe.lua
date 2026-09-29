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
 local dx,dz=0,0
 fp.moveVector=function()return dx,dz end;fp.moveWorld=function(x,z)return x,z end
 V.require('LocalLights').setting:setValue(true,game,true)
 V.require('Gen1PalletVillage').buildings:setValue(true,game,true)
 local trace,wrap=assert(loadfile(assert(os.getenv('QA_VASC_ROOT'))..'/tests/native/rc27_model_trace.lua'))()(V,game)
 for _,spec in ipairs{{'WaterReflection','draw'},{'Voxel3D','beginWater'},{'Voxel3D','endWater'},{'Water','begin'},{'Water','draw'},{'Water','finish'},{'PropVisibility','visibleWater'},{'ShadowMap','begin'},{'ShadowMap','draw'}}do wrap(V.require(spec[1]),spec[2],table.concat(spec,'.'))end
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




 local Scene=V.require('VoxelScene');local render=Scene.render;local args;Scene.render=function(...)args={n=select('#',...),...};return render(...)end; local H=V.require('HorizonWall');local Chunk=V.require('ChunkMesher')
 local R=V.require('RegionPreparation');local Atlas=V.require('TerrainAtlas');local Loader=require('src.world.MapLoader')
 local json=require('src.link.Json')
 local cached=R.cachedScene;local reused=0
 R.cachedScene=function(...)
  if os.getenv('QA_DISABLE_REGION_HOLD')then return end
  local canvas=cached(...);if canvas then reused=reused+1 end;return canvas
 end
 V.require('WorldResidency').setting:setValue(tonumber(os.getenv('QA_CACHE_MB'))or 512,game,true)
 P.setLevel('voxel',tonumber(os.getenv('QA_CAMERA_LEVEL'))or 7);V.require('SilphWindows').setting:setValue(true,game,true)
 V.require('AntiAlias').resolution:setValue('balanced',game,true)
 U.teleport(game,'SILPH_CO_1F',9,9,'down')
 game.overworld:startWarpTo('SAFFRON_CITY',15,15,'down')
 for i=1,15000 do if not game.overworld.transitioning then break end;U.wait(1)end
 assert(not game.overworld.transitioning and Scene.readyForReveal(game.overworld),'initial native arrival incomplete')
 assert(game.stack:top()==game.overworld)

 print('WATER_LEVEL',V.require('Water').level())

 local function slot(fn,name,seen)
  seen=seen or{};if type(fn)~='function'or seen[fn]then return end;seen[fn]=true
  for i=1,100 do local k,v=debug.getupvalue(fn,i);if not k then break end;if k==name then return fn,i,v end end
  for i=1,100 do local k,v=debug.getupvalue(fn,i);if not k then break end;local a,b,c=slot(v,name,seen);if a then return a,b,c end end
 end
 local F=V.require('VoxelFurniture')
 local snapshot=F.snapshot
 local stats={}
 F.snapshot=function(state)
  local t=love.timer.getTime();local r=snapshot(state);local id=state.map.id
  local row=stats[id]or {calls=0,uncached=0,ms=0,entries=0};stats[id]=row
  row.calls=row.calls+1;row.ms=row.ms+(love.timer.getTime()-t)*1000
  if not r or not r._voxelStaticSnapshot then row.uncached=row.uncached+1 end
  row.entries=r and #r or 0
  return r
 end
 for _,name in ipairs{'snapshot','find','enabled','each','drawOpaque','drawDetails'}do wrap(F,name,'Furniture.'..name)end

 local results={}
 for _,id in ipairs{'SAFFRON_CITY','CELADON_CITY'}do
  local x,y=25,25;if id=='CELADON_CITY'then x,y=24,23 end
  U.teleport(game,id,x,y,'down');game.overworld:startWarpTo(id,x,y,'down')
  for i=1,15000 do if not game.overworld.transitioning then break end;U.wait(1)end
  assert(Scene.readyForReveal(game.overworld));U.wait(180)
  P.setLevel('voxel',7)
  for view=1,4 do
   fp.yaw=(view-1)*math.pi*.5;fp.pitch=-.08;U.wait(60)
   for _,variant in ipairs{'profile'}do
    stats={}
    U.wait(20)
    local rows={}
    for i=1,240 do local measuredFrame=trace.frame;U.wait(1);rows[#rows+1]=measuredFrame end
    results[#results+1]={map=id,view=view,variant=variant,frames=rows}
    print('FURNITURE_PROFILE',id,view,assert(json.encode(stats)))
   end
  end
 end

 local f=assert(io.open(dir..'/phases.json','w'));f:write(json.encode(results));f:close()
 print('PASS_OPAQUE_BENCH');love.event.quit(0)
end
