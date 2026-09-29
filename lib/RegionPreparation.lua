-- Shared, bounded loading-screen work. Terrain/aux/atlas use their existing
-- caches and queue; complete future panoramas use the protected scenery lane.
local V=...
local M={}
local Plan=V.require('RegionPlan')
local Chunk=V.require('ChunkMesher')
local Atlas=V.require('TerrainAtlas')
local Horizon=V.require('HorizonWall')
local Residency=V.require('WorldResidency')
local last
function M.new(game)
 local ow=game.overworld
 return {owner=ow,map=ow.map,plan=Plan.new(game.data,ow),phase='plan',index=1,
  maps={},order={},scenes={},skipped={}}
end
function M.status(job)
 job=job or last;if not job then return end
 return {root=job.map.id,phase=job.phase,scope=job.plan.scope,discovered=#job.plan.ids,
  prepared=#job.order,ids=job.order,limited=job.limited,error=job.error,skipped=job.skipped}
end
local function finish(job,why)
 job.phase='done';job.limited=why or job.limited;last=job;return true
end
local function retain(job,ow)
 -- Closest prepared maps win over farther ones. Required visible maps are
 -- separately pinned; future rooms never masquerade as the current scene.
 for i=#job.order,1,-1 do Residency.touch(job.order[i])end
 Chunk.setLive(job.live);Atlas.setLive(job.live)
 local protected={};for id in pairs(Residency.retained())do protected[id]=true end
 protected[ow.map.id]=true
 for _,nb in ipairs(ow.neighbors or{})do protected[nb.map.id]=true end
 require('src.world.MapLoader').trim(protected)
 return Residency.retained()
end
local function advance(job,game)
 local ow=game.overworld
 if ow~=job.owner or ow.map~=job.map or not V.require('VoxelState').active()then return finish(job,'cancelled')end
 if job.phase=='done'then return true end
 if job.phase=='plan'then
  if not Plan.step(job.plan)then return false end
  if job.plan.error then job.error=job.plan.error;return finish(job,'plan')end
  -- A region can end inside a connected route (for example at a gate).
  -- Its outdoor panorama still displays the direct neighbours beyond that
  -- boundary. Prepare this one-map visual border too, without flooding the
  -- next gameplay region or entering any of its houses.
  local seen,halo={},{}
  for _,id in ipairs(job.plan.ids)do seen[id]=true end
  for _,id in ipairs(job.plan.ids)do
   if Plan.isOutside(game.data,id)then
    for _,row in ipairs(require('src.world.OverworldController').computeNeighbors(game.data.maps,id,1))do
     if not seen[row.id]then seen[row.id]=true;halo[#halo+1]=row.id end
    end
   end
  end
  table.sort(halo);job.plan.halo=halo
  for _,id in ipairs(halo)do job.plan.ids[#job.plan.ids+1]=id end
  job.visible=V.require('VisibleNeighborhood').apply(ow)
  job.live={[ow.map.id]=true};job.maps[ow.map.id]=ow.map
  for _,nb in ipairs(job.visible.neighbors or{})do job.live[nb.map.id]=true;job.maps[nb.map.id]=nb.map end
  job.phase='terrain';return false
 end
 if job.phase=='terrain'then
  local id=job.plan.ids[job.index]
  if not id then job.phase='scenery';job.index=1;return false end
  local map=job.maps[id]
  if not map then
   -- Admit an ID before constructing any GPU renderer. Cache count and byte
   -- pressure can end optional work while the actual arrival remains intact.
   job.order[#job.order+1]=id
   local retained=retain(job,ow)
   if not retained[id]then table.remove(job.order);job.limited='memory';job.phase='scenery';job.index=1;return false end
   map=require('src.world.MapLoader').load(game.data,id);job.maps[id]=map
   return false -- at most one cold native map allocation per update
  end
  if not job.seen then job.seen={}end
  if not job.seen[id]then
   job.seen[id]=true
   local found=false;for _,v in ipairs(job.order)do if v==id then found=true;break end end
   if not found then job.order[#job.order+1]=id end
  end
  local body=Horizon.preferBody(map)==true
  -- Closed rooms have no masks; outdoor bodies are reusable after re-rooting.
  if not body and next(map.def.connections or{})then
   job.skipped[id]='full-border';job.index=job.index+1;return false
  end
  if not Chunk.ready(map,body)or not Chunk.auxReady(map)then
   if job.requested==id and not Chunk.building(map,body)then
    job.skipped[id]='terrain';job.index=job.index+1;job.requested=nil;return false
   end
   Chunk.request(map,body,nil,false,1);job.requested=id;return false
  end
  job.requested=nil
  if not Atlas.prepared(map)then
   if not Atlas.prepare(map)then job.skipped[id]='atlas';job.index=job.index+1 end
   return false
  end
  local retained=retain(job,ow)
  if not retained[id]then
   job.maps[id]=nil;table.remove(job.order);job.limited='memory';job.phase='scenery';job.index=1;return false
  end
  job.index=job.index+1;return false
 end
 local platform=require('src.core.Platform').detect()
 if platform.mobile or platform.console then return finish(job)end
 local id=job.order[job.index]
 if not id then return finish(job)end
 local map=job.maps[id]
 if job.skipped[id]or not map or id==ow.map.id then job.index=job.index+1;return false end
 if not job.future then
  local scene={map=map,neighbors={},worldMaps=game.data.maps}
  local rows=require('src.world.OverworldController').computeNeighbors(game.data.maps,id,1)
  for _,row in ipairs(rows)do
   local nb=job.maps[row.id]
   if not nb or not Chunk.ready(nb,true)or not Chunk.auxReady(nb)then
    job.skipped[id]='partial-neighbourhood';job.index=job.index+1;return false
   end
   scene.neighbors[#scene.neighbors+1]={map=nb,ox=row.ox,oy=row.oy}
  end
  job.future=scene
 end
 local status=Horizon.cacheStatus(job.future)
 if status.failed then job.skipped[id]='scenery';job.future=nil;job.index=job.index+1;return false end
 local ready=status.ready
 if not ready then
  -- If the visible map uses the renderer's established full fallback, there
  -- is no semantic cache to pin. Do not wait forever for an optional one.
  local visible=Horizon.cacheStatus(job.visible)
  if visible.failed then return finish(job,'scenery-fallback')end
  local _,done,rejected=Horizon.prepareOptional(job.future,job.visible,job.scenes)
  if rejected then return finish(job,'scenery-memory-or-build')end
  ready=done
 end
 if ready then job.scenes[#job.scenes+1]=job.future;job.future=nil;job.index=job.index+1 end
 return false
end
function M.update(job,game)
 local ok,done=pcall(advance,job,game)
 if not ok then job.error=tostring(done);return finish(job,'error')end
 last=job;return done
end
local transition
function M.arm(game,id)
 transition=nil
 if not V.require('VoxelState').active()or not(game and game.overworld and game.data)then return end
 local source=game.overworld.map.id
 local building=Plan.isLarge(game.data,id)and not Plan.sameBuilding(game.data,source,id)
 local areaExit=source~=id and Plan.isOutside(game.data,id)and (Plan.isBoundary(game.data,source)or Plan.isLarge(game.data,source))
 if building or areaExit then
  transition={owner=game.overworld,id=id,game=game}
 end
end
-- Borrow the already-presented scene only during an opaque, native region
-- wait. Region preparation still advances in update; fades and gameplay must
-- always draw fresh frames. The transition owns this reference, not the GPU.
local function coveredTransition(state)
 local t=transition
 if not t or not t.job or t.owner~=state or t.job.map~=state.map then return end
 local top=t.game.stack and t.game.stack:top()
 if not top or (top.phase~='in' and top.phase~='out')
     or type(top.alpha)~='function' or top:alpha()<1 then
  t.frame=nil;return
 end
 return t,top
end
function M.cachedScene(state,w,h,vw,vh)
 local t,top=coveredTransition(state);local f=t and t.frame
 if not f then return end
 if f.cover~=top or f.w~=w or f.h~=h or f.vw~=vw or f.vh~=vh
     or not V.require('VoxelScene').readyForReveal(state)then
  t.frame=nil;return
 end
 return f.canvas
end
function M.rememberScene(canvas,state,w,h,vw,vh)
 local t,top=coveredTransition(state)
 if t and canvas then t.frame={canvas=canvas,cover=top,w=w,h=h,vw=vw,vh=vh}end
end
function M.transitionReady(game,ready)
 if not transition then return ready end
 local ow=game and game.overworld
 if not ow or ow~=transition.owner or ow.map.id~=transition.id
     or not V.require('VoxelState').active()then transition=nil;return ready end
 if not ready then transition.frame=nil;return false end
 transition.job=transition.job or M.new(game)
 if M.update(transition.job,game)then transition=nil;return true end
 return false
end
return M
