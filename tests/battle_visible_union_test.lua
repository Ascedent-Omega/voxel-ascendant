-- SCENERY OFF must use the scene's proven visible union, while still
-- rejecting an unproved partial arena or a missing terrain/horizon.
package.preload['src.render.PaletteFX']=function()return{}end
local host={id='HOST'};local state={map=host,neighbors={{},{},{},{},{}}}
local plan={state={map=host,neighbors={{},{}}},warmComplete=true}
local terrain={};local horizonReady=true;local semantic=false
local modules={
 VoxelScene={prefetch=function()return terrain,{},nil,{},plan end},
 HorizonWall={meshes=function()return{},horizonReady end,preferBody=function()return semantic end},
}
local B=assert(loadfile('lib/BattleScene.lua')){require=function(name)return modules[name]or{}end}
assert(B._prefetchArena(state,host),'complete filtered union declined')
plan.warmComplete=false;assert(not B._prefetchArena(state,host),'unproved partial union admitted')
plan.state.neighbors=state.neighbors;assert(B._prefetchArena(state,host),'legacy complete union declined')
plan.state.neighbors={{},{}};plan.warmComplete=true
horizonReady=false;assert(not B._prefetchArena(state,host),'missing horizon admitted');horizonReady=true
terrain=nil;assert(not B._prefetchArena(state,host),'missing terrain admitted');terrain={}
plan.warmComplete=false;semantic=true;assert(B._prefetchArena(state,host),'closed semantic partial union declined')
print('PASS battle visible union: proven ordinary-voxel arena, legacy full union, terrain/horizon/partial guards and semantic closure')
