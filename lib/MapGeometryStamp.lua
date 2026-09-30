local V=...
local M={}
function M.forMap(map)
 if not(map and map.def and map.tileset)then return nil end
 local ok,value=pcall(function()
  return V.require("TerrainDiskCache").fingerprint({definition=map.def,tileset=map.tileset,
   walkable=map.walkable,water=map.waterTiles,doors=map.doorTiles,warps=map.warpAt,
   warpTiles=map.warpTiles})
 end)
 return ok and value or nil
end
return M
