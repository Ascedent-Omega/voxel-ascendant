-- Door openings share the already transformed exterior used by real windows.
-- No second scene, capture, image decode or per-frame mesh construction.
local V=...
local M={}
local cache=setmetatable({},{__mode='k'})
function M.apertures(map)
 if not V.require('SilphWindows').enabled(map)then return{}end
 if cache[map]then return cache[map].panes end
 local profile=V.require('Gen1InteriorPanoramas').profileFor(map)
 local panes,rects,edges={},{},{0,0,0,0}
 local rows={north=1,south=2,west=3,east=4}
 if profile then
  local bounds=V.require('Gen1RoomBounds').forMap(map)
  for _,p in ipairs(V.require('Gen1InteriorLayout').panelsFor(map,profile))do
   if not p.column and not p.endcap and not p.wallThickness and
    (p.at==bounds[p.edge]or V.require('HouseWindows').perimeter(map,p))then
    for _,door in ipairs(p.openings or{})do
     if door.material=='room_glass_door'and door.doorView and #panes<4 then
      panes[#panes+1]={edge=p.edge,at=p.at,from=door.from,upto=door.upto,bottom=0,top=door.height,door=true}
      rects[#rects+1]={door.from,door.upto,p.at,door.height};edges[#panes]=rows[p.edge]
     end
    end
   end
  end
 end
 for i=#rects+1,4 do rects[i]={0,0,0,0}end
 cache[map]={panes=panes,rects=rects,edges=edges}
 return panes
end
function M.matches(map,p,door)
 for _,a in ipairs(M.apertures(map))do
  if a.edge==p.edge and a.at==p.at and a.from==door.from and a.upto==door.upto then return true end
 end
 return false
end
function M.uniforms(map)
 M.apertures(map)
 local c=cache[map]
 return c and c.rects,c and c.edges
end
return M
