-- Black void outside the projected glazing. Runs after sky, before the room;
-- window pixels retain the real sky. CPU convex clipping needs no new shader,
-- stencil attachment, texture or second scene render.
local V=...
local M={}
local function clip(poly,distance)
 local out={};if #poly==0 then return out end
 local a=poly[#poly];local da=distance(a)
 for _,b in ipairs(poly)do
  local db=distance(b)
  if (da>=0)~=(db>=0)then
   local t=da/(da-db);local p={}
   for i=1,#a do p[i]=a[i]+(b[i]-a[i])*t end
   out[#out+1]=p
  end
  if db>=0 then out[#out+1]=b end
  a,da=b,db
 end
 return out
end
function M.windows(w,d,H,eye,vp,rearOnly,apertures)
 local out={}
 local walls={{3,1,0,w,-1},{3,1,d,w,1},{1,3,0,d,-1},{1,3,w,d,1}}
 if apertures then
  walls={}
  for _,p in ipairs(apertures)do
   local horizontal=p.edge=='north'or p.edge=='south'
   walls[#walls+1]={horizontal and 3 or 1,horizontal and 1 or 3,p.at,p.upto,
    (p.edge=='north'or p.edge=='west')and -1 or 1,p.from,p.bottom,p.top}
  end
 end
 for index,wall in ipairs(walls)do
  if rearOnly and index>1 then break end
  local axis,along,at,span,side=unpack(wall)
  if (eye[axis]-at)*side<=0 then
   local poly={}
   for _,corner in ipairs{{wall[6]or 0,wall[7]or 10},{span,wall[7]or 10},{span,wall[8]or H-5},{wall[6]or 0,wall[8]or H-5}}do
    local p={0,corner[2],0,1};p[axis]=at;p[along]=corner[1]
    local q={};for row=0,3 do q[row+1]=vp[row*4+1]*p[1]+vp[row*4+2]*p[2]+vp[row*4+3]*p[3]+vp[row*4+4]end
    poly[#poly+1]=q
   end
   -- Clip before dividing by w, including panes crossing the camera plane.
   poly=clip(poly,function(p)return p[4]-.00001 end)
   for axis=1,3 do for _,side in ipairs{-1,1}do
    poly=clip(poly,function(p)return p[4]+side*p[axis]end)
   end end
   if #poly>=3 then
    local projected={};for _,p in ipairs(poly)do projected[#projected+1]={p[1]/p[4],p[2]/p[4]}end
    out[#out+1]=projected
   end
  end
 end
 return out
end
local function area(poly)
 local sum=0;for i,p in ipairs(poly)do local q=poly[i%#poly+1];sum=sum+p[1]*q[2]-q[1]*p[2]end
 return sum/2
end
M.area=area
function M.complement(windows)
 local pieces={{{-1,-1},{1,-1},{1,1},{-1,1}}}
 for _,window in ipairs(windows)do
  local signed=area(window)
  if math.abs(signed)>1e-10 then
   local sign=signed>0 and 1 or -1;local nextPieces={}
   for _,piece in ipairs(pieces)do
    local inside=piece
    for i,a in ipairs(window)do
     if #inside<3 then break end
     local b=window[i%#window+1]
     local function distance(p)return sign*((b[1]-a[1])*(p[2]-a[2])-(b[2]-a[2])*(p[1]-a[1]))end
     local outside=clip(inside,function(p)return -distance(p)end)
     if #outside>=3 and math.abs(area(outside))>1e-10 then nextPieces[#nextPieces+1]=outside end
     inside=clip(inside,distance)
    end
   end
   pieces=nextPieces
  end
 end
 return pieces
end
function M.inside(w,d,H,eye,b)
 b=b or {west=0,east=w,north=0,south=d}
 return eye and eye[1]>b.west and eye[1]<b.east and eye[3]>b.north and eye[3]<b.south and eye[2]<H
end
function M.paint(g,w,h,map,H,eye,vp)
 -- A camera inside the room sees its real ceiling. Never replace that
 -- first/third-person backdrop with an artificial black surround.
 if M.inside(map.def.width*32,map.def.height*32,H,eye,V.require('Gen1RoomBounds').forMap(map))then M.lastPieces=0;return end
 local apertures={}
 for _,p in ipairs(V.require('SilphWindows').apertures(map,H))do apertures[#apertures+1]=p end
 for _,p in ipairs(V.require('GlassDoorWindows').apertures(map))do apertures[#apertures+1]=p end
 local pieces=M.complement(M.windows(map.def.width*32,map.def.height*32,H,eye,vp,false,apertures))
 g.setShader();g.setDepthMode();g.setColor(0,0,0,1)
 for _,poly in ipairs(pieces)do
  local vertices={};for _,p in ipairs(poly)do vertices[#vertices+1]=(p[1]+1)*w/2;vertices[#vertices+1]=(p[2]+1)*h/2 end
  g.polygon('fill',vertices)
 end
 M.lastPieces=#pieces
end
return M
