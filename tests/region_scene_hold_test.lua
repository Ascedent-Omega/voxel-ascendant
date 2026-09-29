local ready=true
local map={id='CITY'};local cover={phase='in',alpha=function()return 1 end}
local top=cover;local ow={map={id='GATE'}}
local game={overworld=ow,data={},stack={top=function()return top end}}
local modules={RegionPlan={isLarge=function()return false end,isOutside=function()return true end,
 isBoundary=function()return true end,sameBuilding=function()return false end,
 new=function()return{ids={}}end,step=function()return false end},
 ChunkMesher={},TerrainAtlas={},HorizonWall={},WorldResidency={},VoxelState={active=function()return true end},
 VoxelScene={readyForReveal=function()return ready end}}
local R=assert(loadfile('lib/RegionPreparation.lua')){require=function(n)return assert(modules[n],n)end}
local canvas={};local function remember()R.rememberScene(canvas,ow,800,600,400,300)end
local function cached()return R.cachedScene(ow,800,600,400,300)end
R.arm(game,'CITY');ow.map=map
remember();assert(not cached(),'cached before region job existed')
assert(not R.transitionReady(game,true));remember();assert(cached()==canvas)
assert(not R.cachedScene(ow,801,600,400,300),'resize reused canvas');assert(not cached())
remember();ready=false;assert(not cached(),'invalidation reused incomplete scene');ready=true
remember();assert(not R.transitionReady(game,false));assert(not cached(),'not-ready transition retained frame')
remember();top={phase='in',alpha=function()return 1 end};assert(not cached(),'different cover reused frame')
top=cover;remember();cover.alpha=function()return .9 end;assert(not cached(),'fade reused frozen scene')
cover.alpha=function()return 1 end;remember();top=ow;assert(not cached(),'gameplay reused frame')
top=cover;remember();local old=ow.map;ow.map={id='CITY'};assert(not cached(),'different map object reused frame');ow.map=old
R.arm(game,'OTHER');assert(not cached(),'new transition retained old frame')
R.transitionReady(game,true);assert(not cached(),'cancelled transition retained frame')
print('PASS region scene hold: opaque native job only, same owner/map/cover/dimensions, readiness, fade, gameplay and cancellation')
