local glass,pipeline=true,'voxel'
local E={matches=function(map)return map.id=='SILPH_CO_ELEVATOR'end}
local modules={SilphElevator=E,SilphWindows={setting={get=function()return glass end}}}
local V={require=function(n)return assert(modules[n],n)end,mod={read=function()return 'wave'end}}
local released,playing,volume,allocations=0,false,0,0
local source={setLooping=function(_,on)assert(on)end,setVolume=function(_,v)volume=v end,
 play=function()playing=true end,stop=function()playing=false end,isPlaying=function()return playing end,
 release=function()released=released+1 end}
local cleanup
package.loaded['src.render.Assets']={register=function(fn)cleanup=fn end}
package.loaded['src.render.Pipelines']={worldPipeline=function()return pipeline end}
local native={};package.loaded['src.core.Sound']={play=function(_,id)native[id]=(native[id]or 0)+1;return 'native'end}
local S=package.loaded['src.core.Sound']
local fail=false
love={filesystem={newFileData=function()return{release=function()end}end},
 sound={newSoundData=function()if fail then error('decoder unavailable')end;return{release=function()end}end},
 audio={newSource=function()allocations=allocations+1;return source end}}
local M=assert(loadfile('lib/SilphElevatorAudio.lua'))(V);M.install();M.install()
local ow={map={id='SILPH_CO_ELEVATOR'}};local top
local game={overworld=ow,save={options={sfxVol=7}},stack={top=function()return top end}}
local ride={game=game,ow=ow,phase='pre',frames=0};top=ride;E.ride=ride
M.start(game,ride);assert(allocations==1 and not playing)
ride.phase='shake';ride.frames=60;M.update();assert(playing and volume==.14)
for i=1,100 do S.play({},'Collision')end
assert(not native.Collision,'glass lift still retriggers collisions')
assert(S.play({},'Menu_Beep')=='native'and native.Menu_Beep==1)
assert(S.play({},'Safari_Zone_PA')=='native'and native.Safari_Zone_PA==1 and not playing)
ride.frames=1;M.update();assert(volume>0 and volume<.14,'motor did not fade in')
ride.frames=199;M.update();assert(volume>0 and volume<.14,'motor did not fade out')
game.save.options.sfxVol=0;M.update();assert(volume==0 and not playing)
game.save.options.sfxVol=7;M.update();assert(playing)
top={};M.update();assert(not playing,'motor survived a covered/paused ride');top=ride
for _,mode in ipairs{'glass-off','classic','other-map'}do
 glass=mode~='glass-off';pipeline=mode=='classic'and'classic'or'voxel'
 ow.map.id=mode=='other-map'and'CELADON_MART_ELEVATOR'or'SILPH_CO_ELEVATOR'
 assert(S.play({},'Collision')=='native');M.update();assert(not playing)
end
assert(native.Collision==3)
glass=true;pipeline='voxel';ow.map.id='SILPH_CO_ELEVATOR'
ride.frames=60;M.update();assert(playing)
M.finish({});assert(playing,'another ride stopped this motor')
M.finish(ride);assert(not playing and not M.ride and allocations==1)
cleanup();assert(released==1 and not M.source)
fail=true;E.ride=ride;M.start(game,ride)
assert(not M.source and M.failed and S.play({},'Collision')=='native','audio failure swallowed native SFX')
M.finish(ride)
print('PASS quiet glass-lift loop: collision replacement, SFX/fades/pause/exit, arrival and other sounds retained, source reuse and decode fallback')
