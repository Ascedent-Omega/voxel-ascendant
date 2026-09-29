return function(game)
 assert(os.getenv('POKEPORT_IDENTITY')=='vasc-video-polish-qa')
 love.audio.setVolume(0)
 local ex=assert(game.mods.exports.VOXEL_ASCENDANT)
 local function find(fn,name,seen)
  if type(fn)~='function'then return end;seen=seen or{};if seen[fn]then return end;seen[fn]=true
  for i=1,100 do local k,v=debug.getupvalue(fn,i);if not k then break end;if k==name then return v end end
  for i=1,100 do local k,v=debug.getupvalue(fn,i);if not k then break end;local got=find(v,name,seen);if got then return got end end
 end
 local V=assert(find(ex.lib.require('VoxelScene').render,'V'))
 local G=V.require('Voxel3D');local Upload=V.require('SceneryMeshUpload')
 local probeData=love.data.newByteData(24*3)
 local supported,probe=pcall(love.graphics.newMesh,G.FORMAT,probeData,'triangles','static')
 probeData:release();assert(supported,probe);probe:release()
 local vertices,indices={},{}
 for box=1,256 do
  for face,corners in ipairs(G.FACE_CORNERS)do
   G.pushQuad(indices,#vertices/4)
   for _,p in ipairs(corners)do
    vertices[#vertices+1]={box*.75+p[1]*3,face+p[2]*9,-box+p[3]*7,.137,.523,G.FACE_SHADE[face]}
   end
  end
 end
 local reference=assert(G.newMesh(vertices,indices))
 local slices=0
 local mesh=assert(Upload.newMesh(vertices,indices,function()slices=slices+1 end))
 assert(mesh:getVertexCount()==reference:getVertexCount())
 for i=1,#vertices do
  local a,b={reference:getVertex(i)},{mesh:getVertex(i)}
  assert(#a==#b)
  for k,value in ipairs(a)do assert(value==b[k],'packed float mismatch '..i..':'..k)end
 end
 local a,b=reference:getVertexMap(),mesh:getVertexMap()
 assert(#a==#b and #a==#indices)
 for i,value in ipairs(a)do assert(value==b[i],'packed index mismatch '..i)end
 reference:release();mesh:release()
 print('PASS_SCENERY_UPLOAD_NATIVE vertices='..#vertices..' indices='..#indices..' packingCheckpoints='..slices)
 love.event.quit()
end
