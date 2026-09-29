-- One atmosphere volume in world coordinates, independent of the active map.
local V=...
local M={}
local maps={LAVENDER_TOWN=true,ROUTE_8=true,ROUTE_10=true,ROUTE_12=true}
function M.region(map)
 if not(map and map.def and map.def.generation~=2 and maps[map.id])then return nil end
 local P=V.require('WorldPlacement')
 local here,town=P.position(map.id),P.position('LAVENDER_TOWN')
 if not(here and town and here.anchor==town.anchor)then return nil end
 local x,z=town.x-here.x,town.y-here.y
 return {x-96,z-96,x+320+96,z+288+96}, {here.x,here.y}
end
function M.weight(region,x,z)
 if not region or not x or not z then return 0 end
 local distance=math.min(x-region[1],z-region[2],region[3]-x,region[4]-z)
 local t=math.max(0,math.min(1,distance/192))
 return t*t*(3-2*t)
end
return M
