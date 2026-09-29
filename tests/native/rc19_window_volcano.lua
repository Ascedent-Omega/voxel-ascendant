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
 local source=os.getenv('WINDOW_SOURCE')
 if source then
  game.data.maps=assert(loadfile(source..'/data/generated/maps.lua'))()
  game.data.tilesets=assert(loadfile(source..'/data/generated/tilesets.lua'))()
  V.require('WorldPlacement').invalidate();V.require('TileShape').invalidate()
 end
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
 local function clean(v,seen)
  if type(v)=='function'or type(v)=='userdata'or type(v)=='thread'then return nil end
  if type(v)~='table'then return v end
  seen=seen or{};if seen[v]then return nil end;seen[v]=true
  local out={};for k,x in pairs(v)do if type(k)=='string'or type(k)=='number'then out[k]=clean(x,seen)end end;seen[v]=nil;return out
 end
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




 local Map=require('src.world.Map');local Stairs=V.require('Gen1Stairs');local Structures=V.require('Structures')
 Stairs.setting:setValue(true,game);W.setting:setValue(true,game)



 local Map=require('src.world.Map');local WC=V.require('WindowImageCache')
 local B=V.require('Gen1RoomBounds');local G=V.require('Voxel3D');local Outdoor=V.require('OutdoorHorizon')
 local rig;local rawFrame=fp.frame
 fp.frame=function(...)
  local r,cx,cz=rawFrame(...)
  if r and rig then r.eye=rig.eye;r.focus=rig.focus;r.fov=rig.fov;r.curve=0;return r,r.eye[1],r.eye[3]end
  return r,cx,cz
 end
 local draw=Outdoor.draw;local draws=0
 Outdoor.draw=function(rim,...)
  local result=draw(rim,...)
  if rim.windowLandmark and result then draws=draws+1 end
  return result
 end
 V.require('CinnabarVolcano').setting:setValue('connected',game)
 P.setLevel('voxel',6)
 for _,id in ipairs{'CELADON_MART_5F','SILPH_CO_11F','VIRIDIAN_POKECENTER','REDS_HOUSE_1F'}do
  if not os.getenv('WINDOW_VIEW_FILTER')or id:match(os.getenv('WINDOW_VIEW_FILTER'))then
  local before=WC.hits
  U.teleport(game,id,5,5,'down');Scene.setPreparationCovered(true);ready()
  for i=1,1200 do local status=H.cacheStatus(game.overworld);assert(not status.failed);if status.ready then break end;U.wait(1)end
  Scene.setPreparationCovered(false)
  local map=game.overworld.map;local entry={map=map,w=map.def.width*32,h=map.def.height*32}
  local x,y,z=W.volcanoPosition(entry);assert(x,'landmark missing '..id)
  -- Aim from an actual window aperture toward the source volcano summit.
  local profile=V.require('Gen1InteriorPanoramas').profiles[id]
  local best,score
  for _,pane in ipairs(W.apertures(map,profile.shellHeight))do
   local a=(pane.from+pane.upto)/2
   local e=pane.edge=='north'and{a,24,pane.at+18}or pane.edge=='south'and{a,24,pane.at-18}
    or pane.edge=='west'and{pane.at+18,24,a}or{pane.at-18,24,a}
   local dx,dz=x-700-e[1],z+144-e[3]
   local facing=pane.edge=='north'and -dz or pane.edge=='south'and dz or pane.edge=='west'and -dx or dx
   if facing>0 and(not score or facing/math.sqrt(dx*dx+dz*dz)>score)then
    local horizontal=pane.edge=='north'or pane.edge=='south'
    local distance=math.abs((horizontal and z+144 or x-700)-pane.at)
    if horizontal then e[1]=a-(x-700-a)*18/distance else e[3]=a-(z+144-a)*18/distance end
    best,score=e,facing/math.sqrt(dx*dx+dz*dz)
   end
  end
  assert(best,'no volcano-facing pane '..id)
  local dx,dy,dz=x-700-best[1],y+470-best[2],z+144-best[3]
  local length=math.sqrt(dx*dx+dy*dy+dz*dz)
  rig={eye=best,focus={best[1]+dx/length*64,best[2]+dy/length*64,best[3]+dz/length*64},fov=1.1,up={0,1,0},curve=0}
  draws=0;U.wait(35)
  print('VOLCANO_VIEW',id,x,y,z,'draws',draws,'cache',WC.hits-before)
  assert(draws>0,'volcano rejected before draw '..id)
  assert(WC.hits>before,'image cache missed '..id)
  while game.stack:top()~=game.overworld do game.stack:pop()end
  U.wait(1)
  U.shot(game,dir..'/'..id..'-volcano.png')
  end
 end
 fp.frame=rawFrame;Outdoor.draw=draw
 print('PASS_WINDOW_VOLCANO_VIEWS');love.event.quit()
end
