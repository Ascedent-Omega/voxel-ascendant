local C=assert(loadfile('shared/WeatherCover.lua'))()
local map={def={width=4,height=4}}
local f=C.begin(map)
f:add({{0,24,0},{16,24,0},{16,24,16},{0,24,16}})
f:add({{16,0,0},{16,40,0},{16,40,16},{16,0,16}})
f:publish()
assert(C.height(map,4,4)==24 and C.height(map,20,4)==nil,'wall expands the sheltered area')
assert(C.sheltered(map,4,4,0)and not C.sheltered(map,4,4,24),'roof standing surface sheltered')
local old=C.revision(map);local new=C.begin(map)
assert(C.revision(map)==old,'unfinished geometry published')
new:add({0,28,0,16,28,0,16,28,16,0,28,16},32,4,0,true);new:publish()
assert(C.height(map,4,4)==nil and C.height(map,36,4)==32,'old roof remains after remesh')
local prop=C.begin(map,'props')
prop:add({{0,48,0},{16,48,0},{16,48,16},{0,48,16}});prop:publish()
assert(C.height(map,4,4)==48 and C.height(map,36,4)==32,'props overwrite terrain layer')
local slopes=C.begin(map,'props');slopes:add({{0,10,0},{16,26,0},{16,26,16},{0,10,16}});slopes:publish()
assert(C.height(map,2,2)==12 and C.height(map,14,2)==24,'roof slope uses ridge height')
C.begin(map,'props'):publish();assert(C.height(map,4,4)==nil,'leaf loss retains old crown cover')
local payload=C.export(map);local adapter={def=map.def,tileset=map.tileset}
assert(C.height(adapter,36,4)==32,'promoted map loses cover')
C.invalidate(map);assert(not C.height(map,36,4));assert(C.restore(map,payload));assert(C.height(map,36,4)==32,'disk-cache restoration loses roof')
assert(not C.restore(map,{bad=20}) and C.height(map,36,4)==32,'bad cache partially publishes')
local count,plays=0,0
local function source()
 count=count+1
 return{setVolume=function(s,v)s.volume=v end,setLooping=function(s,v)s.loop=v end,
  setPitch=function()end,play=function(s)s.playing=true;plays=plays+1 end,
  stop=function(s)s.playing=false end,isPlaying=function(s)return s.playing end,release=function()end}
end
local focused=true
love={window={hasFocus=function()return focused end},audio={newSource=source},filesystem={newFileData=function()return{release=function()end}end}}
local mode='rain';local p={cellX=0,cellY=0};local W={isOutdoor=function(m)return m==map end,mode=function()return mode end,setThunderHook=function()end}
local modules={SnowTracks={update=function()end},RainStrength={profile=function()return{audio=1}end},Weather=W,WeatherCover=C,WorldWeather={surface=function()return 0,true,0 end}}
local A=assert(loadfile('shared/WeatherAudio.lua')){mod={read=function()return 'test sound'end},require=function(n)return assert(modules[n],n)end}
local game={save={options={sfxVol=7}},overworld={map=map,player=p}}
for i=1,100 do A.update(.016,game)end
assert(A.sources.rain and A.sources.rain:isPlaying()and A.sources.rain.volume>0)
local before=count;assert(A.step(game,'rain',1,'grass'));assert(A.lastStepKind=='wetgrass' and count==before,'step allocates audio')
assert(not A.step(game,'rain',1,'grass'),'duplicate step sound')
local exposed=A.sources.rain.volume
p.cellX=2;for i=1,100 do A.update(.016,game)end
assert(A.last.sheltered and A.sources.rain.volume<exposed and A.sources['sheltered-rain']:isPlaying())
assert(not A.step(game,'snow',1,'stone'),'snow step underneath roof')
mode='storm';for i=1,12 do A.update(.1,game)end
assert(A.onLightning(map,1,'town:1'));assert(not A.onLightning(map,1,'town:1'),'VR schedules double thunder')
for i=1,30 do A.update(.1,game)end
assert(A.thunder and A.thunder:isPlaying(),'delayed thunder missing')
game.save.options.sfxVol=0;A.update(.1,game)
for _,s in pairs(A.sources)do assert(not s:isPlaying(),'mute left a source playing')end
before=count;for i=1,10 do A.update(.1,game)end;assert(count==before,'muted state loads audio')
game.save.options.sfxVol=7;mode='rain';focused=false;A.update(.1,game);assert(A.last.muted)
focused=true;game.overworld.map={def={}};for i=1,100 do A.update(.1,game)end
assert(not A.sources.rain:isPlaying()and not A.pending,'indoor weather did not stop')
A.invalidate();assert(not next(A.sources));print('PASS roof cells, atomic replacement, exposed/sheltered crossfade, prewarmed steps, thunder debounce, mute/focus/indoor cleanup')
