-- Air, not a dark floor decal: integrate drifting density between the camera
-- and the actual scene depth. One half-resolution pass, twelve bounded samples.
local V=...
local M={}
local shader,noise,buffer,bw,bh
local litShader
local slices,sliceShader,sliceMap,sliceBase,sliceHeight
local tower={color={.48,.46,.54},density=.018,height=42}
local cave={color={.43,.47,.50},density=.015,height=38}
local town={color={.43,.44,.49},density=.009,height=48}
local forest={color={.43,.49,.44},density=.009,height=44}
local outdoorTint={}
local function isForest(map)
 local d=map and map.def
 return d and d.generation~=2 and (map.id or d.id)=='VIRIDIAN_FOREST'
end
function M.tint(map,normal,x,z)
 local forestMap=isForest(map)
 local region=V.require('LavenderFog').region(map)
 local weight=V.require('LavenderFog').weight(region,x,z)
 if not forestMap and weight==0 then return normal end
 outdoorTint[1]=normal[1]*(forestMap and .72 or 1-.32*weight)
 outdoorTint[2]=normal[2]*(forestMap and .80 or 1-.30*weight)
 outdoorTint[3]=normal[3]*(forestMap and .73 or 1-.20*weight)
 return outdoorTint
end
function M.base(map)
 if not isForest(map)and not V.require("Weather").isLavender(map)then return 0 end
 return V.require("LedgeElevation").basisAtCell(map,map.def.width,map.def.height)
end
function M.profile(map,dark)
 local d=map and map.def
 if not d or dark then return nil end
 if map.id=='KA_HOENN_BIRTH_ISLAND'and V.require('KascBirthIsland').matches(map)then return V.require('KascBirthIsland').mist(map)end
 if map.id=='KA_HEVO_RAYQUAZA_CHAMBER'then return V.require('KascSkySanctum').mist(map)end
 if d.runtimeAuthority=='KASC_6_7_STARTER_HABITAT_V2_3'then return V.require('KascHabitatScenery').mist(map)end
 if (map.id or ''):match('^KA_BLAINE_')then local mist=V.require('BlaineVolcano').mist(map);if mist then return mist end end
 if (map.id or ''):match('^KA_MOLTRES_VOLCANO')then local mist=V.require('KascVolcano').mist(map);if mist then return mist end end
 local legend=V.require('KascLegendAtmosphere').profile(map)
 if legend then return legend end
 if d.generation==2 then return nil end
 local region,offset=V.require('LavenderFog').region(map)
 if region then return {color=town.color,density=town.density,height=town.height,region=region,offset=offset}end
 if isForest(map)then return forest end
 if V.require('TowerAtmosphere').active(map)then
  return tower
 elseif d.tileset=='CAVERN'then
  return cave
 end
 local L=V.require('LocalLights')
 local indoor=L.active() and L.current().map==map and L.current().interior
 if indoor then return {color={.37,.39,.43},density=.0015,height=indoor.profile.shellHeight} end
