local Catalog=dofile('integrated/ascendant_pokemon_overworld/src/catalog.lua')
local species={'AMBIPOM','MISMAGIUS','HONCHKROW','WEAVILE','MAGNEZONE',
  'LICKILICKY','RHYPERIOR','TANGROWTH','ELECTIVIRE','MAGMORTAR','TOGEKISS',
  'YANMEGA','LEAFEON','GLACEON','GLISCOR','MAMOSWINE','PORYGON_Z','AZURILL','WYNAUT'}
local national={424,429,430,461,462,463,464,465,466,467,468,469,470,471,472,473,474,298,360}
local hevo={OWNER='kasc.hevo-species/v1',enabled=true,presentationBySpecies={}}
local game={data={pokemon={}},mods={exports={kanto_ascendant={
  hevoSpecies=hevo,seviiExpedition={maps={island=true,room=true}}}}},overworld={map={id='island'}}}
for i,name in ipairs(species)do
  game.data.pokemon[name]={dex=260+i,hevoSourceDex=national[i]}
  hevo.presentationBySpecies[name]={dex=260+i,sourceDex=national[i]}
end
local checks=0
local function check(value,message)checks=checks+1;assert(value,message)end
for _,map in ipairs({'island','room'})do
  game.overworld.map.id=map
  for i,name in ipairs(species)do
    for _,value in ipairs({name,{species=name},{species=name,nationalDex=260+i}})do
      check(Catalog.presentationDexFor(game,value)==national[i],map..' '..name..' canonical identity')
    end
  end
end
game.overworld.map.id='PALLET_TOWN'
for i,name in ipairs(species)do
  check(Catalog.presentationDexFor(game,name)==260+i,'existing Kanto HEVO presentation')
end
for i=1,411 do
  check(Catalog.presentationDexFor(game,{nationalDex=i})==i,'existing Kanto explicit identity')
end
game.overworld.map.id='island';hevo.OWNER='another-owner'
check(Catalog.presentationDexFor(game,'RHYPERIOR')==267,'unverified owner not admitted')
hevo.OWNER='kasc.hevo-species/v1';game.data.pokemon.RHYPERIOR.hevoSourceDex=1
check(Catalog.presentationDexFor(game,'RHYPERIOR')==267,'stale owner contract not admitted')
print('PASS Sevii species identity: '..checks..' checks')
