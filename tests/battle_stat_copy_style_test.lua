-- Battle-only stats are not an appearance change: modern split Special,
-- Speed Swap and Power Trick all detach them from the saved Pokemon.
local choice='crystal';local image={};local calls=0
package.loaded['src.core.Game']={}
package.loaded['src.battle.BattleState']={}
local animation={presentationAnimation=function(_,mon,view,surface,opts)
 assert(opts.forceStyle and (surface=='battle'or surface=='voxel_map'))
 calls=calls+1;return {image=image,variant=mon.shiny and 'shiny'or'normal'}
end,advancePresentation=function(p)return p.image end}
local modules={ModSetting={new=function(key)return {get=function()return key=='battleSpriteStyle'and choice or false end}end},
 OverworldBattle={playerBackPinned=function()return false end},
 HdPokemonPresentation={create=function()calls=calls+1;return{image=image}end,advancePresentation=function(p)return p.image end}}
local V={mod={find=function()return{exports={crystalAnimation=animation}}end},require=function(name)return assert(modules[name],name)end}
local C=assert(loadfile('lib/BattleSpriteControl.lua'))(V)
local function battle()
 local mon={species='GOROCHU',stats={hp=353,special=170},moves={{id='THUNDERBOLT',pp=15}}}
 return{data={pokemon={GOROCHU={dex=1026}}},player={mon=mon,curStats={hp=353,special=170,specialAttack=170,specialDefense=170},curMoves=mon.moves},enemy={}}
end
for _,style in ipairs{'crystal','hd'}do
 choice=style
 for _,shiny in ipairs{false,true}do
  for _,view in ipairs{'front','back'}do
   local b=battle();b.player.mon.shiny=shiny
   assert(C.imageFor(b,'player',view,style)==image,'detached stats discarded selected '..style)
   assert(b.player.curStats~=b.player.mon.stats and b.player.mon.stats.specialAttack==nil,'save stats mutated')
   if style=='hd'then assert(C.prepare(b,'player',view),'HD preload rejected ordinary stats')end
  end
 end
 for _,flag in ipairs{'transformed','preTransform','_ascMegaProfile'}do
  local b=battle();b.player[flag]=true
  assert(not C.imageFor(b,'player','front',style),'overrode '..flag)
  if style=='hd'then assert(not C.prepare(b,'player','front'))end
 end
 local b=battle();b.player.curMoves={{id='SURF',pp=5}}
 assert(not C.imageFor(b,'player','front',style),'overrode native Transform')
 if style=='hd'then assert(not C.prepare(b,'player','front'))end
 b=battle();b.enemy=b.player;b.player={};b.ghost=true
 assert(not C.imageFor(b,'enemy','front',style),'overrode ghost')
end
print('PASS selected Crystal/HD survives detached battle stats, front/back, normal/shiny; Transform, Mega and ghosts retain ownership')
