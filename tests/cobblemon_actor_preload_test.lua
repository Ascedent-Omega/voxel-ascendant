local reads,images=0,0
local content={catalog={},epoch=0,available=function()return true end,
 record=function(dex,variant)reads=reads+1;return {texture='base',identity=dex..':'..variant}end,
 read=function()return 'image'end}
local function resource()return {getWidth=function()return 2 end,getHeight=function()return 2 end,setFilter=function()end,release=function()end}end
love={image={newImageData=resource},graphics={newImage=function()images=images+1;return resource()end}}
local modules={CobblemonContent=content,CobblemonGeometry={},Diagnostics={write=function()end},
 EngineCompat={fs=function()return {newFileData=resource}end}}
local pack=assert(loadfile('lib/CobblemonPack.lua'))({require=function(n)return assert(modules[n],n)end})
local world={entities={}}
for i=1,20 do world.entities[i]={ascendantPokemonModelSource='cobblemon',ascendantPokemonModelDex=i,px=i,py=2}end
world.entities[21]={ascendantPokemonModelSource='stadium2',ascendantPokemonModelDex=30}
world.entities[22]={ascendantPokemonModelSource='cobblemon',ascendantPokemonModelDex=31,pokemonModel=false}
for i=1,20 do
 assert(not pack.entitiesReady(world));local n=reads;assert(pack.prewarmEntities(world));assert(reads==n+1,'more than one model per step')
end
assert(pack.entitiesReady(world)and not pack.prewarmEntities(world))
assert(reads==20 and images==20)
collectgarbage('collect')
for _,e in ipairs(world.entities)do
 if e.ascendantPokemonModelDex<=20 then
  local model=pack.load(e.ascendantPokemonModelDex);assert(pack.image(model,1));assert(e.px==e.ascendantPokemonModelDex and e.py==2)
 end
end
assert(reads==20 and images==20,'actor leases lost warmed models after bounded LRU eviction')
local n=reads
for i=1,100 do assert(pack.entitiesReady(world))end
assert(reads==n,'readiness loaded data')
local actor=world.entities[1];actor.ascendantPokemonModelAppearance={shiny=true}
assert(not pack.entitiesReady(world));assert(pack.prewarmEntities(world));assert(pack.entitiesReady(world));assert(reads==21)
actor.ascendantPokemonModelAppearance.shiny=false;actor.ascendantPokemonModelAppearance.gender='female'
assert(not pack.entitiesReady(world));assert(pack.prewarmEntities(world));assert(pack.entitiesReady(world));assert(reads==22)
content.epoch=1;assert(not pack.entitiesReady(world))
for i=1,20 do assert(pack.prewarmEntities(world))end
assert(pack.entitiesReady(world))
local weak=setmetatable({pack.load(2)},{__mode="v"})
assert(weak[1])
local another={map={},entities={world.entities[2]}}
assert(not pack.entitiesReady(another));assert(pack.prewarmEntities(another));assert(pack.entitiesReady(another))
assert(not pack.entitiesReady(world),'foreign map reused a preparation receipt')
for i=1,20 do assert(pack.prewarmEntities(world))end
another=nil
-- Failed optional content releases the gate; a changed content epoch retries.
local failure={entities={{ascendantPokemonModelSource='cobblemon',ascendantPokemonModelDex=55}}}
content.record=function()reads=reads+1;error('missing package')end
assert(pack.prewarmEntities(failure));assert(pack.entitiesReady(failure));assert(not pack.prewarmEntities(failure))
content.epoch=2;assert(not pack.entitiesReady(failure))
-- Removed actors cannot keep a model alive after ordinary LRU eviction.
local model=pack.load -- keep only the function, not a model/actor reference
world=nil;actor=nil;failure=nil
for i=60,90 do pcall(model,i)end
collectgarbage('collect');collectgarbage('collect')
assert(weak[1]==nil,'removed actor retained model')
assert(pack.entitiesReady(nil)and not pack.prewarmEntities(nil))
print('PASS actor preload: one model/step, exact shared records/textures, LRU pressure, live variants/epoch, pure readiness and optional failures')
