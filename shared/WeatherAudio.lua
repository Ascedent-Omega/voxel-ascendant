-- Shared weather Foley owner. Update-only loading/playback, bounded reusable
-- stereo sources, SFX-volume authority, no music ducking and no render ticks.
local V=...
local M={sources={},levels={},failed={},clock=0,installed=false,last={}}
local loops={'rain','sheltered-rain','wind','snow-wind'}
local stepIndex=0
local function clamp(v,a,b)return math.max(a,math.min(b,tonumber(v)or a))end
function M.scale(game)
 local options=game and game.save and game.save.options or game and game.options
 return clamp(options and options.sfxVol or 7,0,7)/7
end
local function load(name)
 if M.sources[name]~=nil or M.failed[name]then return M.sources[name]end
 if not(love and love.audio and love.filesystem)then return nil end
 local ok,source=pcall(function()
  local bytes=assert(V.mod:read('assets/audio/weather/'..name..'.wav'))
  local file=love.filesystem.newFileData(bytes,name..'.wav')
  local s=love.audio.newSource(file,'static');file:release()
  -- Stereo buffers stay non-positional, regardless of the 3D listener.
  s:setVolume(0)
  for _,loop in ipairs(loops)do if name==loop then s:setLooping(true)end end
  return s
 end)
 if ok then M.sources[name]=source else M.failed[name]=tostring(source)end
 return ok and source or nil
end
function M.stop()
 for _,s in pairs(M.sources)do s:stop();s:setVolume(0)end
 M.levels={};M.pending=nil
end
function M.shelter(game)
 local world=game and(game.overworld or game.world)
 local map,p=world and world.map,world and world.player
 if not(map and p and map.def)then return false end
 local x,z=(p.px or(p.cellX or 0)*16)+8,(p.py or(p.cellY or 0)*16)+8
 local _,_,ground=V.require('WorldWeather').surface(map,x,z)
 return V.require('WeatherCover').sheltered(map,x,z,ground or 0)
end
function M.targets(mode,sheltered,outdoor,profile)
 if not outdoor then return {}end
 local wet=mode=='rain' or mode=='storm'
 local strength=profile and profile.audio or 1
 return {rain=wet and(sheltered and .025 or mode=='storm' and .30 or .23)*strength or 0,
  ['sheltered-rain']=wet and sheltered and .24*strength or 0,
  wind=mode=='storm' and(sheltered and .07 or .17)or mode=='fog' and .035 or 0,
  ['snow-wind']=mode=='snow' and(sheltered and .025 or .095)or 0}
end
function M.gust(event)
 if not event or(event.kind~='wind'and event.kind~='stormLeaves')or(event.strength or 0)<.42 or event.key==M.gustKey then return false end
 M.gustKey=event.key;M.gustUntil=M.clock+2.4;M.gustGain=.13*math.min(1,event.strength)
 return true
end
function M.onLightning(map,flash,occurrence)
 if M.mode~='storm' or not map or map~=M.map or occurrence==M.lastOccurrence then return false end
 M.lastOccurrence=occurrence
 local hash=0;for i=1,#tostring(occurrence)do hash=(hash*31+tostring(occurrence):byte(i))%997 end
 M.pending={delay=.35+hash%120/100,age=0,name='thunder-'..(hash%3+1),gain=.62+hash%19/100}
 return true
