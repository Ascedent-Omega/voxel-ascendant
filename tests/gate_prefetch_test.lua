local requests, loads, textures, horizons = {}, {}, {}, {}
local active, ready, priority, dt, capacity, mobile = true, false, false, 1/60, 16, false
local defs={WEST={tileset='OVERWORLD',connections={east={map='NEIGHBOR'}}},
 EAST={tileset='OVERWORLD',connections={west={map='NEIGHBOR'}}},
 NEIGHBOR={tileset='OVERWORLD',connections={}},LOFT={tileset='GATE'}}
local maps, built, textured = {}, {}, {}
for id,def in pairs(defs)do maps[id]={id=id,def=def}end
love={timer={getDelta=function()return dt end}}
package.loaded['src.core.Platform']={detect=function()return{mobile=mobile}end}
package.loaded['src.world.MapLoader']={load=function(_,id)loads[#loads+1]=id;return assert(maps[id])end}
package.loaded['src.world.Warp']={destination=function(_,w,last)
 if w.destMap=='BROKEN'then error('bad warp')end
 return w.destMap=='LAST_MAP'and last.id or w.destMap
end}
package.loaded['src.world.OverworldController']={computeNeighbors=function()return{{id='NEIGHBOR',ox=320,oy=0}}end}
local modules={
 ChunkMesher={setLive=function(live)assert(live.ROUTE_16_GATE_1F and not live.EAST,'future map pinned as current')end,hasPriorityWork=function()return priority end,
  ready=function(m)return built[m.id]end,auxReady=function(m)return built[m.id]end,
  request=function(m,body,mask,urgent,rank)assert(body and not mask and not urgent and rank==0);requests[#requests+1]=m.id end},
 HorizonWall={preferBody=function()return true end,cacheStatus=function(scene)
  for _,s in ipairs(horizons)do if s==scene then return{ready=true}end end;return{ready=false}
 end,prepareOptional=function(scene,visible)
  assert(visible.map.id=='ROUTE_16_GATE_1F','visible room not protected')
  horizons[#horizons+1]=scene;return{},true,false
 end},
 TerrainAtlas={setLive=function()end,prepared=function(m)return textured[m.id]end,prepare=function(m)textured[m.id]=true;textures[#textures+1]=m.id end},
 WorldResidency={retained=function()return{EAST=true,WEST=true,NEIGHBOR=true}end,capacity=function()return capacity end,touch=function()end},
 VoxelState={active=function()return active end},
 GateDoors=assert(loadfile('lib/GateDoors.lua'))(),
 WarpDestinations=assert(loadfile('lib/WarpDestinations.lua'))(),
 VisibleNeighborhood={setting={get=function()return true end}}}
local M=assert(loadfile('lib/GatePrefetch.lua')){require=function(n)return assert(modules[n],n)end}
local function gate(x)
 return{map={id='ROUTE_16_GATE_1F',def={warps={{x=0,y=3,destMap='WEST'},
 {x=15,y=3,destMap='EAST'},{x=1,y=1,destMap='LOFT'},{x=2,y=2,destMap='BROKEN'}}}},
 player={cellX=x,cellY=3},lastOutdoor={id='WEST'}}
end
local game={data={maps=defs},overworld=gate(0)}
local forestGate=gate(0);defs.FOREST={tileset='FOREST'}
forestGate.map.def.warps[2].destMap='FOREST'
assert(M.destination(game,forestGate)=='FOREST','forest gate prepared wrong side')
assert(M.destination(game,game.overworld)=='EAST','opposite exit not selected')
assert(M.destination(game,gate(15))=='WEST','reverse entry wrong')
game.overworld.map.def.warps[1].destMap='LAST_MAP'
assert(M.destination(game,game.overworld)=='EAST','LAST_MAP entrance lost')
local function tick(covered)modules.VoxelState.ready=ready;M.update(game,covered or false)end
tick();assert(#loads==0 and M.status().destination=='EAST','did not capture entry before readiness')
game.overworld.player.cellX=14;ready=true;priority=true;tick();assert(#loads==0)
priority=false;dt=.05;tick();assert(#loads==0,'slow-frame load')
dt=1/60;tick();assert(#loads==1 and loads[1]=='EAST','arrival direction changed while loading')
tick();assert(#loads==2 and #requests==0,'more than one allocation in tick')
tick();assert(requests[1]=='EAST' and #horizons==1,'scenery waited for all terrain');built.EAST=true
tick();assert(requests[2]=='NEIGHBOR');built.NEIGHBOR=true
tick();assert(#textures==1);tick();assert(#textures==2);tick()
assert(M.status().phase=='ready' and #horizons==1 and #horizons[1].neighbors==1)
assert(horizons[1].neighbors[1].ox==320,'native placement lost')
built.EAST=nil;tick();assert(requests[#requests]=='EAST','invalidated cache did not rearm')
game.overworld=gate(15);capacity=2;tick();assert(M.status().maps==1)
tick();assert(requests[#requests]=='WEST','small cache root missing')
assert(M.status().maps==1,'small cache expanded whole ring')
active=false;local count=#loads;tick();assert(not M.status() and #loads==count,'vanilla generated work')
active=true;mobile=true;capacity=16;game.overworld=gate(0);tick();tick()
assert(M.status().maps==1,'mobile expanded desktop ring')
game.overworld.map.id='HOUSE';tick();assert(not M.status(),'gate state survived exit')
mobile=false;game.overworld=gate(0);modules.WorldResidency.retained=function()return{}end
built.EAST=nil;tick();tick();tick()
assert(M.status().failed=='cache budget' and modules.VoxelState.ready,'budget miss broke visible scene')
local failedRequests=#requests;tick();assert(#requests==failedRequests,'evicted future area rebuilt in loop')
print('PASS gate preload: both entry sides, native LAST_MAP, stairs excluded, one allocation/job/resource per tick, slow-frame/priority/vanilla gates, mobile and low cache, invalidation')
