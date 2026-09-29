local packed,fail,created,released={},nil,0,0
local sourceRows,sourceIndices={},{}
for i=1,600 do sourceRows[i]={i,i/2,-i,.25,.75,1}end
for i=1,900 do sourceIndices[i]=(i-1)%600+1 end
local format={{'VertexPosition','float',3},{'VertexTexCoord','float',2},{'VertexShade','float',1}}
local function byteData(bytes)
 if fail=='data'then error('allocation failure')end
 return{bytes=bytes,release=function()released=released+1 end}
end
love={data={pack=function(kind,fmt,...)
 local key='<'..tostring(#packed+1)..'>';packed[#packed+1]={key=key,format=fmt,values={...}};return key
end,newByteData=byteData},graphics={newMesh=function(fmt,data,mode,usage)
 assert(fmt==format and type(data.bytes)=='string' and mode=='triangles'and usage=='static')
 if fail=='mesh'then error('allocation failure')end
 created=created+1
 return{vertexBytes=data.bytes,setVertexMap=function(self,data,kind,n)
  assert(kind=='uint16'and n==900);if fail=='indices'then error('index failure')end
  self.indexBytes=data.bytes
 end,release=function()released=released+1 end}
end}}
local G={FORMAT=format,newMesh=function(v,i)assert(v==sourceRows and i==sourceIndices);return'fallback'end}
local M=assert(loadfile('lib/SceneryMeshUpload.lua')){require=function()return G end}
local yields=0
local mesh=M.newMesh(sourceRows,sourceIndices,function()yields=yields+1;assert(created==0,'cancel could retain a GPU handle')end)
assert(mesh and created==1 and released==2 and yields>1)
local allFloats,allIndices={},{}
for _,p in ipairs(packed)do
 local into=p.format:find('f',1,true)and allFloats or allIndices
 for _,v in ipairs(p.values)do into[#into+1]=v end
 assert(#p.values<=768,'packing exceeded argument/page bound')
end
assert(#allFloats==3600 and #allIndices==900)
for i,row in ipairs(sourceRows)do for k,value in ipairs(row)do assert(allFloats[(i-1)*6+k]==value)end end
for i,value in ipairs(sourceIndices)do assert(allIndices[i]==value-1,'indices must become zero based')end
for _,kind in ipairs{'data','mesh','indices'}do
 fail=kind;created=0;released=0
 assert(M.newMesh(sourceRows,sourceIndices)==nil)
 local expected=kind=='data'and 0 or kind=='mesh'and 2 or 3
 assert(released==expected,'failed upload leaked native allocations: '..kind)
end
fail=nil;love.data=nil
assert(M.newMesh(sourceRows,sourceIndices)=='fallback')
print('PASS packed scenery: complete float/index stream, bounded packing, cancellation before allocation, failures release buffers, legacy fallback')
