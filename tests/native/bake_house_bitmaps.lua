-- Offline derivative of validated packaged hybrid captures. No scene-building
-- or render-to-texture work runs on the player's device, including first launch.
return function(game)
 assert((os.getenv('POKEPORT_IDENTITY')or''):match('^vasc%-.*%-qa$'))
 io.stdout:setvbuf('no');love.audio.setVolume(0)
 local U=require('tests.drivers.util');game:startNewGame{intro=false}
 local function find(fn,name,seen)
  if type(fn)~='function'then return end;seen=seen or{};if seen[fn]then return end;seen[fn]=true
  for i=1,100 do local k,v=debug.getupvalue(fn,i);if not k then break end;if k==name then return v end end
  for i=1,100 do local k,v=debug.getupvalue(fn,i);if not k then break end;local r=find(v,name,seen);if r then return r end end
 end
 local ex=game.mods.exports.VOXEL_ASCENDANT;ex.setupCard.suspended=true
 local V=assert(find(ex.lib.require('VoxelScene').render,'V'))
 love.draw=function()end
 love.window.hasFocus=function()return true end;love.window.isVisible=function()return true end
 local C=V.require('RooftopCache');local W=V.require('WindowImageCache');local G=V.require('Voxel3D')
 local Mat=V.require('Mat4');local P=V.require('VoxelItems');local World=V.require('RooftopWorld');local g=love.graphics
 local output=assert(os.getenv('WINDOW_BITMAP_DIR'));assert(output:match('^[%w_/%-%.]+$'))
 local function write(path,bytes)local f=assert(io.open(output..'/'..path,'wb'));f:write(bytes);f:close()end
 local function serial(v)
  if type(v)=='string'then return string.format('%q',v)elseif type(v)~='table'then return tostring(v)end
  local keys={};for k in pairs(v)do keys[#keys+1]=k end;table.sort(keys,function(a,b)return tostring(a)<tostring(b)end)
  local rows={'{'};for _,k in ipairs(keys)do rows[#rows+1]='['..serial(k)..']='..serial(v[k])..','end;rows[#rows+1]='}';return table.concat(rows)
 end
 local sourcePath=os.getenv('WINDOW_BITMAP_SOURCE')
 local source=sourcePath and assert(loadfile(sourcePath))()or V.data('window_cache');local index={};local keys={}
 for key in pairs(source)do local id=key:match('^(.-)%-');if W.bitmapEligible({id=id})then keys[#keys+1]=key end end;table.sort(keys)
 local shader=g.newShader([[
  uniform int pass;
  uniform bool baked;
  uniform bool foliagePart;
  uniform bool snowPart;
  uniform bool litPart;
  uniform Image materials;
  varying float shade;
  varying float top;
  vec4 effect(vec4 c,Image image,vec2 uv,vec2 px){
   vec4 tex=Texel(image,uv);
   if(baked && tex.a<0.01) discard;
   if(pass==2){
    if(baked) return Texel(materials,uv);
    return vec4(snowPart?top:0.0,foliagePart?1.0:0.0,0.0,1.0);
   }
   if(pass==1) return vec4(litPart?vec3(baked?tex.r:1.0):vec3(0.0),baked?tex.a:1.0);
   return vec4(tex.rgb*shade,baked?tex.a:1.0);
  }
 ]],[[
  uniform mat4 vp;
  attribute float VertexShade;
  varying float shade;
  varying float top;
  vec4 position(mat4 t,vec4 p){top=step(1.5,VertexShade);shade=VertexShade-top*2.0;return vp*p;}
 ]])
 local size=W.BITMAP_SIZE
 local color=g.newCanvas(size,size,{format='rgba8',dpiscale=1,msaa=0})
 local depth=g.newCanvas(size,size,{format='depth24',readable=false,dpiscale=1,msaa=0})
 for n,key in ipairs(keys)do
  local old=source[key];local entry={w=old.width,h=old.depth}
  local near,far=assert(C.loadMeta)(entry,old,nil,{size=W.FACE_SIZE,eyeY=40,class='silph_exterior'})
  assert(near and far,'broken source '..key)
  local batches,parts={},{}
  for _,box in ipairs(near)do
   local x,y,z,w,h,d,c,lit,foliage=unpack(box)
   local k=(lit and 1 or 0)+(foliage and 2 or 0)+(c==8 and 4 or 0)
   local b=batches[k]
   if not b or #b.v>=6144 then b={v={},i={},lit=lit,foliage=foliage,snow=not lit and c~=8};parts[#parts+1]=b;batches[k]=b end
   for face,corners in ipairs(G.FACE_CORNERS)do
    local base=#b.v
    for _,p in ipairs(corners)do b.v[#b.v+1]={x+p[1]*w,y+p[2]*h,z+p[3]*d,(c-.5)/#P.palette,.5,G.FACE_SHADE[face]+(face==3 and 2 or 0)}end
    for _,j in ipairs{1,2,3,1,3,4}do b.i[#b.i+1]=base+j end
   end
  end
  for _,b in ipairs(parts)do b.mesh=assert(G.newMesh(b.v,b.i));b.mesh:setTexture(World.texture());b.v=nil;b.i=nil end
  local meta={revision=W.BITMAP_REVISION,size=size,width=old.width,depth=old.depth,signature=old.signature,
   configuration=old.configuration,maps=old.maps,path='assets/scenery/house-bitmaps/'..key,near=0,sourceNear=old.near,files={}}
  assert(os.execute("mkdir -p '"..output..'/'..key.."'")==0)
  write(key..'/near.bin',C.pack({}))
  local eye={entry.w/2,40,entry.h/2}
  for _,face in ipairs(C.faces)do
   local target={eye[1]+face.dir[1],eye[2]+face.dir[2],eye[3]+face.dir[3]}
   local vp=Mat.mul(Mat.scale(1,-1,1),Mat.mul(Mat.perspective(math.pi/2,1,1,16000),Mat.lookAt(eye,target,face.up)))
   for pass,layer in ipairs{'land','lights','materials'}do
    g.push('all');g.origin();g.setCanvas({color,depthstencil=depth});g.clear(0,0,0,0,0,1)
    g.setShader(shader);shader:send('vp','row',vp);shader:send('pass',pass-1)
    g.setMeshCullMode('none');g.setDepthMode('lequal',true);g.setBlendMode('replace');g.setColor(1,1,1,1)
    shader:send('baked',true)
    -- Base land writes depth/black in the light pass; light overlays then
    -- overwrite only genuinely illuminated pixels, preserving occlusion.
    for _,lights in ipairs{false,true}do for _,p in ipairs(far)do
     if p.windowLight==lights and (not lights or layer=='lights')then
      shader:send('litPart',lights)
      if p.materialMask then shader:send('materials',p.materialMask)end
      p.mesh:setTexture(p.texture);g.draw(p.mesh)
     end
    end end
    shader:send('baked',false)
    for _,b in ipairs(parts)do
     shader:send('litPart',b.lit==true);shader:send('foliagePart',b.foliage==true);shader:send('snowPart',b.snow==true);g.draw(b.mesh)
    end
    g.setCanvas();g.pop()
    local image=color:newImageData();local x0,y0,x1,y1=size,size,-1,-1;local pixels=0;local signal=false
    image:mapPixel(function(x,y,r,gg,b,a)
     if layer=='lights'and r<0.01 then a=0 end
     if a>0 then pixels=pixels+1;x0=math.min(x0,x);y0=math.min(y0,y);x1=math.max(x1,x);y1=math.max(y1,y);if r>0 or gg>0 or b>0 then signal=true end end
     return r,gg,b,a
    end)
    if layer=='materials'and meta.files[face.name..'-land']then local crop=meta.files[face.name..'-land'];x0,y0,x1,y1=crop.x+1,crop.y+1,crop.x+crop.w-2,crop.y+crop.h-2 end
    if pixels>0 and (layer~='lights'or signal)then
     x0,y0=math.max(0,x0-1),math.max(0,y0-1);x1,y1=math.min(size-1,x1+1),math.min(size-1,y1+1)
     local crop=love.image.newImageData(x1-x0+1,y1-y0+1);crop:paste(image,0,0,x0,y0,x1-x0+1,y1-y0+1)
     local encoded=crop:encode('png');local name=face.name..'-'..layer;write(key..'/'..name..'.png',encoded:getString());encoded:release();crop:release()
     meta.files[name]={x=x0,y=y0,w=x1-x0+1,h=y1-y0+1,pixels=pixels}
    end
    image:release();U.wait(1)
   end
  end
  for _,b in ipairs(parts)do b.mesh:release()end
  for _,p in ipairs(far)do p.mesh:release();p.texture:release();if p.materialMask then p.materialMask:release()end end
  index[key]=meta;write('index.lua','return '..serial(index)..'\n');collectgarbage('collect')
  print('BITMAP_READY',n,#keys,key,#near)
 end
 shader:release();color:release();depth:release();print('PASS_HOUSE_BITMAP_BAKE');love.event.quit()
end
