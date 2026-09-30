-- Cache geometry visibility in a small world-space volume, rather than
-- tracing eight building boxes and twelve cave cells for every screen pixel.
-- Light colour/flicker, diffuse response and water glints stay per pixel.
local V=...
local M={SIZE=32,LAYERS=8,STEP=8}
local atlas,shader,key,lastFrame,atlasW,atlasH
local retainedSlots
local function signature(frame)
 local parts={tostring(frame.wall and frame.wall.texture)}
 local function n(x)parts[#parts+1]=string.format('%.4f',x or 0)end
 for _,l in ipairs(frame.lights)do
  n(l.x);n(l.y);n(l.z);n(l.radius);n(l.owner.index)
 end
 parts[#parts+1]='portals'
 for _,p in ipairs(frame.portals or {})do
  for _,x in ipairs(p.position)do n(x)end
  for _,x in ipairs(p.normal)do n(x)end
 end
 if #(frame.portals or {})>0 then
  for i=1,3 do parts[#parts+1]=string.format('%.3f',frame.portalSky.direction[i])end
  n(frame.map.def.width);n(frame.map.def.height)
 end
 parts[#parts+1]='blockers'
 for _,b in ipairs(frame.blockers)do for _,x in ipairs(b.lo)do n(x)end;for _,x in ipairs(b.hi)do n(x)end end
 if frame.interior then for _,b in ipairs(frame.interior.blockers)do for _,x in ipairs(b.lo)do n(x)end;for _,x in ipairs(b.hi)do n(x)end end end
 return table.concat(parts,',')
end
-- Retain visibility per emitter, not just for one exact scene-wide list.
-- Adding a distant building should not redraw every existing window volume.
local function emitterPlan(frame,lights)
 local plans={}
 local wall=frame.wall
 local wallKey=tostring(wall and wall.texture)..':'..table.concat(wall and wall.size or {0,0},',')
 for i,l in ipairs(frame.lights)do
  local relevant={}
  for _,b in ipairs(frame.blockers)do
   local dx=l.x-math.max(b.lo[1],math.min(b.hi[1],l.x))
   local dy=l.y-math.max(b.lo[2],math.min(b.hi[2],l.y))
   local dz=l.z-math.max(b.lo[3],math.min(b.hi[3],l.z))
   local d=dx*dx+dy*dy+dz*dz
   if d<l.radius*l.radius then relevant[#relevant+1]={b=b,d=d}end
  end
  table.sort(relevant,function(a,b)return a.d<b.d end)
  local count=math.min(#relevant,lights.MAX_BLOCKERS);local owner=0
  local parts={wallKey,l.x,l.y,l.z,l.radius,count}
  for j=1,count do
   local b=relevant[j].b
   if b==l.owner then owner=j end
   for axis=1,3 do parts[#parts+1]=b.lo[axis];parts[#parts+1]=b.hi[axis]end
  end
  parts[#parts+1]=owner
  plans[i]={blocks=relevant,count=count,owner=owner,key=table.concat(parts,',')}
 end
 return plans
end
function M.prepare(frame,lights,blank)
 local count=#frame.lights+#(frame.portals or {})
 if count==0 then return blank end
 if atlas and lastFrame==frame then return atlas end
 local nextKey=signature(frame)
 if atlas and key==nextKey then lastFrame=frame;return atlas end
 local g=love.graphics
 if not shader then
  shader=g.newShader(lights.glsl(true)..[[
   uniform vec4 visibilityArea;
   uniform vec4 visibilityOrigin; // emitter xyz, owning blocker
   uniform vec3 visibilityNormal;
   uniform vec3 visibilitySun;
   uniform float visibilityPortal;
   uniform float visibilityBase;
   vec4 effect(vec4 color,Image tex,vec2 tc,vec2 sc) {
    vec2 cell=mod(sc,32.0)/32.0;
    float layer=floor(mod(sc.y,256.0)/32.0);
    vec3 world=vec3(visibilityArea.x+cell.x*visibilityArea.z,
      visibilityBase+layer*8.0,visibilityArea.y+cell.y*visibilityArea.w);
    vec3 origin=visibilityOrigin.xyz;
    if(visibilityPortal>.5) {
      float facing=dot(visibilitySun,visibilityNormal);
      if(abs(facing)<.015)return vec4(0,0,0,1);
      float t=dot(origin-world,visibilityNormal)/facing;
      if(t<0.0||t>400.0)return vec4(0,0,0,1);
      origin=world+visibilitySun*t+visibilityNormal*.4;
    }
    float lit=localVisible(origin,world,visibilityOrigin.w);
    return vec4(lit,lit,lit,1);
   }
  ]])
 end
 local slots=lights.MAX_LIGHTS+lights.MAX_PORTALS
 local columns=math.min(64,slots);local rows=math.ceil(slots/columns)
 local width,height=columns*M.SIZE,rows*M.SIZE*M.LAYERS
 local plans=frame.perLightBlockers and emitterPlan(frame,lights) or nil
 local oldAtlas,oldW,oldH=atlas,atlasW,atlasH
 local reuse=plans and #(frame.portals or {})==0 and retainedSlots or nil
 local inPlace=oldAtlas and atlasW==width and atlasH==height
 if inPlace and reuse then
  for i,p in ipairs(plans)do
   local slot=reuse[p.key]
   if slot and slot~=i then inPlace=false;break end
  end
 end
 if not inPlace then
  atlas=g.newCanvas(width,height,{dpiscale=1});atlasW,atlasH=width,height
  atlas:setFilter('linear','linear')
 end
 V.require('RasterResources').changing(atlas)
 local copied,rendered=0,0
 g.push('all')
 local ok,err=pcall(function()
 g.origin();g.setScissor();g.setCanvas(atlas);g.setDepthMode()
 g.setMeshCullMode('none');g.setBlendMode('replace');g.setShader(shader);g.setColor(1,1,1,1)
 if not(plans and inPlace and reuse)then g.clear(1,1,1,1)end
 shader:send('localWallSize',frame.wall and frame.wall.size or {0,0})
 shader:send('localWallMask',frame.wall and frame.wall.texture or blank)
 if not frame.perLightBlockers then
 shader:send('localBlockCount',#frame.blockers)
 for i,b in ipairs(frame.blockers)do shader:send('localLo'..(i-1),b.lo);shader:send('localHi'..(i-1),b.hi)end
 end
 shader:send('visibilitySun',frame.portalSky and {unpack(frame.portalSky.direction,1,3)} or {0,1,0})
 for i,l in ipairs(frame.lights)do
  local plan=plans and plans[i]
  local slot=plan and reuse and reuse[plan.key]
  if slot then
   copied=copied+1
   if not inPlace then
    local oldColumns=oldW/M.SIZE
    local quad=g.newQuad(((slot-1)%oldColumns)*M.SIZE,math.floor((slot-1)/oldColumns)*M.SIZE*M.LAYERS,
      M.SIZE,M.SIZE*M.LAYERS,oldW,oldH)
    g.setShader();g.draw(oldAtlas,quad,((i-1)%columns)*M.SIZE,math.floor((i-1)/columns)*M.SIZE*M.LAYERS)
    quad:release();g.setShader(shader)
   end
  else
   rendered=rendered+1
   if frame.perLightBlockers then
    -- Use the same nearest blockers that define this cached volume.
    local p=assert(plan)
    shader:send('localBlockCount',p.count)
    for j=1,p.count do local b=p.blocks[j].b;shader:send('localLo'..(j-1),b.lo);shader:send('localHi'..(j-1),b.hi)end
    shader:send('visibilityOrigin',{l.x,l.y,l.z,p.owner})
   end
   shader:send('visibilityPortal',0);if not frame.perLightBlockers then shader:send('visibilityOrigin',{l.x,l.y,l.z,l.owner.index or 0})end
   shader:send('visibilityNormal',{0,1,0});shader:send('visibilityBase',l.y-24)
   shader:send('visibilityArea',{l.x-l.radius,l.z-l.radius,l.radius*2,l.radius*2})
   g.rectangle('fill',((i-1)%columns)*M.SIZE,math.floor((i-1)/columns)*M.SIZE*M.LAYERS,M.SIZE,M.SIZE*M.LAYERS)
  end
 end
 for i,p in ipairs(frame.portals or {})do
  shader:send('visibilityPortal',1);shader:send('visibilityOrigin',{p.position[1],p.position[2],p.position[3],0})
  shader:send('visibilityNormal',p.normal);shader:send('visibilityBase',p.position[2]-24)
  shader:send('visibilityArea',{0,0,frame.map.def.width*32,frame.map.def.height*32})
  local blocks=frame.interior and frame.interior.blockers
  if blocks and #blocks>0 then
   -- Test every partition once in the cached low-resolution volume. A fixed
   -- lamp blocker budget must never allow sun through a distant office wall.
   g.setBlendMode('multiply','premultiplied')
   for first=1,#blocks,lights.MAX_BLOCKERS do
    local count=math.min(lights.MAX_BLOCKERS,#blocks-first+1)
    shader:send('localBlockCount',count)
    for j=1,count do local b=blocks[first+j-1];shader:send('localLo'..(j-1),b.lo);shader:send('localHi'..(j-1),b.hi)end
    g.rectangle('fill',(lights.MAX_LIGHTS+i-1)*M.SIZE,0,M.SIZE,M.SIZE*M.LAYERS)
   end
   g.setBlendMode('replace')
  else
   g.rectangle('fill',(lights.MAX_LIGHTS+i-1)*M.SIZE,0,M.SIZE,M.SIZE*M.LAYERS)
  end
 end
 end)
 g.pop()
 if oldAtlas and oldAtlas~=atlas then oldAtlas:release()end
 if not ok then M.invalidate();error(err,0) end
 retainedSlots=nil
 if plans and #(frame.portals or {})==0 then
  retainedSlots={};for i,p in ipairs(plans)do retainedSlots[p.key]=i end
 end
 M.last={reused=copied,rendered=rendered}
 key=nextKey;lastFrame=frame
 M.rebuilds=(M.rebuilds or 0)+1
 return atlas
end
function M.invalidate()
 if atlas then atlas:release()end
 if shader then shader:release()end
 atlas,shader,key,lastFrame=nil,nil,nil,nil
 retainedSlots=nil;M.last=nil
end
return M
