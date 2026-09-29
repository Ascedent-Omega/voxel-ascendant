local Bridge=assert(loadfile('integrated/ascendant_pokemon_overworld/src/pokemon_world_sprites.lua'))()
local callbacks,sources={},{}
local enabled=true
local mod={id='test',options={get=function()return enabled end},events={on=function(_,name,fn)callbacks[name]=fn end}}
local bridge=Bridge.new{mod=mod,catalog={},compat={wildsSources=function()return sources end},pokemonWalksheets={},scaleProfiles={}}
local invalidations,refreshes=0,0
local function provider()
 return {provider={render={spriteResolver={resolveForEntity=function()return {}end,invalidateCache=function()invalidations=invalidations+1 end}},refreshAllEntitySprites=function()refreshes=refreshes+1 end}}
end
sources[1]=provider()
local function actor(dex)
 return {overworldWildSpawn=true,species='TEST',dex=dex,pokemonModel=true,stadiumModel=true,sprite={def={id='owner'}}}
end
local game={overworld={npcs={actor(25)}}}
-- Isolate source/catalog lookup; exercise the real live-card binding,
-- restoration and per-entity model ownership paths below.
function bridge:_presentation(_,entity)
 local card={ascendantPokemonWalksheet=true,ascendantAtlasImage='card-'..entity.dex,pokemonDex=entity.dex}
 return {species=entity.species},{id='card'},card,{source='pokemmo'},nil,entity.sprite.def
end
function bridge:_enforceScale()end
bridge:install()
callbacks['map.entered']{game=game}
assert(invalidations==1 and refreshes==1)
local first=game.overworld.npcs[1]
assert(first.sprite.def.ascendantAtlasImage=='card-25' and first.pokemonModel==false)
local renderer=first.sprite
for i=1,100 do callbacks['world.stepped']{game=game}end
assert(invalidations==1 and refreshes==1,'walking rebuilt provider caches')
assert(first.sprite==renderer and first.sprite.def.ascendantAtlasImage=='card-25')
local second=actor(133);game.overworld.npcs[2]=second
callbacks['world.stepped']{game=game}
assert(second.sprite.def.ascendantAtlasImage=='card-133','late actor not bound')
first.dex=151
callbacks['world.stepped']{game=game}
assert(first.sprite.def.pokemonDex==151,'live identity change not observed')
first.sprite={def={id='new-owner'}}
callbacks['world.stepped']{game=game}
assert(first.sprite.def.ascendantAtlasImage=='card-151','owner renderer replacement not repaired')
sources[2]=provider()
callbacks['world.stepped']{game=game}
assert(invalidations==3 and refreshes==3,'new provider not initialized')
callbacks['world.stepped']{game=game}
assert(invalidations==3 and refreshes==3,'new provider refreshed repeatedly')
callbacks['mod.options_changed']{mod='test'}
assert(invalidations==5 and refreshes==5,'settings did not refresh sources')
bridge:public().refresh(game)
assert(invalidations==7 and refreshes==7,'explicit public refresh lost')
enabled=false
callbacks['mod.options_changed']{mod='test'}
assert(first.sprite.def.id=='new-owner' and not first.sprite.def.ascendantPokemonWalksheet)
assert(first.pokemonModel==true and second.pokemonModel==true,'disable did not restore owner')
for _,event in ipairs{'mods.loaded','game.ready','save.loaded','map.entered','map.reloaded'}do
 local before=invalidations;callbacks[event]{game=game};assert(invalidations==before+2,event)
end
bridge:restore()
print('PASS step refresh: stable caches, late actors/providers, identity/renderer changes, settings, lifecycle and owner restoration')
