local f=assert(io.open('gen2/lib/Voxel3D.lua'));local source=f:read('*a');f:close()
local a=assert(source:find('function Voxel3D.beginWater',1,true))
local b=assert(source:find('-- Put the frame back:',a,true))
local factory=assert((loadstring or load)('return function(active,canvas,held,depthTarget,activeShader) local Voxel3D={} '
 ..source:sub(a,b-1)..' return Voxel3D end'))()
local allocated,drawn,painted,fail=0,0,0,false
local target,depthMode,blend
love={graphics={newCanvas=function()allocated=allocated+1;return{}end,
 setShader=function()end,setDepthMode=function(mode)depthMode=mode end,
 setCanvas=function(value)if fail and value=='scene'then error('bind failed')end;target=value end,
 setBlendMode=function(mode)blend=mode end,setColor=function()end,clear=function()end,
 draw=function()drawn=drawn+1 end}}
local held={depth='depth',w=800,h=600};local attachment={};local paint=function()painted=painted+1 end
local G=factory(true,'scene',held,function()return attachment end,{})
local color,depth=G.beginWater(paint,'atlas')
assert(color=='atlas'and depth=='depth'and target=='scene'and depthMode==nil and blend=='alpha')
assert(allocated==0 and drawn==0 and painted==0 and not held.mirror)
G.beginWater(paint);assert(allocated==1 and drawn==1 and painted==1)
G.beginWater(paint);assert(allocated==1 and drawn==2 and painted==2,'FULL mirror not reused')
G.beginWater(paint,'atlas');assert(allocated==1 and drawn==2 and painted==2,'SKY copied existing mirror')
fail=true;assert(G.beginWater(paint,'atlas')==nil and target==attachment,'failure did not restore depth attachment')
assert(factory(false,'scene',held,function()end,{}).beginWater(paint,'atlas')==nil)
assert(factory(true,'scene',{},function()end,{}).beginWater(paint,'atlas')==nil)
print('PASS Gen2 SKY water: no allocation/copy/cast, detached depth, FULL reuse, failed binding recovery, unavailable scene')
