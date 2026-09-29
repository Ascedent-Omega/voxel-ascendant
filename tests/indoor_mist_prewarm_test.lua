local count,active,enabled,profile,fail=0,true,true,true,false
love={graphics={newShader=function(source)count=count+1;if fail then error('unsupported')end;return {release=function()end,source=source}end}}
local mods={LocalLights={active=function()return active end,enabled=function()return enabled end,glsl=function()return 'lights' end},
 HorizonWall={interiorProfileFor=function()return profile and {nativeRoomPanels=true}end}}
local M=assert(loadfile('lib/IndoorMist.lua')){require=function(n)return assert(mods[n],n)end}
M.profile=function()return nil end
M.litSource=function()return 'lit' end
local map={}
assert(M.prepareProgram(map,false)and count==1,'cold room failed to prepare before light frame exists')
assert(not M.prepareProgram(map,false)and count==1,'warm room compiled twice')
active=false
assert(M.prepareProgram(map,false)and count==2,'unlit variant missing')
assert(not M.prepareProgram(map,false)and count==2)
M.invalidate();profile=false;enabled=false
assert(not M.prepareProgram(map,false)and count==2,'irrelevant map compiled')
M.profile=function()return {}end
assert(not M.prepareProgram(map,true)and count==2,'dark map compiled')
fail=true
assert(M.prepareProgram(map,false)and count==3 and M.programError,'failure missing')
assert(not M.prepareProgram(map,false)and count==3,'failed shader retried forever')
M.invalidate();fail=false
assert(M.prepareProgram(map,false)and count==4 and not M.programError,'invalidation cannot retry')
print('PASS mist prewarm: relevant room before lighting, one selected shader per step, dark/off, failure and retry')
