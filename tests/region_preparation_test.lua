local active=true
local setting={get=function()return 128 end}
local Residency=assert(loadfile('lib/WorldResidency.lua')){require=function()return{new=function()return setting end}end}
local ids={'ROOT','HOUSE','UPSTAIRS','NEXT','TOO_FAR'}
local maps={};for _,id in ipairs(ids)do maps[id]={id=id,def={connections={}}}end
local built={ROOT=true};local atlas={ROOT=true};local loaded,requests={},{}
local horizon={ROOT=true};local pending;local scenesProtected=0
local chunk={ready=function(m)return built[m.id]end,auxReady=function(m)return built[m.id]end,
 building=function(m)return pending==m.id end,
 request=function(m,body,masks,urgent,rank)
  assert(not urgent and rank==1,'region bypassed shared queue priority');requests[#requests+1]=m.id;pending=m.id
 end,
 setLive=function(live)
  assert(live.ROOT and not live.HOUSE,'future maps pinned as live')
  for id in pairs(built)do Residency.record(id,{})end
  local keep=Residency.keep(live)
  for id in pairs(built)do if not keep[id]then built[id]=nil end end
 end}
package.loaded['src.core.Platform']={detect=function()return{}end}
package.loaded['src.world.MapLoader']={load=function(_,id)loaded[#loaded+1]=id;return maps[id]end,trim=function(p)assert(p.ROOT)end}
package.loaded['src.world.OverworldController']={computeNeighbors=function()return{}end}
local plan={new=function()return{ids=ids,scope='region'}end,step=function()return true end,
 isOutside=function(_,id)return id=='ROOT'end,isBoundary=function(_,id)return id=='GATE'end,
 isLarge=function(_,id)return id=='ROOT'end,sameBuilding=function(_,a,b)return a==b end}
local modules={RegionPlan=plan,ChunkMesher=chunk,WorldResidency=Residency,
 VoxelState={active=function()return active end},VisibleNeighborhood={apply=function(ow)return ow end},
 TerrainAtlas={prepared=function(m)return atlas[m.id]end,prepare=function(m)atlas[m.id]=true;return true end,setLive=function()end},
 HorizonWall={preferBody=function()return true end,cacheStatus=function(s)return{ready=horizon[s.map.id]}end,
 prepareOptional=function(s,visible,protected)
  assert(visible.map.id=='ROOT');scenesProtected=math.max(scenesProtected,#protected)
  horizon[s.map.id]=true;return{},true,false
 end}}
local M=assert(loadfile('lib/RegionPreparation.lua')){require=function(n)return assert(modules[n],n)end}
local game={overworld={map=maps.ROOT,neighbors={}},data={maps={}}}
local function drain(job)
 for i=1,100 do
  if pending then built[pending]=true;pending=nil end
  if M.update(job,game)then return end
 end;error('region stuck')
end
local job=M.new(game);drain(job)
local s=M.status(job)
assert(s.phase=='done'and s.limited=='memory'and s.prepared==4 and not s.error)
assert(#loaded==3 and not built.TOO_FAR,'over-budget map allocated')
assert(built.ROOT and built.HOUSE and built.UPSTAIRS and built.NEXT,'nearby maps lost')
assert(scenesProtected==2,'earlier future panoramas not protected')
local n=#requests;job=M.new(game);drain(job);assert(#requests==n,'warm region rebuilt')
job=M.new(game);active=false;assert(M.update(job,game)and M.status(job).limited=='cancelled');active=true
-- Native building entry holds only until this finite job completes. Internal
-- floor changes bypass another region pass, and changing/resetting owners cancels.
game.overworld.map={id='OUTSIDE'};M.arm(game,'ROOT');game.overworld.map=maps.ROOT
assert(not M.transitionReady(game,false))
for i=1,100 do if pending then built[pending]=true;pending=nil end;if M.transitionReady(game,true)then break end end
assert(M.transitionReady(game,true))
M.arm(game,'ROOT');assert(M.transitionReady(game,true),'same-building floor got another preload')
game.overworld.map={id='OUTSIDE'};M.arm(game,'ROOT');game.overworld={map=maps.ROOT}
assert(M.transitionReady(game,true),'cancelled warp held new overworld')
game.overworld.map={id='GATE'};M.arm(game,'ROOT');game.overworld.map=maps.ROOT
assert(not M.transitionReady(game,true),'gate exit skipped region preparation')
for i=1,100 do if M.transitionReady(game,true)then break end end
print('PASS region preparation: ordinary rooms, shared queue, memory admission before allocation, near-map retention, protected panoramas, warm hits, cancellation and one-time building entry')
