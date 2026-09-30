-- One west-coast landmark shared by the shore and distant roof view.
-- Native maps and story warps stay owned
-- by the engine; the expansion is a reversible scenery preference.
local V=...
local M={HEIGHT=672,WIDTH=1280}
M.setting=V.require('ModSetting').new('cinnabarVolcano','CINNABAR VOLCANO',
 {'connected','classic'},{'VOLCANIC COAST','CLASSIC PANORAMA'},'connected')
function M.active()return M.setting:get()=='connected'end
-- Semantic colours make the same landmark independent of either horizon palette.
M.colors={basalt={.095,.10,.115},rock={.17,.17,.18},ash={.38,.36,.34},sand={.69,.64,.51},magma={1,.3,.035},bark={.25,.20,.15},leaf={.22,.32,.18},leafTop={.32,.42,.23}}
-- All scenery stays west of the native map: the original north/south
-- surf corridor (x >= 0) and its coast are never covered by land or stones.
M.EAST_LIMIT=-64
local function shore(z)
 local t=(z-144)/400
 local half=math.sqrt(math.max(0,1-t*t))*622
 local edge=math.sin(z*.053)*10+math.sin(z*.021)*14
 local left=math.floor((-630-half+edge)/8)*8
 local right=math.min(M.EAST_LIMIT-8-8*math.sin(z*.027),math.ceil((-630+half+edge)/8)*8)
 return left,right
end
local function ground(x,z)
 local roll=(math.sin(x*.022+math.sin(z*.017))+math.sin(z*.025-x*.007))*.5
 local radius=math.sqrt(((x+700)/455)^2+((z-144)/330)^2)
 local foothill=math.max(0,1-math.abs(radius-1.1)/.45)
 -- Keep the detailed surface above its solid foundation, including troughs.
 return 5.2+math.max(0,roll)*5+foothill*3
