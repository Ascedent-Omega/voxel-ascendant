local root=os.getenv('INTRO_ROOT')or '.'
local function read(p)local f=assert(io.open(root..'/integrated/ascendant_startup/'..p,'rb'));local s=f:read('*a');f:close();return s end
function love.load()
 io.stdout:setvbuf('no')
 local Scene=assert(loadstring(read('IntroScene.lua')))()
 local scene=Scene.new(read);local count=0
 for name,s in pairs(scene.sounds)do assert(s:getDuration('seconds')>0,name);count=count+1 end
 assert(count==4,'all four real audio assets decode');assert(math.abs(scene.sounds.gamecube:getDuration('seconds')-Scene.eyeSeconds)<.01,'animation and GameCube audio duration match');scene:release()
 local original=love.audio.newSource;local sources={}
 love.audio.newSource=function(fd)
  local s={name=fd:getFilename(),count=0,volume=0}
  function s:setVolume(v)self.volume=v end
  function s:play()self.count=self.count+1;self.playing=true end
  function s:isPlaying()return self.playing end
  function s:getDuration()return 30 end
  function s:seek(t)self.seekAt=t end
  function s:stop()self.playing=false end
  function s:release()assert(not self.playing);self.released=true end
  sources[#sources+1]=s;return s
 end
 scene=Scene.new(read);scene:play(.5)
 scene:draw(0,1280,720,0);assert(sources[1].count==1 and sources[2].count==0)
 scene:draw(9.79,1280,720,9.79);assert(sources[2].count==0)
 scene:draw(9.8,1280,720,9.8);assert(sources[2].count==1)
 scene:draw(10.65,1280,720,10.65);assert(sources[3].count==1)
 scene:syncAudio(11);assert(math.abs(sources[2].seekAt-1.2)<.0001)
 scene:draw(Scene.eyeAt-.01,1280,720,Scene.eyeAt-.01);assert(sources[4].count==0)
 scene:draw(Scene.eyeAt,1280,720,Scene.eyeAt);assert(sources[4].count==1)
 for _,t in ipairs{23.14,24,24.4,40}do scene:draw(Scene.duration-.6,1280,720,t)end
 for _,s in ipairs(sources)do assert(s.count==1,'hold must never loop audio')end
 scene:setVolume(0);for _,s in ipairs(sources)do assert(s.volume==0,'skip/mute affects every cue')end
 scene:release();scene:release();for _,s in ipairs(sources)do assert(s.released)end
 sources={};scene=Scene.new(read);scene:play(0)
 for _,t in ipairs{0,10,12,24}do scene:draw(t,720,1280,t)end
 for _,s in ipairs(sources)do assert(s.count==0,'splashMute stays silent')end
 scene:release();love.audio.newSource=original
 print('PASS real rendering, all audio decode, cue timing, single playback on holds, mute, skip volume, resync, portrait and cleanup')
 love.event.quit()
end
function love.errorhandler(err)print(debug.traceback(err));return function()love.event.quit(1)end end
