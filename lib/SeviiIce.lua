-- Faceted ice on the reviewed, blocked source ice-boulder plots only.
-- Every column fits its native 16px cell; nearby thin ice and water stay free.
local M={}
function M.register(P)
 for variant=1,4 do
  local name='sevii_iceberg_'..variant
  if not P.models[name]then
   local c=P.decorColors;local boxes={}
   for z=2,12,2 do for x=2,12,2 do
    local dx,dz=(x+1-8)/6,(z+1-8)/6
    local distance=math.abs(dx)*.72+math.abs(dz)*.83
    local ridge=math.max(0,1-distance)
    if ridge>0 then
     local height=2+2*math.floor(ridge*(4+variant%2))
     local blue=(x+z+variant)%3==0 and(c.iceLight or c.silphGlass)or(c.iceMid or 7)
     boxes[#boxes+1]={x,0,z,2,height,2,blue}
     boxes[#boxes+1]={x,height,z,2,2,2,c.iceFrost or 14}
    end
   end end
   P.models[name]={boxes=boxes,directBoxes=true,terrain=true,step=2,
    frameW=16,frameH=32,depth=16,offsetY=-16}
  end
 end
end
return M
