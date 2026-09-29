local modules={};local V={require=function(n)return assert(modules[n],n)end}
local enabled=true
local north={edge='north',at=0,from=0,upto=480,openings={}}
local door={from=80,upto=96,height=24,open=false}
local partition={edge='north',at=64,from=0,upto=480,openings={door},wallThickness=16}
local profile={nativeRoomPanels=true,shellHeight=50,theme='corporate'}
modules.HorizonWall={interiorProfileFor=function()return profile end}
modules.Gen1InteriorLayout={panelsFor=function()return{north,partition}end}
modules.Gen1InteriorFinish={placement=function()return nil end}
modules.SilphWindows={enabled=function()return enabled end,perimeter=function(_,p)return enabled and p==north end}
local I=assert(loadfile('lib/InteriorLights.lua'))(V)
local map={id='SILPH_CO_1F',def={width=15,height=9,blocks={}}}
local layout=I.layout(map);assert(#layout.portals==1)
assert(layout.portals[1].rect[3]==10 and layout.portals[1].rect[4]==45)
local function crosses(b,x,y,z)return x>b.lo[1]and x<b.hi[1]and y>b.lo[2]and y<b.hi[2]and z>=b.lo[3]and z<=b.hi[3]end
local function blocked(x,y,z)for _,b in ipairs(layout.blockers)do if crosses(b,x,y,z)then return true end end;return false end
assert(not blocked(200,25,0)and blocked(200,5,0)and blocked(200,48,0))
assert(blocked(88,15,64),'closed security door admits sunlight')
door.open=true;map.def.blocks[1]=1;layout=I.layout(map)
assert(not blocked(88,15,64)and blocked(88,30,64),'door lintel is not opaque')
enabled=false;layout=I.layout(map);assert(#layout.portals==0 and blocked(200,25,0),'window toggle leaks light')
modules.CanvasPresentation={OS='OS X'}
modules.ModSetting={new=function()return{setGate=function()end}end}
local L=assert(loadfile('lib/LocalLights.lua'))(V)
local panes={}
for _,n in ipairs{{1,0,0},{-1,0,0},{0,0,1},{0,0,-1}}do panes[#panes+1]={normal=n,facade=true}end
local east=L.windowPortals(panes,{.8,.6,0,1});local west=L.windowPortals(panes,{-.8,.6,0,1})
assert(#east==1 and east[1].normal[1]==-1)
assert(#west==1 and west[1].normal[1]==1)
assert(#L.windowPortals(panes,{0,1,0,1})==0,'overhead sun lights vertical facade')
assert(#L.windowPortals(panes,{.5,.7,.5,1})==2,'diagonal sun should illuminate two faces')
print('PASS daylight: sill/lintel, open and closed partitions, OFF cache invalidation, sun-facing selection, two-facade mobile budget')

-- Domestic apertures must not turn their entire wall into a sunlight portal.
enabled=true
modules.SilphWindows.panelApertures=function()return{{from=120,upto=160,bottom=12,top=30}}end
map.def.blocks[1]=2;layout=I.layout(map)
assert(#layout.portals==1)
assert(not blocked(140,20,0)and blocked(200,20,0)and blocked(140,35,0)and blocked(140,8,0))
print('PASS house daylight restricted to actual glass, opaque wall and window head/sill')
