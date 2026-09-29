local time,created,released,input=0,0,0,0
local active=true
local function noop()end
love={timer={getTime=function()return time end},graphics={
 newCanvas=function()created=created+1;return{release=function()released=released+1 end}end,
 push=noop,pop=noop,setCanvas=noop,origin=noop,setShader=noop,setScissor=noop,
 setDepthMode=noop,setBlendMode=noop,setColor=noop,clear=noop,draw=noop,setColorMask=noop}}
local OW={handleInput=function()input=input+1;return 'input' end}
package.loaded['src.world.OverworldController']=OW
local H=assert(loadfile('lib/WorldSceneHold.lua')){require=function(name)
 assert(name=='VoxelState');return{active=function()return active end}end}
local world=setmetatable({map={id='ROUTE_12'}},{__index=OW})
H.install();H.install()
local first=assert(H.pending(world,800,600,'horizon-pending'))
assert(H.loading(world));assert(world:handleInput()==nil and input==0)
time=30
assert(H.pending(world,800,600,'horizon-pending')==first,'slow load leaked native 2D')
assert(created==1,'cover reallocated each frame')
H.presented({},world,800,600)
assert(not H.loading(world) and released==1)
assert(world:handleInput()=='input' and input==1)
-- A later rebuild on the same, already displayed map must stay covered too.
assert(H.pending(world,800,600,'props-pending'))
active=false;assert(world:handleInput()=='input' and input==2);active=true
assert(not H.pending(world,800,600,'shader-failed'),'renderer error hidden indefinitely')
assert(not H.loading(world))
world.map={id='ROUTE_13'}
assert(H.pending(world,800,600,'terrain-pending'))
assert(H.pending(world,600,800,'terrain-pending'));assert(released==3)
H.clear();assert(not H.loading(world));assert(created==released)
print('PASS world scene hold: slow load, post-reveal rebuild, input, vanilla, errors, resize, cleanup')
