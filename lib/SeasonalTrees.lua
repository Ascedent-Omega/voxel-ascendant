-- Seasonal geometry; weather overrides never decide whether a tree sheds.
local V=...
local S={}
function S.winter()
 local W=V.require('Weather')
 return W.seasonAt(W.clock)=='winter'
end
function S.sheds(id,x,z)
 local h=17
 for i=1,#tostring(id or '')do h=(h*31+tostring(id):byte(i))%65521 end
 -- Coordinate mixing avoids rows of identical evergreen exceptions.
 h=(h+(x or 0)*73856093+(z or 0)*19349663+(x or 0)*(z or 0)*83492791)%100003
 return h%10~=0
end
local variants=setmetatable({},{__mode='k'})
function S.kind(P,kind,id,x,z)
 local source=P.models[kind]
 if not(source and source.seasonalFoliage and source.leafColors and S.winter() and S.sheds(id,x,z))then return kind end
 local winterKind=kind..'_bare_winter'
 if variants[source] and P.models[winterKind]==variants[source]then return winterKind end
 local model={};for k,v in pairs(source)do model[k]=v end
 model.boxes={};model.seasonalFoliage=false;model.blossomSource=nil
 local top=0
 for _,b in ipairs(source.boxes)do
  top=math.max(top,b[2]+b[5])
  if not source.leafColors[b[7]]then model.boxes[#model.boxes+1]=b end
 end
 local w,d=source.frameW,source.depth;local cx,cz=w/2,d/2
 local C=P.decorColors;local wood=C.walnut
 local function b(x,y,z,bw,bh,bd,c)
  model.boxes[#model.boxes+1]={math.floor(x),math.floor(y),math.floor(z),math.max(1,math.floor(bw)),math.max(1,math.floor(bh)),math.max(1,math.floor(bd)),c or wood}
 end
 -- Stepped asymmetric forks stay within the original blocked footprint.
 local stem=math.max(2,math.floor(w/8));local start=math.floor(top*.38)
 b(cx-stem/2,start,cz-stem/2,stem,top*.46,stem)
 for arm=0,3 do
  local dx=arm==0 and -1 or arm==1 and 1 or 0
  local dz=arm==2 and -1 or arm==3 and 1 or 0
  for step=1,3 do
   local reach=step*w*.105;local y=start+step*top*.115+(arm%2)*2
   b(cx+dx*reach-1,y,cz+dz*reach-1,2,top*.13,2,step==3 and C.oak or wood)
   b(cx+dx*reach-1-math.max(dx,0)*w*.11,y,cz+dz*reach-1-math.max(dz,0)*d*.11,
    dx~=0 and w*.11+2 or 2,2,dz~=0 and d*.11+2 or 2)
  end
 end
 P.models[winterKind]=model;variants[source]=model
 return winterKind
end
return S
