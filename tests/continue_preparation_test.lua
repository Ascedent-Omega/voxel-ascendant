local active,ready,serial,calls=true,false,0,0
package.loaded['src.render.Pipelines']={worldPipeline=function()return active and 'voxel'or 'vanilla'end}
local pending
local regionDone,regionCalls=true,0
local modules={LoadingCompanion={probe=function(map,done)pending=not done end},
 VoxelScene={readyForReveal=function()return ready end},WorldSceneHold={serial=function()return serial end}}
love={graphics={push=function()end,pop=function()end,setShader=function()end,setColor=function()end,rectangle=function()end}}
modules.RegionPreparation={new=function()return{}end,update=function()regionCalls=regionCalls+1;return regionDone end}
local M=assert(loadfile('lib/ContinuePreparation.lua')){require=function(n)return assert(modules[n],n)end}
local game={stack={states={}},overworld={map={id='SILPH_CO_6F'}}}
function game.stack:push(s)self.states[#self.states+1]=s end
function game.stack:top()return self.states[#self.states]end
function game:restoreSave(loaded,recovered,opts)calls=calls+1;self.stack.states={self.overworld};return 'native-result' end
M.install(game);local wrapper=game.restoreSave;M.install(game);assert(wrapper==game.restoreSave)
game:restoreSave({},false,{continued=true});assert(calls==0 and pending)
local cover=game.stack:top();cover:update();assert(calls==0,'restored before showing indicator')
cover:draw();cover:update();assert(calls==1 and game.stack:top()==cover)
ready=true;cover:update();assert(game.stack:top()==cover,'released without first rendered scene')
cover:draw();cover:update();assert(game.stack:top()==cover,'old frame counted as prepared')
serial=serial+1;cover:update();assert(game.stack:top()==game.overworld and not pending and calls==1)
active=false;assert(game:restoreSave({},false,{continued=true})=='native-result' and calls==2)
active=true;assert(game:restoreSave({},false,{freshBoot=true})=='native-result' and calls==3)
print('PASS Continue: draw-before-restore, exactly once, prepared and presented gate, Vanilla/non-Continue unchanged, idempotent install')
local clock=0;love.timer={getTime=function()return clock end}
regionDone=false;ready=true;game:restoreSave({},false,{continued=true});cover=game.stack:top();cover:draw();cover:update()
cover:draw();serial=serial+1;cover:update();assert(game.stack:top()==cover,'region preparation skipped')
clock=10;cover:update();assert(game.stack:top()==cover,'region released on arbitrary timeout')
local canvas={};local state=game.overworld
M.rememberScene(canvas,state,800,600,160,144)
assert(M.cachedScene(state,800,600,160,144)==canvas,'hidden completed scene not reused')
assert(not M.cachedScene({map={}},800,600,160,144),'reused different map')
ready=false;assert(not M.cachedScene(state,800,600,160,144),'reused invalid scene')
ready=true;assert(not M.cachedScene(state,800,600,160,144),'invalid scene retained')
M.rememberScene(canvas,state,800,600,160,144)
assert(not M.cachedScene(state,801,600,160,144),'reused different viewport')
M.rememberScene(canvas,state,800,600,160,144)
local dialogue={};game.stack:push(dialogue)
assert(not M.cachedScene(state,800,600,160,144),'reused behind non-opaque top state')
table.remove(game.stack.states)
regionDone=true;cover:update();assert(game.stack:top()==game.overworld,'complete region held')
assert(not M.cachedScene(state,800,600,160,144)and not cover.frame,'held first visible frame')
assert(regionCalls>0)
print('PASS Continue region: stays covered beyond timer, releases immediately when budgeted work completes')
