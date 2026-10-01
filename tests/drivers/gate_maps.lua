return function(game)
 io.stdout:setvbuf('no')
 assert((os.getenv('POKEPORT_IDENTITY')or''):match('^vasc%-.*%-qa$'))
 local out=assert(os.getenv('HABITAT_QA_ROOT'))
 local U=require('tests.drivers.util')
 local Q=dofile(assert(os.getenv('BLAINE_KASC_ROOT'))..'/tests/habitat_playthrough/drivers/common.lua')(game)
 Q.setup();Q.V.setupCard.suspended=true
 game.save.flags.EVENT_OAK_GOT_PARCEL=true;game.save.flags.EVENT_GOT_POKEDEX=true
 game.save.flags.EVENT_BEAT_ROUTE22_RIVAL_1ST_BATTLE=true
 love.window.hasFocus=function()return true end;love.window.isVisible=function()return true end
 love.window.setMode(1100,760,{resizable=true,vsync=0});love.audio.setVolume(0)
 local function find(fn,name,seen)
  if type(fn)~='function'then return end;seen=seen or{};if seen[fn]then return end;seen[fn]=true
  for i=1,200 do local k,v=debug.getupvalue(fn,i);if not k then break end;if k==name then return v end end
  for i=1,200 do local k,v=debug.getupvalue(fn,i);if not k then break end;local x=find(v,name,seen);if x then return x end end
 end
 local V=assert(find(Q.V.lib.require('VoxelScene').render,'V'));local scene=V.require('VoxelScene')
 local function ready(id)
  for i=1,2400 do U.wait(1);local l=V.require('LoadingCompanion').status()
   if i>60 and V.require('VoxelState').ready and not scene.pendingReason and not l.visible and not l.cover then return end
  end
  error('scene not ready '..id..' '..tostring(scene.pendingReason))
 end
 local settings=Q.V.setupCard.new(game).settings
 require('src.render.Pipelines').setLevel('voxel',1)
 local fp=V.require('FirstPerson');local frame=fp.frame;local rigSpec
 fp.frame=function(...)local rig,x,z=frame(...);if rigSpec then rig={eye=rigSpec.eye,focus=rigSpec.focus,fov=.94,up={0,1,0},near=.3,far=10000,curveK=0};V.require('Voxel3D').camera=rig;return rig,rigSpec.focus[1],rigSpec.focus[3]end;return rig,x,z end
 assert(settings.apo_hd_walking_sprites):setValue(true,game)
 assert(settings.apo_human_art_style):setValue('cobble',game)
 assert(settings.voxelCharacterCardEnabled):setValue(true,game)
 V.require('Weather').setting:setValue('clear',game);V.require('DayNight').setting:setValue('day',game)
 rigSpec=nil;require('src.render.Pipelines').setLevel('voxel',1)
 V.require('PokemonModelProvider').setting:setValue('cobblemon',game)


 local Map=require('src.world.Map');local G=V.require('GateMaps');local H=V.require('HorizonWall');local W=V.require('HouseWindows')
 local P=require('src.render.Pipelines');local L=V.require('SetupLocale');local rows={}
 for _,id in ipairs{'ROUTE_11_GATE_1F','ROUTE_5_GATE','VIRIDIAN_FOREST_NORTH_GATE','SAFARI_ZONE_GATE'}do
  local d=game.data.maps[id];local map=Map.new(d,game.data.tilesets[d.tileset]);assert(not W.describe(map),'guardhouse has live windows')
  local points=G.placements(map);assert(#points>0,'no real map placements '..id)
  local lights=assert(V.require('InteriorLights').layout(map));assert(#lights.portals>0,'no flat-window light '..id)
  local x,y;for cy=0,d.height*2-1 do for cx=0,d.width*2-1 do if not x and map:isWalkableCell(cx,cy)then x,y=cx,cy end end end
  rigSpec=nil;P.setLevel('voxel',1);U.teleport(game,id,x,y,'up');ready(id);Q.settle();assert(U.shot(game,out..'/'..id..'-flat-day.png'))
  print('PASS_FLAT_GATE',id,#points,#lights.portals)
  rows[#rows+1]={map=id,posters=#points,flatWindows=#lights.portals}
 end
 local id='ROUTE_11_GATE_1F';local d=game.data.maps[id];local map=Map.new(d,game.data.tilesets[d.tileset]);local points=G.placements(map)
 for _,region in ipairs{'kanto','sevii'}do
  local target;for _,p in ipairs(points)do if p.region==region then target=p;break end end;assert(target,region)
  local best,dist
  for cy=0,d.height*2-1 do for cx=0,d.width*2-1 do if map:isWalkableCell(cx,cy)then
   local x,z=cx*16+8,cy*16+8;local p=G.closest(points,x,z);local v=(x-target.x)^2+(z-target.z)^2
   if p==target and(not dist or v<dist)then best={cx,cy};dist=v end
  end end end;assert(best,'poster inaccessible '..region)
  G.dismissed=nil;rigSpec=nil;P.setLevel('voxel',1);U.teleport(game,id,best[1],best[2],'down');ready(id);Q.settle()
  G.update(0,game,1);assert(G.visible and G.visible.region==region,'no nearby prompt '..region)
  U.wait(10);assert(U.shot(game,out..'/gate-map-'..region..'-prompt.png'));U.tap(game,'a');U.wait(5);assert(G.viewer,'A did not open wall map')
  U.wait(10);assert(U.shot(game,out..'/gate-map-'..region..'-viewer.png'))
  if region=='sevii'then for page=1,3 do G.viewer.page=page;U.wait(5);assert(U.shot(game,out..'/gate-map-sevii-'..page..'.png'))end end
  if region=='sevii'then U.tap(game,'right');assert(G.viewer.page==1);U.tap(game,'left');assert(G.viewer.page==3)end
  U.tap(game,'b');assert(not G.viewer,'B did not close wall map');U.wait(10);G.update(0,game,1);assert(not G.visible,'dismissed prompt repeated')
  print('PASS_GATE_MAP_VIEWER',region,best[1],best[2])
 end
 V.require('DayNight').setting:setValue('night',game);rigSpec=nil;P.setLevel('voxel',1);U.teleport(game,'ROUTE_11_GATE_1F',2,3,'up');ready('gate-night')
 assert(U.shot(game,out..'/ROUTE_11_GATE_1F-flat-night.png'))
 print('GATE_MAPS_NATIVE_DONE');love.event.quit()
end
