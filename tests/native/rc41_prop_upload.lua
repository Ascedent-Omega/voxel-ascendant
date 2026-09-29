return function(game)
 assert(os.getenv('POKEPORT_IDENTITY')=='vasc-video-polish-qa');love.audio.setVolume(0)
 io.stdout:setvbuf('no');game:startNewGame{intro=false}
 local ex=game.mods.exports.VOXEL_ASCENDANT;ex.setupCard.suspended=true
 ex.ascendantContent.promptDisabled=true;ex.ascendantContent.onboardingShown=true
 local function find(fn,name,seen)
  if type(fn)~='function'then return end;seen=seen or{};if seen[fn]then return end;seen[fn]=true
  for i=1,100 do local k,v=debug.getupvalue(fn,i);if not k then break end;if k==name then return v end end
  for i=1,100 do local k,v=debug.getupvalue(fn,i);if not k then break end;local x=find(v,name,seen);if x then return x end end
 end
 local V=assert(find(ex.lib.require('VoxelScene').render,'V'))
 local G=V.require('Voxel3D');assert(G.canInstance())
 local root=assert(os.getenv('QA_VASC_ROOT'));local dir=assert(os.getenv('SHOT_DIR'))
 local baseline=assert(loadfile(assert(os.getenv('QA_PROP_BASELINE'))))(V)
 local current=assert(loadfile(root..'/lib/VoxelPropBatch.lua'))(V)
 local function hash(s)return love.data.encode('string','hex',love.data.hash('sha256',s))end
 local function digest(mesh)
  local rows={}
  for i=1,mesh:getVertexCount()do rows[i]=love.data.pack('string','=ffffff',mesh:getVertex(i))end
  local indices=mesh:getVertexMap()or{}
  return hash(table.concat(rows)),hash(table.concat(indices,','))
 end
 local shader=love.graphics.newShader([[
  attribute vec3 InstanceOffset;
  vec4 position(mat4 transform_projection,vec4 vertex_position){
   return transform_projection*vec4(vertex_position.xyz+InstanceOffset,1.0);
  }
 ]])
 local function pixels(bundle)
  local g=love.graphics;local c=g.newCanvas(256,256)
  g.push('all');g.setCanvas(c);g.origin();g.setScissor();g.setDepthMode();g.clear(0,0,0,0)
  g.setColor(.5,.75,1,1);g.setShader(shader)
  local inst=bundle.instances[1];g.drawInstanced(inst.mesh,inst.count)
  g.pop();local data=c:newImageData();local value=hash(data:getString());data:release();c:release();return value
 end
 local results={}
 for _,n in ipairs{768,6000,19998}do for _,indexed in ipairs{false,true}do
  local vertices,indices={},{}
  for i=1,n do
   local corner=(i-1)%3
   vertices[i]={20+(corner==1 and 12 or 0),20+(corner==2 and 12 or 0),0,0,0,1}
   indices[i]=i
  end
  local original=assert(G.newMesh(vertices,indexed and indices or nil))
  local expectedVertex,expectedIndex=digest(original)
  local state,receipt={map={}},{ }
  local row={vertices=n,indexed=indexed}
  for _,case in ipairs{{'before',baseline},{'after',current}}do
   local B=case[2];B.clear();local enumerations=0
   local function each(_,visit)
    enumerations=enumerations+1
    for i=1,5 do visit(original,nil,{1,0,0,i*30,0,1,0,i*20,0,0,1,0,0,0,0,1},1)end
   end
   local steps,maxMs,total=0,0,0
   repeat
    B.beginFrame(false);local t=love.timer.getTime()
    local ready=B.prewarm(state,each,.0005,receipt)
    local ms=(love.timer.getTime()-t)*1000;steps=steps+1;total=total+ms;maxMs=math.max(maxMs,ms)
    assert(steps<10000 and not B.lastError,B.lastError or 'timeout')
    if ready then break end
   until false
   local captures={}
   for _,pass in ipairs{'color','shadow'}do
    B.draw(state,each,function(bundle)
     assert(bundle.__voxelMeshBundle and #bundle.instances==1)
     local inst=bundle.instances[1];assert(inst.count==5)
     local vh,ih=digest(inst.mesh);assert(vh==expectedVertex and ih==expectedIndex,'geometry changed')
     captures[pass]=pixels(bundle);return true
    end,pass)
   end
   row[case[1]]={steps=steps,maxMs=maxMs,totalMs=total,enumerations=enumerations-2,pixels=captures}
   B.clear()
  end
  assert(row.before.pixels.color==row.after.pixels.color and row.before.pixels.shadow==row.after.pixels.shadow,'render changed')
  assert(row.after.enumerations==1,'repeated immutable discovery')
  results[#results+1]=row;original:release()
  print('PROP_PAIR',n,indexed,row.before.maxMs,row.after.maxMs,row.before.totalMs,row.after.totalMs)
 end end
 shader:release()
 local f=assert(io.open(dir..'/prop-pairs.json','w'));f:write(require('src.link.Json').encode(results));f:close()
 print('PASS_PROP_UPLOAD',#results);love.event.quit(0)
end
