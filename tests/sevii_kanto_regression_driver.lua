-- QA-only deterministic reference captures; no source files are modified.
return function(game)
 io.stdout:setvbuf('no')
 assert((os.getenv('POKEPORT_IDENTITY')or''):match('^vasc%-sevii%-.*%-qa$'))
 local out=assert(os.getenv('HABITAT_QA_ROOT'))
 local U=require('tests.drivers.util')
 local Q=dofile(assert(os.getenv('SEVII_KASC_ROOT'))..'/tests/habitat_playthrough/drivers/common.lua')(game)
 love.math.setRandomSeed(731)
 Q.setup();Q.V.setupCard.suspended=true
 local actualUpdate=game.update;game.update=function(self,dt)return actualUpdate(self,1/60)end
 -- Pin every renderer clock, including deferred mesh/material preparation.
 love.timer.getTime=function()return 20 end
 require('src.world.NPC').update=function()end
 local manager=require('src.mods.ManagerState').new(game)
 manager:setOption('kanto_ascendant','living_world_towns',false)
 manager:setOption('kanto_ascendant','wilds_town_pokemon_amount',0)
 manager:setOption('kanto_ascendant','qol_location_banners',false)
 love.window.hasFocus=function()return true end;love.window.isVisible=function()return true end
 love.window.setMode(1100,760,{resizable=true,vsync=1});love.audio.setVolume(0)
 local function find(fn,name,seen)
  if type(fn)~='function'then return end;seen=seen or{};if seen[fn]then return end;seen[fn]=true
  for i=1,200 do local k,v=debug.getupvalue(fn,i);if not k then break end;if k==name then return v end end
  for i=1,200 do local k,v=debug.getupvalue(fn,i);if not k then break end;local x=find(v,name,seen);if x then return x end end
 end
 local V=assert(find(Q.V.lib.require('VoxelScene').render,'V'))
 local function R(name)return V.require(name)end
 local M=R('KascSeviiScenery');local scene=R('VoxelScene')
 R('VascControls').hintAlpha=function()return 0 end
 local day,sky,weather=R('DayNight'),R('Sky'),R('Weather')
 day.setting:setValue('day',game);weather.setting:setValue('off',game)
 local TileRenderer=require('src.render.TileRenderer')
 -- Pin the exact engine animation counter and the matching VASC fallback
 -- clock for each capture. Keep the normal frame clock between captures.
 local function pin()
  sky.clock=20;weather.setClock(20)
  for i=1,20 do
   local key=debug.getupvalue(TileRenderer.animClock,i)
   if not key then break end
   if key=='animFrame'then debug.setupvalue(TileRenderer.animClock,i,1200)end
  end
 end
 local originalRender=scene.render
 scene.render=function(...)
  pin();local originalTime=love.timer.getTime
  love.timer.getTime=function()return 20 end
  local args={...};local result
  local ok,why=xpcall(function()result={originalRender(unpack(args))}end,debug.traceback)
  love.timer.getTime=originalTime
  if not ok then error(why,0)end
  return unpack(result)
 end
 local p=R('VoxelItems');local scenery=R('Gen1OutdoorScenery');local village=R('Gen1PalletVillage')
 for _,setting in ipairs{p.setting,scenery.ground,scenery.trees,scenery.stone,village.surrounds,village.lights,R('Gen1InteriorFloors').setting,R('Gen1Stairs').setting}do setting:setValue(true,game)end
 village.buildings:setValue(true,game);R('HorizonWall').setting:setValue('full',game);R('OutdoorHorizon').setting:setValue('voxel',game)
 local pipelines=require('src.render.Pipelines');pipelines.setLevel('tiltshift',0)
 local Loader=require('src.world.MapLoader')
 local references={{'PALLET_TOWN',6,8},{'VIRIDIAN_CITY',10,10},{'CERULEAN_CITY',12,12},
 {'CINNABAR_ISLAND',9,8},{'ROUTE_1',6,10},{'ROUTE_12',10,20},{'ROUTE_20',10,10},{'ROUTE_23',10,20},{'VIRIDIAN_FOREST',10,12},
 {'REDS_HOUSE_1F',3,5},{'VERMILION_TRADE_HOUSE',3,5},{'VIRIDIAN_POKECENTER',5,5},{'GAME_CORNER',8,9},
 {'SEAFOAM_ISLANDS_1F',8,8},{'MT_MOON_1F',10,10},{'ROCK_TUNNEL_1F',10,10}}
 if os.getenv('SEVII_KANTO_MAP')then local selected={};for _,r in ipairs(references)do if r[1]==os.getenv('SEVII_KANTO_MAP')then selected[#selected+1]=r end end;assert(#selected==1);references=selected end
 local receipts={}
 for _,r in ipairs(references)do
  love.math.setRandomSeed(731);math.randomseed(731)
  local map=Loader.load(game.data,r[1]);local bx,by,best=nil,nil,math.huge
  for y=0,map.heightCells-1 do for x=0,map.widthCells-1 do
   local score=(x-r[2])^2+(y-r[3])^2
   if score<best and map:isWalkableCell(x,y)and not map:warpAtCell(x,y)then best,bx,by=score,x,y end
  end end
  assert(bx);U.teleport(game,r[1],bx,by,'down');Q.settle()
  assert(not M.profile(game.overworld.map),'Sevii profile owns Kanto '..r[1])
  for _,npc in pairs(game.overworld.npcPool or{})do
   if npc.resetToSpawn then npc:resetToSpawn();npc.update=function()end end
  end
  pipelines.setLevel('voxel',1);pipelines.syncOptions(game.save.options)
  local stable=0
  for frame=1,3000 do U.wait(1)
   if not scene.pendingReason and not R('WorldSceneHold').loading(game.overworld)then stable=stable+1 else stable=0 end
   if stable>=450 then break end
  end
  assert(stable>=450,'reference scene did not present '..r[1])
  -- Freeze actors at their authored positions for an exact visual fixture.
  for _,npc in pairs(game.overworld.npcs or{})do
   if npc.resetToSpawn then npc:resetToSpawn();npc.update=function()end end
  end
  pin();assert(U.still(game,out..'/kanto-'..r[1]..'.png'))
  receipts[#receipts+1]={map=r[1],x=bx,y=by,camera=1,animationFrame=1200,day='day',weather='off',eye=R('Voxel3D').eye,focus=R('Voxel3D').focus,vp=R('Voxel3D').vp}
  print('SEVII_KANTO_REFERENCE_PASS',r[1],bx,by)
 end
 local f=assert(io.open(out..'/references.json','w'));f:write(require('src.link.Json').encode(receipts));f:close()
 print('SEVII_KANTO_REGRESSION_CAPTURE_PASS',#receipts)
 love.event.quit()
end