end
-- Pivoted inverse handles both perspective and orthographic camera modes.
function M.inverse(m)
 local a={}
 for r=1,4 do a[r]={};for c=1,8 do a[r][c]=c<=4 and m[(r-1)*4+c]or(c-4==r and 1 or 0)end end
 for c=1,4 do
  local p=c;for r=c+1,4 do if math.abs(a[r][c])>math.abs(a[p][c])then p=r end end
  if math.abs(a[p][c])<1e-12 then return nil end
  a[c],a[p]=a[p],a[c];local scale=a[c][c]
  for j=1,8 do a[c][j]=a[c][j]/scale end
  for r=1,4 do if r~=c then local k=a[r][c];for j=1,8 do a[r][j]=a[r][j]-k*a[c][j]end end end
 end
 local out={};for r=1,4 do for c=5,8 do out[#out+1]=a[r][c]end end;return out
end
M.GLSL=[[
uniform Image sceneDepth;
uniform Image mistNoise;
uniform mat4 inverseVP;
uniform vec2 mistResolution;
uniform vec3 mistCurve; // focus x/z and the same ground curvature as Voxel3D
uniform vec3 mistMin;
uniform vec3 mistMax;
uniform vec3 mistColor;
uniform float mistDensity;
uniform float mistTime;
uniform vec2 mistWorldOffset;
uniform float mistEdge;
vec3 unproject(vec2 uv,float depth) {
 vec4 p=inverseVP*vec4(uv*2.0-1.0,depth*2.0-1.0,1.0);
 return p.xyz/p.w;
}
// Camera rays are straight in rendered space; logical terrain height along
// them is quadratic. Clip to that curved air shell before spending any of
// the twelve samples. A ray can cross two disjoint portions of the shell.
vec2 mistRoots(float a,float b,float c,float discriminant) {
 float root=sqrt(max(0.0,discriminant));
 float q=-0.5*(b+(b>=0.0?root:-root));
 if(abs(q)<0.0000001)return vec2(-b/(2.0*a));
 vec2 r=vec2(q/a,c/q);return vec2(min(r.x,r.y),max(r.x,r.y));
}
vec4 mistIntervals(vec3 start,vec3 ray,float lengthRay) {
 if((abs(ray.x)<0.00001 && (start.x<mistMin.x||start.x>mistMax.x))
 ||(abs(ray.z)<0.00001 && (start.z<mistMin.z||start.z>mistMax.z)))return vec4(0.0);
 vec2 safe=mix(vec2(0.00001),ray.xz,step(vec2(0.00001),abs(ray.xz)));
 vec2 a=(mistMin.xz-start.xz)/safe,b=(mistMax.xz-start.xz)/safe;
 vec2 lo=min(a,b),hi=max(a,b);
 float enter=max(0.0,max(lo.x,lo.y));
 float leave=min(lengthRay,min(hi.x,hi.y));
 if(leave<=enter)return vec4(0.0);
 vec3 p=start+ray*enter;vec2 d=p.xz-mistCurve.xy;
 float qa=mistCurve.z*dot(ray.xz,ray.xz);
 float qb=ray.y+2.0*mistCurve.z*dot(d,ray.xz);
 float qc=p.y+mistCurve.z*dot(d,d);
 float first=0.0,last=leave-enter;
 if(qa<0.0000000001) {
  if(abs(qb)<0.00001) {
   if(qc<mistMin.y||qc>mistMax.y)return vec4(0.0);
  } else {
   float u=(mistMin.y-qc)/qb,v=(mistMax.y-qc)/qb;
   first=max(first,min(u,v));last=min(last,max(u,v));
  }
  if(last<=first)return vec4(0.0);
  return vec4(enter+first,enter+last,0.0,0.0);
 }
 float disc=qb*qb-4.0*qa*(qc-mistMax.y);
 if(disc<=0.0)return vec4(0.0);
 vec2 roof=mistRoots(qa,qb,qc-mistMax.y,disc);
 first=max(first,roof.x);last=min(last,roof.y);
 if(last<=first)return vec4(0.0);
 disc=qb*qb-4.0*qa*(qc-mistMin.y);
 if(disc<=0.0)return vec4(enter+first,enter+last,0.0,0.0);
 vec2 floorRoots=mistRoots(qa,qb,qc-mistMin.y,disc);
 float endFirst=clamp(floorRoots.x,first,last);
 float startSecond=clamp(floorRoots.y,first,last);
 return vec4(enter+first,enter+endFirst,enter+startSecond,enter+last);
}
vec4 effect(vec4 color,Image tex,vec2 tc,vec2 sc) {
 vec2 uv=sc/mistResolution;
 vec3 start=unproject(uv,0.0);
 vec3 stop=unproject(uv,min(Texel(sceneDepth,uv).r,0.99999));
 vec3 delta=stop-start;
 float lengthRay=length(delta);
 vec3 ray=delta/max(lengthRay,0.0001);
 vec4 intervals=mistIntervals(start,ray,lengthRay);
 float firstLength=intervals.y-intervals.x;
 float stepSize=(firstLength+intervals.w-intervals.z)/12.0;
 float optical=0.0;
 for(int i=0;i<12;i++) {
  float travel=(float(i)+0.5)*stepSize;
  float along=travel<firstLength?intervals.x+travel:intervals.z+travel-firstLength;
  vec3 p=start+ray*along;
  vec2 bend=p.xz-mistCurve.xy;p.y+=dot(bend,bend)*mistCurve.z;
  vec2 drift=vec2(mistTime*0.55,mistTime*0.23);
  float broad=Texel(mistNoise,(p.xz+mistWorldOffset+drift+p.y*vec2(0.8,-0.6))/210.0).r;
  float fine=Texel(mistNoise,(p.xz+mistWorldOffset-drift*0.6)/76.0).r;
  float cloud=smoothstep(0.27,0.73,broad*0.72+fine*0.28);
  float height=(p.y-mistMin.y)/(mistMax.y-mistMin.y);
  float layer=smoothstep(0.0,0.12,height)*(1.0-smoothstep(0.30,1.0,height));
  vec2 edge=min(p.xz-mistMin.xz,mistMax.xz-p.xz);
  float region=mix(1.0,smoothstep(0.0,192.0,min(edge.x,edge.y)),mistEdge);
  optical+=region*stepSize*mistDensity*(0.12+cloud*1.35)*layer;
 }
 return vec4(mistColor,1.0-exp(-optical));
}
]]
local function prepareNoise()
 local g=love.graphics
 if not noise then
  local data=love.image.newImageData(8,8);local seed=71237
  for y=0,7 do for x=0,7 do
   seed=(seed*16807)%2147483647;local n=seed/2147483647;data:setPixel(x,y,n,n,n,1)
  end end
  noise=g.newImage(data);data:release();noise:setFilter('linear','linear');noise:setWrap('repeat','repeat')
 end
end
-- Lighting changes the light in the mist, never its density integration.
-- Keep the same twelve density samples and grid with either light setting;
-- evaluate the more expensive irradiance only at every other sample.
function M.litSource()
  local source=V.require('LocalLights').glsl()..M.GLSL
  source=source:gsub('float optical=0.0;', 'float optical=0.0; vec3 scattered=vec3(0.0);')
  source=source:gsub('optical%+=region%*stepSize', [[
  if(mod(float(i),2.0)<0.5) {
  vec3 incoming=localIrradiance(p,vec3(0,1,0));
  if(localSkyState.y>.5) incoming+=vec3(.95,.92,.72)*max(0.0,localSurfaceShade(0.0,vec3(0,1,0),p)-.38)*.28;
  scattered+=incoming*region*stepSize*.018*layer*(.35+cloud*.65);
  }
  optical+=region*stepSize]])
  source=source:gsub('return vec4%(mistColor,1.0%-exp%(%-optical%)%);',
    'float alpha=1.0-exp(-optical); return vec4(mistColor+min(scattered/max(alpha,.0001),vec3(.25)),alpha);')
  return source
end
-- Compile only the selected lighting variant, once. The transition queue
-- can retire this work before the first visible volume draw.
local function prepareVolumeProgram(luminous)
 local program
 -- Lua's and/or idiom cannot preserve a cached false failure.
 if luminous then program=litShader else program=shader end
 if program==nil then
  local ok,value=pcall(love.graphics.newShader,luminous and M.litSource()or M.GLSL)
  program=ok and value or false
  if luminous then litShader=program else shader=program end
  if not ok then M.programError=tostring(value)end
 end
 return program
end
function M.prepareProgram(map,dark)
 if not map or dark then return false end
 local lights=V.require('LocalLights')
 local luminous=lights.active()
 if luminous and litShader~=nil or not luminous and shader~=nil then return false end
 local needed=M.profile(map,dark)
 if not needed and lights.enabled()then
  -- The light frame has not necessarily been built for this room yet.
  local profile=V.require('HorizonWall').interiorProfileFor(map)
  needed=profile and profile.nativeRoomPanels
 end
 if not needed then return false end
 prepareVolumeProgram(luminous)
 return true
end
local function prepare(w,h,luminous)
 local g=love.graphics
 if not prepareVolumeProgram(luminous)then return false end
 prepareNoise()
 if bw~=w or bh~=h then
  if buffer then buffer:release()end
  buffer=g.newCanvas(w,h);buffer:setFilter('linear','linear');bw,bh=w,h
 end
 return true
end
-- Phones keep their inexpensive internal depth attachment. They get real
-- translucent air layers tested against it, not a black screen-space mask.
M.SLICE_GLSL=[[
varying highp vec3 mistWorld;
#ifdef VERTEX
uniform highp mat4 mistVP;
uniform highp vec3 mistCurve;
vec4 position(mat4 transform_projection,vec4 vertex_position) {
 mistWorld=vertex_position.xyz;
 highp vec4 p=vertex_position;
 highp vec2 delta=p.xz-mistCurve.xy;p.y-=dot(delta,delta)*mistCurve.z;
 return mistVP*p;
}
#endif
#ifdef PIXEL
uniform Image mistNoise;
uniform vec3 mistColor;
uniform highp float mistTime;
uniform highp float mistHeight;
uniform highp float mistBase;
uniform vec2 mistWorldOffset;
uniform vec4 mistRegion;
uniform float mistEdge;
vec4 effect(vec4 color,Image tex,vec2 tc,vec2 sc) {
 highp vec2 drift=vec2(mistTime*0.55,mistTime*0.23);
 float broad=Texel(mistNoise,(mistWorld.xz+mistWorldOffset+drift+mistWorld.y*vec2(0.8,-0.6))/210.0).r;
 float fine=Texel(mistNoise,(mistWorld.xz+mistWorldOffset-drift*0.6)/76.0).r;
 float cloud=smoothstep(0.27,0.73,broad*0.72+fine*0.28);
 highp float height=(mistWorld.y-mistBase)/mistHeight;
 float layer=smoothstep(0.0,0.12,height)*(1.0-smoothstep(0.30,1.0,height));
 vec2 edge=min(mistWorld.xz-mistRegion.xy,mistRegion.zw-mistWorld.xz);
 float region=mix(1.0,smoothstep(0.0,192.0,min(edge.x,edge.y)),mistEdge);
 return vec4(mistColor,(0.015+cloud*0.09)*layer*region);
}
#endif
]]
function M.drawLayers(map,p,vp)
 local g=love.graphics
 prepareNoise()
 if not sliceShader then sliceShader=g.newShader(M.SLICE_GLSL)end
 local base=p.region and 0 or M.base(map)
 if sliceMap~=map or sliceBase~=base or sliceHeight~=p.height then
  if slices then slices:release()end
  local vertices={};local rect=p.region or {-32,-32,map.def.width*32+32,map.def.height*32+32}
  local w,h=rect[3],rect[4]
  -- A map-sized quad cannot follow the world's curved terrain: its corners
  -- sink while its centre cuts through the air/ground. Match the 32-unit
  -- terrain grid; the mesh is built once per map/profile, never per frame.
  for i=1,12 do
   local y=base+p.height*i/13
   for z=rect[2],h-1,32 do for x=rect[1],w-1,32 do
    local x1,z1=math.min(x+32,w),math.min(z+32,h)
    vertices[#vertices+1]={x,y,z};vertices[#vertices+1]={x1,y,z}
    vertices[#vertices+1]={x1,y,z1};vertices[#vertices+1]={x,y,z}
    vertices[#vertices+1]={x1,y,z1};vertices[#vertices+1]={x,y,z1}
   end end
  end
  slices=g.newMesh({{'VertexPosition','float',3}},vertices,'triangles','static')
  sliceMap,sliceBase,sliceHeight=map,base,p.height
 end
 g.push('all');g.setShader(sliceShader);g.setColor(1,1,1,1)
 g.setDepthMode('lequal',false);g.setBlendMode('alpha','alphamultiply');g.setMeshCullMode('none')
 local world=V.require('Voxel3D')
 sliceShader:send('mistCurve',{world.curveX or 0,world.curveZ or 0,world.curveK or 0})
 sliceShader:send('mistVP','row',vp);sliceShader:send('mistNoise',noise)
 sliceShader:send('mistColor',p.color);sliceShader:send('mistHeight',p.height);sliceShader:send('mistBase',base)
 sliceShader:send('mistWorldOffset',p.offset or {0,0});sliceShader:send('mistEdge',p.region and 1 or 0)
 sliceShader:send('mistRegion',p.region or {0,0,1,1})
 sliceShader:send('mistTime',V.require('Sky').clock or 0)
 g.draw(slices);g.pop()
 M.last={map=map.id,layers=12,draws=1,mode='layers'}
 return true
end
function M.draw(map,dark,canvas,depth,vp)
 local p=M.profile(map,dark)
 if not p then return false end
 if not depth then return M.drawLayers(map,p,vp)end
 local inv=M.inverse(vp);if not inv then return false end
 local lights=V.require('LocalLights')
 local luminous=lights.active()
 local w,h=canvas:getDimensions();local divisor=2
 local fw,fh=math.ceil(w/divisor),math.ceil(h/divisor)
 if not prepare(fw,fh,luminous)then return false end
 local g=love.graphics
 local program=luminous and litShader or shader
 g.push('all');g.origin();g.setScissor();g.setDepthMode();g.setMeshCullMode('none')
 -- The readable depth must be detached before it becomes a sampler.
 g.setCanvas(buffer);g.clear(0,0,0,0);g.setShader(program);g.setColor(1,1,1,1)
 program:send('sceneDepth',depth);program:send('mistNoise',noise)
 program:send('inverseVP','row',inv);program:send('mistResolution',{fw,fh})
 local world=V.require('Voxel3D')
 program:send('mistCurve',{world.curveX or 0,world.curveZ or 0,world.curveK or 0})
 local base=p.region and 0 or M.base(map)
 local rect=p.region or {-32,-32,map.def.width*32+32,map.def.height*32+32}
 program:send('mistMin',{rect[1],base,rect[2]})
 program:send('mistMax',{rect[3],base+p.height,rect[4]})
 program:send('mistWorldOffset',p.offset or {0,0});program:send('mistEdge',p.region and 1 or 0)
 program:send('mistColor',p.color);program:send('mistDensity',p.density)
 program:send('mistTime',V.require('Sky').clock or 0)
 if luminous then lights.send(program,true) end
 g.setBlendMode('replace');g.rectangle('fill',0,0,fw,fh)
 -- The replace pass uses alphamultiply, so the buffer already contains
 -- premultiplied RGB. Composite it once instead of weighting it by alpha again.
 g.setCanvas(canvas);g.setShader();g.setBlendMode('alpha','premultiplied')
 g.draw(buffer,0,0,0,w/fw,h/fh);g.pop()
 M.last={map=map.id,width=fw,height=fh,samples=12,lightSamples=luminous and 6 or 0,draws=2,mode='volume'}
 return true
end
function M.invalidate()
 for _,resource in pairs({shader,litShader,noise,buffer,slices,sliceShader})do if resource then resource:release()end end
 shader,litShader,noise,buffer,bw,bh=nil,nil,nil,nil,nil,nil
 M.programError=nil
 slices,sliceShader,sliceMap,sliceBase,sliceHeight=nil,nil,nil,nil,nil
end
return M
