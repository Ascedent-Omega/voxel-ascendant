-- Distant templates retain the exact union of solid boxes. Only paint/detail
-- boxes already wholly contained in an earlier solid may be omitted.
local D={enabled=true}
function D.model(model,budget)
 if not model or not model.terrain or model.landmarkHeight or model.directBoxes
     or not model.boxes or #model.boxes<8 then return end
 local boxes={}
 for i,b in ipairs(model.boxes)do
  if budget then budget.check()end
  local contained=false
  for j=1,i-1 do
   local a=model.boxes[j]
   if a[1]<=b[1] and a[2]<=b[2] and a[3]<=b[3]
     and a[1]+a[4]>=b[1]+b[4] and a[2]+a[5]>=b[2]+b[5] and a[3]+a[6]>=b[3]+b[6]then
    contained=true;break
   end
  end
  if not contained then boxes[#boxes+1]=b end
 end
 if #boxes>#model.boxes*.90 then return end
 return {boxes=boxes,step=model.step or 1}
end
-- Actual screen footprint, not just distance: zoomed/nearby props stay exact.
function D.use(bounds,mat,eye,vp,height)
 if not D.enabled or not bounds or not mat or not eye or not vp or not height then return false end
 -- Bounds below are translated directly. Rotated/scaled props keep their
 -- original geometry until their full transformed footprint is supported.
 if mat[1]~=1 or mat[6]~=1 or mat[11]~=1 or mat[16]~=1
   or mat[2]~=0 or mat[3]~=0 or mat[5]~=0 or mat[7]~=0
   or mat[9]~=0 or mat[10]~=0 or mat[13]~=0 or mat[14]~=0 or mat[15]~=0 then return false end
 local x=(bounds[1]+bounds[4])*.5+mat[4];local y=(bounds[2]+bounds[5])*.5+mat[8];local z=(bounds[3]+bounds[6])*.5+mat[12]
 if (x-eye[1])^2+(y-eye[2])^2+(z-eye[3])^2<320^2 then return false end
 local lo,hi=math.huge,-math.huge
 for i=0,7 do
  local px=bounds[i%2==0 and 1 or 4]+mat[4]
  local py=bounds[math.floor(i/2)%2==0 and 2 or 5]+mat[8]
  local pz=bounds[i<4 and 3 or 6]+mat[12]
  local w=vp[13]*px+vp[14]*py+vp[15]*pz+vp[16]
  if w<=.01 then return false end
  local sy=(vp[5]*px+vp[6]*py+vp[7]*pz+vp[8])/w
  lo=math.min(lo,sy);hi=math.max(hi,sy)
 end
 return (hi-lo)*height*.5<72
end
return D
