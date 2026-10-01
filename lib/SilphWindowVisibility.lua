-- Conservative portal culling for closed Silph offices. It only selects
-- exterior draw batches; native room masks, actors and collisions are untouched.
local V=...
local M={};local cache
local function dot(a,b)return a[1]*b[1]+a[2]*b[2]+a[3]*b[3]end
local function plane(eye,a,b,centre)
 local u={a[1]-eye[1],a[2]-eye[2],a[3]-eye[3]}
 local v={b[1]-eye[1],b[2]-eye[2],b[3]-eye[3]}
 local n={u[2]*v[3]-u[3]*v[2],u[3]*v[1]-u[1]*v[3],u[1]*v[2]-u[2]*v[1]}
 local length=math.sqrt(dot(n,n));if length<1e-8 then return end
 for i=1,3 do n[i]=n[i]/length end
 n[4]=-dot(n,eye)
 if dot(n,centre)+n[4]<0 then for i=1,4 do n[i]=-n[i]end end
 return n
end
local function clear(eye,target,panels,H)
 for _,p in ipairs(panels)do
  local axis,along=p.axis,p.along
  local delta=target[axis]-eye[axis]
  if math.abs(delta)>1e-8 then
   local t=(p.at-eye[axis])/delta
   if t>.001 and t<.999 then
    local at=eye[along]+(target[along]-eye[along])*t
    local y=eye[2]+(target[2]-eye[2])*t
    if at>p.from-.05 and at<p.upto+.05 and y>0 and y<H then
     local opening=false
     for _,o in ipairs(p.openings or{})do
      if o.open and at>o.from+.05 and at<o.upto-.05 and y>(o.bottom or 0)and y<(o.height or 24)then opening=true;break end
     end
     if not opening then return false end
    end
   end
  end
 end
 return true
