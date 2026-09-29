-- Conservative solid-face occlusion. Every corner of a candidate AABB must
-- project strictly inside ONE authored opaque face, with that face in front.
-- Door/window gaps are never replaced by a building's enclosing bounds.
-- Opt-in only: measured CPU cost cancelled the draw savings on the QA host.
local O={enabled=false,last={}}
function O.faces(entries,solids,eye,curve)
 if not O.enabled or not eye or (curve or 0)~=0 then return {}end
 local faces={}
 for _,p in ipairs(entries)do
  local m=p[3]
  if m and m[1]==1 and m[6]==1 and m[11]==1 and m[2]==0 and m[3]==0 and m[5]==0 and m[7]==0 and m[9]==0 and m[10]==0 then
   for _,b in ipairs(solids(p[1])or{})do
    for axis=1,3 do
     local u=axis%3+1;local v=u%3+1
     local low,high=b[axis]+m[axis*4],b[axis+3]+m[axis*4]
     local plane=eye[axis]<low and low or eye[axis]>high and high
     if plane then
      local distance=math.abs(plane-eye[axis]);local score=(b[u+3]-b[u])*(b[v+3]-b[v])/(distance*distance+1)
      if score>.015 and distance>2 then
       faces[#faces+1]={axis=axis,u=u,v=v,plane=plane,loU=b[u]+m[u*4]+.25,hiU=b[u+3]+m[u*4]-.25,
        loV=b[v]+m[v*4]+.25,hiV=b[v+3]+m[v*4]-.25,score=score,mesh=p[1],mat=m}
      end
     end
    end
   end
  end
 end
 table.sort(faces,function(a,b)return a.score>b.score end)
 for i=#faces,17,-1 do faces[i]=nil end
 for _,f in ipairs(faces)do
  local a,u,v=f.axis,f.u,f.v;local sign=f.plane>eye[a]and 1 or -1
  local distance=math.abs(f.plane-eye[a]);local planes={}
  local function plane(axisWeight,other,otherWeight,offset)
   local n={0,0,0};n[a]=axisWeight;if other then n[other]=otherWeight end
   n[4]=offset or -(n[1]*eye[1]+n[2]*eye[2]+n[3]*eye[3]);planes[#planes+1]=n
  end
  plane(sign,nil,0,-sign*f.plane-.01)
  plane(sign*(eye[u]-f.loU),u,distance)
  plane(sign*(f.hiU-eye[u]),u,-distance)
  plane(sign*(eye[v]-f.loV),v,distance)
  plane(sign*(f.hiV-eye[v]),v,-distance)
  f.planes=planes
 end
 return faces
end
function O.hidden(b,m,faces,eye)
 if not b or not m or not eye or m[1]~=1 or m[6]~=1 or m[11]~=1 or m[2]~=0 or m[3]~=0 or m[5]~=0 or m[7]~=0 or m[9]~=0 or m[10]~=0 then return false end
 local x0,y0,z0=b[1]+m[4],b[2]+m[8],b[3]+m[12]
 local x1,y1,z1=b[4]+m[4],b[5]+m[8],b[6]+m[12]
 for _,f in ipairs(faces)do
  local full=true
  for _,n in ipairs(f.planes)do
   -- The minimum support vertex proves all eight corners lie inside.
   if n[1]*(n[1]>=0 and x0 or x1)+n[2]*(n[2]>=0 and y0 or y1)
      +n[3]*(n[3]>=0 and z0 or z1)+n[4]<=.0001 then full=false;break end
  end
  if full then return true end
 end
 return false
end
return O
