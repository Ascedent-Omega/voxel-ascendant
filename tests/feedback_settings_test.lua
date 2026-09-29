local root='gen2/lib/'
for _,generation in ipairs{1,2}do
 local bucket={pokemonModelSkin='crystal',stadium3dSprites=false}
 local mod={id='VOXEL_ASCENDANT',_vascHostGeneration=generation,options={get=function(_,k)return bucket[k]end}}
 local writes=0;local game={save={options={modOptions={VOXEL_ASCENDANT=bucket}}},mods={modOptions={VOXEL_ASCENDANT=bucket}}}
 game.writeOptions=function()writes=writes+1 end
 local modules={};local V={mod=mod};V.require=function(n)return assert(modules[n],n)end
 modules.ModSetting=assert(loadfile((generation==2 and root or 'lib/')..'ModSetting.lua'))(V)
 modules.CobblemonContent={available=function()return true end}
 modules.OverworldBattle={mode=function()return true end,MAP=true}
 modules.StadiumInstall={available=function()return false end}
 if generation==1 then
  package.loaded['src.core.Game']=game;package.loaded['src.battle.BattleState']={}
  local control=assert(loadfile('lib/BattleSpriteControl.lua'))(V);V.BattleSpriteControl=control
  control.styleSetting:setValue('hd',game);control.setting:setValue(true,game)
  local b={player={},enemy={}};assert(control.choice(b)=='hd');game.stack={states={b}}
 end
 local provider=assert(loadfile(root..'PokemonModelProvider.lua'))(V)
 provider.setting:sync('cobblemon');assert(bucket.stadium3dSprites==false,'boot sync enabled models')
 provider.setting:setValue('cobblemon',game)
 assert(provider.resolve()=='cobblemon')
 if generation==2 then assert(bucket.stadium3dSprites==true)
 else assert(bucket.battleSpriteStyle=='current' and bucket.battleHdSprites==false);assert(V.BattleSpriteControl.modelRequest()==nil)end
 provider.setting:setValue('crystal',game);assert(provider.resolve()=='crystal')
 provider.setting:setValue('cobblemon',game);assert(provider.resolve()=='cobblemon')
 assert(writes>0)
 print('PASS explicit model selection and sprite roundtrip Gen '..generation)
end
local values={gen2TrainerArt='auto'}
local V={mod={options={get=function(_,k)return values[k]end},assets={image=function(_,p)return {path=p}end}},require=function()return{}end}
local art=assert(loadfile(root..'Gen2TrainerArt.lua'))(V)
local screen={showPlayerTrainer=true,save={version='crystal',player={gender='male'}},playerBackImage={},playerBackPath='native/male.png',data={gen2MenuGfx={battleHud={playerBack='native/male.png',playerBackFemale='native/female.png',dudeBack='native/dude.png'}}}}
assert(art.player(screen).inkIdentity:find('gold_front_hd',1,true))
screen.playerBackPath='native/female.png';assert(art.player(screen)==nil,'external identity using native art overwritten')
screen.playerBackPath='mods/custom/back.png';assert(art.player(screen)==nil,'custom trainer overwritten')
values.gen2TrainerArt='hd';assert(art.player(screen))
values.gen2TrainerArt='native';assert(art.player(screen)==nil)
values.gen2TrainerArt='hd';screen.tutorial=true;assert(art.player(screen)==nil,'tutorial trainer replaced')
print('PASS trainer auto/custom/native/HD/tutorial precedence')
local mode='original';local originalCalls,overlayCalls=0,0
local Battle={new=function()return {}end,animForMove=function()originalCalls=originalCalls+1;return true end,update=function()end,drawSceneBody=function()end}
package.loaded['src.ui.gen2.BattleState']=Battle
local modules={};V={mod={options={get=function()return mode end}},require=function(n)return assert(modules[n],n)end}
modules.Gen2AnimationStyle=assert(loadfile(root..'Gen2AnimationStyle.lua'))(V)
modules.VascBattleAnimPlayer={newGen2Overlay=function()overlayCalls=overlayCalls+1;return {}end}
local bridge=assert(loadfile(root..'Gen2VascBattleAnimations.lua'))(V);assert(bridge.install())
local native=Battle.new();mode='vasc';Battle.animForMove(native,33,'player');assert(overlayCalls==0 and originalCalls==1)
local modern=Battle.new();mode='original';Battle.animForMove(modern,33,'enemy');assert(overlayCalls==1 and originalCalls==2)
print('PASS original timing path retained; style latched per encounter, VASC overlay restored')
