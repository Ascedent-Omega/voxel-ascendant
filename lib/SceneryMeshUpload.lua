-- Pack bounded scenery batches before the indivisible graphics allocation.
-- LOVE's nested-table constructor otherwise converts thousands of vertex
-- tables in one native call, outside the background scheduler's deadline.
local V=...
local M={}
local G=V.require('Voxel3D')
local unpackValues=unpack or table.unpack
local FLOATS=6
local function release(data)if data and data.release then pcall(data.release,data)end end
function M.newMesh(vertices,indices,yieldStep)
 local api=love and love.data
 if not(api and api.pack and api.newByteData and G.FORMAT)then
  return G.newMesh(vertices,indices)
 end
 if #vertices==0 then return nil end
 local clock=love.timer and love.timer.getTime
 local started=clock and clock()or 0
 local function checkpoint()
  if yieldStep and (not clock or clock()-started>=.00075)then
   yieldStep();started=clock and clock()or 0
  end
 end
 local pieces={}
 for at=1,#vertices,128 do
  local values={}
  for i=at,math.min(at+127,#vertices)do
   for k=1,FLOATS do values[#values+1]=vertices[i][k]end
  end
  local ok,bytes=pcall(api.pack,'string','='..string.rep('f',#values),unpackValues(values))
  if not ok then return G.newMesh(vertices,indices)end
  pieces[#pieces+1]=bytes;checkpoint()
 end
 local vertexBytes=table.concat(pieces);pieces={}
 -- These batches normally fit uint16, including GLES devices. Do not force
 -- a uint32 index buffer for a six-thousand-vertex skyline section.
 local indexType=#vertices<=65535 and 'uint16'or'uint32'
 local indexPack=indexType=='uint16'and'I2'or'I4'
 for at=1,#indices,768 do
  local values={}
  for i=at,math.min(at+767,#indices)do values[#values+1]=indices[i]-1 end
  local ok,bytes=pcall(api.pack,'string','='..string.rep(indexPack,#values),unpackValues(values))
  if not ok then return G.newMesh(vertices,indices)end
  pieces[#pieces+1]=bytes;checkpoint()
 end
 local indexBytes=table.concat(pieces);pieces=nil
 -- Yield before allocating: no GPU handle can be stranded by cancellation
 -- during packing. Once allocated, publish or release it without yielding.
 if yieldStep then yieldStep()end
 local ok,vertexData=pcall(api.newByteData,vertexBytes)
 if not ok or not vertexData then return nil end
 local indexOK,indexData=pcall(api.newByteData,indexBytes)
 if not indexOK or not indexData then release(vertexData);return nil end
 -- Initialize the static buffer in the constructor. Allocating an empty
 -- buffer and then setVertices() forced an avoidable driver synchronization
 -- with the visible scene (over 20ms on the measured macOS path).
 local allocated,mesh=pcall(love.graphics.newMesh,G.FORMAT,vertexData,'triangles','static')
 if not allocated or not mesh then release(vertexData);release(indexData);return nil end
 local indexed=pcall(mesh.setVertexMap,mesh,indexData,indexType,#indices)
 release(vertexData);release(indexData)
 if not indexed then release(mesh);return nil end
 return mesh
end
return M
