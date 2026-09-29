local now=0
love={timer={getTime=function()return now end}}
local enabled=true;local resolved,draws=0,0
local modules={BuildBudget=assert(loadfile('lib/BuildBudget.lua'))(),
 Weather={clock=0},Mat4={translate=function()return{}end},Voxel3D={draw=function()draws=draws+1 end}}
local P={models={},decorColors={silver=14},resourceVersion=0,setting={get=function()return enabled end}}
modules.VoxelItems=P
local cache={}
P.resolveKind=function(kind)
 if not cache[kind]then
  for i=1,5 do now=now+.0005;modules.BuildBudget.check()end
  resolved=resolved+1;cache[kind]={kind=kind}
 end
 return cache[kind],{}
end
local V={require=function(n)return assert(modules[n],n)end}
local F=assert(loadfile('lib/SilphFountains.lua'))(V)
local map={id='SILPH_CO_1F',def={width=15,height=9,tileset='FACILITY'},tileAt=function()return 20 end,isWaterCell=function()return true end}
assert(not F.prepared(map));F.draw({map=map});assert(resolved==0 and draws==0,'draw built cold geometry')
local frames=0
repeat
 local before=now;F.prepare(map,true);assert(now-before<=.0026,'covered slice unbounded')
 frames=frames+1;assert(frames<100)
until F.prepared(map)
assert(resolved==17,'not all animation phases prepared')
for i=0,31 do modules.Weather.clock=i/12;F.draw({map=map})end
assert(draws==128 and resolved==17,'animation caused a new upload')
P.resourceVersion=1;cache={};assert(not F.prepared(map),'stale graphics receipt survived reset')
F.draw({map=map});assert(draws==128,'released mesh drawn')
enabled=false;assert(F.prepared(map));enabled=true
P.resolveKind=function()error('bad mesh')end
assert(F.prepare(map,true) and F.prepared(map),'failed resource deadlocked reveal')
assert(F.lastError:find('bad mesh'));F.draw({map=map});assert(draws==128)
assert(F.prepared({id='SILPH_CO_2F'}))
print('PASS fountain prewarm: bounded slices, 17 resources, zero draw-time builds, invalidation, OFF, failure')
