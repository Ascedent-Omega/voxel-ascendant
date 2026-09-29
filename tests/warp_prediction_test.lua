local requests,loads,touches={},{},{}
local defs={HOUSE={connections={}},TOWN={connections={north={map='NEXT'}}}}
package.loaded['src.core.Platform']={detect=function()return{mobile=false}end}
package.loaded['src.world.MapLoader']={load=function(_,id)loads[#loads+1]=id;return{id=id,def=defs[id]}end}
package.loaded['src.world.Warp']={destination=function(_,w,last)return w.destMap=='LAST_MAP'and last.id or w.destMap end}
local voxel={ready=true,active=function()return true end}
local chunk={preloadSetting={get=function()return false end},hasPriorityWork=function()return false end,
 request=function(map,body,masks,urgent,priority)requests[#requests+1]={map.id,body,urgent,priority}end}
local modules={RegionPreparation={arm=function()end},WarpDestinations=assert(loadfile('lib/WarpDestinations.lua'))(),ChunkMesher=chunk,HorizonWall={preferBody=function(m)return m.id=='TOWN'end},VoxelState=voxel,
 WorldResidency={touch=function(id)touches[#touches+1]=id end}}
local M=assert(loadfile('lib/WarpPrefetch.lua')){require=function(n)return assert(modules[n],n)end}
local nativeCalls=0
local ow={map={id='CURRENT',def={warps={{x=10,y=10,destMap='HOUSE'},{x=1,y=1,destMap='UNKNOWN'}}}},player={cellX=10,cellY=15},startWarpTo=function()nativeCalls=nativeCalls+1;return 'native',17 end}
local game={overworld=ow,data={maps=defs}}
assert(M.install(game));M.update(game,false)
assert(loads[1]=='HOUSE' and requests[1][1]=='HOUSE' and requests[1][3]==false and requests[1][4]==0,'prediction became urgent')
M.update(game,false);assert(#loads==1,'same cell repeatedly loaded')
ow.player.cellX=40;M.update(game,false);assert(#loads==1,'distant doors prefetched')
ow.player.cellX=10;voxel.ready=false;M.update(game,false);assert(#loads==1,'prediction competes with loading')
voxel.ready=true;chunk.hasPriorityWork=function()return true end;M.update(game,false);assert(#loads==1,'prediction competes with visible jobs')
chunk.hasPriorityWork=function()return false end
ow.map.def.warps={{x=10,y=15,destMap='LAST_MAP'}};ow.lastOutdoor={id='TOWN'};ow.player.cellY=14
M.update(game,false);assert(loads[#loads]=='TOWN','LAST_MAP ignored native resolver')
local a,b=ow:startWarpTo('HOUSE');assert(a=='native'and b==17 and nativeCalls==1,'warp behavior changed')
print('PASS predictive preload: real nearby destination, one probe per cell, no priority/load competition, native warp preserved')
