-- Imported Sevii atlases already name every native water/shore cell. The
-- engine's fallback Kanto shore IDs ($32/$48) refer to unrelated RGB grass
-- tiles here. Restore the imported lookup in loaded and connected maps;
-- leave source blocks, collision metadata and all other owners untouched.
local V=...
local M={}
function M.install()
 local Map=require('src.world.Map')
 Map.__vascSeviiWaterOwner=V.require('KascSeviiScenery')
 if Map.__vascSeviiWaterWrapped then return end
 Map.__vascSeviiWaterWrapped=true
 local function owned(def,ts)
  if not(def and def.kaOwner=='kasc.sevii-expedition/v1')then return false end
  return Map.__vascSeviiWaterOwner.profile{id=def.id,def=def,tileset=ts}~=nil
 end
 local function water(ts,tile)
  for _,id in ipairs(ts.waterTiles or{})do if id==tile then return true end end
  for _,id in ipairs(ts.shoreTiles or{})do if id==tile then return true end end
  return false
 end
 local new=Map.new
 Map.new=function(def,ts)
  local map=new(def,ts)
  if owned(def,ts)then
   local lookup={}
   for _,id in ipairs(ts.waterTiles or{})do lookup[id]=true end
   for _,id in ipairs(ts.shoreTiles or{})do lookup[id]=true end
   map.waterTiles=lookup
  end
  return map
 end
 local defWater=Map.defIsWaterCell
 Map.defIsWaterCell=function(def,ts,x,y)
  if owned(def,ts)then return water(ts,Map.defCellTile(def,ts,x,y))end
  return defWater(def,ts,x,y)
 end
end
return M