end
function M.prepare(map,profile,panels)
 local windows,opaque={},{};local W=V.require('SilphWindows')
 for _,p in ipairs(panels)do
  if W.perimeter(map,p)then
   local panes=W.panelApertures and W.panelApertures(map,p,profile.shellHeight)or{p}
   local wall={edge=p.edge,at=p.at,from=p.from,upto=p.upto,openings={}}
   for _,o in ipairs(p.openings or{})do wall.openings[#wall.openings+1]=o end
   for _,a in ipairs(panes)do
    local pane={edge=p.edge,at=p.at,from=math.max(p.from,a.from),upto=math.min(p.upto,a.upto),
     bottom=a.bottom or 10,top=a.top or profile.shellHeight-5,openings=p.openings}
    windows[#windows+1]=pane
    wall.openings[#wall.openings+1]={open=true,from=pane.from,upto=pane.upto,bottom=pane.bottom,height=pane.top}
   end
   opaque[#opaque+1]=wall
  else opaque[#opaque+1]=p end
 end
 for i,source in ipairs(opaque)do
  local p={};for k,v in pairs(source)do p[k]=v end;opaque[i]=p
  -- Compile immutable scalar descriptors, without editing the shared layout.
  local horizontal=p.edge=='north'or p.edge=='south'
  p.axis=horizontal and 3 or 1;p.along=horizontal and 1 or 3
 end
 for _,a in ipairs(V.require('GlassDoorWindows').apertures(map))do
  windows[#windows+1]=a
  for _,p in ipairs(opaque)do if p.edge==a.edge and p.at==a.at then
   local openings={};for _,o in ipairs(p.openings or{})do openings[#openings+1]=o end
   openings[#openings+1]={open=true,from=a.from,upto=a.upto,bottom=0,height=a.top}
   p.openings=openings
  end end
 end
 return {windows=windows,opaque=opaque}
end
function M.apertures(map,profile,eye,panels,prepared)
 prepared=prepared or M.prepare(map,profile,panels)
 local windows,opaque=prepared.windows,prepared.opaque
 local out={}
 for _,p in ipairs(windows)do
  local axis=(p.edge=='north'or p.edge=='south')and 3 or 1
  local side=(p.edge=='north'or p.edge=='west')and -1 or 1
  -- Orbit cutaways expose only walls seen from their room side. A camera
  -- outside the near wall must not use it to reveal the whole city.
  if (eye[axis]-p.at)*side<=0 then
  local horizontal=p.edge=='north'or p.edge=='south'
  -- A ray from the eye to this pane stays inside their bounding box.
  -- Reject unrelated partitions once per pane, before sampling its openings.
  local candidates={}
  local loX,hiX=math.min(eye[1],horizontal and p.from or p.at),math.max(eye[1],horizontal and p.upto or p.at)
  local loZ,hiZ=math.min(eye[3],horizontal and p.at or p.from),math.max(eye[3],horizontal and p.at or p.upto)
  for _,wall in ipairs(opaque)do
   local lo,hi,a,b
   if wall.axis==3 then lo,hi,a,b=loZ,hiZ,loX,hiX else lo,hi,a,b=loX,hiX,loZ,hiZ end
   if wall.at>=lo and wall.at<=hi and wall.upto+.05>=a and wall.from-.05<=b then
    candidates[#candidates+1]=wall
   end
  end
  local run
  local function finish(to)
   if not run then return end
   out[#out+1]={edge=p.edge,at=p.at,from=run,upto=to,bottom=p.bottom,top=p.top};run=nil
  end
  for a=p.from,p.upto-1,8 do
   local b=math.min(a+8,p.upto);local seen=false;local doorway=false
   for _,o in ipairs(p.openings or{})do if (a+b)/2>=o.from and (a+b)/2<o.upto then doorway=true end end
   if not doorway or p.door then
    for _,along in ipairs{a+.1,(a+b)/2,b-.1}do
     for _,height in ipairs{(p.bottom or 10)+.1,((p.bottom or 10)+(p.top or profile.shellHeight-5))/2,(p.top or profile.shellHeight-5)-.1}do
      local target=horizontal and {along,height,p.at}or{p.at,height,along}
      if clear(eye,target,candidates,profile.shellHeight)then seen=true;break end
     end
     if seen then break end
    end
   end
   if seen then run=run or a else finish(a)end
  end
  finish(p.upto)
  end
 end
 return out
end
function M.cones(eye,apertures,H)
 local out={}
 for _,p in ipairs(apertures)do
  local horizontal=p.edge=='north'or p.edge=='south'
  local function v(a,y)return horizontal and {a,y,p.at}or{p.at,y,a}end
  local bottom,top=(p.bottom or 10)-.6,(p.top or H-5)+.6
  local corners={v(p.from-.6,bottom),v(p.upto+.6,bottom),v(p.upto+.6,top),v(p.from-.6,top)}
  local centre=v((p.from+p.upto)/2,(bottom+top)/2);local planes={}
  for i=1,4 do local n=plane(eye,corners[i],corners[i%4+1],centre);if n then planes[#planes+1]=n end end
  local sign=(p.edge=='north'or p.edge=='west')and -1 or 1
  planes[#planes+1]=horizontal and {0,0,sign,-p.at*sign}or{sign,0,0,-p.at*sign}
  out[#out+1]=planes
 end
 return out
end
function M.accepts(cones,b,ox,oz,oy)
 if not b then return true end
 ox,oz,oy=ox or 0,oz or 0,oy or 0
 for _,planes in ipairs(cones)do
  local inside=true
  for _,p in ipairs(planes)do
   local x=(p[1]>=0 and b[4]or b[1])+ox
   local y=(p[2]>=0 and b[5]or b[2])+oy
   local z=(p[3]>=0 and b[6]or b[3])+oz
   if p[1]*x+p[2]*y+p[3]*z+p[4]<-.6 then inside=false;break end
  end
  if inside then return true end
 end
 return false
end
function M.forView(map,profile,eye)
 -- Every camera uses the same window apertures, including orbit views above
 -- the ceiling. Batch rejection saves work; the pixel mask clips partial batches.
 if not (V.require('SilphWindows').enabled(map)and profile and eye)then M.last=nil;return end
 local signature=table.concat(map.def.blocks or{},',')
 if not cache or cache.map~=map or cache.signature~=signature or cache.height~=profile.shellHeight then
  cache={map=map,signature=signature,profile=profile,height=profile.shellHeight,panels=V.require('Gen1InteriorLayout').panelsFor(map,profile)}
  cache.prepared=M.prepare(map,profile,cache.panels)
 end
 if cache.x~=eye[1]or cache.y~=eye[2]or cache.z~=eye[3]then
  cache.x,cache.y,cache.z=eye[1],eye[2],eye[3]
  -- Broad-phase batches only: the actual room depth buffer and aperture
  -- shader already hide partitions, door jambs and covered window pixels.
  -- Recasting nine CPU rays per eight-pixel strip against every partition
  -- was more expensive than drawing the handful of cached exterior batches.
  -- Keep this conservative, so narrow views can never disappear between samples.
  cache.apertures={}
  for _,p in ipairs(cache.prepared.windows)do
   local axis=(p.edge=='north'or p.edge=='south')and 3 or 1
   local side=(p.edge=='north'or p.edge=='west')and -1 or 1
   if (eye[axis]-p.at)*side<=0 then cache.apertures[#cache.apertures+1]=p end
  end
  cache.cones=M.cones(eye,cache.apertures,profile.shellHeight)
 end
 local cones=cache.cones
 local onPane=false
 for _,p in ipairs(cache.prepared.windows)do
  local axis=(p.edge=='north'or p.edge=='south')and 3 or 1
  if math.abs(eye[axis]-p.at)<.001 then onPane=true;break end
 end
 M.last={portals=#cones,accepted=0,rejected=0}
 local stats=M.last
 local shift=V.require('SilphElevator').offset(map)
 return function(bounds,ox,oz)
  local accepted=onPane or M.accepts(cones,bounds,ox,oz,shift)
  local k=accepted and 'accepted'or 'rejected';stats[k]=stats[k]+1
  return accepted
 end
end
-- Exact per-fragment window boundary, shared by desktop and mobile shaders.
-- No stencil canvas or extra scene copy. All coordinates remain world units.
M.GLSL=[[
uniform highp vec4 glassDoorRects[4];
uniform highp vec4 glassDoorEdges;
uniform highp vec2 houseWindow; // mask enabled, north wall position
uniform Image houseWindowMask;
uniform highp float silphRearOnly;
uniform highp vec4 silphBounds; // west, north, east, south at native inner faces
uniform highp vec4 silphWindow; // width, depth, sill, head; width=0 disables
bool silphCross(highp float ea, highp float pa, highp float eo,
 highp float po, highp float py, highp float at, highp float lo, highp float span, highp float side, highp float row) {
 highp float delta=pa-ea;
 if ((ea-at)*side>0.001 || (pa-at)*side<0.0 || abs(delta)<0.0001) return false;
 highp float t=(at-ea)/delta;
 if(t<0.0 || t>1.0) return false;
 highp float y=mix(eye.y,py,t);
 highp float a=mix(eo,po,t);
 return y>=silphWindow.z && y<=silphWindow.w && a>=lo && a<=span
  && (houseWindow.x<0.5 || Texel(houseWindowMask,vec2((floor(a)+0.5)/1024.0,(row+0.5)/4.0)).r>0.5);
}
bool glassDoorCross(highp vec3 p, highp vec4 r, highp float edge) {
 if(edge<0.5)return false;
 bool horizontal=edge<2.5;
 highp float ea=horizontal?eye.z:eye.x, pa=horizontal?p.z:p.x;
 highp float eo=horizontal?eye.x:eye.z, po=horizontal?p.x:p.z;
 highp float side=(edge<1.5 || (edge>2.5 && edge<3.5))?-1.0:1.0;
 highp float delta=pa-ea;
 if((ea-r.z)*side>0.001 || (pa-r.z)*side<0.0 || abs(delta)<0.0001)return false;
 highp float t=(r.z-ea)/delta;
 highp float y=mix(eye.y,p.y,t), a=mix(eo,po,t);
 return t>=0.0 && t<=1.0 && y>=0.0 && y<=r.w && a>=r.x && a<=r.y;
}
bool silphThroughWindow(highp vec3 p) {
 if(glassDoorCross(p,glassDoorRects[0],glassDoorEdges.x)
  ||glassDoorCross(p,glassDoorRects[1],glassDoorEdges.y)
  ||glassDoorCross(p,glassDoorRects[2],glassDoorEdges.z)
  ||glassDoorCross(p,glassDoorRects[3],glassDoorEdges.w))return true;
 return silphCross(eye.z,p.z,eye.x,p.x,p.y,silphBounds.y,silphBounds.x,silphBounds.z,-1.0,0.0)
  || (silphRearOnly<0.5 && (silphCross(eye.z,p.z,eye.x,p.x,p.y,silphBounds.w,silphBounds.x,silphBounds.z,1.0,1.0)
  || silphCross(eye.x,p.x,eye.z,p.z,p.y,silphBounds.x,silphBounds.y,silphBounds.w,-1.0,2.0)
  || silphCross(eye.x,p.x,eye.z,p.z,p.y,silphBounds.z,silphBounds.y,silphBounds.w,1.0,3.0)));
}
]]
-- CPU equivalent for boundary tests and diagnostics.
function M.through(eye,p,w,d,H,rearOnly,b)
 b=b or {west=0,north=0,east=w,south=d}
 for index,wall in ipairs{{3,1,b.north,b.east,-1,b.west},{3,1,b.south,b.east,1,b.west},{1,3,b.west,b.south,-1,b.north},{1,3,b.east,b.south,1,b.north}}do
  if rearOnly and index>1 then break end
  local axis,along,at,span,side=unpack(wall);local delta=p[axis]-eye[axis]
  if (eye[axis]-at)*side<=.001 and (p[axis]-at)*side>=0 and math.abs(delta)>=.0001 then
   local t=(at-eye[axis])/delta
   local y,a=eye[2]+(p[2]-eye[2])*t,eye[along]+(p[along]-eye[along])*t
   if t>=0 and t<=1 and y>=10 and y<=H-5 and a>=wall[6] and a<=span then return true end
  end
 end
 return false
end
return M
