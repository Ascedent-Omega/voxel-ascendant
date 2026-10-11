-- Imported atlases use local tile numbers. Kanto's numbered floor donors
-- would therefore sample furniture or border art under a claimed wall.
local V=...
local M={}
local cache=setmetatable({},{__mode='k'})
function M.tile(map,tx,ty)
 local source=V.require('KascSeviiScenery')
 if not source.profile(map)then return end
 local field=cache[map]
 if not field then
  local w,h=map.def.width*2,map.def.height*2
  field={width=w,donors={}};local queue={}
  for y=0,h-1 do for x=0,w-1 do
   local tag=source.token(map,x*2,y*2)
   if tag=='G'and map:isWalkableCell(x,y)and not map:isWaterCell(x,y)
    and not source.portalAt(map,x,y)then
    local key=y*w+x;field.donors[key]={x*2,y*2};queue[#queue+1]=key
   end
  end end
  local cursor=1
  while cursor<=#queue do
   local key=queue[cursor];cursor=cursor+1
   local x,y=key%w,math.floor(key/w)
   for _,d in ipairs{{-1,0},{1,0},{0,-1},{0,1}}do
    local xx,yy=x+d[1],y+d[2];local nextKey=yy*w+xx
    if xx>=0 and yy>=0 and xx<w and yy<h and not field.donors[nextKey]
     and not map:isWaterCell(xx,yy)then
     field.donors[nextKey]=field.donors[key];queue[#queue+1]=nextKey
    end
   end
  end
  cache[map]=field
 end
 local x,y=math.floor(tx/2),math.floor(ty/2)
 local donor=x>=0 and y>=0 and x<field.width and y<map.def.height*2 and field.donors[y*field.width+x]
 if donor then return map:tileAt(donor[1]+tx%2,donor[2]+ty%2)end
 -- A source without ordinary flooring retains its own artwork.
 return map:tileAt(tx,ty)
end
return M
