-- Optional bounded voxel snowdrifts. No map/collision edits; the existing
-- surface coat owns distant snow, roofs and the thaw after a snow front.
local V=...
local D={CELL=8,RADIUS=20,MAX_QUADS=41*41*5,last={draws=0,count=0}}
D.setting=V.require('ModSetting').new('snowDepth','SNOW DEPTH',{'normal','deep'},{'NORMAL','DEEP'},'normal')
local mesh,texture,signature,failed,count,geometry,uploadKey
local uploaded={}
local triangles={1,2,3,1,3,4}
local checks={{1,1},{7,1},{7,7},{1,7},{4,4}}
local exits={{0,0},{1,0},{-1,0},{0,1},{0,-1}}
-- Cover the visible foreground as well as the look-at point. Quantization
-- keeps stationary cameras/VR eyes on one retained patch; cap long vistas.
function D.anchor(focus,eye)
 local dx,dz=eye and (eye[1]-focus[1])*.5 or 0,eye and (eye[3]-focus[3])*.5 or 0
 local length=math.sqrt(dx*dx+dz*dz)
 if length>96 then dx,dz=dx*96/length,dz*96/length end
 return {math.floor((focus[1]+dx)/32)*32,focus[2]or 0,math.floor((focus[3]+dz)/32)*32}
end
-- The same quantized buildup drives the mesh and battle feet, even before
-- the first snow draw. Battle snow is a continuous, level four-voxel surface.
function D.amount(map,mode)
 if D.setting:get()~='deep' or not map then return 0 end
 local W=V.require('Weather');if not W.isOutdoor(map)then return 0 end
 mode=mode or W.modeAt(map,W.setting:get(),W.clock)
 local T=V.require('WeatherTweak')
 if T.groundMode(map,mode,true)~='snow'then return 0 end
 return math.max(0,math.min(1,(T.groundAmount(map,mode,true)-.18)/.82))
end
function D.battleLift(map,arena)
 if not arena or arena.discs or arena.portableStage then return 0 end
 local amount=D.amount(map)
 return amount>.001 and (.045+4*math.max(1,math.floor(amount*16+.5))/16)or 0
end
function D.buriesFlowers(map)
 return D.amount(map)>.35
