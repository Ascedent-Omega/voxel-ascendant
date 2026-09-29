-- VASC voxel precipitation: one retained depth-tested batch, shared by Gen1/2.
-- Design reference: Kanto Dynamic Weather's world-space rain, independently
-- implemented for VASC's scene lifecycle, bounded cache and voxel palette.
local V=...
local M={MAX_QUADS=605,CELL=32,RADIUS=5,last={draws=0,count=0}}
local mesh,shader,cacheKey,failed
local tick,sourceClock=0,nil
local function hash(x,z,s)
 local n=(x*104729+z*13007+s*7919)%2147483647
 n=(n*48271)%2147483647;n=(n*48271)%2147483647
 return n/2147483647
end
M.hash=hash
function M.advance(now,storm)
 if sourceClock~=nil then
  local dt=now-sourceClock
  if dt>0 and dt<2 then tick=tick+dt*(storm and 1.35 or 1)end
 end
 sourceClock=now;return tick
end
local corners={{-1,0},{1,0},{1,1},{-1,0},{1,1},{-1,1}}
-- Resolve the actual drawn cell, never Gen2's collision-class-as-tile shortcut.
local function ground(map,cx,cz,shapes)
 if not(map.inBounds and map:inBounds(cx,cz))then return 0,false,false end
 local T=V.require('TileShape');local tx,tz=cx*2,cz*2+1
 local s=T.at(map,shapes or T.forMap(map),map:tileAt(tx,tz),tx,tz)
 if not s then return 0,false,false end
 local walk=map.isWalkableCell and map:isWalkableCell(cx,cz)
 local water=s.art=='water' or s.kind=='water' or (s.h or 0)<0
 local h=math.max(0,s.h or 0)
 if map.def.generation==2 then h=V.require('VoxelScene').groundAt(map,cx,cz)
 else local e=V.require('LedgeElevation').map(map);if e then h=math.max(h,e:at(cx,cz)or 0)end end
 return h,(walk or water) and(s.art=='flat' or water)and h<128,walk and not water and (s.flat==true or s.art=='flat'),s.class=='ledge'
end
local function covered(map,x,z,h,splash,land,ledge)
 local cap=V.require('WeatherCover').height(map,x,z)
 local shelter=cap and cap>h+2
 return math.max(h,cap or h)+.18,not shelter and splash,h,not shelter and land,ledge
end
function M.surface(map,x,z)
 return covered(map,x,z,ground(map,math.floor(x/16),math.floor(z/16)))
end
-- A build-local cache: exact 4px roof queries remain live, but a native tile,
-- collision and elevation are resolved only once per 16px ground cell.
function M.sampler(map,stats)
 local cells={};local shapes=V.require('TileShape').forMap(map)
 return function(_,x,z)
  local cx,cz=math.floor(x/16),math.floor(z/16);local k=cx..':'..cz
  local cell=cells[k]
  if not cell then
   cell={ground(map,cx,cz,shapes)};cells[k]=cell
   if stats then stats.groundCells=(stats.groundCells or 0)+1 end
  end
  if stats then stats.samples=(stats.samples or 0)+1 end
  return covered(map,x,z,cell[1],cell[2],cell[3],cell[4])
 end
