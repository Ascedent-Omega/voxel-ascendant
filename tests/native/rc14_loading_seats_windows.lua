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

 local HW=V.require('HouseWindows');local G=V.require('Voxel3D')

 local Windows=V.require('SilphWindows');local Room=V.require('CurrentRoom')
 local Cache=V.require('WindowImageCache')
 for floor=1,11 do
  local hits=Cache.hits
  U.teleport(game,'SILPH_CO_'..floor..'F',3,4,'up');ready();U.wait(8)
  assert(Cache.hits>hits,'missing floor capture '..floor)
  print('PASS_WINDOW_FLOOR',floor,Windows.height(game.overworld.map))
 end
 for _,id in ipairs{'MR_PSYCHICS_HOUSE','VERMILION_TRADE_HOUSE','SILPH_CO_1F','SILPH_CO_11F'}do
  U.teleport(game,id,id=='SILPH_CO_1F'and 10 or 5,id=='SILPH_CO_1F'and 16 or 6,'up');ready();U.wait(80)
  local view=Room.prepare(game.overworld)
  assert(view and view.complete and not view.mesh,'extra room curtain '..id)
  local L=V.require('Gen1InteriorLayout');local map=game.overworld.map
  for _,p in ipairs(L.panelsFor(map,V.require('Gen1InteriorPanoramas').profiles[id]))do
   if id:match('^SILPH')then assert(not(p.wallThickness and (p.at==map.def.height*32-16 and p.edge=='south'or p.at==0 and p.edge=='east')),'double boundary')end
  end
  assert(G.curveK==0,'indoor curvature')
  assert(U.shot(game,dir..'/'..id..'-final.png'))
  if id=='SILPH_CO_1F'then
   fp.yaw=0;U.wait(60);assert(U.shot(game,dir..'/silph-entrance-final.png'))
  end
  if id=='MR_PSYCHICS_HOUSE'then
   assert(not (function()for _,p in ipairs(HW.describe(map).panes)do if p.edge=='east'then return true end end end)(),'shared neighbour wall got a window')
   local beforeOff=Cache.hits
   Windows.setting:setValue(false,game);ready();U.wait(20)
   assert(Cache.hits==beforeOff,'window OFF decoded a capture')
   Windows.setting:setValue(true,game)
   local observed=false;for i=1,1000 do U.wait(1)
    if V.require('LoadingCompanion').status().visible then observed=true end
    if H.cacheStatus{map=map,neighbors={}}.ready then break end
   end
   U.wait(2);assert(not V.require('LoadingCompanion').status().visible,'window loader stuck')
   print('PASS_WINDOW_TOGGLE',observed)
  end
  print('PASS_ROOM '..id)
 end
 local Seats=V.require('WorldSeats')
 for _,id in ipairs{'ROUTE_12_GATE_2F','CELADON_MART_ROOF','REDS_HOUSE_1F'}do
  U.teleport(game,id,3,3,'down');ready();U.wait(60)
  local world=game.overworld;local found=false
  for y=0,world.map.def.height*2-1 do for x=0,world.map.def.width*2-1 do
   if not found and Seats.chairAt(world,x,y)and not world:npcAtCell(x,y)then
    for _,delta in ipairs{{1,0,'left'},{-1,0,'right'},{0,1,'up'},{0,-1,'down'}}do
     local xx,yy=x+delta[1],y+delta[2]
     if world.map:inBounds(xx,yy)and world.map:isWalkableCell(xx,yy)and not Seats.chairAt(world,xx,yy)and not world:npcAtCell(xx,yy)and not world.map:warpAtCell(xx,yy)then
      local p=world.player;p.cellX,p.cellY,p.px,p.py,p.facing=xx,yy,xx*16,yy*16,delta[3]
      assert(Seats.sit(world,x,y));U.wait(30)
      P.setLevel('voxel',3);for i=1,14 do game:zoomStep(1)end;U.wait(80);assert(U.shot(game,dir..'/seat-'..id..'-orbit.png'))
      P.setLevel('voxel',7);fp.yaw=math.pi/2;fp.pitch=.5;U.wait(100);assert(U.shot(game,dir..'/seat-'..id..'-third.png'))
      assert(Seats.stand(world));found=true;break
     end
    end
   end
  end end
  assert(found,'no chair '..id);print('PASS_SEAT '..id)
 end
 local L=V.require('LoadingCompanion');local observed=0
 local function warp(id,x,y)
  local complete=0;local started=love.timer.getTime()
  game.overworld:startWarpTo(id,x,y,'up',function()complete=complete+1 end)
  for i=1,4000 do
   U.wait(1)
   if L.status().visible then
    observed=observed+1
    if observed==1 or observed==30 then assert(U.shot(game,dir..'/loading-'..observed..'.png'))end
   end
   if complete>0 then break end
  end
  assert(complete==1,'warp did not finish exactly once '..id)
  assert(not L.status().visible,'animation extended warp')
  print('PASS_WARP '..id..' '..(love.timer.getTime()-started))
 end
 warp('SILPH_CO_2F',6,5);warp('ROUTE_15_GATE_1F',3,3)
 assert(observed>0,'cold scene never displayed loader')
 P.setLevel('voxel',0);local beforeVanilla=Cache.hits;warp('PALLET_TOWN',8,8);assert(not L.status().visible)
 assert(Cache.hits==beforeVanilla,'vanilla decoded a window capture')
 print('PASS_NATIVE_RC14');love.event.quit(0)
end
