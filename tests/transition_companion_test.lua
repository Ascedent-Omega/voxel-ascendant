local probes,sceneReady,owner=0,false,'voxel'
local map={id='DEST'};local game={overworld={map=map}}
local V={mod={id='VOXEL_ASCENDANT'},require=function(n)
 if n=='VoxelScene'then return{readyForReveal=function()return sceneReady end}end
 if n=='LoadingCompanion'then return{probe=function(_,ready)probes=probes+1;assert(ready==sceneReady)end}end
 error(n)
end}
local P={worldPipeline=function()return owner end}
local T={}
function T.update(self)
 self.t=self.t+1
 if self.phase=='out'and self.t>=self.frames then self.phase='in';self.t=0;self.midpoint=self.midpoint+1;self:finish('native')end
end
local R=assert(loadfile('lib/TransitionReveal.lua'))(V)
R.configure{Pipelines=P,Game=game,Schemas={},Transition=T}
R.configure{Pipelines=P,Game=game,Schemas={},Transition=T}
local finished=0
local a=setmetatable({phase='out',t=0,frames=1,framesIn=0,midpoint=0,finish=function(self,arg)assert(arg=='native');finished=finished+1 end},{__index=T})
a:update();assert(a.midpoint==1 and finished==0 and probes==1)
a:update();assert(a.midpoint==1 and finished==0)
sceneReady=true;a:update();assert(finished==1 and a.midpoint==1)
owner='vanilla';sceneReady=false;local before=probes
a.phase='out';a.t=0;a:update();assert(finished==2 and probes==before,'vanilla waited or animated')
print('PASS native zero-in reveal: cold hold, one midpoint/callback, idempotent hook and vanilla bypass')
