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
 local Mist=R('IndoorMist');local Lights=R('LocalLights');local Json=require('src.link.Json')
 local camera=tonumber(os.getenv('SEVII_MIST_CAMERA')or'1');local fixed=os.getenv('SEVII_MIST_FIXED')=='1'
 local receipts={points={},api={},references={},camera=camera,fixed=fixed,scope='Actual packaged native map presentation: five Sevii families and five Kanto references, DAY/NIGHT and dynamic lights ON/OFF, same coordinates with fixed clocks. All 266 source-family mist API resolutions sampled separately; this is the mist cause scope, not the entire setting/preset/geometry matrix.'}
 local function write()local f=assert(io.open(out..'/mist-conventions.json','w'));f:write(Json.encode(receipts));f:close()end
 local cref=Loader.load(game.data,'MT_MOON_1F');local fref=Loader.load(game.data,'VIRIDIAN_FOREST');receipts.cave=Mist.profile(cref,false);receipts.canopy=Mist.profile(fref,false)
 local ids={};for id in pairs(Q.K.seviiExpedition.maps)do ids[#ids+1]=id end;table.sort(ids)
 for _,id in ipairs(ids)do
  local map=Loader.load(game.data,id);local p=assert(M.profile(map));local mist=Mist.profile(map,false)
  receipts.api[#receipts.api+1]={id=id,kind=p.kind,mist=mist,darkMist=Mist.profile(map,true)}
  if fixed then
   if p.kind=='cave'then assert(mist==receipts.cave,'Sevii cave does not use shared Kanto mist')
   elseif p.kind=='canopy'then assert(mist==receipts.canopy,'Sevii forest does not use shared Kanto mist')
   else assert(mist==nil,'inactive room/exterior invented generic mist')end
  end
 end
 local references={{'KA_SEVII_FIVE_ISLAND_LOST_CAVE_ROOM1',6,5},{'KA_SEVII_THREE_ISLAND_BERRY_FOREST',12,10},{'KA_SEVII_FIVE',8,5},{'KA_SEVII_MT_EMBER_EXTERIOR',12,12},{'KA_SEVII_CENTER',5,5},{'MT_MOON_1F',10,10},{'VIRIDIAN_FOREST',10,12},{'ROUTE_21',5,12},{'ROUTE_3',12,10},{'VIRIDIAN_POKECENTER',5,5}}
 for _,r in ipairs(references)do
  love.math.setRandomSeed(731);math.randomseed(731)
  local map=Loader.load(game.data,r[1]);local bx,by,best=nil,nil,math.huge
  for y=0,map.heightCells-1 do for x=0,map.widthCells-1 do local score=(x-r[2])^2+(y-r[3])^2
   if score<best and map:isWalkableCell(x,y)and not M.portalAt(map,x,y)then best,bx,by=score,x,y end
  end end
  assert(bx);U.teleport(game,r[1],bx,by,'down');Q.settle();pipelines.setLevel('voxel',camera);pipelines.syncOptions(game.save.options)
  for _,daytime in ipairs{'day','night'}do for _,lit in ipairs{true,false}do
   day.setting:setValue(daytime,game);Lights.setting:setValue(lit,game);Q.settle();U.wait(120)
   for _,npc in pairs(game.overworld.npcs or{})do if npc.resetToSpawn then npc:resetToSpawn();npc.update=function()end end end
   pin();local presentMap=game.overworld.map;local p=M.profile(presentMap);local m=Mist.profile(presentMap,false);local frame=Lights.current()
   local item={map=r[1],x=bx,y=by,day=daytime,lightRequested=lit,lightActive=Lights.active(),roomActive=frame.map==presentMap and frame.interior~=nil,mist=m,kind=p and p.kind,darkMist=Mist.profile(presentMap,true),tint=Mist.tint(presentMap,{1,1,1},bx*16+8,by*16+8),base=Mist.base(presentMap)}
   if fixed and p and p.kind=='room'and camera==1 and lit and item.roomActive then assert(m and m.density==.0015 and m.height==frame.interior.profile.shellHeight,'owned active room lost canonical light mist')end
   local file='mist-'..r[1]..'-'..daytime..'-'..(lit and'on'or'off')..'.png';assert(U.still(game,out..'/'..file));item.image=file;receipts.points[#receipts.points+1]=item;write()
   print('SEVII_NATIVE_MIST_CONVENTION_FRAME',r[1],daytime,lit,item.lightActive,item.roomActive)
  end end
 end
 receipts.completed=true;write();print('SEVII_NATIVE_MIST_CONVENTION_PROOF_COMPLETE',#receipts.api,#receipts.points);love.event.quit()
end
