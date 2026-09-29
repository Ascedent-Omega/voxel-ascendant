-- One reusable mono source for the two Silph pools. Position attenuates the
-- loop; no per-frame sound generation and no source survives a room exit.
local V=...
local M={}
function M.update(dt,game,level)
 local ow=game and game.overworld
 local enabled=(level or 0)>0 and ow and V.require('SilphFountains').matches(ow.map)
  and V.require('VoxelItems').setting:get()and game.stack:top()==ow
 local volume=0
 if enabled then
  local p=ow.player;local distance=math.huge
  for _,c in ipairs(V.require('SilphFountains').centers)do
   distance=math.min(distance,math.sqrt(((p.px or p.cellX*16)+8-c[1])^2+((p.py or p.cellY*16)+8-c[2])^2))
  end
  local options=game.save and game.save.options or{}
  volume=.3*math.max(0,1-distance/220)^2*math.max(0,math.min(7,tonumber(options.sfxVol)or 7))/7
 end
 if volume>0 and not M.source and not M.failed then
  local ok,source=pcall(function()
   local raw=assert(V.mod:read('assets/audio/silph-fountain.wav'))
   local file=love.filesystem.newFileData(raw,'silph-fountain.wav')
   local sound=love.sound.newSoundData(file);file:release()
   local source=love.audio.newSource(sound,'static');sound:release();source:setLooping(true);return source
  end)
  if ok then M.source=source else M.failed=true end
  if not M.registered then
   require('src.render.Assets').register(function()if M.source then M.source:release()end;M.source=nil;M.failed=nil end);M.registered=true
  end
 end
 M.volume=volume
 if M.source then
  M.source:setVolume(volume)
  if volume<=0 then M.source:stop()elseif not M.source:isPlaying()then M.source:play()end
 end
end
return M
