-- Bounded, camera-independent irradiance for stationary facade lights.
-- Six face directions preserve voxel normals. Actors/water and nonstationary
-- sources retain their original shading. Incomplete/unsupported caches fall
-- back to the exact grid rather than exposing partially baked illumination.
local V=...
local F={enabled=true,rebuilds=0}
local current,job,shader,allowance,lastFrame,failed,covered
local observedKey,settleUntil,persistence
local function release(v)if v and v.release then v:release()end end
local function discardJob()
 if job then
  if job.readTask then V.require('StaticLightDiskCache').cancelWrite(job.readTask)end
  release(job.texture);job=nil
 end
end
function F.beginFrame(underCover)
 covered=underCover;allowance=covered and 6 or 1;lastFrame=nil
 if covered and persistence and V.require('StaticLightDiskCache').stepWrite(persistence)then persistence=nil end
end
function F.pending()return job~=nil or persistence~=nil end
local function cancelPersistence()
 if persistence then V.require('StaticLightDiskCache').cancelWrite(persistence);persistence=nil end
end
local function persist(field)
 if covered and not field.persisted then
  cancelPersistence();field.persisted=true
  persistence=V.require('StaticLightDiskCache').beginWrite(field.diskKey,field.texture)
 end
end
function F.invalidate()
 cancelPersistence()
 release(current and current.texture);discardJob();release(shader)
 current,job,shader,lastFrame,failed=nil,nil,nil,nil,nil
 F.last,F.lastError=nil,nil
 observedKey,settleUntil=nil,nil
end
function F.plan(grid,limit,mobile)
 local step,nx,nz=4
 local layers=14
 repeat
  nx=math.ceil(grid.grid[3]*16/step);nz=math.ceil(grid.grid[4]*16/step)
  if nx*6<=limit and nz*layers<=limit and nx*nz*6*layers*4<=(mobile and 8 or 16)*1024*1024 then break end
  step=step*2
 until step>16
 if step>16 then return end
 return {nx=nx,nz=nz,step=step,layers=layers,width=nx*6,height=nz*layers,
  area={grid.grid[1],grid.grid[2],step,nx},heightInfo={-8,8,layers,nz}}
end
local function sendGrid(sh,g)
 sh:send('localGridOn',1);sh:send('localUnoccluded',0)
 sh:send('localGridData',g.data);sh:send('localGridIndices',g.indices)
 sh:send('localGridVisibility',g.visibility);sh:send('localGridOrigin',g.origin)
 sh:send('localGridSpan',g.span);sh:send('localGridArea',g.grid)
 sh:send('localGridListSize',g.listSize);sh:send('localGridInfo',g.info)
end
function F.programPrepared()return not F.enabled or failed or shader~=nil end
function F.prepareProgram()
 if F.programPrepared()then return false end
 local g=love.graphics
 local ok,result=pcall(function()return g.newShader('uniform float localUnoccluded;\n'..V.require('LocalLightGrid').GLSL..[[
     uniform vec4 fieldArea; uniform vec4 fieldHeight;
     uniform vec3 faceNormal; uniform float planeHeight; uniform float powerScale;
     vec4 effect(vec4 color,Image tex,vec2 tc,vec2 sc) {
      vec2 cell=mod(sc,vec2(fieldArea.w,fieldHeight.w));
      vec3 world=vec3(fieldArea.x+cell.x*fieldArea.z,planeHeight,fieldArea.y+cell.y*fieldArea.z);
      return vec4(localGridLightRaw(world,faceNormal,vec3(0),0.0,2.0)/(powerScale*4.0),1);
     }
    ]]) end)
 if ok then shader=result else failed=true;F.lastError=tostring(result)end
 return true
