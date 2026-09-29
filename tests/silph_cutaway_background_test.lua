local Bounds=assert(loadfile('lib/Gen1RoomBounds.lua'))()
local B=assert(loadfile('lib/SilphCutawayBackground.lua'))({require=function(n)assert(n=='Gen1RoomBounds');return Bounds end})
local function sum(pieces)local n=0;for _,p in ipairs(pieces)do n=n+math.abs(B.area(p))end;return n end
assert(sum(B.complement({}))==4)
local whole={{-1,-1},{1,-1},{1,1},{-1,1}}
assert(#B.complement({whole})==0,'near-glass full view lost its sky')
local half={{-1,-1},{0,-1},{0,1},{-1,1}}
local reverse={{-1,1},{0,1},{0,-1},{-1,-1}}
assert(sum(B.complement({half}))==2 and sum(B.complement({reverse}))==2)
assert(sum(B.complement({half,half}))==2,'overlapping panes double-mask sky')
local other={{0,-1},{1,-1},{1,1},{0,1}}
assert(#B.complement({half,other})==0)
local diamond={{0,-1},{1,0},{0,1},{-1,0}}
assert(math.abs(sum(B.complement({diamond}))-2)<1e-8,'angled edge leaks sky')
local Mat=assert(loadfile('lib/Mat4.lua'))()
for _,eye in ipairs{{128,100,240},{128,24,3},{-30,90,350},{128,24,0}}do
 local vp=Mat.mul(Mat.perspective(1,1.5,.1,6000),Mat.lookAt(eye,{128,24,-80},{0,1,0}))
 local windows=B.windows(256,288,50,eye,vp)
 local pieces=B.complement(windows);local a=sum(pieces)
 assert(a>=0 and a<=4.00001)
 for _,poly in ipairs(pieces)do for _,p in ipairs(poly)do assert(p[1]==p[1]and p[2]==p[2]and math.abs(p[1])<=1.00001 and math.abs(p[2])<=1.00001)end end
end
print('PASS black complement: full/empty/overlapping/angled panes; near-plane and orbit projection; finite viewport bounds')

assert(B.inside(480,288,50,{240,24,100}),'third person inside must keep ceiling')
assert(not B.inside(480,288,50,{240,100,100}),'overview above ceiling must cut away')
assert(not B.inside(480,288,50,{-20,24,100}),'outside camera must cut away')
B.paint({},1200,800,{def={width=15,height=9}},50,{240,24,100},{})
assert(B.lastPieces==0,'indoor camera received black backdrop')
print('PASS indoor first/third person retains ceiling and sky; only outside/above camera uses black surround')
