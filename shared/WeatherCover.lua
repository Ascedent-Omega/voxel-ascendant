-- A sparse 4px height field from the same quads that build the terrain.
-- Published atomically after meshing; no GPU readback, per-frame mesh scan,
-- collision changes, or invented roof rectangles.
local resources=...
local M={CELL=4,MAX_CELLS=196608}
local fields=setmetatable({},{__mode='k'})
local props=setmetatable({},{__mode='k'})
local image,activeKey,origin,size
local revision=0
-- Gen1 enables cooperative preparation once per update. Other hosts retain
-- the synchronous API until they opt into the same frame/reveal contract.
local budget,attempted,job,deadline,checks,activeContext,failedContext
function M.beginFrame(covered)
 budget=covered and .002 or .0005;attempted=false
end
function M.check()
 if not(job and coroutine.running()==job.co)then return end
 checks=(checks or 0)+1
 if checks>=32 then
  checks=0
  if love.timer.getTime()>=deadline then coroutine.yield()end
 end
end
local function cancel()
 if job and job.data then job.data:release()end
 job=nil
end
-- A refresh keeps the last complete mask for this same neighborhood.
-- Only a cold context blocks reveal; routine validation must not reclose it.
function M.pending()return job~=nil and image==nil end
local function owner(map)return map and(map.def or map)end
local function fieldFor(layer,map)
 local field=map and layer[owner(map)]
 return field and field.tileset==map.tileset and field or nil
end
local function key(x,z)return math.floor(x/M.CELL)..':'..math.floor(z/M.CELL)end
function M.begin(map,layer)
 local target=layer=='props' and props or fields
 local field={cells={},count=0,tileset=map.tileset}
 function field:add(q,ox,oy,oz,compact)
  M.check()
  ox,oy,oz=ox or 0,oy or 0,oz or 0
  local a,b,c,d
  if compact then
   if math.max(q[2],q[5],q[8],q[11])+oy<2 then return end
   if math.abs((q[4]-q[1])*(q[9]-q[3])-(q[6]-q[3])*(q[7]-q[1]))<.0001 then return end
  else
   a,b,c,d=q[1],q[2],q[3],q[4]
   if math.max(a[2],b[2],c[2],d[2])+oy<2 then return end
   if math.abs((b[1]-a[1])*(c[3]-a[3])-(b[3]-a[3])*(c[1]-a[1]))<.0001 then return end
  end
  local x0,x1,z0,z1,y=math.huge,-math.huge,math.huge,-math.huge,-math.huge
  local xs,zs,ys={},{},{}
  for i=1,4 do
   local a=compact and (i-1)*3+1 or i
   local x,yy,z
   if compact then x,yy,z=q[a],q[a+1],q[a+2] else x,yy,z=q[a][1],q[a][2],q[a][3] end
   xs[i],zs[i],ys[i]=x+ox,z+oz,yy+oy
   x0=math.min(x0,x+ox);x1=math.max(x1,x+ox);z0=math.min(z0,z+oz);z1=math.max(z1,z+oz);y=math.max(y,yy+oy)
  end
  local function inside(x,z,a,b,c)
   local den=(zs[b]-zs[c])*(xs[a]-xs[c])+(xs[c]-xs[b])*(zs[a]-zs[c])
   if math.abs(den)<.0001 then return nil end
   local u=((zs[b]-zs[c])*(x-xs[c])+(xs[c]-xs[b])*(z-zs[c]))/den
   local v=((zs[c]-zs[a])*(x-xs[c])+(xs[a]-xs[c])*(z-zs[c]))/den
   if u>=-.001 and v>=-.001 and u+v<=1.001 then return u*ys[a]+v*ys[b]+(1-u-v)*ys[c] end
  end
  if math.abs((xs[2]-xs[1])*(zs[3]-zs[1])-(zs[2]-zs[1])*(xs[3]-xs[1]))<.0001 then return end
  if y<2 or x1-x0<.001 or z1-z0<.001 then return end
  -- Interpolate each real roof triangle. A ridge must not mask its own
  -- lower slope; only the XZ boundary is quantized to a 4px cell.
  for z=math.floor(z0/M.CELL),math.ceil(z1/M.CELL)-1 do
   for x=math.floor(x0/M.CELL),math.ceil(x1/M.CELL)-1 do
    M.check()
    local k=x..':'..z;local old=self.cells[k]
    local px=math.max(x0+.0001,math.min(x1-.0001,(x+.5)*M.CELL))
    local pz=math.max(z0+.0001,math.min(z1-.0001,(z+.5)*M.CELL))
    local top=inside(px,pz,1,2,3)or inside(px,pz,1,3,4)
    if top and(old or self.count<M.MAX_CELLS)then
     if not old then self.count=self.count+1 end
     self.cells[k]=math.max(old or -math.huge,top)
    end
   end
  end
 end
 function field:publish()
  revision=revision+1;self.revision=revision;target[owner(map)]=self
  -- Definitions remain in the engine registry; weak keys alone do not bound
  -- a whole playthrough's fields. More than the visible neighborhood fits.
  local count,oldest,oldKey=0,math.huge
  for k,v in pairs(target)do count=count+1;if v.revision<oldest then oldest,oldKey=v.revision,k end end
  if count>32 then target[oldKey]=nil end
 end
 return field
end
function M.height(map,x,z)
 local k=key(x,z)
 local fa,fb=fieldFor(fields,map),fieldFor(props,map)
 local a,b=fa and fa.cells[k],fb and fb.cells[k]
 return a and b and math.max(a,b)or a or b
