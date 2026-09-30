-- World-space light lists. A screen can contain many lamps without choosing
-- a handful around the player. RGBA8 data works without float-texture support.
local V=...
local M={CELL=16,MAX_OVERLAP=4}
local layout,key,colors,texture,indices,visibility,lastFrame,lastResult,lastReturned
local previousSources,previousBlockers,previousWall,previousLimit
local function release(x)if x and x.release then x:release()end end
local function sig(sources)
 local t={}
 for _,l in ipairs(sources)do
  t[#t+1]=table.concat({l.x,l.y,l.z,l.radius,
   (not l.kind or l.kind=='window') and l.owner and l.owner.lo and 1 or 0},',')
 end
 return table.concat(t,';')
end
-- Authored facades often describe one window as many adjacent glass boxes.
-- Group their irradiance within a fixed world cell, retaining each facade and
-- never joining separate buildings or torch/wayfinding sources. This replaces
-- duplicate near-identical lamps, not a player-dependent source budget.
function M.sources(sources)
 local owners,out={},{}
 for _,l in ipairs(sources)do
  local owner=l.owner
  if owner and owner.lo and owner.hi and (not l.kind or l.kind=='window')then
   local bins=owners[owner]or {};owners[owner]=bins
   local n=l.normal
   -- Same six-value key without allocating a temporary table for every pane.
   local k=math.floor(l.x/32)..':'..math.floor(l.y/32)..':'..math.floor(l.z/32)..':'..n[1]..':'..n[2]..':'..n[3]
   local group=bins[k]
   if not group then
    group={x=l.x,y=l.y,z=l.z,radius=l.radius,power=l.power,normal=n,color=l.color,owner=owner,kind=l.kind,weight=1,count=1,members={l}}
    bins[k]=group;out[#out+1]=group
   else
    group.members[#group.members+1]=l
    group.x=group.x+l.x;group.y=group.y+l.y;group.z=group.z+l.z
    group.count=group.count+1;group.power=math.max(group.power,l.power)
   end
  else out[#out+1]=l end
 end
 for _,group in ipairs(out)do if group.members then
  group.x=group.x/group.count;group.y=group.y/group.count;group.z=group.z/group.count
  group.radius=0
  for _,l in ipairs(group.members)do
   local d=math.sqrt((group.x-l.x)^2+(group.y-l.y)^2+(group.z-l.z)^2)
   group.radius=math.max(group.radius,l.radius+d)
  end
  group.members=nil
 end end
 return out
end
function M.layout(sources,limit,checkpoint)
 limit=limit or M.MAX_OVERLAP
 local x0,z0,x1,z1=math.huge,math.huge,-math.huge,-math.huge
 local y0,y1=math.huge,-math.huge
 for _,l in ipairs(sources)do
  x0=math.min(x0,l.x-l.radius);x1=math.max(x1,l.x+l.radius)
  z0=math.min(z0,l.z-l.radius);z1=math.max(z1,l.z+l.radius)
  y0=math.min(y0,l.y);y1=math.max(y1,l.y)
 end
 if #sources==0 then return end
 x0=math.floor(x0/M.CELL)*M.CELL;z0=math.floor(z0/M.CELL)*M.CELL
 local nx,nz=math.max(1,math.ceil((x1-x0)/M.CELL)),math.max(1,math.ceil((z1-z0)/M.CELL))
 local cells,weights,maxCount={},{},0
 local function score(id,cx,cz)
  local l=sources[id];local d=((l.x-cx)^2+(l.z-cz)^2)/(l.radius*l.radius)
  return l.power*math.max(0,1-d)^2/(1+3*d)
 end
 local function insert(cell,rank,id,value)
  local at=1
  while at<=#cell and (rank[at]>value or (rank[at]==value and cell[at]<id))do at=at+1 end
  if at<=limit then
   for j=math.min(limit,#cell+1),at+1,-1 do cell[j]=cell[j-1];rank[j]=rank[j-1]end
   cell[at]=id;rank[at]=value
  end
 end
 for i,l in ipairs(sources)do
  local left,right=math.floor((l.x-l.radius-x0)/M.CELL),math.min(nx-1,math.floor((l.x+l.radius-x0)/M.CELL))
  local top,bottom=math.floor((l.z-l.radius-z0)/M.CELL),math.min(nz-1,math.floor((l.z+l.radius-z0)/M.CELL))
  for z=top,bottom do for x=left,right do
   local dx=l.x-math.max(x0+x*M.CELL,math.min(x0+(x+1)*M.CELL,l.x))
   local dz=l.z-math.max(z0+z*M.CELL,math.min(z0+(z+1)*M.CELL,l.z))
   if dx*dx+dz*dz<=l.radius*l.radius then
    local n=z*nx+x+1;local cell=cells[n]
    if not cell then cell={};cells[n]=cell end
    local rank=weights[n]
    if not rank and #cell<limit then
     -- Underfull cells retain source order exactly as before.
     cell[#cell+1]=i;maxCount=math.max(maxCount,#cell)
    else
     local cx,cz=x0+(x+.5)*M.CELL,z0+(z+.5)*M.CELL
     if not rank then
      -- Rank only when the cell first overflows. Never build an unbounded
      -- candidate list just to discard all but four entries afterwards.
      local initial=cell;cell={};rank={};cells[n]=cell;weights[n]=rank
      for _,id in ipairs(initial)do insert(cell,rank,id,score(id,cx,cz))end
     end
     insert(cell,rank,i,score(i,cx,cz))
    end
   end
  end end
  if checkpoint and i%8==0 then checkpoint()end
 end
 maxCount=math.min(maxCount,limit)
 return {x=x0,z=z0,nx=nx,nz=nz,cells=cells,stride=maxCount+1,
  origin={x0,y0,z0},span={nx*M.CELL,math.max(1,y1-y0),nz*M.CELL}}
end
local function pair(n)
 n=math.floor(math.max(0,math.min(1,n))*65535+.5)
 return math.floor(n/256)/255,(n%256)/255
end
-- The packed CPU index image belongs to its pending job until publication.
-- Cancelling preparation releases it without touching the active grid.
local function indexData(layout,sources,checkpoint,own)
 local texels=layout.nx*layout.nz*layout.stride
 local width=math.min(512,texels);local height=math.ceil(texels/width)
 local limit=love.graphics.getSystemLimits().texturesize
 assert(height<=limit and math.ceil(#sources/64)*256<=limit,'local light grid exceeds GPU texture limit')
 local data=love.image.newImageData(width,height);own(data)
 local function set(n,value,dynamic)local a,b=pair(value/65535);data:setPixel(n%width,math.floor(n/width),a,b,dynamic and 1 or 0,1)end
 local count=0
 for n,cell in pairs(layout.cells)do
  local dynamic=false
  for _,id in ipairs(cell)do
   if not sources[id].staticLight then dynamic=true;break end
  end
  local base=(n-1)*layout.stride;set(base,#cell,dynamic)
  for i,id in ipairs(cell)do set(base+i,id)end
  count=count+1;if checkpoint and count%32==0 then checkpoint()end
 end
 layout.fingerprint=love.data and love.data.hash and love.data.hash('sha256',data:getString()) or nil
 layout.texSize={width,height}
 return data
end
-- The world update lane grants one shared CPU allowance for all shader
-- consumers. Standalone callers and battle fixtures remain synchronous.
local remaining,pending,previousMap
function M.beginFrame(covered)
 remaining=covered and .004 or .00075
end
function M.pending()return pending~=nil end
function M.cancelPending()
 if pending then release(pending.data);pending=nil end
end
local function stagedLayout(sources,limit,nextKey,map)
 if not pending or pending.key~=nextKey or pending.map~=map then
  -- Snapshot powers/geometry: authored source tables are reused for flicker.
  M.cancelPending()
  local snapshot={}
  for i,l in ipairs(sources)do snapshot[i]={x=l.x,y=l.y,z=l.z,radius=l.radius,power=l.power,
    staticLight=(not l.kind or l.kind=='window') and l.owner and l.owner.lo and true or false}end
  pending={key=nextKey,map=map}
  local job=pending
  job.co=coroutine.create(function()
   local function checkpoint()
    if job.deadline and love.timer.getTime()>=job.deadline then coroutine.yield()end
   end
   job.result=M.layout(snapshot,limit,checkpoint)
   checkpoint()
   indexData(job.result,snapshot,checkpoint,function(data)job.data=data end)
  end)
 end
 while remaining==nil or remaining>0 do
  local started=love.timer.getTime()
  pending.deadline=remaining and (started+math.min(.00075,remaining)) or nil
  local ok,err=coroutine.resume(pending.co)
  if remaining then remaining=remaining-(love.timer.getTime()-started)end
  if not ok then M.cancelPending();error(err,0)end
  if coroutine.status(pending.co)=='dead'then
   local result,data=pending.result,pending.data;pending=nil;return result,data
  end
 end
end
local function image(data)
 local t=V.require("RasterResources").seal(love.graphics.newImage(data));t:setFilter('nearest','nearest');t:setWrap('clamp','clamp');return t
end
local function sameVector(a,b)
 if a==b then return true end
 return a and b and a[1]==b[1] and a[2]==b[2] and a[3]==b[3]
end
local function unchanged(frame,limit)
 local sources,blocks=frame.allLights,frame.allBlockers or frame.blockers
 if not previousSources or #sources~=#previousSources or not previousBlockers or #blocks~=#previousBlockers
    or previousWall~=frame.wall or previousLimit~=limit then return false end
 for i,l in ipairs(sources)do local p=previousSources[i]
  if l.kind~=p.kind or l.power~=p.power or not sameVector(l.color,p.color)then return false end
  -- Authored building instances own immutable geometry until their model or
  -- transform changes. Thousands of facade panes otherwise compare their
  -- position/normal/building bounds again on every single frame.
  if not l.geometryKey or l.geometryKey~=p.geometryKey then
   if l.x~=p.x or l.y~=p.y or l.z~=p.z or l.radius~=p.radius
     or not sameVector(l.normal,p.normal)then return false end
   if not sameVector(l.owner.lo,p.owner.lo)or not sameVector(l.owner.hi,p.owner.hi)then return false end
  end
 end
 for i,b in ipairs(blocks)do local p=previousBlockers[i]
  if not sameVector(b.lo,p.lo)or not sameVector(b.hi,p.hi)then return false end
 end
 return true
end
local function pendingMatches(frame,limit)
 if not pending or pending.map~=frame.map or pending.limit~=limit
    or not pending.raw or #pending.raw~=#frame.allLights then return false end
 for i,l in ipairs(frame.allLights)do local p=pending.raw[i]
  if not l.geometryKey or l.geometryKey~=p.geometryKey then
   if l.x~=p.x or l.y~=p.y or l.z~=p.z or l.radius~=p.radius
      or l.kind~=p.kind or not sameVector(l.normal,p.normal)
      or not sameVector(l.owner and l.owner.lo,p.lo)
      or not sameVector(l.owner and l.owner.hi,p.hi)then return false end
  end
 end
 return true
end
local function rememberRequest(frame,limit,sources)
 pending.limit=limit;pending.sources=sources;pending.raw={}
 for i,l in ipairs(frame.allLights)do
  pending.raw[i]={geometryKey=l.geometryKey,x=l.x,y=l.y,z=l.z,radius=l.radius,
    kind=l.kind,normal={l.normal[1],l.normal[2],l.normal[3]},
    lo=l.owner and l.owner.lo and {unpack(l.owner.lo)},
    hi=l.owner and l.owner.hi and {unpack(l.owner.hi)}}
 end
end
-- Canonical ordering makes persisted irradiance independent of the order in
-- which connected maps finished loading (pairs/order differs after restart).
local function orderedSources(sources)
 local keys={}
 for _,l in ipairs(sources)do
  local n=l.normal;local c=l.color or {1,.64,.27};local o=l.owner or{}
  keys[l]=table.concat({l.x,l.y,l.z,l.radius,n[1],n[2],n[3],l.kind or 'window',
    c[1],c[2],c[3],l.power,table.concat(o.lo or{},','),table.concat(o.hi or{},',')},':')
 end
 table.sort(sources,function(a,b)return keys[a]<keys[b]end)
 return sources
end
local function orderedBlocks(blocks)
 local result,keys={},{}
 for i,b in ipairs(blocks)do result[i]=b;keys[b]=table.concat(b.lo,',')..':'..table.concat(b.hi,',')end
 table.sort(result,function(a,b)return keys[a]<keys[b]end)
 return result
end
function M.prepare(frame,lights,blank)
 local limit=math.min(M.MAX_OVERLAP,lights.MAX_LIGHTS)
 if lastFrame==frame then return lastReturned end
 if not frame.allLights or #frame.allLights==0 then M.cancelPending();return end
 if lastResult and previousMap==frame.map and unchanged(frame,limit)then M.cancelPending();lastFrame=frame;lastReturned=lastResult;return lastResult end
 local reused=pendingMatches(frame,limit)
 local sources=reused and pending.sources or orderedSources(M.sources(frame.allLights))
 local nextKey=reused and pending.key or (tostring(limit)..":"..sig(sources))
 local nextLayout,nextData
 if nextKey~=key then
  nextLayout,nextData=stagedLayout(sources,limit,nextKey,frame.map)
  if not nextLayout then
   if not reused then rememberRequest(frame,limit,sources)end
   lastFrame=frame
   -- Same-map expansion can retain its complete old grid. A different map
   -- must never sample stale coordinates merely to avoid a loading slice.
   lastReturned=previousMap==frame.map and lastResult or nil
   return lastReturned
  end
  -- Only now refresh live power/colour. Regrouping thousands of facade panes
  -- in every pending frame otherwise creates more GC work than it saves.
  if reused then sources=orderedSources(M.sources(frame.allLights))end
 else M.cancelPending()end
 previousSources={};previousBlockers={}
 local function copy(v)return v and {v[1],v[2],v[3]}end
 for i,l in ipairs(frame.allLights)do previousSources[i]={kind=l.kind,geometryKey=l.geometryKey,x=l.x,y=l.y,z=l.z,radius=l.radius,power=l.power,
  normal=copy(l.normal),color=copy(l.color),owner={lo=copy(l.owner.lo),hi=copy(l.owner.hi)}}end
 for i,b in ipairs(frame.allBlockers or frame.blockers)do previousBlockers[i]={lo=copy(b.lo),hi=copy(b.hi)}end
 previousWall=frame.wall;previousLimit=limit
 if nextKey~=key then
  local data=assert(nextData)
  nextLayout.fingerprint=nextLayout.fingerprint or nextKey
  local ok,uploaded=pcall(image,data);data:release()
  if not ok then error(uploaded,0)end
  release(indices);indices=uploaded;layout=nextLayout
  release(texture);texture=nil;colors=nil;key=nextKey
 end
 local colorKey={}
 for _,l in ipairs(sources)do
  local c=l.color or {1,.64,.27};local n=l.normal
  colorKey[#colorKey+1]=table.concat({c[1],c[2],c[3],l.power,n[1],n[2],n[3],
   (not l.kind or l.kind=='window') and l.owner and l.owner.lo and 1 or 0},',')
 end
 colorKey=table.concat(colorKey,';')
 if colorKey~=colors then
  local data=love.image.newImageData(4,#sources)
  for i,l in ipairs(sources)do
   local a,b=pair((l.x-layout.origin[1])/layout.span[1]);local c,d=pair((l.y-layout.origin[2])/layout.span[2])
   data:setPixel(0,i-1,a,b,c,d)
   a,b=pair((l.z-layout.origin[3])/layout.span[3]);c,d=pair(l.radius/1024)
   data:setPixel(1,i-1,a,b,c,d)
   local rgb=l.color or {1,.64,.27};data:setPixel(2,i-1,rgb[1],rgb[2],rgb[3],math.min(1,l.power*.72/8))
   local n=l.normal;data:setPixel(3,i-1,n[1]*.5+.5,n[2]*.5+.5,n[3]*.5+.5,
    (not l.kind or l.kind=='window') and l.owner and l.owner.lo and 1 or 0)
  end
  if texture then V.require("RasterResources").changing(texture);texture:replacePixels(data)else texture=image(data)end
  data:release();colors=colorKey
 end
 if not visibility then visibility=assert((loadstring or load)(assert(V.mod:read('lib/LightVisibility.lua')),'@grid/LightVisibility.lua'))(V)end
 local blocks=orderedBlocks(frame.allBlockers or frame.blockers)
 local f={lights=sources,blockers=blocks,wall=frame.wall,perLightBlockers=true}
 local policy={MAX_LIGHTS=#sources,MAX_PORTALS=0,MAX_BLOCKERS=lights.MAX_BLOCKERS,glsl=lights.glsl}
 local mask=visibility.prepare(f,policy,blank)
 M.last={sources=#sources,maxOverlap=layout.stride-1,visibilityRebuilds=visibility.rebuilds,
  visibilityReused=visibility.last and visibility.last.reused,visibilityRendered=visibility.last and visibility.last.rendered}
 lastFrame=frame;previousMap=frame.map
 lastResult={data=texture,indices=indices,visibility=mask,origin=layout.origin,span=layout.span,
  grid={layout.x,layout.z,layout.nx,layout.nz},listSize={layout.texSize[1],layout.texSize[2],layout.stride},
  info={#sources,math.min(64,#sources),math.ceil(#sources/64)}}
 local power,staticCount=0,0
 for _,l in ipairs(sources)do
  if (not l.kind or l.kind=='window') and l.owner and l.owner.lo then power=math.max(power,l.power);staticCount=staticCount+1 end
 end
 local stamp={key,layout.fingerprint,tostring(lights.MAX_BLOCKERS),tostring(frame.wall and frame.wall.texture)}
 for _,b in ipairs(blocks)do
  stamp[#stamp+1]=table.concat(b.lo,',')..':'..table.concat(b.hi,',')
 end
 for i,l in ipairs(sources)do
  if (not l.kind or l.kind=='window') and l.owner and l.owner.lo then
   stamp[#stamp+1]=i..':'..table.concat(l.owner.lo,',')..':'..table.concat(l.owner.hi,',')
   local c=l.color or {1,.64,.27};local n=l.normal
   stamp[#stamp+1]=string.format('%.6f,%g,%g,%g,%g,%g,%g',power>0 and l.power/power or 0,c[1],c[2],c[3],n[1],n[2],n[3])
  end
 end
 lastResult.staticKey=table.concat(stamp,';');lastResult.staticPower=power
 lastResult.dynamicCount=#sources-staticCount
 lastReturned=lastResult
 return lastResult
end
M.GLSL=[[
#ifdef GL_ES
precision highp float;
#endif
uniform float localGridOn;
uniform Image localGridData;
uniform Image localGridIndices;
uniform Image localGridVisibility;
uniform vec3 localGridOrigin;
uniform vec3 localGridSpan;
uniform vec4 localGridArea;
uniform vec3 localGridListSize;
uniform vec3 localGridInfo;
float gridUint(vec2 bytes) { return dot(bytes,vec2(65280.0,255.0)); }
float gridRead(float index) {
 vec2 uv=(vec2(mod(index,localGridListSize.x),floor(index/localGridListSize.x))+.5)/localGridListSize.xy;
 return floor(gridUint(Texel(localGridIndices,uv).rg)+.5);
}
float gridVisible(vec3 world,vec4 pos,float slot) {
 if(localUnoccluded>.5)return 1.0;
 vec2 cell=clamp((world.xz-pos.xz+pos.ww)/(pos.w*2.0)*32.0,vec2(.5),vec2(31.5));
 float layer=clamp((world.y-pos.y+24.0)/8.0,0.0,7.0);
 vec2 start=vec2(mod(slot,localGridInfo.y)*32.0,floor(slot/localGridInfo.y)*256.0);
 vec2 size=vec2(localGridInfo.y*32.0,localGridInfo.z*256.0);
 float a=Texel(localGridVisibility,(start+vec2(cell.x,floor(layer)*32.0+cell.y))/size).r;
 float b=Texel(localGridVisibility,(start+vec2(cell.x,min(7.0,floor(layer)+1.0)*32.0+cell.y))/size).r;
 return mix(a,b,fract(layer));
}
vec3 localGridLightRaw(vec3 world,vec3 normal,vec3 reflected,float mode,float selection) {
 if(localGridOn<.5)return vec3(0.0);
 vec2 cell=floor((world.xz-localGridArea.xy)/16.0);
 if(cell.x<0.0||cell.y<0.0||cell.x>=localGridArea.z||cell.y>=localGridArea.w)return vec3(0.0);
 float base=(cell.y*localGridArea.z+cell.x)*localGridListSize.z;
 float count=gridRead(base);vec3 sum=vec3(0.0);
 for(int i=0;i<4;i++) {
  if(float(i)>=count)break;
  float slot=gridRead(base+1.0+float(i))-1.0;
  float row=(slot+.5)/localGridInfo.x;
  vec4 a=Texel(localGridData,vec2(.125,row)),b=Texel(localGridData,vec2(.375,row));
  vec4 pos=vec4(localGridOrigin+vec3(gridUint(a.rg),gridUint(a.ba),gridUint(b.rg))/65535.0*localGridSpan,gridUint(b.ba)/65535.0*1024.0);
  vec3 d=world-pos.xyz;float r2=dot(d,d)/(pos.w*pos.w);
  if(r2<1.0) {
   vec4 direction=Texel(localGridData,vec2(.875,row));
   if(selection>.5 && selection<1.5 && direction.a>.5)continue;
   if(selection>1.5 && direction.a<.5)continue;
   vec3 dir=direction.rgb*2.0-1.0;
   float front=dot(dir,dir)<.1?1.0:smoothstep(-1.5,3.0,dot(d,dir));
   if(front>0.0) {
    vec4 tint=Texel(localGridData,vec2(.625,row));
    vec3 lamp=tint.rgb*tint.a*8.0*front*(1.0-r2)*(1.0-r2)/(1.0+3.0*r2)*gridVisible(world,pos,slot);
    vec3 incoming=normalize(-d);float diffuse=max(0.0,dot(normal,incoming));
    if(mode>1.5)lamp*=.07+.9*pow(max(0.0,dot(reflected,incoming)),24.0);
    else lamp*=mode>.5?.55+.45*diffuse:.12+.88*diffuse;
    sum+=lamp;
   }
  }
 }
 return sum;
}
#ifdef GL_ES
precision mediump float;
#endif
]]
if V.require then M.GLSL=M.GLSL..V.require('StaticLightField').GLSL end
function M.invalidate()
 V.require('StaticLightField').invalidate()
 M.cancelPending();previousMap=nil
 release(texture);release(indices);if visibility then visibility.invalidate()end
 layout,key,colors,texture,indices,lastFrame,lastResult,lastReturned=nil,nil,nil,nil,nil,nil,nil,nil
 previousSources,previousBlockers,previousWall,previousLimit=nil,nil,nil,nil
end
return M
