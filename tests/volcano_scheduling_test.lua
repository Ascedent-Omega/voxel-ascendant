-- Cooperative landmark generation must preserve every face, including lava,
-- and leave all allocated meshes owned by the cancellable parent job.
local modules={ModSetting={new=function()return{get=function()return'connected'end}end}}
local V={require=function(name)return assert(modules[name],name)end}
local corners={{{0,0,0},{0,0,1},{0,1,1},{0,1,0}},{{1,0,0},{1,1,0},{1,1,1},{1,0,1}},
 {{0,1,0},{0,1,1},{1,1,1},{1,1,0}},{{0,0,0},{1,0,0},{1,0,1},{0,0,1}},
 {{0,0,0},{0,1,0},{1,1,0},{1,0,0}},{{0,0,1},{1,0,1},{1,1,1},{0,1,1}}}
local allocated,uploads,failAt={},0
modules.Voxel3D={FACE_CORNERS=corners,newMesh=function(vertices,indices)
 uploads=uploads+1
 if failAt==uploads then return nil end
 local mesh={vertices=vertices,indices=indices,release=function(self)self.released=true end}
 allocated[#allocated+1]=mesh;return mesh
end}
modules.SceneryMeshUpload=assert(loadfile('lib/SceneryMeshUpload.lua'))(V)
love={image={newImageData=function()return{setPixel=function()end,release=function()end}end},
 graphics={newImage=function()return{setFilter=function()end,release=function()end}end}}
package.loaded['src.render.Assets']={register=function()end}
local M=assert(loadfile('lib/CinnabarVolcano.lua'))(V)
local reference=M.meshes(31,-73,6)
local owned={};allocated={};uploads=0
local co=coroutine.create(function()return M.meshes(31,-73,6,function()coroutine.yield()end,owned)end)
local slices=0
repeat
 local before=uploads;slices=slices+1
 local ok,err=coroutine.resume(co);assert(ok,err)
 assert(uploads-before<=1,'multiple GPU uploads in a slice')
 assert(#owned==#allocated,'cancellation would leak GPU meshes')
until coroutine.status(co)=='dead'
local function flatten(parts)
 local all={}
 for _,part in ipairs(parts)do
  for _,index in ipairs(part.mesh.indices)do
   local v=part.mesh.vertices[index]
   all[#all+1]={v[1],v[2],v[3],v[4],v[5],v[6],part.magma}
  end
 end
 return all
end
local function same(a,b)
 a,b=flatten(a),flatten(b);assert(#a==#b)
 for i,v in ipairs(a)do for k=1,7 do assert(v[k]==b[i][k],'changed landmark face '..i..':'..k)end end
end
same(reference,owned)
for _,part in ipairs(owned)do assert(#part.mesh.vertices<=6144,'unbounded GPU allocation')end
-- Optional immutable pre-change artifact: checks the new batch boundaries
-- against the former two-mesh landmark, not only against the new sync path.
if os.getenv('QA_VOLCANO_REFERENCE')then
 local old=assert(loadfile(os.getenv('QA_VOLCANO_REFERENCE')))(V)
 same(old.meshes(31,-73,6),owned)
end
-- Optional transformed views preserve every source face and material.
local view={transform=function(x,y,z)
 local c,s=math.cos(.18),math.sin(.18);local dx,dz=x+700,z-144
 return 248+(s*dx-c*dz)*8,(y-5)*8,80+(c*dx+s*dz-492)*8
end}
local source=M.meshes(0,0,0)
local entrance=M.meshes(0,0,0,nil,nil,view)
local a,b=flatten(source),flatten(entrance);assert(#a==#b)
for i,v in ipairs(a)do
 local x,y,z=view.transform(v[1],v[2],v[3])
 assert(b[i][1]==x and b[i][2]==y and b[i][3]==z,'entrance is not shared volcano geometry')
 for k=4,7 do assert(v[k]==b[i][k],'entrance material/lava differs')end
end
-- The actual Blaine adapter preserves the complete mountain, omitting the coast.
modules.CinnabarVolcano=M
local B=assert(loadfile('lib/BlaineVolcano.lua'))(V)
assert(B.ENTRANCE_SCALE==8,'entrance must not regress to a room-sized miniature')
local actual=B.buildHorizon({ox=17,oy=29},nil,{})
local uncropped=M.meshes(17,29,0,nil,nil,{transform=view.transform,coneOnly=true})
same(uncropped,actual)
for _,part in ipairs(actual)do for _,v in ipairs(part.mesh.vertices)do
 for axis=1,3 do assert(v[axis]>=part.bounds[axis]and v[axis]<=part.bounds[axis+3],'transformed cone culled')end
end end
local low,high=math.huge,-math.huge
for _,part in ipairs(actual)do low=math.min(low,part.bounds[2]);high=math.max(high,part.bounds[5])end
assert(high-low>5000,'volcano lost its mountain scale relative to the player')
print('PASS actual Blaine adapter: full-sized shared cone/lava, canonical offsets and culling bounds')
uploads=0;allocated={};failAt=2
assert(not pcall(M.meshes,0,0,0),'allocation failure silently accepted')
assert(#allocated==1 and allocated[1].released,'standalone failure leaked first mesh')
print('PASS volcano: exact rock/lava faces, bounded uploads, cancellation ownership and allocation failure; '..slices..' slices')
