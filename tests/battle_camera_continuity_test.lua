local f=assert(io.open('lib/BattleCam.lua'));local source=f:read('*a');f:close()
local function between(a,b)
 local first=assert(source:find(a,1,true));local last=assert(source:find(b,first+#a,true))
 return source:sub(first,last-1)
end
local battle={phase='moveSelect',player={mon={}},enemy={mon={}}}
local arena={map={}}
local camera={eye={10,30,50},focus={0,0,0},fov=.5}
local checks,rescues=0,0
local result,reason=false,'playerHero-under-fight'
local finalFault
local C={directorClock=0,directorManualUntil=0,viewportW=1196,viewportH=540,
 angularCamera=function()return false end}
local env={BattleCam=C,activeBattle=battle,activeArena=arena,
 screenSafetyEvaluator=function()end,
 sameScreenOwner=function(r,a,b)return r and rawequal(r.arena,a)and rawequal(r.battle,b)end,
 screenSafeCamera=function(_,_,_,_,context)
  checks=checks+1
  if finalFault and context.phase=='rendered-composition-retain' then
   return nil,finalFault
  end
  return result,reason
 end,
 freezeRejectedDirectorPath=function()end,rollbackManualInput=function()return false end,
 exhaustPendingScreenFrames=function()end,consumePendingScreenFrame=function()return false end,
 retreatActorCamera=function()end,renderedPortableFrameRescue=function()end,
 renderedActorFrameRescue=function()rescues=rescues+1 end,
 authoredArena=function()return false end}
local code=between('local function copyCamera(', 'local function rollbackManualInput(')
 ..between('local function returnRevalidatedScreenCamera(', '-- Large flying poses')
 ..between('local function guardRenderedCamera(', '-- Decide once whether')
 ..'\nreturn guardRenderedCamera, compositionLimit'
local chunk=assert(loadstring(code));setfenv(chunk,setmetatable(env,{__index=_G}))
local guard,limit=chunk()
for _,r in ipairs({'playerHero-under-fight','enemy-under-message','player-under-command',
 'enemyHero-under-enemy-status','player-outside-safe-frame','enemyHero-outside-safe-frame',
 'actor-pair-too-close','status-card-overlap','owner-render-unsafe'})do
 result,reason=false,r;C.compositionContinuity=nil
 local cam=guard(arena,0,camera,1,false)
 assert(cam and cam~=camera and cam.eye[1]==10,r..' retired the chosen view')
 assert(C.screenSafetyOK==false and C.screenSafetyReason=='composition-limited:'..r)
 local calls=rescues
 for i=1,300 do assert(guard(arena,0,camera,1,false))end
 assert(rescues==calls,'repeated expensive rescues in unchanged composition')
end
for _,r in ipairs({'evaluator-error:broken','provider-bounds-malformed','owner-render-pending',
 'playerHero-placement-unavailable','actor-contact-outside-ground','camera-travel-blocked',
 'garbage-under-fight','rendered-owner-mismatch'})do
 assert(not limit(r),'non-composition fault was whitelisted: '..r)
 result,reason=nil,r
 assert(guard(arena,0,camera,1,false)==nil,'cached pose masked fault '..r)
end
result,reason=false,'enemy-under-message'
for _,fault in ipairs({'provider-bounds-malformed','evaluator-error:failed'})do
 C.compositionContinuity=nil;finalFault=fault
 assert(guard(arena,0,camera,1,false)==nil,'final chosen camera masked '..fault)
end
finalFault=nil
assert(guard(arena,0,camera,1,false));local calls=rescues
battle.phase='menu';assert(guard(arena,0,camera,1,false));assert(rescues>calls)
calls=rescues;C.viewportW,C.viewportH=540,1196
assert(guard(arena,0,camera,1,false));assert(rescues>calls,'rotation reused old composition')
calls=rescues;battle.player.mon={}
assert(guard(arena,0,camera,1,false));assert(rescues>calls,'new deployment reused old composition')
calls=rescues;C.directorManualUntil=1
assert(guard(arena,0,camera,1,false));assert(rescues>calls,'manual input trapped in cached pose')
C.directorManualUntil=0
result,reason=true,'actor-hulls-clear'
assert(guard(arena,0,camera,1,false));assert(C.screenSafetyOK)
env.activeArena={}
assert(guard(arena,0,camera,1,false)==nil,'foreign owner reused camera')
print('PASS composition faults keep live view; bounded rescues; phase/rotation/deployment/manual reset; hard faults remain visible')
