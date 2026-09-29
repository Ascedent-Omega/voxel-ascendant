local O=assert(loadfile('lib/PropOcclusion.lua'))();O.enabled=true
local D=assert(loadfile('lib/DistantProps.lua'))()
local I={1,0,0,0,0,1,0,0,0,0,1,0,0,0,0,1};local eye={0,5,0};local mesh={}
local faces=O.faces({{mesh,nil,I}},function()return{{-10,-10,10,10,20,12}}end,eye,0)
assert(O.hidden({-1,4,20,1,6,22},I,faces,eye))
assert(not O.hidden({-1,4,4,1,6,6},I,faces,eye),'front object hidden')
assert(not O.hidden({-1,4,9,1,6,13},I,faces,eye),'intersecting object hidden')
assert(not O.hidden({-1,4,20,40,6,22},I,faces,eye),'partly visible object hidden')
assert(#O.faces({{mesh,nil,I}},function()return{{-10,-10,10,10,20,12}}end,eye,.001)==0,'curved view treated as flat')
local gap=O.faces({{mesh,nil,I}},function()return{{-10,-10,10,-2,20,12},{2,-10,10,10,20,12}}end,eye,0)
assert(not O.hidden({-.5,4,20,.5,6,22},I,gap,eye),'door gap filled')
local boxes={{0,0,0,20,20,20,1}}
for i=1,20 do boxes[#boxes+1]={i%16,3,2,2,2,2,2}end
boxes[#boxes+1]={20,0,0,2,8,3,3}
local low=assert(D.model({terrain=true,boxes=boxes}))
assert(#low.boxes==2 and low.boxes[2]==boxes[#boxes],'silhouette feature removed')
assert(not D.model({terrain=true,boxes=boxes,landmarkHeight=100}),'landmark simplified')
local smallProjection={.001,0,0,0,0,.001,0,0,0,0,.001,0,0,0,0,1}
local far={1,0,0,500,0,1,0,0,0,0,1,0,0,0,0,1}
assert(D.use({0,0,0,20,20,20},far,eye,smallProjection,800),'small distant prop not selected')
far[1]=0;far[3]=1;far[9]=-1;far[11]=0
assert(not D.use({0,0,0,20,20,20},far,eye,smallProjection,800),'rotated footprint assumed to be translated')
local B=assert(loadfile('lib/BackgroundBudget.lua'))();local dt=1/30
love={timer={getDelta=function()return dt end}}
for i=1,59 do assert(B.allowance(.004,false)==0)end
assert(B.allowance(.004,false)==.00025,'no bounded progress')
assert(B.allowance(.012,true)==.012,'load cover throttled')
dt=1/120;assert(B.allowance(.004,false)>0 and B.allowance(.004,false)<.004)
print('PASS render round2: conservative occlusion/gaps, unchanged distant solid union, bounded optional work')
-- Compare every occupied voxel, not just an enclosing box: the distant
-- template may change paint, but cannot introduce holes or new solids.
local function occupied(list,x,y,z)
 for _,b in ipairs(list)do if x>=b[1]and y>=b[2]and z>=b[3]and x<b[1]+b[4]and y<b[2]+b[5]and z<b[3]+b[6]then return true end end
 return false
end
for z=-1,21 do for y=-1,21 do for x=-1,23 do assert(occupied(boxes,x,y,z)==occupied(low.boxes,x,y,z))end end end
local M=assert(loadfile('lib/Mat4.lua'))()
local modules={Mat4=M,VoxelState={angle=.7,FOCAL=1},Gen1CaveWalls={}}
local S=assert(loadfile('lib/ShadowMap.lua')){require=function(n)return assert(modules[n],n)end}
local fit
for i=1,100 do local n,v=debug.getupvalue(S.begin,i);if not n then break end;if n=='fit'then fit=v end end
assert(fit);fit(0,0,320,180,160,true);local a=S.clipVP
fit(20,20,320,180,160,true);for i=1,16 do assert(a[i]==S.clipVP[i],'stationary shadow projection changed inside retained cell')end
fit(80,0,320,180,160,true);assert(a[4]~=S.clipVP[4]or a[8]~=S.clipVP[8],'cell transition retained stale projection')
print('PASS exact distant solid union and padded shadow projection reuse')
