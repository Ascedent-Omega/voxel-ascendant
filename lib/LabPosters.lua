-- UV crops of the existing authored scientific scrolls. Keep all three
-- readable, unmirrored and on one north wall; no raster resampling required.
local M={}
-- Native starter balls, from left to right: Charmander, Squirtle, Bulbasaur.
M.crops={{.345,.458,.148,.681},{.866,.980,.148,.681},{.021,.117,.148,.681}}
function M.matches(map)
 local d=map and map.def
 return map and map.id=='OAKS_LAB'and d and d.generation~=2
  and d.tileset=='DOJO'and d.width==5 and d.height==6
end
function M.layout(panel,height)
 if panel.edge~='north'then return {}end
 local span=panel.upto-panel.from
 -- Keep the 50px scrolls and native bookcase. Lower the scrolls by 12px;
 -- the starter illustrations stay above the shelf, while its back may
 -- naturally overlap the lower study diagrams on the right-hand poster.
 local bottom=22
 local h=math.min(50,height-bottom-4,(span-20)/3/.63)
 if h<12 then return {}end
 local w=h*.63;local gap=(span-w*3)/4;local out={}
 for i,crop in ipairs(M.crops)do
  local left=panel.from+gap*i+w*(i-1)
  out[i]={from=left,upto=left+w,bottom=bottom,top=bottom+h,
   u0=crop[1],u1=crop[2],v0=crop[4],v1=crop[3]}
 end
 return out
end
return M