end
M.groundHeight=ground
function M.geometry(emit)
 local function b(x,y,z,w,h,d,c)emit(x,y,z,w,h,d,c,false,false)end
 -- Irregular volcanic coast set back from the native surfing route.
 local leftRim,rightRim={},{}
 for z=-248,535,24 do
  local depth=math.min(24,536-z)
  local x,right=shore(z+depth/2)
  b(x,-30,z,right-x,32,depth,'basalt')
  b(x+5,2,z,math.max(1,right-x-5),3,depth,'ash')
  leftRim[#leftRim+1]={x+14,z+depth/2}
  rightRim[#rightRim+1]={right-10,z+depth/2}
 end
 -- Low, rounded one-cell barrier stones, like the native shore boulders.
 -- The eastern row uses exactly the same size as the rest of the rim.
 local function stone(x,z,i)
  local h=7+i%3;local base=ground(x,z)
  b(x-7,base,z-5,14,h-2,10,'basalt')
  b(x-5,base,z-7,10,h-2,14,'basalt')
  b(x-4,base+h-2,z-4,8,2,8,'rock')
 end
 local rim=leftRim
 for i=#rightRim,1,-1 do rim[#rim+1]=rightRim[i]end
 local carry,index=0,0
 for i,a in ipairs(rim)do
  local c=rim[i%#rim+1]
  local dx,dz=c[1]-a[1],c[2]-a[2];local length=math.sqrt(dx*dx+dz*dz)
  local distance=carry
  while distance<length do
   stone(a[1]+dx*distance/length,a[2]+dz*distance/length,index)
   index=index+1;distance=distance+16
  end
  carry=distance-length
 end
 -- A few trees on the cool, flat apron. Keep the molten outlet and steep
 -- cone bare; roots and stones follow the low rolling ash surface.
 local trees={{-202,18},{-142,83},{-177,267},{-304,376},
  {-519,487},{-850,481},{-1070,385},{-1167,238},
  {-1154,25},{-995,-117},{-768,-211},{-458,-165}}
 for i,p in ipairs(trees)do
  local x,z=p[1],p[2];local h=16+i%4*2;local base=ground(x,z)
  b(x-2,base,z-2,4,h,4,'bark')
  b(x-9,base+h-5,z-7,18,9,14,'leaf')
  b(x-7,base+h-5,z-9,14,9,18,'leaf')
  b(x-6,base+h+4,z-6,12,6,12,'leafTop')
 end
 -- Scattered cooled basalt at the foot and exposed coast. Clustered pockets
 -- leave open stretches of ash instead of an evenly planted decorative grid.
 for cluster=0,15 do
  local a=cluster/16*math.pi*2+.16
  local x=-700+math.cos(a)*(500+cluster%3*20)
  local z=144+math.sin(a)*(350+cluster%4*9)
  local left,right=shore(z)
  if x>left+24 and x<right-24 then
   for j=0,2 do
    local xx=x+math.sin(j*2.1+cluster)*14;local zz=z+math.cos(j*2.7)*11
    stone(xx,zz,cluster+j)
   end
  end
 end
end
local texture
local names={'basalt','rock','ash','sand','magma','bark','leaf','leafTop'}
local function palette()
 if not texture then
  local data=love.image.newImageData(#names,1)
  for i,name in ipairs(names)do local c=M.colors[name];data:setPixel(i-1,0,c[1],c[2],c[3],1)end
  texture=love.graphics.newImage(data);data:release();texture:setFilter('nearest','nearest')
  require('src.render.Assets').register(function()if texture then texture:release();texture=nil end end)
 end
 return texture
end
local function surface(t,a)
 local r=104+340*(1-t)^1.12
 local rough=(math.sin(a*5+.6)+.5*math.sin(a*9-t*2)+.25*math.sin(a*17+t))* (14+18*(1-t))
 local x=-700+math.cos(a)*(r+rough)
 local z=144+math.sin(a)*(r*.72+rough*.65)
 local y=5+t*640+math.sin(a*7+.4)*t*13+math.cos(a*3)*t*11
 local breach=math.exp(-((a-.18)/.065)^2)*math.max(0,(t-.88)/.12)
 y=y-70*breach
 return {x,y,z}
end
-- The broad cone is an irregular basalt surface. Lava is its own continuous
-- ribbon over that same surface, so it follows the slope without box stairs.
function M.meshes(ox,oz,oy,yieldStep,ownedMeshes,view)
 local clock=love and love.timer and love.timer.getTime
 local started=clock and clock()or 0
 local work=0
 local groups={{vertices={},indices={}},{vertices={},indices={}}}
 local function quad(g,a,b,c,d,color,shade)
  work=work+1
  if yieldStep and (work>=64 or work%8==0 and clock and clock()-started>=.00075)then
   yieldStep();work=0;started=clock and clock()or 0
  end
  local n=#g.vertices
  local points={a,b,c,d}
  if view and view.opening then
   local q=view.opening
   local lo,hi={math.huge,math.huge,math.huge},{-math.huge,-math.huge,-math.huge}
   for _,p in ipairs(points)do
    local x,y,z=view.transform(p[1],p[2],p[3])
    for axis,v in ipairs{x,y,z}do lo[axis]=math.min(lo[axis],v);hi[axis]=math.max(hi[axis],v)end
   end
   if lo[1]<q[4]and hi[1]>q[1]and lo[2]<q[5]and hi[2]>q[2]and lo[3]<q[6]and hi[3]>q[3]then return end
  end
  for _,p in ipairs(points)do
   local x,y,z=p[1],p[2],p[3]
   if view then x,y,z=view.transform(x,y,z)end
   g.vertices[#g.vertices+1]={x+ox,y+(oy or 0),z+oz,color<0 and color or (color-.5)/#names,.5,shade or 1}
  end
  for _,i in ipairs{1,2,3,1,3,4}do g.indices[#g.indices+1]=n+i end
 end
 local rock,lava=groups[1],groups[2]
 local indices={basalt=1,rock=2,ash=3,sand=4,magma=5,bark=6,leaf=7,leafTop=8}
 if not(view and view.coneOnly)then
 M.geometry(function(x,y,z,w,h,d,c)
  for face,corners in ipairs(V.require('Voxel3D').FACE_CORNERS)do
   local points={}
   for _,v in ipairs(corners)do points[#points+1]={x+v[1]*w,y+v[2]*h,z+v[3]*d}end
   quad(rock,points[1],points[2],points[3],points[4],indices[c],({.82,.82,1,.65,.85,.85})[face])
  end
 end)
 -- Shallow uneven soil uses the same fine ash/mineral material as the
 -- town. Shared edge heights prevent cracks; the cone hides the inner grid.
 for z=-248,535,24 do
  local depth=math.min(24,536-z);local left,right=shore(z+depth/2)
  for x=left+5,right-1,24 do
   local endX=math.min(x+24,right)
   local centerX,centerZ=(x+endX)/2,z+depth/2
   local radius=((centerX+700)/420)^2+((centerZ-144)/285)^2
   if radius>.92 then
    quad(rock,{x,ground(x,z),z},{x,ground(x,z+depth),z+depth},
     {endX,ground(endX,z+depth),z+depth},{endX,ground(endX,z),z},-183,1)
   end
  end
 end
 end
 for ring=0,31 do for sector=0,63 do
  local a,b=sector/64*math.pi*2,(sector+1)/64*math.pi*2
  local t,u=ring/32,(ring+1)/32
  local shade=.72+.23*math.cos(a-.8)
  local c=(sector+math.floor(ring/4))%19==0 and 2 or 1
  quad(rock,surface(t,a),surface(t,b),surface(u,b),surface(u,a),c,shade)
 end end
 -- Inward crater walls descend to the molten lake, never cap its opening.
 for sector=0,63 do
  local a,b=sector/64*math.pi*2,(sector+1)/64*math.pi*2
  local function inner(angle)return {-700+math.cos(angle)*76,586,144+math.sin(angle)*53}end
  quad(rock,surface(1,a),surface(1,b),inner(b),inner(a),1,.82)
  quad(lava,{-700,588,144},inner(a),inner(b),{-700,588,144},5,1)
 end
 local function outlet(side)
  local a=.18+side*.026
  local p=surface(1,a);p[2]=p[2]+2
  return p,{-700+math.cos(a)*76,589,144+math.sin(a)*53}
 end
 local a,b=outlet(-1);local c,d=outlet(1);quad(lava,b,a,c,d,5,1)
 -- A breach in the eastern crater feeds a winding stream. A second narrow
 -- branch forks halfway down; neither draws a floating vertical waterfall.
 for branch=1,2 do
  local stop=branch==1 and 1 or .55
  for i=0,95 do
   local t=i/96*stop;local u=(i+1)/96*stop
   local function edge(at,side)
    local angle=.18+math.sin(at*6)*.07+(branch==2 and .24*(1-at/stop)or 0)
    local width=(branch==1 and .026 or .014)*(1+.25*math.sin(at*13))
    local p=surface(at,angle+width*side);p[2]=p[2]+2;return p
   end
   quad(lava,edge(t,-1),edge(u,-1),edge(u,1),edge(t,1),5,1)
  end
 end
 local out=ownedMeshes or {}
 local tex=palette()
 for i,g in ipairs(groups)do
  -- Preserve every quad and material order, but bound each indivisible GPU
  -- allocation. Publish ownership before yielding so cancelled skyline jobs
  -- release already uploaded volcano sections as well.
  for first=1,#g.vertices,6144 do
   local vertices,indices={},{}
   for at=first,math.min(first+6143,#g.vertices)do vertices[#vertices+1]=g.vertices[at]end
   local indexFirst=(first-1)/4*6+1
   for at=indexFirst,indexFirst+#vertices/4*6-1 do indices[#indices+1]=g.indices[at]-first+1 end
   local bounds={math.huge,math.huge,math.huge,-math.huge,-math.huge,-math.huge}
   for _,v in ipairs(vertices)do for axis=1,3 do
    bounds[axis]=math.min(bounds[axis],v[axis]);bounds[axis+3]=math.max(bounds[axis+3],v[axis])
   end end
   local mesh=V.require('SceneryMeshUpload').newMesh(vertices,indices,yieldStep)
   if not mesh then
    if not ownedMeshes then for _,part in ipairs(out)do part.mesh:release()end end
    error('volcano mesh',0)
   end
   out[#out+1]={mesh=mesh,texture=tex,ox=0,oy=0,kind='wall',class='voxel_horizon',
    magma=i==2,castsShadow=false,bounds=bounds}
   if yieldStep then yieldStep()end
  end
 end
 return out
end
function M.position(rootId,defs)
 local P=V.require('WorldPlacement')
 local a,b=P.position('CINNABAR_ISLAND',defs),P.position(rootId,defs)
 if a and b and a.anchor==b.anchor then return a.x-b.x,a.y-b.y end
end
function M.world(maps,defs,emit)
 if not M.active()or not defs or not maps[1]then return end
 local root=maps[1];local x,z=M.position(root.map.id,defs)
 if not x or x*x+z*z>6000*6000 then return end
 M.geometry(function(dx,y,dz,w,h,d,c,lit)
  emit(x+(root.ox or 0)+dx,y,z+(root.oy or 0)+dz,w,h,d,c,lit,false)
 end)
end
return M
