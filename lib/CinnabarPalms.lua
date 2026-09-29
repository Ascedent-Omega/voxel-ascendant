-- Original Orange Islands coconut palms on the three existing quay anchors.
-- Only high foliage overhangs the native cell; roots and collision stay put.
local M={}
function M.register(P,F,enabled)
 local C=P.decorColors
 for variant,at in ipairs({{8,24},{12,28},{38,28}})do
  local kind='cinnabar_palm_'..variant
  local model={terrain=true,boxes={},step=1,frameW=16,frameH=68,depth=16,offsetY=-52}
  P.models[kind]=model
  local function b(x,y,z,w,h,d,c)
   model.boxes[#model.boxes+1]={math.floor(x+.5),math.floor(y+.5),math.floor(z+.5),w,h,d,c}
  end
  -- Port of Orange-Island-Voxel-Demo/sinnoh_models.py:palm, archived
  -- 2026-09-21. Original seven tapered blades, rings, colours and coconuts.
  local scale=variant==1 and .9 or 1
  local height=43*scale;local seed=(at[1]/2+at[2]/2)%7
  for y=0,math.ceil(height)-1 do
   local bend=5*(y/height)^2;local radius=2.3*scale*(1-.28*y/height)
   for x=-3,3 do for z=-3,3 do if x*x+z*z<=radius*radius then
    b(8+math.floor(bend+.5)+x,y,4+z,1,1,1,y%6<2 and C.palmBark or C.palmWood)
   end end end
  end
  for frond=0,6 do
   local a=frond*math.pi*2/7+seed*.31
   local length=(25+(frond*7)%9)*scale
   for j=0,math.ceil(length)-1 do
    local t=j/length;local y=height+7*math.sin(t*math.pi)-12*t*t
    local half=math.max(.6,3.8*math.sin(math.pi*t)^.7)*scale
    for side=-math.ceil(half),math.ceil(half)do if math.abs(side)<=half then
     local x=5*scale+math.cos(a)*j-math.sin(a)*side
     local z=math.sin(a)*j+math.cos(a)*side
     b(8+x,y-math.abs(side)*.35,4+z,1,1,1,
      side==0 and C.palmLight or (frond+j)%3~=0 and C.palmLeaf or C.palmDark)
    end end
   end
  end
  for _,fruit in ipairs{{2,0},{6,2},{5,-3}}do
   b(8+fruit[1]*scale,height-3,4+fruit[2]*scale,3*scale,3*scale,3*scale,C.palmCoconut)
  end
  F.patterns[#F.patterns+1]={kind=kind,sets={OVERWORLD=true},maps={CINNABAR_ISLAND=true},
   x=at[1],y=at[2],tiles={{51,51},{20,20}},voxelOnly=true,keepTerrain=true,
   enabled=enabled,
   guard=function(map,x,y)
    return map.def.generation~=2 and map.def.width==10 and map.def.height==9
     and not map:isWalkableCell(x/2,y/2)and not map:isWarpTileCell(x/2,y/2)
   end}
 end
end
return M