end
function D.build(state,focus,resolve)
 local W=V.require('WorldWeather');local samplers={}
 local root=state.map;local maps={{map=root,ox=0,oy=0}}
 for _,nb in ipairs(state.neighbors or{})do maps[#maps+1]=nb end
 local function at(x,z)
  for _,nb in ipairs(maps)do
   local m=nb.map;local nx,nz=x-(nb.ox or 0),z-(nb.oy or 0)
   local cx,cz=math.floor(nx/16),math.floor(nz/16)
   if m and m.inBounds and m:inBounds(cx,cz)then
    -- Clear the approach cell too; deep snow must not hide a warp threshold.
    if m.isWarpTileCell then for _,v in ipairs(exits)do if m:isWarpTileCell(cx+v[1],cz+v[2])then return end end end
    local fn=resolve or samplers[m]
    if not fn then fn=W.sampler(m);samplers[m]=fn end
    local _,_,h,land=fn(m,nx,nz)
    if land then
     -- Keep the native jump lip plus takeoff/landing approach readable.
     -- This is visual only; native hops and the existing Kanto snow ramps own movement.
     for _,delta in ipairs{{-16,0},{16,0},{0,-16},{0,16}}do
      local _,_,_,_,ledge=fn(m,nx+delta[1],nz+delta[2]);if ledge then return end
     end
     return h
    end
    return
   end
  end
 end
 local gx,gz=math.floor(focus[1]/32)*4,math.floor(focus[3]/32)*4
 local cells={}
 for iz=-D.RADIUS,D.RADIUS do
  local row={};cells[iz]=row
  for ix=-D.RADIUS,D.RADIUS do
   local x,z=(gx+ix)*D.CELL,(gz+iz)*D.CELL
   local base;local valid=true
   for _,q in ipairs(checks)do
    local h=at(x+q[1],z+q[2])
    if not h or(base and math.abs(base-h)>.25)then valid=false;break end
    base=h
   end
   if valid then
    local field=math.sin(x*.047)+math.cos(z*.053)+math.sin((x+z)*.027)*.65
    local height=state.snowArena and 4 or 2+math.floor(math.max(0,math.min(2,(field+2.65)/1.78)))
    row[ix]={x=x,z=z,base=base,height=height}
   end
  end
 end
 local verts,quads={},0
 local function face(corners,shade)
  quads=quads+1
  for _,i in ipairs(triangles)do local q=corners[i];verts[#verts+1]={q[1],q[2],q[3],q[4],shade}end
 end
 for iz=-D.RADIUS,D.RADIUS do for ix=-D.RADIUS,D.RADIUS do
  local c=cells[iz][ix]
  if c then
   local x,z,y,h=c.x,c.z,c.base,c.height
   face({{x,y,z,h},{x+8,y,z,h},{x+8,y,z+8,h},{x,y,z+8,h}},3)
   local edges={
    {ix,iz-1,x,z,x+8,z,.73},{ix+1,iz,x+8,z,x+8,z+8,.83},
    {ix,iz+1,x+8,z+8,x,z+8,.88},{ix-1,iz,x,z+8,x,z,.77}}
   for _,e in ipairs(edges)do
    local neighbor=cells[e[2]]and cells[e[2]][e[1]]
    local lower=neighbor and math.abs(neighbor.base-y)<.25 and neighbor.height or 0
    -- Internal equal-height walls never enter the vertex stream.
    if lower<h then face({{e[3],y,e[4],lower},{e[5],y,e[6],lower},{e[5],y,e[6],h},{e[3],y,e[4],h}},e[7])end
   end
  end
 end end
 D.cells=cells;D.cellOrigin={gx,gz}
 return verts,quads
end
function D.draw(state,mode)
 D.last={draws=0,count=0}
 local amount=D.amount(state and state.map,mode)
 if amount<=.001 then return false end
 local G=V.require('Voxel3D');local g=love and love.graphics
 if failed or not(g and G.vp and G.focus)then return false end
 local pushed=false
 local ok,err=pcall(function()
  local C=V.require('WeatherCover');local f=D.anchor(G.focus,G.eye)
  local key=tostring(state.map)..':'..math.floor(f[1]/32)..':'..math.floor(f[3]/32)..':'..C.revision(state.map)
  local arena=state.snowArena
  if arena then key=key..':battle' end
  for _,nb in ipairs(state.neighbors or{})do key=key..':'..tostring(nb.map)..':'..(nb.ox or 0)..':'..(nb.oy or 0)..':'..C.revision(nb.map)end
  if key~=signature then
   local verts,n=D.build({map=state.map,neighbors=state.neighbors,snowArena=state.snowArena},f)
   geometry=verts;uploadKey=nil
   count=n;D.rebuilds=(D.rebuilds or 0)+1
   if n>0 then
    if not mesh then mesh=g.newMesh(G.FORMAT,D.MAX_QUADS*6,'triangles','dynamic')end
    mesh:setDrawRange(1,#verts)
   end
   signature=key
  end
  if not count or count==0 then return end
  -- Sixteen buildup steps reuse the retained geometry and ordinary world
  -- shader, including actual scene lighting, fog and actor/building shadows.
  local level=math.max(1,math.floor(amount*16+.5))
  if uploadKey~=level then
   local cx,cz=math.floor(f[1]/32)*32,math.floor(f[3]/32)*32
   for i,q in ipairs(geometry)do
    local distance=math.sqrt((q[1]-cx)^2+(q[3]-cz)^2)
    local fade=math.max(0,math.min(1,(152-distance)/24));fade=fade*fade*(3-2*fade)
    local v=uploaded[i]or{};uploaded[i]=v
    v[1],v[2],v[3],v[4],v[5],v[6]=q[1],q[2]+.045+q[4]*level/16*fade,q[3],.5,.5,q[5]
   end
   for i=#uploaded,#geometry+1,-1 do uploaded[i]=nil end
   mesh:setVertices(uploaded,1,#geometry);uploadKey=level;D.uploads=(D.uploads or 0)+1
  end
  if not texture then
   local pixels=love.image.newImageData(1,1);pixels:setPixel(0,0,.89,.945,.99,1)
   texture=g.newImage(pixels);pixels:release();texture:setFilter('nearest','nearest')
  end
  g.push('all');pushed=true;g.setDepthMode('lequal',true);g.setMeshCullMode('none');g.setColor(1,1,1,1)
  G.weatherGround(true);G.weatherGrass(false);G.glass(false);G.seams(false)
  if G.seasonFoliage then G.seasonFoliage(false)end
  G.draw(mesh,texture);g.pop();pushed=false
  D.last={draws=1,count=count,amount=amount,centre=f}
  local origin=D.cellOrigin
  V.require('SnowTracks').draw(state,function(x,z)
   if not(origin and D.cells)then return end
   local ix,iz=math.floor(x/8)-origin[1],math.floor(z/8)-origin[2]
   local c=D.cells[iz]and D.cells[iz][ix];if not c then return end
   local distance=math.sqrt((x-f[1])^2+(z-f[3])^2)
   local fade=math.max(0,math.min(1,(152-distance)/24));fade=fade*fade*(3-2*fade)
   if fade<.1 then return end
   return c.base+.045+c.height*level/16*fade
  end,uploadKey..':'..key)
 end)
 if pushed then g.pop()end
 if not ok then failed=tostring(err);D.error=failed;print('[VASC snow] surface-coat fallback: '..failed)end
 return ok
end
function D.invalidate()
 for _,v in ipairs{mesh or false,texture or false}do if v and v.release then v:release()end end
 mesh,texture,signature,failed,count,geometry,uploadKey=nil,nil,nil,nil,nil,nil,nil;uploaded={};D.error=nil
end
return D
