local Bridge=assert(loadfile('integrated/ascendant_pokemon_overworld/src/pokemon_world_sprites.lua'))()
local callbacks={};local enabled=true;local source='hd'
local mod={id='test',options={get=function()return enabled end},events={on=function(_,event,fn)callbacks[event]=fn end}}
package.loaded['src.render.SpriteRenderer']={new=function(def)return{def=def}end}
local bridge=Bridge.new{mod=mod,catalog={},compat={wildsSources=function()return{}end},pokemonWalksheets={},scaleProfiles={}}
function bridge:_presentation(_,entity,context)
 assert(context=='follower','duel ignored follower settings')
 local def={image=source,ascendantAtlasImage=source,pokemonDex=9,ascendantPokemonWalksheet=true}
 return entity.pokemon,{id=source=='cobblemon'and'cobblemon'or'card'},def,{source=source},nil,entity.sprite.def
end
function bridge:_enforceScale()end
local sprite={def={image='original'}}
local actor={def={name='KA_LIFE_DUEL_BLUE'},kascSpectatorPokemon='kasc.rival-duel/v1',pokemon={species='BLASTOISE'},sprite=sprite,px=32,py=48}
local game={overworld={npcs={actor}}};bridge:install();bridge:refresh(game)
assert(actor.sprite~=sprite and actor.sprite.def.image=='hd')
source='pokemmo';callbacks['mod.options_changed']{mod='test'}
assert(actor.sprite.def.image=='pokemmo','settings switch retained old card')
source='cobblemon';callbacks['mod.options_changed']{mod='test'}
assert(actor.sprite==sprite and actor.ascendantPokemonSpriteMode=='cobblemon_preferred','model choice not restored to model path')
enabled=false;callbacks['mod.options_changed']{mod='test'}
assert(actor.sprite==sprite and not actor.ascendantPokemonSpriteContext,'OFF failed to restore')
assert(actor.px==32 and actor.py==48 and not actor.isPokemonFollower,'presentation altered movement ownership')
print('PASS rival follower context: HD/MMO/model switches, OFF, original renderer and actor ownership')
