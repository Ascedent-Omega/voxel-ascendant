-- Offline build driver. Requires an isolated QA identity and explicit output.
return function(game)
 io.stdout:setvbuf('no')
 assert((os.getenv('POKEPORT_IDENTITY')or''):match('^vasc%-.*%-qa$'))
 local output=assert(os.getenv('WINDOW_BAKE_DIR'));assert(output:match('^[%w%_/%-%.]+$'));local U=require('tests.drivers.util')
 game:startNewGame{intro=false}
 local exports=game.mods.exports.VOXEL_ASCENDANT
 local function find(fn,name,seen)
  if type(fn)~='function'then return end;seen=seen or{};if seen[fn]then return end;seen[fn]=true
  for i=1,200 do local k,v=debug.getupvalue(fn,i);if not k then break end;if k==name then return v end end
  for i=1,200 do local k,v=debug.getupvalue(fn,i);if not k then break end;local r=find(v,name,seen);if r then return r end end
 end
 local V=assert(find(exports.lib.require('VoxelScene').render,'V'))
 exports.setupCard.suspended=true
 love.draw=function()end
 love.window.hasFocus=function()return true end;love.window.isVisible=function()return true end
 local World=V.require('RooftopWorld');local Cache=V.require('RooftopCache');local P=V.require('VoxelItems')
 local G=V.require('Voxel3D');local Mat=V.require('Mat4');local g=love.graphics
 local Map=require('src.world.Map');local metadata={}
 local source=os.getenv('WINDOW_SOURCE');local suffix=os.getenv('WINDOW_SUFFIX')or''
 if source then
  game.data.maps=assert(loadfile(source..'/data/generated/maps.lua'))()
  game.data.tilesets=assert(loadfile(source..'/data/generated/tilesets.lua'))()
  V.require('WorldPlacement').invalidate();V.require('TileShape').invalidate()
  metadata={}
 end
 local function write(path,raw)local f=assert(io.open(output..'/'..path,'wb'));f:write(raw);f:close()end
 if os.getenv('WINDOW_RESUME')=='1'then
  local chunk=loadfile(output..'/index.lua')
  if chunk then metadata=chunk()end
 end
 local nextYield=love.timer.getTime()+.03
 local function yieldWork()
  if love.timer.getTime()>=nextYield then U.wait(1);nextYield=love.timer.getTime()+.03 end
 end
 local function serial(v)
  if type(v)=='string'then return string.format('%q',v)elseif type(v)=='number'or type(v)=='boolean'then return tostring(v)end
  local keys={};for k in pairs(v)do keys[#keys+1]=k end;table.sort(keys,function(a,b)return tostring(a)<tostring(b)end)
  local rows={'{'};for _,k in ipairs(keys)do rows[#rows+1]='['..serial(k)..']='..serial(v[k])..','end;rows[#rows+1]='}';return table.concat(rows)
 end
 local shader=g.newShader([[
  uniform bool maskPass;
  uniform bool materialPass;
  uniform bool foliagePart;
  uniform bool snowPart;
  uniform bool litPart;
  varying float shade;
  varying float top;
  vec4 effect(vec4 c, Image image, vec2 uv, vec2 px) {
   if (materialPass) return vec4(snowPart ? top : 0.0,foliagePart ? 1.0 : 0.0,0.0,1.0);
   if (maskPass) return litPart ? vec4(1.0) : vec4(0.0);
   return vec4(Texel(image,uv).rgb * shade,1.0);
  }
 ]],[[
  uniform mat4 vp;
  attribute float VertexShade;
  varying float shade;
  varying float top;
  vec4 position(mat4 t,vec4 p){top=step(1.5,VertexShade);shade=VertexShade-top*2.0;return vp*p;}
 ]])
 local Windows=V.require('SilphWindows');local WC=V.require('WindowImageCache')
 local size=WC.FACE_SIZE
 local idsToBake={}
 local filter=os.getenv('WINDOW_FILTER')
 for id,d in pairs(game.data.maps)do
  local map=Map.new(d,game.data.tilesets[d.tileset])
  if (not filter or id:match(filter)) and (Windows.floor(map)or V.require('HouseWindows').describe(map)) then idsToBake[#idsToBake+1]=id end
 end
 table.sort(idsToBake)
 print('BAKE_ROOM_COUNT',#idsToBake)
 local color=g.newCanvas(size,size,{format='rgba8',dpiscale=1,msaa=0})
 local depth=g.newCanvas(size,size,{format='depth24',readable=false,dpiscale=1,msaa=0})
 for _,style in ipairs({'stone','wood'})do
  V.require('Gen1LavenderTower').setting:setValue(style,game)
  for _,id in ipairs(idsToBake)do
   local start=love.timer.getTime();local d=game.data.maps[id];local map=Map.new(d,game.data.tilesets[d.tileset])
   local entry={map=map,w=d.width*32,h=d.height*32};local key=WC.key(entry)..suffix
   local old=metadata[key]
   local reuse=old and old.revision==WC.REVISION and old.size==size and old.width==entry.w and old.depth==entry.h
    and old.configuration==WC.configuration()and Cache.signature(game.data.maps,old.maps,game.data.tilesets)==old.signature
   if reuse then
    for _,name in ipairs({'near.bin'})do local f=io.open(output..'/'..key..'/'..name,'rb');if f then f:close()else reuse=false end end
    for name in pairs(old.files)do local f=io.open(output..'/'..key..'/'..name..'.png','rb');if f then f:close()else reuse=false end end
   end
   if reuse then print('BAKE_REUSED',key)else
   assert(key:match('^[%w_%-]+$'));assert(os.execute("mkdir -p '"..output..'/'..key.."'")==0)
   local batches,parts,near={}, {},{};local emitted=0
   local function emitPart(b,isNear)
    local x,y,z,w,h,dep,c,lit,foliage=unpack(b);emitted=emitted+1
    if isNear then near[#near+1]=b;return end
    local k=(lit and 1 or 0)+(foliage and 2 or 0)+(c==8 and 4 or 0);local batch=batches[k]
    if not batch or batch.count>=256 then batch={v={},i={},count=0,lit=lit,foliage=foliage,snow=not lit and c~=8};parts[#parts+1]=batch;batches[k]=batch end
    batch.count=batch.count+1
    for face,corners in ipairs(G.FACE_CORNERS)do
     local base=#batch.v
     for _,p in ipairs(corners)do batch.v[#batch.v+1]={x+p[1]*w,y+p[2]*h,z+p[3]*dep,(c-.5)/#P.palette,.5,G.FACE_SHADE[face]+(face==3 and 2 or 0)}end
     for _,j in ipairs({1,2,3,1,3,4})do batch.i[#batch.i+1]=base+j end
    end
   end
   Windows.geometry(entry,game.data.maps,function(...)Cache.partition(entry,{...},emitPart)end,yieldWork)
   for _,part in ipairs(parts)do part.mesh=assert(G.newMesh(part.v,part.i));part.mesh:setTexture(World.texture());part.v=nil;part.i=nil;yieldWork()end
   local ids={};for _,m in ipairs(World.maps(entry,game.data.maps))do ids[#ids+1]=m.id end
   local meta={revision=WC.REVISION,size=size,width=entry.w,depth=entry.h,configuration=WC.configuration(),path='assets/scenery/windows/'..key,signature=Cache.signature(game.data.maps,ids,game.data.tilesets),maps=ids,files={},near=#near,boxes=emitted,landmarks=World.last and World.last.landmarks}
   write(key..'/near.bin',Cache.pack(near))
   local eye={entry.w/2,40,entry.h/2}
   for _,face in ipairs(Cache.faces)do
    local target={eye[1]+face.dir[1],eye[2]+face.dir[2],eye[3]+face.dir[3]}
    local vp=Mat.mul(Mat.scale(1,-1,1),Mat.mul(Mat.perspective(math.pi/2,1,1,16000),Mat.lookAt(eye,target,face.up)))
    for _,layer in ipairs({'land','lights','materials'})do
     g.push('all');g.origin();g.setCanvas({color,depthstencil=depth});g.clear(0,0,0,0,0,1)
     g.setShader(shader);shader:send('vp','row',vp);shader:send('maskPass',layer=='lights');shader:send('materialPass',layer=='materials')
     g.setMeshCullMode('none');g.setDepthMode('lequal',true);g.setBlendMode('replace');g.setColor(1,1,1,1)
     for _,part in ipairs(parts)do shader:send('litPart',part.lit==true);shader:send('foliagePart',part.foliage==true);shader:send('snowPart',part.snow==true);g.draw(part.mesh)end
     g.setCanvas();g.pop()
     local image=color:newImageData();local nonzero=0;local x0,y0,x1,y1=size,size,-1,-1
     -- Full alpha inspection catches empty sky faces and keeps them absent.
     image:mapPixel(function(x,y,r,gg,b,a)if a>0 then nonzero=nonzero+1;x0=math.min(x0,x);x1=math.max(x1,x);y0=math.min(y0,y);y1=math.max(y1,y)end;return r,gg,b,a end)
     if layer=='materials' and meta.files[face.name..'-land'] then
      local crop=meta.files[face.name..'-land'];x0,y0,x1,y1=crop.x+1,crop.y+1,crop.x+crop.w-2,crop.y+crop.h-2
     end
     if nonzero>0 then
      x0,y0=math.max(0,x0-1),math.max(0,y0-1);x1,y1=math.min(size-1,x1+1),math.min(size-1,y1+1)
      local crop=love.image.newImageData(x1-x0+1,y1-y0+1);crop:paste(image,0,0,x0,y0,x1-x0+1,y1-y0+1)
      local name=face.name..'-'..layer;write(key..'/'..name..'.png',crop:encode('png'):getString());crop:release()
      meta.files[name]={x=x0,y=y0,w=x1-x0+1,h=y1-y0+1,pixels=nonzero}
     end
     print('BAKE_FACE',key,face.name,layer,nonzero);image:release();U.wait(1)
    end
   end
   metadata[key]=meta
   for _,part in ipairs(parts)do part.mesh:release()end
   collectgarbage('collect')
   print('BAKE_READY',key,#near,emitted,#parts,love.timer.getTime()-start,collectgarbage('count'))
   write('index.lua','return '..serial(metadata)..'\n')
   end
  end
 end
 shader:release();color:release();depth:release();print('PASS_WINDOW_BAKE');love.event.quit()
end
