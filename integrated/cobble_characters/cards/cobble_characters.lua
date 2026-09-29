local Card={SCHEMA="ascendant.card/v1",ID="ascendant.cobble-characters.visual-provider",VERSION="0.2.4"}
local provides={"ascendant.cobble-characters/v1","ascendant.character-art-catalog/v1","ascendant.character-art-source/v1"}
function Card.descriptor(provider)
  return {schema=Card.SCHEMA,id=Card.ID,version=Card.VERSION,owner="ASCENDANT_COBBLE_CHARACTERS",
    requires={},optionalRequires={},consumes={},provides=provides,
    tests={"tests/provider_test.lua","tests/assets_test.py"},docs={"README-DE.md","docs/INTEGRATION.md"},saveNamespace=false,
    impact={runtimeOwners={"overworld.cobble-character-provider"},saveWrites={},publicHooks={},
      files={"main.lua","src/catalog.lua","src/provider.lua","cards/cobble_characters.lua","assets"}},
    lifecycle={
      install=function() return {provider=provider} end,
      activate=function(_,installed) provider:activate();return installed or {provider=provider},provider:public() end,
      deactivate=function() return provider:deactivate() end,
      abort=function() return provider:deactivate() end,
      health=function() return provider:health() end}}
end
function Card.public(provider)
  return {schema=Card.SCHEMA,id=Card.ID,version=Card.VERSION,provides=provides,
    registration="public art-source; host-owned binding via packaged adapter",
    descriptor=function() return Card.descriptor(provider) end}
end
return Card
