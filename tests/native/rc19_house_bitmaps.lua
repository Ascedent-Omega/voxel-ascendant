return function(game)
 assert(os.getenv('POKEPORT_IDENTITY')=='vasc-video-polish-qa')
 io.stdout:setvbuf('no');love.audio.setVolume(0);love.window.hasFocus=function()return true end;love.window.isVisible=function()return true end
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

 local WC=V.require('WindowImageCache');local C=V.require('RooftopCache')
 local eligible=WC.bitmapEligible
 W.setting:setValue(true,game);V.require('WorldCurve').setting:setValue(0,game,true)
 local function settled()
  Scene.setPreparationCovered(true)
  for i=1,3000 do
   local status=H.cacheStatus(game.overworld)
   assert(not status.failed,'failed scenery '..game.overworld.map.id)
   if status.ready and V.require('VoxelState').ready and not Chunk.hasPriorityWork()then break end
   U.wait(1);assert(i<3000,'timeout')
  end
  Scene.setPreparationCovered(false);U.wait(30)
 end
 local function count()
  local faces,vertices,near=0,0,0
  for _,p in ipairs(H.meshes(game.overworld))do
   if p.class=='silph_exterior'and not p.windowLandmark then
    faces=faces+1;vertices=vertices+p.mesh:getVertexCount()
    if not p.bakedWindow then near=near+1 end
   end
  end
  return faces,vertices,near
 end
 for _,id in ipairs{'REDS_HOUSE_1F','REDS_HOUSE_2F','BLUES_HOUSE','VERMILION_TRADE_HOUSE'}do
  U.teleport(game,id,3,5,'up');settled()
  for _,flat in ipairs{false,true}do
   WC.bitmapEligible=flat and eligible or function()return false end
   H.invalidateMap(id);local before=WC.bitmapHits;local t=love.timer.getTime();settled()
   local readySeconds=love.timer.getTime()-t
   local faces,vertices,near=count()
   if flat then assert(WC.bitmapHits>before,'no bitmap '..id);assert(near==0,'live exterior in bitmap house')end
   P.setLevel('voxel',7);fp.yaw=0;fp.pitch=0;U.wait(30)
   local samples,draws={},0;local began=love.timer.getTime();local prev=began
   for i=1,120 do U.wait(1);local now=love.timer.getTime();samples[#samples+1]=(now-prev)*1000;prev=now;draws=draws+(renderedStats and renderedStats.drawcalls or 0)end
   table.sort(samples)
   emit({map=id,bitmap=flat,parts=faces,vertices=vertices,nearMeshes=near,seconds=readySeconds,
    mean_ms=(prev-began)*1000/120,p95_ms=samples[114],drawcalls=draws/120,textureBytes=love.graphics.getStats().texturememory})
   local tag=id..(flat and '-bitmap'or '-hybrid')
   for _,mode in ipairs{6,7}do
    P.setLevel('voxel',mode)
    for n,yaw in ipairs{0,math.pi/2,math.pi,-math.pi/2}do
     fp.yaw=yaw;fp.pitch=0;U.wait(3);assert(U.shot(game,dir..'/'..tag..'-'..mode..'-'..n..'.png'))
    end
   end
  end
 end
 WC.bitmapEligible=eligible
 -- Same bitmap resources respond to night/snow; no photo recapture on weather.
 local hits=WC.bitmapHits
 V.require('DayNight').setting:setValue('night',game,true);U.wait(20)
 assert(U.shot(game,dir..'/night.png'));assert(WC.bitmapHits==hits)
 V.require('Weather').setting:setValue('snow',game);U.wait(20)
 assert(U.shot(game,dir..'/snow.png'))
 W.setting:setValue(false,game);U.wait(60)
 assert(U.shot(game,dir..'/windows-off.png'))
 print('PASS_DOMESTIC_BITMAP_NATIVE');love.event.quit()
end
