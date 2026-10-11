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
 local Mist=R('IndoorMist');local Horizon=R('HorizonWall');local Lights=R('LocalLights');local Json=require('src.link.Json')
 local camera=tonumber(os.getenv('SEVII_SKY_CAMERA')or'1');local fixed=os.getenv('SEVII_SKY_FIXED')=='1'
 local receipts={points={},api={},references={},camera=camera,fixed=fixed,scope='All 266 authenticated source-family sky/weather/daytime API resolutions. Actual packaged presentation of seven open-air ferry quays and Trainer Tower roof, with Kanto dock/ship/roof references, DAY/NIGHT and dynamic lights ON/OFF. Other settings, all camera angles, geometry and Android remain outside this proof.'}
 local function write()local f=assert(io.open(out..'/sky-conventions.json','w'));f:write(Json.encode(receipts));f:close()end
 local cref=Loader.load(game.data,'MT_MOON_1F');local fref=Loader.load(game.data,'VIRIDIAN_FOREST');receipts.cave=Mist.profile(cref,false);receipts.canopy=Mist.profile(fref,false)
 local ids={};for id in pairs(Q.K.seviiExpedition.maps)do ids[#ids+1]=id end;table.sort(ids)
 for _,id in ipairs(ids)do
  local map=Loader.load(game.data,id);local p=assert(M.profile(map));local mist=Mist.profile(map,false)
  local skyVisible=Horizon.hasSky(map);local modes={}
  for _,selected in ipairs{'off','rain','snow','storm','fog','auto'}do modes[selected]=weather.modeAt(map,selected,20,1)end
  local windowSky=R('SilphWindows').enabled(map);local expectedSky=windowSky or (p.exterior==true and p.kind~='canopy')
  receipts.api[#receipts.api+1]={id=id,source=p.source,sourceOutdoor=p.outdoor,exterior=p.exterior,kind=p.kind,sky=skyVisible,expectedSky=expectedSky,windowSky=windowSky,weatherOutdoor=weather.isOutdoor(map),canopy=day.isCanopy(map),weatherModes=modes,dayTint=day.tint(skyVisible or day.isCanopy(map),day.T.day),nightTint=day.tint(skyVisible or day.isCanopy(map),day.T.night)}
  assert(weather.isOutdoor(map)==p.exterior,'weather source classification mismatch')
  if fixed then assert(skyVisible==expectedSky,'sky differs from authenticated exterior/canopy source: '..id)end
 end
 local references={{'KA_SEVII_HARBOR',5,5},{'KA_SEVII_TWO_ISLAND_HARBOR',5,5},{'KA_SEVII_THREE_ISLAND_HARBOR',5,5},{'KA_SEVII_FOUR_ISLAND_HARBOR',5,5},{'KA_SEVII_FIVE_ISLAND_HARBOR',5,5},{'KA_SEVII_SIX_ISLAND_HARBOR',5,5},{'KA_SEVII_SEVEN_ISLAND_HARBOR',5,5},{'KA_SEVII_TRAINER_TOWER_ROOF',5,5},{'VERMILION_DOCK',5,5},{'SS_ANNE_BOW',5,5},{'CELADON_MART_ROOF',5,5}}
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
   item.sky=Horizon.hasSky(presentMap);item.weatherOutdoor=weather.isOutdoor(presentMap);item.dayTint=day.tint(item.sky or day.isCanopy(presentMap));item.shadowKX=R('Voxel3D').SHADOW_KX;item.shadowKZ=R('Voxel3D').SHADOW_KZ;item.lightSky=frame.sky~=nil
   local file='sky-'..r[1]..'-'..daytime..'-'..(lit and'on'or'off')..'.png';assert(U.still(game,out..'/'..file));item.image=file;receipts.points[#receipts.points+1]=item;write()
   print('SEVII_NATIVE_SKY_CONVENTION_FRAME',r[1],daytime,lit,item.lightActive,item.roomActive)
  end end
 end
 receipts.completed=true;write();print('SEVII_NATIVE_SKY_CONVENTION_PROOF_COMPLETE',#receipts.api,#receipts.points);love.event.quit()
end
