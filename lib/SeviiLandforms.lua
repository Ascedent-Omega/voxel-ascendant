-- Cohesive cliff courses rather than a separate boulder on every cliff cell.
-- Mask bits describe actual adjacent blocked source cliff cells. The model
-- remains inside its own 16px source plot, including at runtime map seams.
local M={}
function M.kind(P,p,map,x,y,token,portal,family)
 local mask=0
 for i,d in ipairs{{-1,0},{1,0},{0,-1},{0,1}}do
  local xx,yy=x+d[1],y+d[2]
  if xx>=0 and yy>=0 and xx<map.def.width*2 and yy<map.def.height*2
   and token(map,xx*2,yy*2)=='C'and not map:isWalkableCell(xx,yy)
   and not map:isWaterCell(xx,yy)and not portal(map,xx,yy)then mask=mask+2^(i-1)end
 end
 if p.cliffMasks and p.cliffMasks[y+1]then mask=p.cliffMasks[y+1]:byte(x+1)-33 end
 local phaseX,phaseZ=(x+p.origin[1])%4,(y+p.origin[2])%4
 local name='sevii_'..family..'_cliff_'..mask..'_'..phaseX..'_'..phaseZ
 if P.models[name]then return name end
 local c=P.decorColors;local boxes={}
 local icy=family=='ice'
 local earthy=family=='canyon'
 local side=earthy and c.looseRock4 or c.looseRock1
 local cap=earthy and c.looseRock6 or family=='basalt'and c.looseRock2 or c.looseRock3
 local function joined(bit)return math.floor(mask/bit)%2==1 end
 for z=0,14,2 do for xx=0,14,2 do
  local edge=16
  if not joined(1)then edge=math.min(edge,xx+1)end
  if not joined(2)then edge=math.min(edge,15-xx)end
  if not joined(4)then edge=math.min(edge,z+1)end
  if not joined(8)then edge=math.min(edge,15-z)end
  local gx,gz=xx+phaseX*16,z+phaseZ*16
  local wave=math.sin(gx*math.pi/32+.5)*math.cos(gz*math.pi/32+.7)
   +.25*math.sin((gx+gz)*math.pi/16)
  local height=(icy and 12 or 18)+2*math.floor((wave+1.25)*1.2)
  if edge<4 then height=height-2*(4-edge)end
  local color=icy and(c.iceMid or 7)or side
  boxes[#boxes+1]={xx,0,z,2,height,2,color}
  local top=icy and(c.iceFrost or 14)or cap
  if family=='forest'and edge>=4 and(gx*3+gz*7)%19==0 then top=c.leafDark end
  boxes[#boxes+1]={xx,height,z,2,2,2,top}
 end end
 P.models[name]={boxes=boxes,terrain=true,step=2,frameW=16,frameH=48,depth=16,offsetY=-32}
 return name
end
return M