end
function M.build(map,focus,storm,neighbors,resolve,profile)
 local snow=storm=="snow"
 storm=storm==true or storm=="storm"
 local samplers,stats={}, {groundCells=0,samples=0}
 if not resolve then resolve=function(m,x,z)
  local fn=samplers[m];if not fn then fn=M.sampler(m,stats);samplers[m]=fn end
  return fn(m,x,z)
 end end
 local verts,n={},0
 local function add(x,y,z,phase,width,length,kind)
  if n>=M.MAX_QUADS then return end
  n=n+1
  for _,c in ipairs(corners)do
   verts[#verts+1]={x,y,z,c[1],c[2],phase,width,length,kind}
  end
 end
 local gx,gz=math.floor(focus[1]/M.CELL),math.floor(focus[3]/M.CELL)
 local function at(x,z)
  local cx,cz=math.floor(x/16),math.floor(z/16)
  if map.inBounds and map:inBounds(cx,cz)then return resolve(map,x,z)end
  for _,nb in ipairs(neighbors or {})do
   local nx,nz=x-(nb.ox or 0),z-(nb.oy or 0)
   if nb.map and nb.map.inBounds and nb.map:inBounds(math.floor(nx/16),math.floor(nz/16))then
    return resolve(nb.map,nx,nz)
   end
  end
  return focus[2]or 0,false
 end
 for dz=-M.RADIUS,M.RADIUS do for dx=-M.RADIUS,M.RADIUS do
  local ix,iz=gx+dx,gz+dz
  for k=1,(snow and 4 or profile and profile.drops or storm and 4 or 3)do
   local x=(ix+.10+hash(ix,iz,k)*.8)*M.CELL
   local z=(iz+.10+hash(ix,iz,k+7)*.8)*M.CELL
   local y,ground=at(x,z)
   -- Sample the slanted trajectory too, so a drop cannot enter beneath a
   -- neighbouring eave while wind carries it toward its terminal column.
   local wind=snow and 6 or storm and 21 or 10
   for _,t in ipairs{.25,.5,.75,1}do
    local roof=at(x-wind*t,z+wind*.52*t)
    if roof>y then y=roof;ground=false end
   end
   local phase=hash(ix,iz,k+19)
   add(x,y,z,phase,snow and(.48+hash(ix,iz,k+29)*.55)or(.22+hash(ix,iz,k+29)*.22),5+hash(ix,iz,k+37)*6,snow and 2 or 0)
   if not snow and k==1 and ground then add(x,y,z,phase,3.6,0,1)end
  end
 end end
 M.buildStats=stats
 return verts,n
end
M.GLSL=[[
varying vec2 dropUV;
varying float dropAlpha;
varying float dropKind;
varying float dropCycle;
#ifdef VERTEX
uniform mat4 vp;
uniform vec3 curve;
uniform vec3 axisR;
uniform vec3 axisU;
uniform vec3 weatherFocus;
uniform vec3 weatherEye;
uniform float weatherClock;
uniform float wind;
attribute vec4 DropData;
vec4 position(mat4 transform_projection,vec4 vertex_position){
 float rate=DropData.w>1.5 ? .10+.035*DropData.x : .92;
 float cycle=fract(weatherClock*rate+DropData.x);
 vec3 p=vertex_position.xyz;
 dropUV=VertexTexCoord.xy;dropKind=DropData.w;dropCycle=cycle;
 float distanceFromFocus=length(p.xz-weatherFocus.xz);
 dropAlpha=1.0-smoothstep(112.0,160.0,distanceFromFocus);
 if(DropData.w>1.5){
  float fall=1.0-cycle;
  p+=vec3(-wind*fall+sin(weatherClock*.7+DropData.x*28.0)*2.0*fall,fall*90.0,wind*.52*fall);
  float depth=abs((vp*vec4(p,1.0)).w);
  float size=min(DropData.y,depth*.0028);
  p+=axisR*dropUV.x*size+axisU*(dropUV.y*2.0-1.0)*size;
  dropAlpha*=smoothstep(5.0,16.0,distance(p,weatherEye));
  dropAlpha*=smoothstep(0.0,.07,cycle)*(1.0-smoothstep(.96,1.0,cycle));
 }else if(DropData.w<.5){
  float height=(1.0-cycle)*90.0;
  vec3 trail=normalize(vec3(-wind,90.0,wind*.52));
  // The trajectory ends on the same sampled surface as its splash.
  p+=vec3(-wind*(1.0-cycle),height,wind*.52*(1.0-cycle));
  float depth=abs((vp*vec4(p,1.0)).w);
  // Bound projected size before a drop reaches the eye: no giant foreground
  // strips, including portrait/first person cameras.
  float width=min(DropData.y,depth*.0016);
  float length=min(DropData.z,depth*.045);
  dropAlpha*=smoothstep(7.0,22.0,distance(p,weatherEye));
  p+=axisR*(dropUV.x*width)+trail*(dropUV.y*length);
  dropAlpha*=smoothstep(.0,.05,cycle)*(1.0-smoothstep(.97,1.0,cycle));
 }else{
  p.x+=dropUV.x*DropData.y;p.z+=(dropUV.y*2.0-1.0)*DropData.y;
 }
 vec2 delta=p.xz-curve.xy;p.y-=dot(delta,delta)*curve.z;
 return vp*vec4(p,1.0);
}
#endif
#ifdef PIXEL
uniform vec3 weatherColor;
uniform float rainIntensity;
vec4 effect(vec4 color,Image tex,vec2 uv,vec2 sc){
 float alpha;
 if(dropKind>1.5){
  vec2 q=abs(vec2(dropUV.x,dropUV.y*2.0-1.0));
  // Small pixel crosses and square flakes; never circular bokeh sprites.
  if(dropCycle>.45 && q.x>.34 && q.y>.34)discard;
  alpha=.72*dropAlpha;
 }else if(dropKind<.5){
  // Three readable intensity steps retain the voxel character of the world.
  float tip=1.0-floor(clamp(dropUV.y,0.0,.999)*3.0)/3.0;
  alpha=(.16+.25*tip)*dropAlpha;
 }else{
  float age=dropCycle/.19;
  if(age>=1.0)discard;
  vec2 q=floor(vec2(dropUV.x,dropUV.y*2.0-1.0)*5.0+.5)/5.0;
  float d=max(max(abs(q.x),abs(q.y)),(abs(q.x)+abs(q.y))*.70);
  float radius=.14+age*.72;
  alpha=(1.0-smoothstep(.06,.19,abs(d-radius)))*(1.0-age)*.42*dropAlpha;
 }
 if(dropKind<1.5)alpha*=rainIntensity;
 if(alpha<.01)discard;
 return vec4(weatherColor,alpha)*color;
}
#endif
]]
function M.draw(state,mode)
 M.last={draws=0,count=0}
 if mode~='rain' and mode~='storm' and mode~='snow'then return false end
 local map=state and state.map
 if not map or not V.require('Weather').isOutdoor(map)then return false end
 local G=V.require('Voxel3D');local g=love and love.graphics
 if failed or not(G.vp and G.focus and g and g.newMesh and g.newShader)then return false end
 local pushed=false
 local ok,err=pcall(function()
  if not shader then shader=g.newShader(M.GLSL)end
  local f=G.focus;local storm=mode=='storm'
  local profile=V.require('RainStrength').profile(mode)
  local Cover=V.require('WeatherCover')
  local key=tostring(map)..':'..math.floor(f[1]/M.CELL)..':'..math.floor(f[3]/M.CELL)..':'..mode..':'..(mode=='snow' and 'snow' or profile.key)..':'..Cover.revision(map)
  -- Neighbour identities participate so an asynchronously arriving map cannot
  -- leave particles spraying at stale ground heights along a connection.
  for _,nb in ipairs(state.neighbors or {})do key=key..':'..tostring(nb.map)..':'..tostring(nb.ox)..':'..tostring(nb.oy)..':'..Cover.revision(nb.map)end
  if cacheKey~=key then
   local verts,n=M.build(map,f,mode,state.neighbors,nil,profile)
   if not mesh then mesh=g.newMesh({{'VertexPosition','float',3},
    {'VertexTexCoord','float',2},{'DropData','float',4}},M.MAX_QUADS*6,'triangles','dynamic')end
   mesh:setVertices(verts,1,#verts);mesh:setDrawRange(1,#verts)
   cacheKey=key;M.count=n;M.rebuilds=(M.rebuilds or 0)+1
  end
  local vp=G.vp;local len=math.sqrt(vp[1]^2+vp[2]^2+vp[3]^2)
  if len<1e-8 then error('invalid weather camera')end
  shader:send('vp','row',vp);shader:send('curve',{G.curveX or 0,G.curveZ or 0,G.curveK or 0})
  shader:send('axisR',{vp[1]/len,vp[2]/len,vp[3]/len});
  local ul=math.sqrt(vp[5]^2+vp[6]^2+vp[7]^2)
  shader:send('axisU',{vp[5]/ul,vp[6]/ul,vp[7]/ul});shader:send('weatherFocus',f)
  shader:send('weatherEye',G.eye or f)
  shader:send('rainIntensity',profile.alpha)
  shader:send('weatherClock',M.advance(V.require('Weather').clock,storm));shader:send('wind',mode=='snow' and 6 or storm and 21 or 10)
  local tint=G.tint or {1,1,1}
  shader:send('weatherColor',{.64+.14*tint[1],.69+.14*tint[2],.75+.14*tint[3]})
  g.push('all');pushed=true;g.setShader(shader);g.setDepthMode('lequal',false)
  g.setMeshCullMode('none');g.setBlendMode('alpha','alphamultiply');g.setColor(1,1,1,1);g.draw(mesh)
  M.last={draws=1,count=M.count,mode=mode}
 end)
 if pushed then g.pop()end
 if not ok then failed=tostring(err);M.error=failed;print('[VASC weather] 2D fallback: '..failed)end
 return ok
end
function M.invalidate()
 for _,v in ipairs{mesh or false,shader or false}do if v and v.release then pcall(v.release,v)end end
 mesh,shader,cacheKey,failed=nil,nil,nil,nil;M.error=nil;sourceClock=nil
end
return M
