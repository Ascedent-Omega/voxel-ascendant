-- The glass lift has a quiet continuous motor instead of 100 collision hits.
-- Native floor timing, arrival chime, music and other elevators keep ownership.
local V=...
local M={volume=0}
local function scoped(ride)
 return ride and ride==V.require('SilphElevator').ride and ride.game==M.game
  and M.game.overworld==ride.ow and V.require('SilphElevator').matches(ride.ow.map)
  and V.require('SilphWindows').setting:get()
  and require('src.render.Pipelines').worldPipeline()=='voxel'
end
local function prepare()
 if M.source then return true end
 if M.failed then return false end
 local ok,source=pcall(function()
  local file=love.filesystem.newFileData(assert(V.mod:read('assets/audio/silph-lift-motor.wav')),'silph-lift-motor.wav')
  local data=love.sound.newSoundData(file);file:release()
  local source=love.audio.newSource(data,'static');data:release()
  source:setLooping(true);return source
 end)
 if ok then M.source=source else M.failed=true end
 return ok
end
function M.stop()
 M.volume=0
 if M.source then M.source:stop();M.source:setVolume(0)end
end
function M.start(game,ride)
 M.stop();M.game=game;M.ride=ride
 if scoped(ride)then prepare()end
end
function M.finish(ride)
 if M.ride==ride then M.stop();M.game=nil;M.ride=nil end
end
function M.update()
 local r=M.ride
 if not(scoped(r)and r.phase=='shake'and M.game.stack:top()==r and prepare())then M.stop();return end
 local options=M.game.save and M.game.save.options or{}
 local sfx=math.max(0,math.min(7,tonumber(options.sfxVol)or 7))/7
 local fade=math.min(1,(r.frames or 0)/12,math.max(0,(200-(r.frames or 0))/12))
 M.volume=.14*sfx*fade
 M.source:setVolume(M.volume)
 if M.volume>0 then if not M.source:isPlaying()then M.source:play()end else M.source:stop()end
end
function M.install()
 if M.installed then return end;M.installed=true
 local S=require('src.core.Sound');local play=S.play
 S.play=function(data,id,...)
  local r=M.ride
  if scoped(r)then
   if id=='Collision'and r.phase=='shake'and prepare()then return end
   if id=='Safari_Zone_PA'then M.stop()end
  end
  return play(data,id,...)
 end
 require('src.render.Assets').register(function()
  M.stop();if M.source then M.source:release()end
  M.source=nil;M.failed=nil;M.ride=nil;M.game=nil
 end)
end
return M
