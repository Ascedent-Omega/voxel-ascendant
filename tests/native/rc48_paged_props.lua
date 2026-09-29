return function(game)
 assert(os.getenv('POKEPORT_IDENTITY')=='vasc-video-polish-qa');love.audio.setVolume(0)
 local root=assert(os.getenv('QA_VASC_ROOT'));local modules={};local V={}
 V.require=function(name)if not modules[name]then modules[name]=assert(loadfile(root..'/lib/'..name..'.lua'))(V)end;return modules[name]end
 local B=V.require('BuildBudget');local P=V.require('PagedPropUpload');assert(P.available())
 local format={{'VertexPosition','float',3},{'VertexTexCoord','float',2},{'VertexShade','float',1}}
 local function hash(s)return love.data.encode('string','hex',love.data.hash('sha256',s))end
 local function digest(mesh)
  local rows={};for i=1,mesh:getVertexCount()do rows[i]=love.data.pack('string','=ffffff',mesh:getVertex(i))end
  return hash(table.concat(rows)),hash(table.concat(mesh:getVertexMap()or{},','))
 end
 local results={}
 for _,n in ipairs{1024,2048,4096,16380,16384,24576}do
  local vertices,indices={},{}
  for i=1,n do vertices[i]={i%31,(i*7)%83,(i*13)%37,(i%16+.5)/16,.5,(i%4)/4}end
  for i=1,n,4 do for _,j in ipairs{0,1,2,0,2,3}do indices[#indices+1]=i+j end end
  local t=love.timer.getTime();local reference=love.graphics.newMesh(format,vertices,'triangles','static');reference:setVertexMap(indices);local oldMs=(love.timer.getTime()-t)*1000
  local vertexHash,indexHash=digest(reference)
  local result,err;local co=coroutine.create(function()result,err=P.create(format,vertices,indices)end)
  local steps,peak,total=0,0,0
  repeat
   B.begin(co,.00001);local t=love.timer.getTime();local ok,message=coroutine.resume(co);local ms=(love.timer.getTime()-t)*1000;B.finish()
   assert(ok,message);steps=steps+1;peak=math.max(peak,ms);total=total+ms;assert(steps<10000)
  until coroutine.status(co)=='dead'
  assert(result,err);assert(steps>1,'cooperative upload failed to yield')
  local vh,ih=digest(result);assert(vh==vertexHash and ih==indexHash,'GPU geometry/index changed')
  results[#results+1]={vertices=n,referenceMs=oldMs,slices=steps,peakMs=peak,totalMs=total}
  reference:release();result:release()
  print('PAGED_PROP',n,oldMs,peak,total,steps)
 end
 local f=assert(io.open(assert(os.getenv('SHOT_DIR'))..'/paged.json','w'));f:write(require('src.link.Json').encode(results));f:close()
 print('PASS_PAGED_PROP_GPU_EQUIVALENCE');love.event.quit(0)
end
