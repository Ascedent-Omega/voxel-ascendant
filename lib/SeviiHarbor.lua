-- Open ferry terminal fronts on their verified source footprints. The door
-- and windows come from the recipe, not a guessed house or rectangular room.
local M={}
function M.facade(P,p,s)
 local name='sevii_quay_front_'..p.source..'_'..s.x..'_'..s.y
 if P.models[name]then return name end
 local w,h=s.w*16,s.h*16;local c=P.decorColors;local boxes={}
 local function b(x,y,z,bw,bh,bd,color)
  if bw>0 and bh>0 and bd>0 then boxes[#boxes+1]={x,y,z,bw,bh,bd,color}end
 end
 local doors={}
 for _,door in ipairs(s.doors or{})do doors[#doors+1]=(door.x-s.x)*16 end
 table.sort(doors)
 local front=h-16;local cursor=0
 local function panel(x,width)
  b(x,0,front,width,8,5,c.stone)
  b(x,8,front,width,18,5,c.clay)
  b(x,26,front,width,3,6,c.stone)
 end
 for _,x in ipairs(doors)do
  panel(cursor,x-cursor)
  b(x,27,front,16,5,6,c.stone)
  b(x-1,0,front-1,1,27,7,c.slate);b(x+16,0,front-1,1,27,7,c.slate)
  cursor=x+16
 end
 panel(cursor,w-cursor)
 b(0,29,0,w,3,h,c.stone);b(0,32,0,w,2,h,c.silver)
 for _,window in ipairs(s.windows or{})do
  local x=window.x*16+2
  b(x,13,front+5,12,8,1,c.silver)
  b(x+1,14,front+6,10,6,.5,8)
  b(x,12,front+5,12,1,2,c.slate)
 end
 P.models[name]={boxes=boxes,directBoxes=true,terrain=true,step=1,frameW=w,frameH=h+48,depth=h,offsetY=-48}
 return name
end
function M.rail(P,kind)
 local name=kind..'_quay';if P.models[name]then return name end
 local source=P.models[kind];local c=P.decorColors;local model={}
 for k,v in pairs(source)do model[k]=v end;model.boxes={}
 for _,b in ipairs(source.boxes)do
  local copy={unpack(b)};copy[7]=b[7]==c.oak and c.silver or b[7]==c.walnut and c.navy or b[7]
  model.boxes[#model.boxes+1]=copy
 end
 P.models[name]=model;return name
end
return M
