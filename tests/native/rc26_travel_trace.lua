-- Diagnostic only; install before the first scene. No synchronous log IO in
-- measured frames: retain records and flush after the driver has completed.
return function(V,game)
 local T={frames={},slowCalls={},allocations={},allocationEvents={},frame=0}
 local now=love.timer.getTime;local unpack=unpack or table.unpack
 local function pack(...)return {n=select("#",...),...}end
 local totals,counts,peaks={},{},{}
 local function wrap(owner,name,label,allocation)
  local fn=owner[name];if type(fn)~='function'then return end
  owner[name]=function(...)
   local startFrame=T.frame;local t=now();local out=pack(fn(...));local ms=(now()-t)*1000
   if startFrame~=T.frame then return unpack(out,1,out.n)end
   totals[label]=(totals[label]or 0)+ms;counts[label]=(counts[label]or 0)+1;peaks[label]=math.max(peaks[label]or 0,ms)
   if allocation then
    T.allocations[label]=(T.allocations[label]or 0)+1
    if #T.allocationEvents<2000 then T.allocationEvents[#T.allocationEvents+1]={frame=T.frame,label=label,ms=ms,stack=debug.traceback('',2)}end
   end
   if ms>4 and #T.slowCalls<3000 then T.slowCalls[#T.slowCalls+1]={frame=T.frame,label=label,ms=ms,stack=debug.traceback('',2)}end
   return unpack(out,1,out.n)
  end
 end
 for _,spec in ipairs{{'VoxelItems','resolveKind'},{'VoxelGeometryCache','get'},{'VoxelGeometryCache','put'},
  {'VoxelFurniture','eachWorld'},{'VoxelPropBatch','prewarm'},{'VoxelPropBatch','draw'},
  {'StaticLightField','prepare'},{'LocalLightGrid','prepare'},{'LocalLights','prepare'},
  {'LightVisibility','prepare'},{'ChunkMesher','pump'},{'HorizonWall','meshes'},
  {'TerrainAtlas','prepare'},{'TerrainAtlas','forMap'},{'VoxelScene','render'},{'VoxelScene','prefetch'},
  {'VoxelScene','drawWater'},{'Voxel3D','preparePokemonFrame'},
  {'WorldPokemonAnimation','prepare'},{'RegionPreparation','update'},
  {'WindowImageCache','draw'},{'WaterActors','prepare'}}do wrap(V.require(spec[1]),spec[2],table.concat(spec,'.'))end
 for _,spec in ipairs{{'Gen1OverworldStadium','prepare'},{'OverworldStadium','safePrepare'},{'OverworldStadium','safeClaimWilds'},
  {'CobblemonPack','load'},{'CobblemonPack','texture'},{'CobblemonGeometry','build'},
  {'Voxel3D','character'},{'Voxel3D','worldCardsReady'}}do
  local ok,m=pcall(V.require,spec[1]);if ok then wrap(m,spec[2],table.concat(spec,'.'))end
 end
 local overworld=require('src.world.OverworldController')
 for _,n in ipairs{'setMap','rebuildNeighbors','rebuildGhosts'}do wrap(overworld,n,'Overworld.'..n)end
 wrap(require('src.world.MapLoader'),'load','MapLoader.load')
 wrap(require('src.render.Assets'),'image','Assets.image')
 -- Count synchronous callback chains by their event name, without log I/O.
 local runtime=require('src.mods.Runtime');local emit=runtime.emit
 for name,list in pairs(runtime.events.listeners or{})do
  if name=='map.entered' or name=='map.exited' or name=='world.live_maps_preparing' or name=='world.live_maps_updated'then
   for _,entry in ipairs(list)do
    local info=debug.getinfo(entry.callback,'S')or{}
    wrap(entry,'callback','listener.'..name..':'..tostring(entry.owner)..':'..tostring(info.short_src)..':'..tostring(info.linedefined))
   end
  end
 end
 runtime.emit=function(name,...)
  local t=now();local out=pack(emit(name,...));local ms=(now()-t)*1000
  if ms>4 and #T.slowCalls<3000 then T.slowCalls[#T.slowCalls+1]={frame=T.frame,label='event.'..tostring(name),ms=ms,stack=debug.traceback('',2)}end
  return unpack(out,1,out.n)
 end
 for _,n in ipairs{'newMesh','newImage','newCanvas','newShader'}do wrap(love.graphics,n,'GPU.'..n,true)end
 local mesh=love.graphics.newMesh(3,'triangles','static');local methods=getmetatable(mesh).__index;mesh:release()
 for _,n in ipairs{'setVertices','setVertexMap'}do wrap(methods,n,'GPU.'..n)end
 local update,draw=love.update,love.draw;local start=now()
 love.update=function(...)
  T.frame=T.frame+1;totals,counts,peaks={},{},{}
  start=now();local t=now();update(...);totals.update=(now()-t)*1000
 end
 love.draw=function(...)
  local t=now();draw(...);totals.draw=(now()-t)*1000
  if #T.frames<12000 then T.frames[#T.frames+1]={frame=T.frame,dt=love.timer.getDelta()*1000,cpuMs=(now()-start)*1000,parts=totals,counts=counts,peaks=peaks,heapKB=collectgarbage('count'),map=game.overworld and game.overworld.map and game.overworld.map.id,covered=game.stack:top()~=game.overworld}end
 end
 local quit=love.event.quit
 love.event.quit=function(...)
  local path=assert(os.getenv('QA_STALL_TRACE'));local f=assert(io.open(path,'w'))
  f:write(assert(require('src.link.Json').encode(T)));f:close();return quit(...)
 end
 return T
end
