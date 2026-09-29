local function section(path,first,last)
 local f=assert(io.open(path));local s=f:read('*a');f:close()
 local a=assert(s:find(first,1,true));local b=assert(s:find(last,a,true))
 return s:sub(a,b-1)
end
local G={eye={0,8,0},focus={0,8,40}}
local env={Voxel3D=G,VoxelScene={}}
setmetatable(env,{__index=_G})
local fn=assert(loadstring(section('lib/VoxelScene.lua','local ACTOR_CARD_SIZE','-- ------- the cast')))
setfenv(fn,env);fn()
local test=env.VoxelScene._actorEngulfsEye
local function model(bounds)return{px=0,py=0,stadiumBounds=bounds}end
assert(test(model{-20,0,2,20,25,30}),'near large follower not hidden')
assert(test(model{-20,0,-5,20,25,30}),'camera inside follower not hidden')
assert(not test(model{20,0,2,40,25,30}),'off-axis actor hidden')
assert(not test(model{-20,30,2,20,60,30}),'actor above eye hidden')
assert(not test(model{-20,0,-30,20,25,-2}),'actor behind eye hidden')
assert(not test(model{-20,0,17,20,25,40}),'distant actor hidden')
G.focus={0,8,0};assert(not test(model{-20,0,-5,20,25,30}))
local B={steerable=true,orbit=0,orbitGoal=0,pitch=0,pitchGoal=0,zoom=1,zoomGoal=1,directorClock=12,directorManualUntil=0,DIRECTOR_MANUAL_HOLD=4}
local camenv={BattleCam=B,activeArena={map={}},authoredArena=function(a)return a and a.arenaStyle end}
setmetatable(camenv,{__index=_G})
local cam=assert(loadstring(section('lib/BattleCam.lua','local function setAxis','-- A drag,')..' return setAxis'))
setfenv(cam,camenv);local setAxis=cam()
assert(setAxis('orbitGoal',.2));assert(B.directorManualUntil==math.huge,'MAP director reclaimed manual view')
camenv.activeArena={discs=true};assert(setAxis('orbitGoal',.3));assert(B.directorManualUntil==16,'DISCS hold changed')
camenv.activeArena={arenaStyle='authored'};assert(not setAxis('orbitGoal',.4),'authored camera moved')
B.steerable=false;camenv.activeArena={map={}};assert(not setAxis('pitchGoal',.2),'locked camera moved')
print('PASS near imported follower ray bounds, MAP manual persistence, DISCS hold and authored/locked input guards')
