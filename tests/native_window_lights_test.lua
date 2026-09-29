-- A cold neighbour must never trigger CPU/GPU model construction from lighting.
-- Once its mesher publishes analysis, exactly the same panes join the scene.
local published={}
local reads,gen2Reads=0,0
local modules={
 Structures={
  peek=function(map)return published[map.id]end,
  forMap=function()error('lighting started synchronous terrain/furniture construction')end,
  lightingForMap=function(map)gen2Reads=gen2Reads+1;return published[map.id]end,
 },
 GlassMask={rects=function()reads=reads+1;return{{x=0,y=0,w=128,h=128}}end},
 LedgeElevation={map=function()return{atTile=function()return 4 end}end},
}
local V={require=function(name)return assert(modules[name],name)end}
local M=assert(loadfile('lib/NativeWindowLights.lua'))(V)
local main,nextMap={id='MAIN',tileset={}},{id='NEXT',tileset={}}
local state={map=main,neighbors={{map=nextMap,ox=100,oy=-20}}}
local function append()
 local lights,blockers={},{};M.append(state,lights,blockers,.5,{0,0,0});return lights,blockers
end
local empty=append();assert(#empty==0 and reads==0,'cold geometry inspected')
local quad={{0,0,0},{8,0,0},{8,8,0},{0,8,0},u=.5,v=.5}
local function analysis(mx,mz)return{buildingStamps={{mx=mx,mz=mz,quads={quad}}}}end
published.MAIN=analysis(10,20)
local lights,blockers=append()
assert(#lights==1 and #blockers==1,'pending neighbour must not duplicate current lights')
local old=lights[1]
assert(old.x==14 and old.y==8 and old.z==20.75 and old.power==.45 and old.radius==56)
assert(old.normal[1]==0 and old.normal[2]==0 and old.normal[3]==1)
assert(blockers[1].lo[1]==10 and blockers[1].lo[2]==4 and blockers[1].hi[1]==18)
-- Publication must become visible on the next lighting pass, without a map
-- change, setting toggle or invalidation of unrelated light instances.
published.NEXT=analysis(2,3)
lights,blockers=append();assert(#lights==2 and #blockers==2)
local joined=lights[2]
assert(joined.x==106 and joined.y==8 and joined.z==-16.25 and joined.power==old.power)
assert(lights[1].x==old.x and lights[1].z==old.z and lights[1].normal[3]==old.normal[3])
-- Invalidated/evicted geometry must not retain ghost lights in a local cache.
published.NEXT=nil;lights=append();assert(#lights==1)
published.MAIN=nil;lights=append();assert(#lights==0)
-- The separately owned Gen-2 published-light API remains unchanged.
V.lightingGeneration=2;published.MAIN=analysis(10,20)
lights=append();assert(gen2Reads==2 and #lights==1 and lights[1].y==4)
M.invalidate();lights=append();assert(#lights==1 and lights[1].x==14)
print('PASS native window lights: no cold map builds; complete lights after publication; translation/elevation; eviction; Gen-2 path')
