local module=assert(loadfile('lib/ScenePrefetchCache.lua'))()
local C=module.new()
local a={id='A',def={width=10,height=9,connections={east={map='B',offset=0}}}}
local b={id='B',def={width=10,height=9}}
local s={map=a,player={cellX=1,cellY=2,px=16,py=32,facing='right'},neighbors={{map=b,ox=320,oy=0}}}
assert(module.covers(s,{A=true,B=true}),'published required maps rejected')
assert(not module.covers(s,{A=true,OLD=true}),'equal-sized obsolete neighbourhood reused')
assert(not module.covers(s,{B=true}),'missing current map reused')
assert(module.covers(s,{A=true,B=true,OLD=true}),'complete retained superset rejected')
local result={'terrain',{},nil,{}, {state=s}}
C.store(s,1,result,1,false,'trees')
assert(C.get(s,1,1,false,'trees')==result,'same-frame work repeated')
assert(not C.get(s,2,1,false,'trees'),'new active frame skipped')
assert(not C.get(s,1,2,false,'trees'),'mesh invalidation ignored')
assert(not C.get(s,1,1,true,'trees'),'cover change ignored')
assert(not C.get(s,1,1,false,'water'),'option change ignored')
s.player.cellX=2;assert(not C.get(s,1,1,false,'trees'),'seam move ignored')
assert(C.matches(s,true,1,false,'trees'),'2D movement retriggers finished warmup')
s.player.cellX=1
s.neighbors[1].ox=352;assert(not C.get(s,1,1,false,'trees'),'in-place offset edit ignored');s.neighbors[1].ox=320
a.def.connections.east.offset=1;assert(not C.get(s,1,1,false,'trees'),'connection edit ignored');a.def.connections.east.offset=0
b.def.width=11;assert(not C.get(s,1,1,false,'trees'),'neighbor size edit ignored');b.def.width=10
s.neighbors[2]={map=b,ox=0,oy=288};assert(not C.get(s,1,1,false,'trees'),'new neighbor ignored');s.neighbors[2]=nil
s.map={id='A',def=a.def};assert(not C.get(s,1,1,false,'trees'),'same-id map replacement ignored');s.map=a
assert(C.get(s,1,1,false,'trees')==result)
s.player.cellX=3;s.player.px=48;s.player.facing='down'
assert(C.reuse(s,2,1,false,'trees')==result,'complete union cannot extend across walking frames')
assert(C.get(s,2,1,false,'trees')==result,'extended receipt does not share the draw frame')
assert(not C.reuse(s,3,2,false,'trees'),'cross-frame reuse ignored geometry revision')
s.neighbors[1].oy=16;assert(not C.reuse(s,3,1,false,'trees'),'cross-frame reuse ignored topology')
s.neighbors[1].oy=0
C.clear();assert(not C.get(s,1,1,false,'trees'));assert(not C.reuse(s,4,1,false,'trees'))
print('PASS prefetch receipt: frames, revisions, options, topology, map replacement and warm movement')