end
function M.revision(map)
 local a,b=fieldFor(fields,map),fieldFor(props,map)
 return math.max(a and a.revision or 0,b and b.revision or 0)
end
function M.propsRevision(map)local f=fieldFor(props,map);return f and f.revision or 0 end
function M.export(map)local f=fieldFor(fields,map);return f and f.cells or {}end
function M.restore(map,cells)
 if type(cells)~='table'then return false end
 local f=M.begin(map)
 for k,y in pairs(cells)do
  if type(k)~='string' or not k:match('^%-?%d+:%-?%d+$') or type(y)~='number' or y~=y or math.abs(y)>2047 or f.count>=M.MAX_CELLS then return false end
  f.cells[k]=y;f.count=f.count+1
 end
 f:publish();return true
end
function M.sheltered(map,x,z,y)return (M.height(map,x,z)or -math.huge)>(y or 0)+10 end
local function clearImage()
 if image then image:release()end
 image,activeKey,origin,size=nil,nil,nil,nil;M.textureBytes=0
end
function M.invalidate(map)
 cancel();activeContext,failedContext=nil,nil
 if map then fields[owner(map)]=nil;props[owner(map)]=nil
 else fields=setmetatable({},{__mode='k'});props=setmetatable({},{__mode='k'})end
 clearImage()
end
local function build(maps)
 local parts={};local x0,z0,x1,z1=0,0,4,4
 for _,nb in ipairs(maps)do
  if nb.map and nb.map.def then
   M.check()
   if M.provider then M.provider(nb.map)end
   local ox,oz=nb.ox or 0,nb.oy or 0
   parts[#parts+1]=tostring(nb.map)..':'..M.revision(nb.map)..':'..ox..':'..oz
   x0=math.min(x0,ox-32);z0=math.min(z0,oz-32)
   x1=math.max(x1,ox+(nb.map.def.width or 1)*32+32)
   z1=math.max(z1,oz+(nb.map.def.height or 1)*32+32)
  end
 end
 local signature=table.concat(parts,';');if signature==activeKey then return end
 x0=math.floor(x0/M.CELL)*M.CELL;z0=math.floor(z0/M.CELL)*M.CELL
 local w,h=math.ceil((x1-x0)/M.CELL),math.ceil((z1-z0)/M.CELL)
 if w>2048 or h>2048 then clearImage();return end
 local data=love.image.newImageData(w,h)
 if job and coroutine.running()==job.co then job.data=data end
 for _,nb in ipairs(maps)do
  for _,layer in ipairs{fields,props}do
  local field=fieldFor(layer,nb.map)
  if field then for k,y in pairs(field.cells)do
   M.check()
   local x,z=k:match('([^:]+):([^:]+)')
   x=math.floor((tonumber(x)*M.CELL+(nb.ox or 0)-x0)/M.CELL)
   z=math.floor((tonumber(z)*M.CELL+(nb.oy or 0)-z0)/M.CELL)
   if x>=0 and x<w and z>=0 and z<h then
    local r,g=data:getPixel(x,z)
    local packed=math.max(math.floor(y*16+32768),math.floor(r*255+.5)*256+math.floor(g*255+.5))
    data:setPixel(x,z,math.floor(packed/256)/255,(packed%256)/255,0,1)
   end
  end end
  end
 end
 local replacement=love.graphics.newImage(data);data:release()
 if resources then resources.seal(replacement)end
 if job and coroutine.running()==job.co then job.data=nil end
 replacement:setFilter('nearest','nearest')
 if image then image:release()end
 image,activeKey,origin,size=replacement,signature,{x0,z0},{w*M.CELL,h*M.CELL}
 M.textureBytes=w*h*4
end
function M.prepare(state,mode)
 M.active=mode==nil or mode=="rain" or mode=="storm" or mode=="snow"
 if not M.active then cancel();return end
 local map=state and state.map
 if not(map and map.def and love and love.image and love.graphics)then cancel();return end
 local maps={{map=map,ox=0,oy=0}}
 for _,nb in ipairs(state.neighbors or {})do
  maps[#maps+1]={map=nb.map,ox=nb.ox,oy=nb.oy}
 end
 if not budget then return build(maps)end
 local parts={}
 for _,nb in ipairs(maps)do
  parts[#parts+1]=tostring(nb.map)..':'..tostring(nb.map and nb.map.tileset)..':'..(nb.ox or 0)..':'..(nb.oy or 0)
 end
 local context=table.concat(parts,';')
 if context~=activeContext then
  cancel();clearImage();activeContext=context;failedContext=nil
 end
 if attempted or failedContext==context then return end
 attempted=true
 if not job then job={co=coroutine.create(function()build(maps)end)}end
 deadline=love.timer.getTime()+budget;checks=0
 local ok,err=coroutine.resume(job.co)
 if not ok then
  M.lastError=tostring(err);failedContext=context;cancel();clearImage()
 elseif coroutine.status(job.co)=='dead'then job=nil end
end
function M.bind(shader)
 if image and M.active~=false and shader:hasUniform('weatherCover')then
  shader:send('weatherCover',image);shader:send('weatherCoverOrigin',origin);shader:send('weatherCoverSize',size)
 end
 if shader:hasUniform('weatherCoverOn')then shader:send('weatherCoverOn',image and M.active~=false and 1 or 0)end
end
return M
