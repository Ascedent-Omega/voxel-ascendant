local clock=0;local reads,images=0,0
love={timer={getTime=function()return clock end}}
local content={catalog={},available=function()return true end,record=function(dex,variant,checkpoint)
 reads=reads+1
 for i=1,12 do clock=clock+.001;checkpoint()end
 return {identity=dex..':'..variant}
end}
local pack=assert(loadfile('lib/CobblemonPack.lua')){require=function(n)
 return assert(({CobblemonContent=content,CobblemonGeometry={},Diagnostics={write=function()end}})[n], n)
end}
pack.image=function()images=images+1 end
local function actor(dex)return {ascendantPokemonModelSource='cobblemon',ascendantPokemonModelDex=dex}end
local a=actor(1);local world={map={},entities={a}}
assert(pack.prewarmEntities(world));assert(not pack.entitiesReady(world)and images==0)
for i=1,30 do pack.prewarmEntities(world);if pack.entitiesReady(world)then break end end
assert(pack.entitiesReady(world)and reads==1 and images==1,'decode restarted or published early')
-- Removal, appearance and map changes cancel suspended work.
world.entities={actor(2)};pack.prewarmEntities(world);world.entities={};assert(not pack.prewarmEntities(world))
local b=actor(3);world.entities={b};pack.prewarmEntities(world);b.ascendantPokemonModelAppearance={shiny=true}
pack.prewarmEntities(world);assert(not pack.entitiesReady(world))
for i=1,30 do pack.prewarmEntities(world);if pack.entitiesReady(world)then break end end
assert(pack.entitiesReady(world)and images==2,'cancelled appearance uploaded')
world.entities={actor(4)};pack.prewarmEntities(world);world.map={};world.entities={actor(5)}
for i=1,30 do pack.prewarmEntities(world);if pack.entitiesReady(world)then break end end
assert(pack.entitiesReady(world)and images==3,'cancelled map uploaded')
content.epoch=1;pack.prewarmEntities(world);assert(not pack.entitiesReady(world))
content.epoch=2
for i=1,30 do pack.prewarmEntities(world);if pack.entitiesReady(world)then break end end
assert(pack.entitiesReady(world)and images==4,'cancelled epoch uploaded')
print('PASS cooperative model preload: sliced decode, atomic readiness, no restart, removed actor/variant/map/epoch cancellation')
