local steps,cancels,begins=0,0,0
local C={key=function()return 'key'end,beginRead=function()return nil end,
 beginWrite=function()begins=begins+1;return {left=3}end,
 stepWrite=function(t)steps=steps+1;t.left=t.left-1;return t.left==0 end,
 cancelWrite=function()cancels=cancels+1 end}
local g={getSystemLimits=function()return {texturesize=4096}end,
 newShader=function()return {send=function()end,release=function()end}end,
 newCanvas=function()return {setFilter=function()end,release=function()end}end}
for _,n in ipairs{'push','pop','origin','setScissor','setCanvas','setDepthMode','setMeshCullMode','setBlendMode','setColor','setShader','rectangle'}do g[n]=function()end end
love={graphics=g,timer={getTime=function()return 0 end}}
local V={require=function(n)if n=='StaticLightDiskCache'then return C end;return {GLSL=''}end}
local F=assert(loadfile('lib/StaticLightField.lua'))(V)
local grid={staticPower=1,staticKey='a',grid={0,0,2,2}}
for i=1,14 do F.beginFrame(true);F.prepare(grid,{})end
assert(begins==1 and steps==0 and F.pending(),'cache must keep reveal covered')
for i=1,10 do F.beginFrame(false);F.prepare(grid,{})end
assert(steps==0,'cache readback during play')
for i=1,3 do F.beginFrame(true);F.prepare(grid,{})end
assert(steps==3 and not F.pending() and begins==1)
F.invalidate();for i=1,14 do F.beginFrame(true);F.prepare(grid,{})end
F.invalidate();assert(cancels==1 and not F.pending(),'cancel before releasing texture')
local readSteps=0
C.beginRead=function()return {}end
C.stepRead=function()readSteps=readSteps+1;if readSteps==2 then return true,{release=function()end}end;return false end
F.beginFrame(true);assert(not F.prepare(grid,{}) and F.pending())
F.beginFrame(true);assert(F.prepare(grid,{}) and not F.pending() and F.last.diskHit)
print('PASS field persistence: covered steps, no play work, bounded completion, cancellation, async cache hit')
