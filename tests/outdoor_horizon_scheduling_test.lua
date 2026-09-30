-- A slow graphics driver must never receive multiple horizon mesh uploads
-- during one cooperative step. Slicing must preserve the complete geometry.
local modules={};local V={require=function(k)return assert(modules[k],k)end}
modules.ModSetting={new=function()return{get=function()return'voxel'end}end}
modules.HorizonBuildings={}
modules.RasterResources=assert(loadfile('lib/RasterResources.lua'))()
local allocations,uploads,slices,maxUploads={},0,0,0
local corners={{{0,0,0},{1,0,0},{1,1,0},{0,1,0}}}
modules.Voxel3D={FACE_CORNERS=corners,FACE_SHADE={1},
 pushQuad=function(indices,n)for _,i in ipairs{1,2,3,1,3,4}do indices[#indices+1]=n*4+i end end,
 newMesh=function(vertices,indices)
  uploads=uploads+1
  local mesh={vertices=vertices,indices=indices,release=function()end}
  allocations[#allocations+1]=mesh;return mesh
 end}
modules.Gen1ForestLandmarks={geometry=function()end}
modules.OceanLandmarks={geometry=function()end}
modules.CinnabarVolcano={active=function()return false end}
package.loaded['src.render.Assets']={register=function()end}
love={image={newImageData=function()return{setPixel=function()end,release=function()end}end},
 graphics={newImage=function()return{setFilter=function()end}end}}
modules.SceneryMeshUpload=assert(loadfile('lib/SceneryMeshUpload.lua'))(V)
local H=assert(loadfile('lib/OutdoorHorizon.lua'))(V)
local silphCalls=0
H.silphLandmark=function()silphCalls=silphCalls+1 end
modules.Gen1PalletVillage={buildings={get=function()return true end}}
modules.VoxelItems={setting={get=function()return true end}}
modules.Gen1LavenderTower={setting={get=function()return 'stone'end}}
H.geometry=function(maps,horizon,emit)
 emit(300,0,0,1,2,3,4,false) -- first batch stays partial while later ones fill
 local before=#allocations
 for i=1,700 do emit(i%20,0,0,1,2,3,4,false)end
 assert(#allocations>=before+2,'full batches retained until all geometry finished')
end
local maps={{map={id='SAFFRON_CITY'}}}
local synchronous=H.build(maps,{},nil,{})
assert(#synchronous==4,'fixture must require several spatial batches')
assert(silphCalls==1,'distant Silph geometry emitted twice')
allocations={};uploads=0
local owned={}
local co=coroutine.create(function()
 return H.build(maps,{},function()coroutine.yield()end,{},owned)
end)
local sliced
repeat
 uploads=0;slices=slices+1
 local ok,result=coroutine.resume(co);assert(ok,result)
 maxUploads=math.max(maxUploads,uploads)
 assert(uploads<=1,'multiple indivisible GPU uploads in one background step')
 assert(#owned==#allocations,'pending job cannot release its completed GPU meshes')
 if coroutine.status(co)=='dead'then sliced=result end
until sliced
assert(maxUploads==1 and #sliced==#synchronous and sliced==owned and silphCalls==2)
local vertices=0
for i,a in ipairs(synchronous)do
 local b=sliced[i];assert(#a.mesh.vertices==#b.mesh.vertices)
 vertices=vertices+#b.mesh.vertices
 for j,v in ipairs(a.mesh.vertices)do for k,value in ipairs(v)do assert(value==b.mesh.vertices[j][k],'slicing altered scenery')end end
 for j,value in ipairs(a.mesh.indices)do assert(value==b.mesh.indices[j])end
 for j,value in ipairs(a.bounds)do assert(value==b.bounds[j])end
end
assert(vertices==701*4,'scenery dropped to meet frame budget')
print('PASS outdoor horizon: one GPU upload per slice, all 701 boxes and batches preserved; '..slices..' slices')
-- Shoreline/coast classification is immutable within a shoulder build.
-- Repeated clearance probes must reuse each exact map/edge/sample lookup.
modules.Gen1ForestLandmarks.gates=function()return{}end
H.profile=function()return 'forest'end
local function shoulders(sliced)
 local seen,boxes={},{}
 local edges={edgeClass=function(map,edge,along)
  local k=edge..':'..along;assert(not seen[k],'repeated expensive edge classification');seen[k]=true
  return edge=='north'and'open_water'or'forest'
 end}
 local e={map={},x0=0,z0=0,x1=256,z1=256,w=256,h=256}
 local function emit(...)boxes[#boxes+1]={...}end
 local co=coroutine.create(function()H.shoulders({e},edges,emit,sliced and function()coroutine.yield()end or nil,96,{})end)
 repeat local ok,err=coroutine.resume(co);assert(ok,err)until coroutine.status(co)=='dead'
 return boxes
end
local a,b=shoulders(false),shoulders(true)
assert(#a>0 and #a==#b)
for i,row in ipairs(a)do for j,value in ipairs(row)do assert(value==b[i][j],'shoulder slicing changed geometry')end end
print('PASS shoulder edge memoization and complete sliced coastal geometry')
