-- Shared entry ownership, native readiness and skip regression; no GPU needed.
local root='integrated/ascendant_startup/'
local Card=assert(loadfile(root..'StartupCard.lua'))()
local Scene=assert(loadfile(root..'IntroScene.lua'))()
local now=0
love={timer={getTime=function()return now end},graphics={getWidth=function()return 1280 end,getHeight=function()return 720 end,getDimensions=function()return 1280,720 end}}
package.loaded['src.core.Music']={duckForFanfare=function()end}
for _,owner in ipairs{'VOXEL_ASCENDANT','kanto_ascendant'}do
 for _,skip in ipairs{false,true}do
  now=0;local callbacks={};local released,volume,syncs=false,1,0
  _G.omegaIntroSceneFactory=function()return {play=function(_,v)volume=v end,setVolume=function(_,v)volume=v end,syncAudio=function()syncs=syncs+1 end,draw=function()end,release=function()released=true end}end
  local function mod(id)return {id=id,events={on=function(_,_,cb)callbacks[#callbacks+1]=cb end},read=function(_,path)
   if path=='IntroScene.lua'then return 'return {duration='..Scene.duration..',new=_G.omegaIntroSceneFactory}'end
   if path=='NativePreload.lua'then return 'return {step=function()return true end}'end
   local f=assert(io.open(root..path));local s=f:read('*a');f:close();return s
  end}end
  local first=Card.attach(mod(owner));local second=Card.attach(mod(owner=='VOXEL_ASCENDANT'and 'kanto_ascendant'or 'VOXEL_ASCENDANT'))
  local ready=false;first:add('must-complete',function()return ready end,true)
  local stack={states={}}
  function stack:top()return self.states[#self.states]end
  function stack:push(s)self.states[#self.states+1]=s end
  function stack:pop()local s=table.remove(self.states);s:exit()end
  local previous=function()end
  local game={stack=stack,draw=previous,save={options={sfxVol=7}}}
  if owner=='kanto_ascendant'then game.makeTitleState=function()return{}end end
  for _,cb in ipairs(callbacks)do cb{game=game}end
  local adopted=0;local state=second:begin('continue',function()adopted=adopted+1 end)
  game.draw();assert(adopted==0,'first visible frame precedes save adoption')
  now=.1;state:update(.1);game.draw();assert(adopted==1)
  if skip then now=.3;state:onKeyPressed('space')end
  -- Native work can remain pending much longer than the music; skip is not
  -- permission to bypass preparation. Long frames advance animation by .1.
  for i=1,220 do now=now+1;game.draw();state:update(.1);assert(not state.closed)end
  assert(syncs>0 and adopted==1 and first:status().owner==owner)
  if skip then assert(volume==0,'skip fades all audio')end
  ready=true
  for i=1,20 do now=now+.1;game.draw();state:update(.1);if state.closed then break end end
  assert(state.closed and released and game.draw==previous and #stack.states==0)
 end
end
_G.omegaIntroSceneFactory=nil
print('PASS both owners, Gen1/Gen2 entry, first-frame adoption, mandatory readiness after long load, skip audio, resync and restoration')
