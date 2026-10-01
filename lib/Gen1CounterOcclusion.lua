-- The native hotel clerk stands on floor behind the reception counter.
-- Orbit-card camera bias must not pull her feet through that opaque desk.
local M={}
function M.pull(map,entity,ground,hopping)
 local d=map and map.def
 if not(d and map.id=='CELADON_HOTEL' and d.generation~=2
   and d.tileset=='POKECENTER' and d.width==7 and d.height==4
   and not next(d.connections or{}))then return nil end
 local e=entity
 if not(e and e.def and e.def.sprite=='SPRITE_GRANNY'
   and not e.moving and not hopping and ground==0
   and type(e.cellX)=='number'and type(e.cellY)=='number')then return nil end
 if e.px~=e.cellX*16 or e.py~=e.cellY*16
   or not map:isWalkableCell(e.cellX,e.cellY)
   or not map:inBounds(e.cellX,e.cellY+1)
   or map:isWalkableCell(e.cellX,e.cellY+1)then return nil end
 local x,y=e.cellX*2,(e.cellY+1)*2
 -- Exact native top/front drawing, not any raised cell or neighboring wall.
 for dx=0,1 do
  if map:tileAt(x+dx,y)~=8 or map:tileAt(x+dx,y+1)~=(dx==0 and 24 or 25) then return nil end
 end
 return 0
end
return M