end
function M.update(dt,game)
 dt=clamp(dt,0,.15);M.clock=M.clock+dt
 local world=game and(game.overworld or game.world)
 local map=world and world.map
 local W=V.require('Weather')
 local outdoor=map and W.isOutdoor(map)or false
 local mode=outdoor and W.mode(map)or 'clear'
 if map~=M.map then
  M.pending=nil;M.lastOccurrence=nil;M.gustUntil=0
  if M.thunder then M.thunder:stop();M.thunder=nil end
 end
 M.map,M.mode=map,mode
 V.require("SnowTracks").update(dt,game,mode)
 local gain=M.scale(game)
 local focused=not(love.window and love.window.hasFocus)or love.window.hasFocus()
 if gain==0 or not focused or not game or not game.save then M.stop();M.last={muted=true};return end
 local shelter=outdoor and M.shelter(game)or false
 local targets=M.targets(mode,shelter,outdoor,V.require('RainStrength').profile(mode))
 if outdoor and M.clock<(M.gustUntil or 0)then
  targets.wind=math.max(targets.wind or 0,(M.gustGain or .1)*math.min(1,(M.gustUntil-M.clock)/.7))
 end
 -- Prepare at most one small buffer per update. Failed assets latch once.
 local wanted={}
 for _,name in ipairs(loops)do if(targets[name]or 0)>0 then wanted[#wanted+1]=name end end
 if mode=='storm'then for i=1,3 do wanted[#wanted+1]='thunder-'..i end end
 if mode=='snow' or mode=='rain' or mode=='storm'then
  for _,kind in ipairs(mode=='snow'and{'snow'}or{'splash','damp','wetgrass'})do
   for i=1,4 do wanted[#wanted+1]=kind..'-'..i end
  end
 end
 for _,name in ipairs(wanted)do if not M.sources[name] and not M.failed[name]then load(name);break end end
 for _,name in ipairs(loops)do
  local s=M.sources[name];local old=M.levels[name]or 0
  local target=targets[name]or 0
  local level=old+(target-old)*(1-math.exp(-dt/(target>old and .8 or .45)))
  M.levels[name]=level
  if s then
   s:setVolume(level*gain)
   if level>.0005 then if not s:isPlaying()then s:play()end else s:stop()end
  end
 end
 if mode~='storm'then M.pending=nil end
 if M.thunder then M.thunder:setVolume((M.thunderGain or 0)*gain*(shelter and .55 or 1))end
 local event=M.pending
 if event then
  event.delay=event.delay-dt;event.age=event.age+dt
  local source=M.sources[event.name]
  if event.delay<=0 and source then
   if M.thunder then M.thunder:stop()end
   M.thunder,M.thunderGain=source,event.gain
   source:stop();source:setVolume(event.gain*gain*(shelter and .55 or 1));source:play();M.pending=nil
  elseif event.age>3 then M.pending=nil end
 end
 M.last={mode=mode,sheltered=shelter,outdoor=outdoor,gain=gain}
end
function M.step(game,mode,amount,material)
 if M.scale(game)<=0 or M.clock-(M.lastStep or -1)<.085 or M.shelter(game)then return false end
 local world=game and(game.overworld or game.world);local p=world and world.player
 if not p or p.surfing then return false end
 amount=clamp(amount or 1,0,1)
 local kind
 if mode=='snow'and amount>.08 then kind='snow'
 elseif mode=='rain'or mode=='storm'then
  if material=='grass' then kind='wetgrass'
  else
   local x,z=(p.cellX or 0)*16+8,(p.cellY or 0)*16+8
   local field=math.sin(x*.092+math.sin(z*.05)*1.3)+math.cos(z*.103)+math.sin((x-z)*.041)*.6
   kind=field>2.65-1.5*amount and 'splash' or 'damp'
  end
 end
 if not kind then return false end
 stepIndex=stepIndex%4+1;local variant=({1,3,2,4})[stepIndex]
 local source=M.sources[kind..'-'..variant]
 if not source then return false end -- prewarming is owned by update, never by a step/render
 M.lastStep=M.clock
 if M.stepSource and M.stepSource:isPlaying()then M.stepSource:stop()end
 M.stepSource=source;source:stop()
 local bike=game.save and game.save.onBike
 source:setPitch(bike and .84 or 1+(variant-2.5)*.018)
 source:setVolume((kind=='snow'and .43 or .36)*M.scale(game)*(bike and .7 or 1))
 source:play();M.lastStepKind=kind
 return true
end
function M.install(mod)
 if M.installed then return true end
 V.require('Weather').setThunderHook(M.onLightning)
 V.require('SnowRamps').install()
 mod.hooks:wrap('core.update',function(next,game,dt)
  local result=next(game,dt);M.update(dt,game);return result
 end)
 M.installed=true;return true
end
function M.invalidate()
 M.stop();for _,s in pairs(M.sources)do s:release()end
 M.sources={};M.failed={};M.thunder=nil;M.stepSource=nil;M.map=nil;M.lastOccurrence=nil
end
return M
