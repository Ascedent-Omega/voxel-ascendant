local original,cries=0,{}
local F={talk=function()original=original+1;return 'native'end}
package.loaded['src.world.PikachuFollower']=F
local zones={{colors={{1,1,1}},x=0,y=0,w=160,h=144}}
local World={sgbPalettes=function()return zones end}
package.loaded['src.world.OverworldController']=World
package.loaded['src.core.Sound']={playCry=function(_,s)cries[#cries+1]=s end}
local M=assert(loadfile('lib/FollowerPresentation.lua'))({})
local game={data={pokemon={MEW={dex=151},PIKACHU={dex=25}}}}
local npc={pikachuFollower=true,sprite={def={pokemonSpecies='MEW'}},cellX=2,cellY=3,moving=true,targetX=3,targetY=3}
M.install();local wrap=F.talk;M.install();assert(wrap==F.talk)
local world={};local done=function()end
F.talk(game,world,npc,done)
assert(cries[1]=='MEW'and original==0 and world.emote.onDone==done)
assert(npc.cellX==3 and npc.px==48 and not npc.moving)
assert(not world.emote.pikaPic,'unavailable portrait must not substitute Pikachu')
npc.sprite.def.pokemonSpecies='PIKACHU';assert(F.talk(game,world,npc)=='native')
npc.sprite.def.pokemonSpecies=nil;npc.ascendantPokemonModelDex=151
assert(M.species(npc,game.data)=='MEW')
npc.pikachuFollower=false;assert(not M.species(npc,game.data))
assert(World.sgbPalettes({})==zones)
assert(World.sgbPalettes({emote={pikaPic='native'},__vascFollowerPicture={}})==zones)
local own=World.sgbPalettes({emote={pikaPic='vasc-follower:MEW'},__vascFollowerPicture={}})
assert(own~=zones and #own==2 and #zones==1 and own[2].colors==false and own[2].x==56)
print('PASS species-specific follower conversation, cry, movement settlement and native Pikachu preservation')
