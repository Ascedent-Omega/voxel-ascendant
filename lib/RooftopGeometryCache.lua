-- Disposable CPU geometry; textures and GPU objects remain owned by the scene.
-- Four fixed slots bound total disk use to 128 MiB, including modded worlds.
local V=...
local C={hits=0,misses=0,writes=0,errors=0,MAX_BYTES=32*1024*1024,MAX_RAW=128*1024*1024}
local names={'frame','world','windows','foliage'}
local allowed={CELADON_MART_ROOF=true,CELADON_MANSION_ROOF=true}
for _,r in ipairs{11,12,15,16,18}do allowed['ROUTE_'..r..'_GATE_2F']=true end
local stamp
local function api()
 local d=love and love.data;local fs=V.mod and V.mod.cache
 if d and d.hash and d.pack and d.unpack and fs and fs.read and fs.write and fs.info then return d,fs end
end
local function hash(d,s)return d.encode('string','hex',d.hash('sha256',s))end
local function pause(y)if y then y()end end
function C.key(entry,defs,address,near,yieldStep)
 local d=api();if not d or not allowed[entry.map.id]then return end
 local style=V.require('Gen1LavenderTower').setting:get()
 if style~='wood'and style~='stone'then return end
 local ok,key=pcall(function()
  if not stamp then
   local parts={'roof-mesh-v2',tostring(V.mod.version)}
   for _,n in ipairs{'Voxel3D','RooftopPanorama','RooftopWorld','RooftopCache','RooftopGeometryCache','Gen1Rooftops','Gen1RoofTerrace','Gen1RoomBounds','Gen1MountainExteriors','VoxelItems','VoxelFurniture','WorldPlacement','TileShape','Gen1OutdoorScenery','Gen1PalletVillage','Gen1LavenderTower','CinnabarVolcano'}do
    parts[#parts+1]=hash(d,assert(V.mod:read('lib/'..n..'.lua')));pause(yieldStep)
   end
   stamp=hash(d,table.concat(parts,'|'))
  end
  local game=require('src.core.Game');defs=defs or game.data.maps
  local ids={entry.map.id};local warps={}
  for _,p in ipairs(V.require('RooftopWorld').maps(entry,defs))do ids[#ids+1]=p.id;warps[p.id]=p.def.warps end
  local world=assert(V.require('RooftopCache').signature(defs,ids,game.data.tilesets))
  pause(yieldStep)
  local detail=assert(V.require('TerrainDiskCache').fingerprint({warps=warps,palette=V.require('VoxelItems').palette,w=entry.w,h=entry.h,facadeHeight=entry.facadeHeight,style=style}))
  local geometry
  if near then geometry=V.require('RooftopCache').pack(near)
  else
   -- Modded maps can invalidate the packaged panorama. Fingerprint the actual
   -- building models too before reusing this complete-world fallback.
   local models={};local items=V.require('VoxelItems');local Map=require('src.world.Map')
   local function model(a)
    if not a then return end
    return {boxes=a.boxes,template=a.template,frameW=a.frameW,depth=a.depth,offsetY=a.offsetY,glassKind=a.glassKind,slidingDoors=a.slidingDoors}
   end
   for _,p in ipairs(V.require('RooftopWorld').maps(entry,defs))do
    local map=Map.new(p.def,game.data.tilesets[p.def.tileset])
    for _,b in ipairs(V.require('VoxelFurniture').findBuildings(map))do
     local a=items.models[b.kind];models[b.kind]=model(a)
     if a and a.glassKind then models[a.glassKind]=model(items.models[a.glassKind])end
     for _,door in ipairs(a and a.slidingDoors or{})do models[door.kind]=model(items.models[door.kind])end
    end
    pause(yieldStep)
   end
   geometry=assert(V.require('TerrainDiskCache').fingerprint({models=models,colors=items.decorColors}))
  end
  return hash(d,stamp..world..tostring(address)..detail..geometry)
 end)
 if not ok then C.errors=C.errors+1;C.lastError=tostring(key);return end
 return key,'rooftop-mesh-v2/'..tostring(tonumber(hash(d,entry.map.id..style):sub(1,8),16)%4)..'.bin'
end
local function finite(n)return n==n and math.abs(n)<1e8 end
function C.get(key,path,yieldStep)
 if not key then return end
 local d,fs=api();local ok,groups,volcano=pcall(function()
  local info=fs:info(path);if not info or info.size<140 or info.size>C.MAX_BYTES then return end
  local raw=fs:read(path)
  if type(raw)~='string'or #raw~=info.size or raw:sub(1,4)~='RMC2'or raw:sub(5,68)~=key then return end
  local payload=raw:sub(133);if hash(d,payload)~=raw:sub(69,132)then return end
  local length=d.unpack('<I4',payload);assert(length>=8 and length<=C.MAX_RAW)
  pause(yieldStep)
  local body=d.decompress('string','zlib',payload:sub(5));assert(#body==length)
  pause(yieldStep)
  local pos=1
  local function read(fmt)local row={d.unpack(fmt,body,pos)};pos=table.remove(row);return unpack(row)end
  local count,has=read('<I4I4');assert(count>0 and count<=2048 and has<=1)
  local peak
  if has==1 then local x,y,z,h=read('<ffff');assert(finite(x)and finite(y)and finite(z)and finite(h));peak={x=x,y=y,z=z,height=h}end
  local out={}
  for i=1,count do
   local kind,flags,nv=read('<I4I4I4');assert(names[kind]and flags<=3 and nv>0 and nv<=4096 and nv%4==0)
   local bounds={read('<ffffff')};for _,n in ipairs(bounds)do assert(finite(n))end
   local vb,ib=nv*24,nv/4*24;assert(pos+vb+ib-1<=#body)
   local vertices=body:sub(pos,pos+vb-1);pos=pos+vb
   local indices=body:sub(pos,pos+ib-1);pos=pos+ib
   out[i]={name=names[kind],lit=flags%2==1,foliage=flags>=2,bounds=bounds,packedVertices=vertices,packedIndices=indices,nv=nv}
   pause(yieldStep)
  end
  assert(pos==#body+1);return out,peak
 end)
 if ok and groups then C.hits=C.hits+1;return groups,volcano end
 if not ok then C.errors=C.errors+1;C.lastError=tostring(groups)end
 C.misses=C.misses+1
end
function C.put(key,path,groups,volcano,yieldStep)
 if not key then return false end
 local d,fs=api();local ok,result=pcall(function()
  assert(#groups>0 and #groups<=2048)
  local parts={d.pack('string','<I4I4',#groups,volcano and 1 or 0)};local bytes=140
  if volcano then parts[#parts+1]=d.pack('string','<ffff',volcano.x,volcano.y,volcano.z,volcano.height);bytes=bytes+16 end
  for _,g in ipairs(groups)do
   local kind;for i,n in ipairs(names)do if g.name==n then kind=i end end
   local nv=#g.vertices;assert(kind and nv>0 and nv<=4096 and nv%4==0 and #g.indices==nv/4*6)
   bytes=bytes+36+nv*30;assert(bytes<=C.MAX_RAW)
   local piece={}
   piece[#piece+1]=d.pack('string','<I4I4I4',kind,(g.lit and 1 or 0)+(g.foliage and 2 or 0),nv)
   piece[#piece+1]=d.pack('string','<ffffff',unpack(g.bounds))
   for i,v in ipairs(g.vertices)do
    for _,n in ipairs(v)do assert(finite(n))end
    piece[#piece+1]=d.pack('string','<ffffff',unpack(v));if i%256==0 then pause(yieldStep)end
   end
   for i,n in ipairs(g.indices)do assert(n>=1 and n<=nv);piece[#piece+1]=d.pack('string','<I4',n-1);if i%512==0 then pause(yieldStep)end end
   parts[#parts+1]=table.concat(piece)
  end
  local body=table.concat(parts);pause(yieldStep)
  local payload=d.pack('string','<I4',#body)..d.compress('string','zlib',body,1)
  C.lastRawBytes=#body;C.lastStoredBytes=#payload+132;assert(#payload+132<=C.MAX_BYTES);pause(yieldStep)
  return fs:write(path,'RMC2'..key..hash(d,payload)..payload)
 end)
 if ok and result then C.writes=C.writes+1;return true end
 C.errors=C.errors+1;C.lastError=tostring(result);return false
end
function C.mesh(g,yieldStep)
 if not g.packedVertices then return V.require('Voxel3D').newMesh(g.vertices,g.indices)end
 local mesh,vertices,indices
 local ok=pcall(function()
  vertices=love.data.newByteData(g.packedVertices);indices=love.data.newByteData(g.packedIndices)
  mesh=love.graphics.newMesh(V.require('Voxel3D').FORMAT,vertices,'triangles','static')
  mesh:setVertexMap(indices,'uint32',#g.packedIndices/4)
 end)
 if vertices then vertices:release()end;if indices then indices:release()end
 if ok then return mesh end
 if mesh then mesh:release()end
 -- Older drivers may reject packed index buffers; retain the established path.
 local vv,ii={},{}
 for i=1,g.nv do local x,y,z,u,v,s=love.data.unpack('<ffffff',g.packedVertices,(i-1)*24+1);vv[i]={x,y,z,u,v,s};if i%256==0 then pause(yieldStep)end end
 for i=1,#g.packedIndices/4 do ii[i]=love.data.unpack('<I4',g.packedIndices,(i-1)*4+1)+1 end
 return V.require('Voxel3D').newMesh(vv,ii)
end
return C
