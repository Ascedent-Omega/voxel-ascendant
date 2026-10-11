-- Exercise the actual sound scanner with borrowed native players. PCM is
-- outside this contract: no sound headers means there is nothing to render.
local made,started,released,bound=0,{},0,0
package.loaded['src.core.ChipSynth']={SAMPLE_RATE=44100,getStereo=function()return true end,
 getChannelVolume=function()return 1 end,getChannelPitch=function()return 0 end,
 getNoiseVolume=function()return 1 end}
package.loaded['src.core.ChipAudio']={}
package.loaded['src.battle.AnimPlayer']={new=function(registry)
 made=made+1
 return{data=registry,events={},start=function(self,id)
  started[#started+1]=id;self.events={{sound=id}}
 end,release=function()released=released+1 end}
end}
local M=dofile('lib/BattleSoundPreparation.lua')
local composition={OWNER='kasc.sevii-battle-animations/v1',bind=function(battle,player)
 bound=bound+1;assert(player~=battle.animPlayer,'scanner must bind the borrowed player')
 if battle.game.overworld.map.id~='SEVII'then return false end
 local original=player.start
 player.start=function(self,id,...)return original(self,id=='SYNTHESIS'and'RECOVER'or id,...)end
 return true
end}
local function fixture(map,owner)
 return{game={overworld={map={id=map}},mods={exports={kanto_ascendant={seviiExpedition={battleAnimations=owner}}}}},
  data={moves={SYNTHESIS={},RECOVER={}},battle_anims={moveAnims={RECOVER={}}}},
  player={mon={species='GROTLE'},curMoves={{id='SYNTHESIS'}}},animPlayer={}}
end
local b=fixture('SEVII',composition);local actual=b.animPlayer
M.scan(b)
assert(made==1 and bound==1 and released==1 and started[1]=='RECOVER','borrowed compilation uses reviewed composition')
assert(b.animPlayer==actual and not actual.start,'real battle animation player retained')
M.scan(b);assert(made==1,'unchanged move list skips extra players')
b.animPlaying=true;b._vascSoundMoves=nil;M.scan(b);assert(made==1,'no preparation during animation')
b.animPlaying=false;M.scan(b);assert(made==2 and released==2,'changed stamp scans and releases')
M.scan(fixture('PALLET_TOWN',composition))
assert(started[#started]=='SYNTHESIS','Kanto keeps original native animation')
M.scan(fixture('SEVII',{OWNER='foreign',bind=function()error('foreign binder called')end}))
assert(started[#started]=='SYNTHESIS','foreign owner cannot bind')
M.scan(fixture('SEVII',nil));assert(started[#started]=='SYNTHESIS','optional KASC remains optional')
assert(made==released,'every borrowed player released')
print('PASS Sevii sound preparation scope, stamp and borrowed-player lifecycle')
