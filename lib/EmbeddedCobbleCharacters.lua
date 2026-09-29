-- Bundled art provider. Entity identity, gameplay and styles remain host-owned.
local M={}
function M.install(mod)
 if mod.exports.characterArtSource then return mod.exports.characterArtSource end
 local root='integrated/cobble_characters/'
 local function load(path)
  return assert(loadstring(assert(mod:read(root..path)),'@'..root..path))()
 end
 local child={id=mod.id,path=mod.path..'/'..root:sub(1,-2),cache=mod.cache}
 function child:find(id)return mod:find(id)end
 local provider=load('src/provider.lua').new(child,load('src/catalog.lua'))
 local wardrobe=load('src/wardrobe_art.lua').new(child,load('src/wardrobe_models.lua'),
  load('src/wardrobe_geometry.lua'),load('src/cube_baker.lua'),load('src/field_equipment.lua'))
 -- Definitions are supplied directly to the existing walking-sprite binder.
 -- Do not register duplicate global sprite IDs if the external Card is present.
 mod.exports.cobbleCharacters=provider:public()
 mod.exports.cobbleCharactersCard=load('cards/cobble_characters.lua').public(provider)
 mod.exports.characterArtSource=load('src/integration.lua').new(provider,wardrobe)
 return mod.exports.characterArtSource
end
return M
