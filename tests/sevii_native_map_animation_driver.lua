-- Native diagnostic: imported 2D animation declarations versus Voxel resources.
-- Teleports and progression/team fixtures isolate rendering; no gameplay proof.
return function(game)
 io.stdout:setvbuf('no')
 assert((os.getenv('POKEPORT_IDENTITY')or''):match('^vasc%-sevii%-.*%-qa$'))
 local out=assert(os.getenv('SEVII_QA_OUTPUT'))
 local U=require('tests.drivers.util')
 local Q=dofile(assert(os.getenv('SEVII_KASC_ROOT'))..'/tests/habitat_playthrough/drivers/common.lua')(game)
 Q.setup();game.save.options.colors='redpp';game:applyOptions();Q.V.setupCard.suspended=true
 local function find(fn,name,seen)
  if type(fn)~='function'then return end;seen=seen or{};if seen[fn]then return end;seen[fn]=true
  for i=1,200 do local k,v=debug.getupvalue(fn,i);if not k then break end;if k==name then return v end end
  for i=1,200 do local k,v=debug.getupvalue(fn,i);if not k then break end;local r=find(v,name,seen);if r then return r end end
 end
 local V=assert(find(Q.V.lib.require('VoxelScene').render,'V'))
 local M=V.require('KascSeviiScenery');local T=V.require('TerrainAtlas');local W=V.require('Water')
 local R=require('src.render.TileRenderer');local Loader=require('src.world.MapLoader');local S=Q.K.seviiExpedition
 local camera=tonumber(os.getenv('SEVII_COMPONENT_CAMERA')or'0')
 local report={maps={},samples={},camera=camera,clock={engineAnimClock=type(R.animClock),engineAnimFrame=type(R.animFrame)},
  scope='All imported Sevii map animation declarations and live native Water.begin passes on representative water families. Source importer declares static tile animations. Screenshots are real world frames; their pixel difference alone is not an animation assertion. Teleports, progression/team and Water FULL are QA fixtures. No mobile execution.'}
 local function write()
  local f=assert(io.open(out..'/map-animation.json','wb'));f:write(require('src.link.Json').encode(report));f:close()
 end
 local ids={};for id in pairs(S.maps)do ids[#ids+1]=id end;table.sort(ids)
 local chosen={};local used={};local waterMaps=0;local declared=0
 for _,id in ipairs(ids)do
  local map=Loader.load(game.data,id);local p=assert(M.profile(map));local ts=map.tileset
  local specs=ts.animatedTiles or R.defaultAnimatedTiles(ts)or{};local live=map.renderer.anims or{}
  local min,mag=map.renderer.image:getFilter()
  local row={map=id,source=p.source,kind=p.kind,animation=ts.animation or false,declared=#specs,native2dEntries=#live,filterMin=min,filterMag=mag,waterCells=0}
  assert(min=='nearest'and mag=='nearest','source atlas filter '..id)
  for y=0,map.heightCells-1 do for x=0,map.widthCells-1 do if map:isWaterCell(x,y)then row.waterCells=row.waterCells+1 end end end
  if row.waterCells>0 then waterMaps=waterMaps+1 end
  declared=declared+#specs;report.maps[#report.maps+1]=row
  local family=p.kind=='cave'and('cave-'..tostring(p.cave))or p.kind=='room'and('room-'..tostring(p.theme))or('outdoor-'..tostring(V.require('SeviiLandscape').region(p)))
  if row.waterCells>0 and not used[family]then
   local best,bestDistance
   for y=2,map.heightCells-3 do for x=2,map.widthCells-3 do
    if map:isWalkableCell(x,y)and not map:warpAtCell(x,y)then
     for dy=-3,3 do for dx=-3,3 do if map:inBounds(x+dx,y+dy)and map:isWaterCell(x+dx,y+dy)then
      local d=math.abs(x-map.widthCells/2)+math.abs(y-map.heightCells/2)
      if not bestDistance or d<bestDistance then best={map=id,x=x,y=y,family=family};bestDistance=d end
     end end end
    end
   end end
   if best then chosen[#chosen+1]=best;used[family]=true end
  end
 end
 report.mapCount=#ids;report.waterMaps=waterMaps;report.declaredEntries=declared;write()
 assert(#ids==266,'complete imported map inventory')
 -- An explicit zero is evidence of an importer limitation, not proof that
 -- FireRed has no tile animation. Never turn it into blanket animation PASS.
 assert(declared==0,'new declarations require actual per-phase comparison')
 local active;local rawBegin=W.begin
 W.begin=function(ctx)
  local ok=rawBegin(ctx)
  if ok and active and game.overworld.map.id==active.map then
   local phase=W._waveTime();active.passes=active.passes+1
   active.firstPhase=active.firstPhase or phase;active.lastPhase=phase
   active.maritime=ctx.maritime==true
  end
  return ok
 end
 if camera>0 then W.setting:setValue('full',game)end
 for _,case in ipairs(chosen)do
  active={map=case.map,x=case.x,y=case.y,family=case.family,passes=0}
  U.teleport(game,case.map,case.x,case.y,'down');Q.settle();U.wait(60)
  assert(U.shot(game,out..'/'..case.family..'-start.png'))
  local startClock=R.animClock();local firstAtlas=T.forMap(game.overworld.map,nil)
  U.wait(120)
  local secondAtlas=T.forMap(game.overworld.map,nil);active.engineClockAdvanced=R.animClock()>startClock
  active.staticAtlasSame=firstAtlas==secondAtlas
  active.waveAdvanced=active.lastPhase and active.firstPhase and active.lastPhase>active.firstPhase or false
  assert(U.shot(game,out..'/'..case.family..'-end.png'))
  report.samples[#report.samples+1]=active;write()
  assert(active.engineClockAdvanced,'native tile clock stalled '..case.map)
  assert(active.staticAtlasSame,'undeclared import unexpectedly animated '..case.map)
  if camera>0 then assert(active.passes>10 and active.waveAdvanced,'native shared water shader did not animate '..case.map)end
  print('SEVII_MAP_ANIMATION_SAMPLE',case.family,active.passes,active.waveAdvanced)
 end
 W.begin=rawBegin;active=nil;report.completed=true;write()
 print('SEVII_MAP_ANIMATION_DIAGNOSTIC_PASS',#ids,waterMaps,declared,#chosen,camera)
 love.event.quit()
end
