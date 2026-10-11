-- Authenticated source animations on KASC's exact imported atlas contract.
-- Native 8px TileRenderer streams feed a double-buffered GPU atlas; no pixel
-- readback, Image:replacePixels, extra shader sampler or per-frame table build.
-- Source flower/steam overlays use the existing thin scenery slab convention.
local V=...
local M={}
local R=require('src.render.TileRenderer')
local Assets=require('src.render.Assets')
local Raster=V.require('RasterResources')
local cache={}
local registeredSize=false
local function owner(map)
 local a=map and map.tileset and map.tileset.kaSeviiTileAnimations
 if a and a.schema=='kasc.sevii-tile-animation/v1'and a.counterMax==640
  and V.require('KascSeviiScenery').profile(map)then return a end
end
function M.active(map,kind)
 local a=owner(map);if not a then return false end
 if not kind then return true end
 for _,g in ipairs(a.groups)do if g.kind==kind then return true end end
 return false
end
local function counter()
 assert(type(R.animClock)=='function','Sevii animations require native TileRenderer.animClock')
 return math.floor(R.animClock())%640
end
local function index(stream,tick)return stream.sequence[tick%#stream.sequence+1]end
local function release(e)
 if not e then return end
 for _,c in ipairs(e.canvases)do Raster.changing(c);c:release()end
 for _,s in ipairs(e.surface)do s.batch:release()end
 for _,s in ipairs(e.background)do s.batch:release()end
 for _,s in ipairs(e.foreground)do if s.mesh then s.mesh:release()end end
end
local function paint(e,target,tick,base)
 local canvas=e.canvases[target]
 Raster.changing(canvas)
 local previous=love.graphics.getCanvas()
 love.graphics.push('all');love.graphics.setCanvas(canvas);love.graphics.setShader()
 love.graphics.origin();love.graphics.setScissor();love.graphics.setDepthMode()
 love.graphics.setColor(1,1,1,1);love.graphics.setBlendMode('replace','premultiplied')
 love.graphics.clear(0,0,0,0);love.graphics.draw(base,0,0)
 for _,s in ipairs(e.background)do love.graphics.draw(s.batch)end
 for _,s in ipairs(e.surface)do
  local n=index(s,tick);s.batch:setTexture(s.textures[n]);love.graphics.draw(s.batch)
  s.frame=n
 end
 love.graphics.setCanvas(previous);love.graphics.pop()
 e.current=target;e.paints=e.paints+1
end
local function slab(stream,placements)
 local mask={}
 for _,path in ipairs(stream.paths)do
  local data=Assets.imageData(path)
  assert(data:getWidth()==16 and data:getHeight()==16,'invalid Sevii scenery animation '..path)
  for y=0,15 do for x=0,15 do local _,_,_,a=data:getPixel(x,y)
   if a>0 then mask[y*16+x]=true end
  end end
 end
 local verts,indices={},{}
 local function face(corners,u,v,shade)
  local first=#verts
  for i=1,4 do local p=corners[i];verts[#verts+1]={p[1],p[2],p[3],u,v,shade}end
  indices[#indices+1]=first+1;indices[#indices+1]=first+2;indices[#indices+1]=first+3
  indices[#indices+1]=first+1;indices[#indices+1]=first+3;indices[#indices+1]=first+4
 end
 for _,p in ipairs(placements)do for y=0,15 do for x=0,15 do if mask[y*16+x]then
  local xa,xb=p.x+x,p.x+x+1;local yt,yb=p.h+16-y,p.h+15-y
  local zb,zf=p.z+7.5,p.z+8.5;local u,v=(x+.5)/16,(y+.5)/16
  -- Every pixel owns all six shell faces: a neighbour can disappear in the
  -- next frame. Sampling its own alpha keeps that moving boundary closed.
  face({{xa,yb,zf},{xb,yb,zf},{xb,yt,zf},{xa,yt,zf}},u,v,.90)
  face({{xb,yb,zb},{xa,yb,zb},{xa,yt,zb},{xb,yt,zb}},u,v,.68)
  face({{xa,yt-.01,zb},{xb,yt-.01,zb},{xb,yt-.01,zf},{xa,yt-.01,zf}},u,v,1)
  face({{xa,yb+.01,zf},{xb,yb+.01,zf},{xb,yb+.01,zb},{xa,yb+.01,zb}},u,v,.55)
  face({{xa+.01,yb,zb},{xa+.01,yb,zf},{xa+.01,yt,zf},{xa+.01,yt,zb}},u,v,.72)
  face({{xb-.01,yb,zf},{xb-.01,yb,zb},{xb-.01,yt,zb},{xb-.01,yt,zf}},u,v,.84)
 end end end end
 local mesh=V.require('Voxel3D').newMesh(verts,indices,true)
 assert(#verts==0 or mesh,'Sevii animation mesh upload failed map='..stream.map..' tile='..stream.tile)
 return mesh,#verts
end
function M.prepared(map)return not owner(map)or cache[map.id]~=nil end
function M.prepare(map)
 local a=owner(map);if not a or cache[map.id]then return true end
 local e={map=map,canvases={},surface={},foreground={},background={},current=1,paints=0,shadowRevision=0}
 local ts=map.tileset;local seen={};local tick=counter()
 for _,spec in ipairs(ts.animatedTiles)do
  local surface=false
  for _,kind in ipairs(spec.kaSeviiAnimationKinds)do if kind=='water'or kind=='sand'then surface=true end end
  if surface then
   local native=assert(map.renderer.claimedBy[spec.tile],'missing native Sevii stream map='..map.id..' tile='..spec.tile)
   local tiles=spec.tiles or native.tiles
   local batch=love.graphics.newSpriteBatch(native.textures[1],#tiles,'static')
   for _,tile in ipairs(tiles)do batch:add(tile%ts.tilesPerRow*8,math.floor(tile/ts.tilesPerRow)*8)end
   e.surface[#e.surface+1]={batch=batch,textures=native.textures,sequence=spec.sequence,frame=index(spec,tick)}
  end
 end
 local backgrounds={}
 for _,g in ipairs(a.groups)do if g.kind=='steam'then
  local path=assert(g.background,'missing Sevii steam background map='..map.id..' tile='..g.tiles[1])
  local s=backgrounds[path]
  if not s then s={image=Assets.image(path),tiles={}};backgrounds[path]=s end
  s.tiles[#s.tiles+1]=g.tiles[1]
 end end
 for _,s in pairs(backgrounds)do
  local batch=love.graphics.newSpriteBatch(s.image,#s.tiles,'static')
  for _,tile in ipairs(s.tiles)do batch:add(tile%ts.tilesPerRow*8,math.floor(tile/ts.tilesPerRow)*8)end
  e.background[#e.background+1]={batch=batch}
 end
 if #e.surface>0 or #e.background>0 then
  for i=1,(#e.surface>0 and 2 or 1)do
   local c=love.graphics.newCanvas(ts.imageWidth,ts.imageHeight,{dpiscale=1,format='rgba8'})
   c:setFilter('nearest','nearest');e.canvases[i]=Raster.seal(c)
  end
  paint(e,1,tick,map.renderer.image)
 end
 local byTile,streams={},{}
 for _,group in ipairs(a.groups)do if group.kind=='flower'or group.kind=='steam'then
  local key=group.kind..':'..table.concat(group.overlays,':')..':'..table.concat(group.sequence,',')
  local s=streams[key]
  if not s then
   s={map=map.id,tile=group.tiles[1],kind=group.kind,paths=group.overlays,
    sequence=group.sequence,textures={},placements={}}
   for _,path in ipairs(s.paths)do
    local image=Assets.image(path);assert(image,'missing Sevii overlay map='..map.id..' tile='..s.tile..' path='..path)
    image:setFilter('nearest','nearest');s.textures[#s.textures+1]=image
   end
   streams[key]=s;e.foreground[#e.foreground+1]=s
  end
  byTile[group.tiles[1]]={stream=s,tiles=group.tiles}
 end end
 for y=0,map.def.height*2-1 do for x=0,map.def.width*2-1 do
  local g=byTile[map:tileAt(x*2,y*2)]
  if g then
   assert(map:tileAt(x*2+1,y*2)==g.tiles[2]and map:tileAt(x*2,y*2+1)==g.tiles[3]
    and map:tileAt(x*2+1,y*2+1)==g.tiles[4],'Sevii source cell animation alignment '..map.id)
   local mesher=V.require('ChunkMesher')
   local h=mesher.surfaceAt(map,x*16+8,y*16+8)
   if h==nil then
    -- Vapour can originate on a blocked rock-top. Use the same resolved
    -- source shape and datum as that terrain, rather than burying it at 0.
    local shapes=V.require('TileShape')
    local shape=shapes.at(map,shapes.forMap(map),map:tileAt(x*2,y*2),x*2,y*2)
    local elevation=mesher.elevation(map)
    h=(shape and shape.h or 0)+(elevation and elevation:atTile(x*2,y*2)or 0)
   end
   g.stream.placements[#g.stream.placements+1]={x=x*16,z=y*16,h=h}
  end
 end end
 e.ownedBytes=#e.canvases*ts.imageWidth*ts.imageHeight*8
 for _,s in ipairs(e.foreground)do
  s.mesh,s.vertices=slab(s,s.placements);s.frame=index(s,tick)
  e.ownedBytes=e.ownedBytes+s.vertices*80
 end
 e.tick=tick;cache[map.id]=e
 if not registeredSize then
  V.require('WorldResidency').registerOwnedSize('sevii-source-animations',M.ownedBytes)
  registeredSize=true
 end
 return true
end
function M.update(map)
 local e=cache[map.id];if not e then return end
 local tick=counter();if tick==e.tick then return end
 local dirty=false
 for _,s in ipairs(e.surface)do if s.frame~=index(s,tick)then dirty=true;break end end
 if dirty then paint(e,3-e.current,tick,e.map.renderer.image)end
 for _,s in ipairs(e.foreground)do
  local frame=index(s,tick)
  if s.kind=='flower'and frame~=s.frame then e.shadowRevision=e.shadowRevision+1 end
  s.frame=frame
 end
 e.tick=tick
end
function M.atlas(map)
 if not owner(map)then return end
 local e=assert(cache[map.id],'unprepared Sevii animated atlas map='..map.id)
 return e.canvases[e.current]or map.renderer.image
end
function M.draw(map,model,pull,sunModel,shadow)
 local e=cache[map.id];if not e then return end
 for _,s in ipairs(e.foreground)do if s.mesh then
  local texture=s.textures[s.frame]
  if shadow then
   if s.kind=='flower'then V.require('ShadowMap').draw(s.mesh,texture,sunModel)end
  else V.require('Voxel3D').draw(s.mesh,texture,model,pull,sunModel)end
 end end
end
function M.receipt(map)return cache[map.id]end
function M.ownedBytes(id)local e=cache[id];return e and e.ownedBytes or 0 end
function M.shadowRevision(map)
 local e=cache[map.id]
 if e then for _,s in ipairs(e.foreground)do
  if s.kind=='flower'and s.mesh then return e.shadowRevision end
 end end
end
function M.setLive()
 local retained=V.require('WorldResidency').retained()
 for id,e in pairs(cache)do if not retained[id]then release(e);cache[id]=nil end end
end
function M.invalidate()for _,e in pairs(cache)do release(e)end;cache={}end
Assets.register(M.invalidate)
return M
