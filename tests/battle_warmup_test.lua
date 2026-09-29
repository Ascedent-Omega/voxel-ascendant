local clock,calls,uploads=0,{},0
love={timer={getTime=function()return clock end}}
local module={prepareResources=function(battle,side,checkpoint)
 calls[#calls+1]={battle,side}
 for i=1,40 do clock=clock+.0002;checkpoint() end
 checkpoint(true);uploads=uploads+1;checkpoint(true)
end}
local M=assert(loadfile('lib/BattleModelWarmup.lua'))({require=function(id)assert(id=='Stadium');return module end})
local owner={battle={}}
local steps=0
repeat
 local start=clock;assert(M.step(owner));steps=steps+1
 assert(clock-start<.0023,'decode exceeded cooperative budget')
 clock=clock+1
until owner.modelPreparationDone or steps>40
assert(owner.modelPreparationDone and not owner.modelPreparationJob)
assert(steps<20 and #calls==2 and uploads==2)
assert(calls[1][1]==owner.battle and calls[1][2]=='enemy' and calls[2][2]=='player')
assert(not M.step(owner) and #calls==2,'completed resources reloaded')
module.prepareResources=function()error('optional asset missing')end
local failed={battle={}};assert(M.step(failed) and failed.modelPreparationDone)
assert(not M.step(failed),'failure retries every frame')
print('PASS bounded per-frame model preparation, renewed deadlines, two sides, completion and failed-resource fallback')
