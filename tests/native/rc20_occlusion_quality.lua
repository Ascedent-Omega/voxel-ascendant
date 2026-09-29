return function(game)
 assert(os.getenv('POKEPORT_IDENTITY')=='vasc-video-polish-qa');love.audio.setVolume(0)
 local root=assert(os.getenv('QA_VASC_ROOT'));local O=assert(loadfile(root..'/lib/PropOcclusion.lua'))()
 local M=assert(loadfile(root..'/lib/Mat4.lua'))();local g=love.graphics
 local shader=g.newShader([[vec4 effect(vec4 c,Image t,vec2 uv,vec2 sc){return c;}]],[[uniform mat4 vp;vec4 position(mat4 ignored,vec4 p){return vp*p;}]])
 local I=M.identity();local out=g.newCanvas(160,120);local entries,solids,bounds={},{},{}
 local triangles={1,2,3,1,3,4,5,8,7,5,7,6,1,5,6,1,6,2,4,3,7,4,7,8,1,4,8,1,8,5,2,6,7,2,7,3}
 local function box(b,color,occluder)
  local x,y,z,X,Y,Z=unpack(b)
  local vertices={}
  for _,p in ipairs{{x,y,z},{X,y,z},{X,Y,z},{x,Y,z},{x,y,Z},{X,y,Z},{X,Y,Z},{x,Y,Z}}do
   vertices[#vertices+1]={p[1],p[2],p[3],color[1],color[2],color[3],1}
  end
  local mesh=g.newMesh({{'VertexPosition','float',3},{'VertexColor','float',4}},vertices,'triangles','static');mesh:setVertexMap(triangles)
  entries[#entries+1]={mesh,nil,I};bounds[mesh]=b;if occluder then solids[mesh]={b}end
 end
 box({-18,0,10,-3,25,11},{.4,.5,.6},true);box({3,0,10,18,25,11},{.6,.5,.4},true)
 box({-18,25,10,18,28,11},{.4,.4,.4},true)
 for z=16,48,8 do for x=-24,24,6 do box({x,1,z,x+2,8,z+2},{(x+25)/52,.7,z/50})end end
 local hiddenCount=0
 local function render(eye,enabled)
  local vp=M.mul(M.perspective(math.pi/3,160/120,.1,200),M.lookAt(eye,{0,12,24},{0,1,0}))
  O.enabled=enabled;local faces=O.faces(entries,function(mesh)return solids[mesh]end,eye,0)
  g.push('all');g.origin();g.setScissor();g.setCanvas({out,depth=true});g.clear(.1,.1,.1,1,true,true);g.setDepthMode('lequal',true);g.setMeshCullMode('none');g.setBlendMode('replace');g.setColor(1,1,1,1);g.setShader(shader);shader:send('vp','row',vp)
  for _,p in ipairs(entries)do
   if O.hidden(bounds[p[1]],I,faces,eye)then hiddenCount=hiddenCount+1 else g.draw(p[1])end
  end
  g.pop();return out:newImageData()
 end
 for i=0,31 do
  local a=i/32*math.pi*2;local eye={math.sin(a)*40,5+i%4*8,24-math.cos(a)*40}
  local reference=render(eye,false);local actual=render(eye,true)
  assert(reference:getString()==actual:getString(),'occlusion changed rendered pixels at view '..i)
  reference:release();actual:release()
 end
 assert(hiddenCount>0,'fixture never culled')
 print('PASS_OCCLUSION_PIXELS',32,'views',hiddenCount,'hidden draws')
 for _,p in ipairs(entries)do p[1]:release()end
 local ex=assert(game.mods.exports.VOXEL_ASCENDANT)
 local function find(fn,name,seen)
  if type(fn)~='function'then return end;seen=seen or{};if seen[fn]then return end;seen[fn]=true
  for i=1,100 do local k,v=debug.getupvalue(fn,i);if not k then break end;if k==name then return v end end
  for i=1,100 do local k,v=debug.getupvalue(fn,i);if not k then break end;local result=find(v,name,seen);if result then return result end end
 end
 local V=assert(find(ex.lib.require('VoxelScene').render,'V'));local P=V.require('VoxelItems')
 local D=V.require('DistantProps');local kinds={} 
 for kind,model in pairs(P.models)do if D.model(model)then kinds[#kinds+1]=kind end end
 table.sort(kinds);local checked=0
 for _,kind in ipairs(kinds)do
  local mesh=P.resolveKind(kind);local low=mesh and P.distant(mesh)
  if low then
   local b=P.bounds(mesh);local center={(b[1]+b[4])*.5,(b[2]+b[5])*.5,(b[3]+b[6])*.5}
   local span=math.max(b[4]-b[1],b[5]-b[2],b[6]-b[3])
   for i=0,7 do
    local a=i/8*math.pi*2;local eye={center[1]+math.sin(a)*span*2,center[2]+span,center[3]+math.cos(a)*span*2}
    local vp=M.mul(M.perspective(math.pi/3,160/120,.1,5000),M.lookAt(eye,center,{0,1,0}))
    local function silhouette(body)
     g.push('all');g.origin();g.setCanvas({out,depth=true});g.clear(0,0,0,1,true,true);g.setDepthMode('lequal',true);g.setMeshCullMode('none');g.setBlendMode('replace');g.setColor(1,1,1,1);g.setShader(shader);shader:send('vp','row',vp);g.draw(body);g.pop();return out:newImageData()
    end
    local reference=silhouette(mesh);local actual=silhouette(low)
    assert(reference:getString()==actual:getString(),'distant silhouette changed '..kind..' view '..i)
    reference:release();actual:release()
   end
   local far={center[1],center[2],center[3]+2000}
   local vp=M.mul(M.perspective(math.pi/3,160/120,.1,5000),M.lookAt(far,center,{0,1,0}))
   assert(D.use(b,I,far,vp,120),'far template never selected')
   checked=checked+1;if checked==8 then break end
  end
 end
 assert(checked>0,'no authored distant templates tested')
 print('PASS_DISTANT_SILHOUETTES',checked,'models, eight views each')
 out:release();shader:release();love.event.quit(0)
end
