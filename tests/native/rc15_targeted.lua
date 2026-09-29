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
   if V.require('VoxelState').ready and active and active.rootId==game.overworld.map.id and not Chunk.hasPriorityWork()and H.cacheStatus{map=game.overworld.map,neighbors={}}.ready then return end
   U.wait(1)
  end
  error('readiness timeout '..game.overworld.map.id)
 end
 P.setLevel('voxel',7);LL.setting:setValue(true,game,true)
 V.require('PerformanceOverlay').enabled:setValue(false,game,true)



 local F=V.require('VoxelFurniture')
 local camera;local oldFrame=fp.frame
 fp.frame=function(me,...)if camera then me={px=camera.x-8,py=camera.z-8,gh=camera.h or 0,lift=0}end;return oldFrame(me,...)end
 local function shot(name,x,z,tx,tz,h,pitch)
  camera={x=x,z=z,h=h};fp.yaw=math.atan2(tx-x,tz-z);fp.pitch=pitch or 0;U.wait(12)
  assert(U.shot(game,dir..'/'..name..'.png'))
 end
 for _,id in ipairs{'SILPH_CO_1F','SILPH_CO_4F','SILPH_CO_6F','SILPH_CO_11F'}do
  camera=nil;P.setLevel('voxel',6);U.teleport(game,id,4,4,'up');ready();U.wait(40)
  shot(id..'-pillar',40,40,0,0,0,0)
  local props=F.find(game.overworld.map)
  for i,p in ipairs(props)do if p.kind=='report_table_top'then
   print('DESK',id,p.kind,p.tx,p.ty,p.w,p.h)
   local x,z=(p.tx+p.w*.5)*8,(p.ty+p.h*.5)*8
   shot(id..'-table',x+32,z+40,x,z,12,.55);break
  end end
 end
 camera=nil;U.teleport(game,'SILPH_CO_4F',4,4,'up');ready();U.wait(40)
 shot('silph-former-pad-hole',264,56,288,56,0,0)
 shot('silph-door-oblique',180,172,204,148,0,0)
 camera=nil
 local L=V.require('LoadingCompanion');local seen=false
 game.overworld:startWarpTo('POWER_PLANT',4,4,'up',function()seen=true end)
 for i=1,4000 do U.wait(1);if seen then break end end
 assert(seen and not L.status().visible,'prepared-light reveal gate stalled')
 assert(Scene.readyForReveal(game.overworld),'lighting not prepared at reveal')
 print('PASS_TARGETED_VISUAL_AND_REVEAL');love.event.quit(0)
end
