-- Exercise actual shared-card lifecycle with a no-GPU scene and real queue.
local root='integrated/ascendant_startup/'
local Card=assert(loadfile(root..'StartupCard.lua'))()
local now=0
love={timer={getTime=function()return now end},graphics={getWidth=function()return 640 end,getHeight=function()return 480 end,getDimensions=function()return 640,480 end}}
package.loaded['src.core.Music']={duckForFanfare=function()end}
for _,owner in ipairs{'VOXEL_ASCENDANT','kanto_ascendant'}do
 for _,language in ipairs{'absent','en','de'}do
  local callbacks,rendered={},nil
  local universal
  local function make(id)
   return {id=id,find=function()return universal end,events={on=function(_,_,callback)callbacks[#callbacks+1]=callback end},read=function(_,path)
    if path=='IntroScene.lua'then return "return {duration=12,new=function()return {play=function()end,draw=function()end,drawStatus=function(_,label)_G.renderedStartupLabel=label end,release=function()end}end}" end
    if path=='NativePreload.lua'then return 'return {step=function()return true end}'end
    local f=assert(io.open(root..path));local s=f:read('*a');f:close();return s
   end}
  end
  local api=Card.attach(make(owner));local other=Card.attach(make(owner=='kanto_ascendant'and 'VOXEL_ASCENDANT'or 'kanto_ascendant'))
  -- Universal publishes after attach, as may happen in real mod load order.
  if language~='absent'then universal={exports={bootLanguage=language,pendingLanguage=language=='en'and 'de'or 'en'}}end
  local stack={states={}}
  function stack:top()return self.states[#self.states]end
  function stack:push(s)self.states[#self.states+1]=s end
  function stack:pop()local s=table.remove(self.states);s:exit()end
  local game={stack=stack,draw=function()end,makeTitleState=function()return{}end}
  for _,cb in ipairs(callbacks)do cb{game=game}end
  local adopted=0
  local prepare={vascContinue=true,stage='save'}
  local state=other:begin('continue',function()adopted=adopted+1;stack:push(prepare)end)
  local de=language=='de'
  game.draw();assert(renderedStartupLabel==(de and 'Spiel vorbereiten'or 'Preparing game'))
  state:update(.016);game.draw();assert(renderedStartupLabel==(de and 'Spielstand laden'or 'Restoring saved game'))
  prepare.stage='region';prepare.region={phase='scenery',order={1,2,3},plan={ids={1,2}},index=2}
  state:update(.016);game.draw();assert(renderedStartupLabel==(de and 'Gebäude vorbereiten 1 / 3'or 'Preparing nearby buildings 1 / 3'))
  table.remove(stack.states,1);state:update(.016);game.draw()
  assert(renderedStartupLabel==(de and 'Vorbereitung abgeschlossen'or 'Preparation complete'))
  assert(adopted==1 and api:status().owner==owner and #stack.states==1)
  state:exit()
 end
end
print('PASS shared startup: both owners, late Universal exports, EN/DE/default, preparation counter, single save adoption')