end
local normals={{1,0,0},{-1,0,0},{0,1,0},{0,-1,0},{0,0,1},{0,0,-1}}
function F.prepare(grid,frame,mobile)
 if not F.enabled or failed or not grid or not grid.staticPower or grid.staticPower<=0 or frame.unoccluded or frame.wall then
  discardJob();return
 end
 if current and current.key==grid.staticKey then
  discardJob();observedKey,settleUntil=nil,nil
  persist(current)
  return current
 end
 if lastFrame==frame then return end
 lastFrame=frame
 local now=love.timer.getTime()
 if job and job.key~=grid.staticKey then
  discardJob();settleUntil=now+.15
 end
 if observedKey~=grid.staticKey then
  observedKey=grid.staticKey
  if settleUntil then settleUntil=now+.15 end
 end
 -- Independently animated window colors/strengths can keep changing a bake
 -- key. Stop allocation churn, render the original lights, and retry only
 -- once that input has settled; never hold a load cover indefinitely.
 if settleUntil then
  if now<settleUntil then return end
  settleUntil=nil
 end
 local g=love.graphics
 local ok,result=pcall(function()
  if not job then
   local p=F.plan(grid,g.getSystemLimits().texturesize,mobile)
   if not p then return end
   p.diskKey=V.require('StaticLightDiskCache').key(grid.staticKey..table.concat(p.area,',')..table.concat(p.heightInfo,','))
   p.key=grid.staticKey;p.slice=0;job=p
   if covered then p.readTask=V.require('StaticLightDiskCache').beginRead(p.diskKey,p.width,p.height) end
  end
  if job.readTask and not covered then
   V.require('StaticLightDiskCache').cancelWrite(job.readTask);job.readTask=nil
  end
  if job.readTask then
   local done,image=V.require('StaticLightDiskCache').stepRead(job.readTask)
   if not done then return end
   job.readTask=nil
   if image then
    cancelPersistence();release(current and current.texture)
    job.texture=image;job.persisted=true;current=job;job=nil
    F.last={bytes=current.width*current.height*4,step=current.step,diskHit=true,rebuilds=F.rebuilds}
    return current
   end
  end
  if not job.texture then
   if not shader then F.prepareProgram();if not shader then return end end
   job.texture=g.newCanvas(job.width,job.height,{dpiscale=1,format='rgba8'})
   job.texture:setFilter('linear','linear')
  end
  local count=math.min(allowance or 1,job.layers*6-job.slice)
  if count<=0 then return end
  g.push('all')
  local rendered,err=pcall(function()
   g.origin();g.setScissor();g.setCanvas(job.texture);g.setDepthMode();g.setMeshCullMode('none')
   g.setBlendMode('replace');g.setColor(1,1,1,1);g.setShader(shader)
   sendGrid(shader,grid);shader:send('fieldArea',job.area);shader:send('fieldHeight',job.heightInfo)
   shader:send('powerScale',grid.staticPower)
   for _=1,count do
    local face=job.slice%6;local layer=math.floor(job.slice/6)
    shader:send('faceNormal',normals[face+1]);shader:send('planeHeight',-8+layer*8)
    g.rectangle('fill',face*job.nx,layer*job.nz,job.nx,job.nz);job.slice=job.slice+1
   end
  end)
  g.pop();if not rendered then error(err)end
  allowance=math.max(0,(allowance or 1)-count)
  if job.slice==job.layers*6 then
   cancelPersistence();release(current and current.texture);current=job;job=nil;F.rebuilds=F.rebuilds+1
   F.last={bytes=current.width*current.height*4,step=current.step,rebuilds=F.rebuilds}
   persist(current)
   return current
  end
 end)
 if not ok then
  F.lastError=tostring(result);failed=true;discardJob()
  return
 end
 return result
end
function F.send(sh,grid,frame,mobile)
 if not sh:hasUniform('staticFieldOn')then return end
 local field=F.prepare(grid,frame,mobile)
 sh:send('staticFieldOn',field and 1 or 0)
 if field then
  sh:send('staticField',field.texture);sh:send('staticFieldArea',field.area)
  sh:send('staticFieldHeight',field.heightInfo)
  sh:send('staticFieldPower',grid.staticPower);sh:send('staticFieldDynamic',grid.dynamicCount)
 end
end
F.GLSL=[[
#ifdef GL_ES
precision highp float;
#endif
uniform float staticFieldOn;
uniform Image staticField;
uniform vec4 staticFieldArea; // x, z, horizontal step, width per face
uniform vec4 staticFieldHeight; // y base, step, layers, height per face
uniform float staticFieldPower;
uniform float staticFieldDynamic;
vec3 staticFieldFace(vec2 cell,float layer,float face) {
 vec2 size=vec2(staticFieldArea.w*6.0,staticFieldHeight.w*staticFieldHeight.z);
 vec2 p=vec2(face*staticFieldArea.w,layer*staticFieldHeight.w)+cell;
 return Texel(staticField,p/size).rgb;
}
vec3 localGridLight(vec3 world,vec3 normal,vec3 reflected,float mode) {
 if(localGridOn<.5)return vec3(0);
 if(staticFieldOn<.5 || mode>.5)return localGridLightRaw(world,normal,reflected,mode,0.0);
 vec2 cell=(world.xz-staticFieldArea.xy)/staticFieldArea.z;
 float y=(world.y-staticFieldHeight.x)/staticFieldHeight.y;
 if(y<0.0 || y>staticFieldHeight.z-1.0 ||
    cell.x<.5 || cell.y<.5 || cell.x>staticFieldArea.w-.5 || cell.y>staticFieldHeight.w-.5)
  return localGridLightRaw(world,normal,reflected,mode,0.0);
 // Axis-aligned voxel faces use one direction. Sloped surfaces retain the
 // exact path, avoiding incorrect interpolation across differently lit faces.
 vec3 n=abs(normal);float face;
 if(n.x>.999)face=normal.x>0.0?0.0:1.0;
 else if(n.y>.999)face=normal.y>0.0?2.0:3.0;
 else if(n.z>.999)face=normal.z>0.0?4.0:5.0;
 else return localGridLightRaw(world,normal,reflected,mode,0.0);
 vec3 value=mix(staticFieldFace(cell,floor(y),face),staticFieldFace(cell,min(floor(y)+1.0,staticFieldHeight.z-1.0),face),fract(y))*staticFieldPower*4.0;
 if(staticFieldDynamic>.5) {
  // A torch elsewhere in the region must not force four per-pixel light
  // evaluations on every stationary surface. Index headers carry a bit for
  // cells whose selected light list actually includes a dynamic source.
  vec2 gridCell=floor((world.xz-localGridArea.xy)/16.0);
  float index=(gridCell.y*localGridArea.z+gridCell.x)*localGridListSize.z;
  vec2 uv=(vec2(mod(index,localGridListSize.x),floor(index/localGridListSize.x))+.5)/localGridListSize.xy;
  if(Texel(localGridIndices,uv).b>.5)value+=localGridLightRaw(world,normal,reflected,mode,1.0);
 }
 return value;
}
#ifdef GL_ES
precision mediump float;
#endif
]]
return F
