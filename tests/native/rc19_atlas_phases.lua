return function(game)
 assert(os.getenv('POKEPORT_IDENTITY')=='vasc-video-polish-qa')
 love.audio.setVolume(0);io.stdout:setvbuf('no')
 local ex=assert(game.mods.exports.VOXEL_ASCENDANT)
 local function find(fn,name,seen)
  if type(fn)~='function'then return end;seen=seen or{};if seen[fn]then return end;seen[fn]=true
  for i=1,100 do local k,v=debug.getupvalue(fn,i);if not k then break end;if k==name then return v end end
  for i=1,100 do local k,v=debug.getupvalue(fn,i);if not k then break end;local got=find(v,name,seen);if got then return got end end
 end
 local V=assert(find(ex.lib.require('VoxelScene').render,'V'))
 local T=V.require('TerrainAtlas');local R=require('src.render.TileRenderer')
 require('src.render.PaletteFX').mode='redpp'
 local Loader=require('src.world.MapLoader');Loader.invalidateAll()
 local f=assert(io.open(assert(os.getenv('QA_ATLAS_REFERENCE'))));local source=f:read('*a');f:close()
 local reference=assert(loadstring(source))(V)
 local frame=0;local clock=R.animFrame;R.animFrame=function()return frame end
 local function pixels(image)
  local w,h=image:getDimensions();local c=love.graphics.newCanvas(w,h)
  love.graphics.push('all');love.graphics.setCanvas(c);love.graphics.clear(0,0,0,0)
  love.graphics.setShader();love.graphics.setBlendMode('replace');love.graphics.setColor(1,1,1,1);love.graphics.draw(image)
  love.graphics.pop();local data=c:newImageData();c:release();local str=data:getString();data:release();return str
 end
 for _,id in ipairs{'SAFFRON_CITY','CELADON_CITY','CINNABAR_ISLAND'}do
  local map=Loader.load(game.data,id)
  assert(map.renderer.gbcAtlas)
  local warm=0
  while not T.prepared(map)and warm<40 do T.prepare(map);warm=warm+1 end
  assert(T.prepared(map),'prewarm incomplete '..id)
  local native=love.graphics.newImage;local creates=0
  love.graphics.newImage=function(...)creates=creates+1;return native(...)end
  local samples={}
  for i=0,31 do frame=i*20;samples[i+1]=pixels(T.forMap(map,nil))end
  love.graphics.newImage=native
  assert(creates==0,'animation uploaded after prewarm '..id..' '..creates)
  for i=0,31 do frame=i*20;assert(samples[i+1]==pixels(reference.forMap(map,nil)),'phase pixel mismatch '..id..' '..i)end
  print('PASS_ATLAS_PHASES',id,'preparationSteps',warm,'phases',32,'gameplayUploads',creates)
 end
 -- Resident bank cleanup releases every GPU phase and CPU scratch copy.
 local animated=find(T.animate,'animated');local handles={}
 for _,entry in pairs(animated)do if entry then for _,im in pairs(entry.frames)do handles[#handles+1]=im end end end
 T.invalidate()
 for _,im in ipairs(handles)do assert(not pcall(im.getWidth,im),'retained animation texture')end
 R.animFrame=clock
 print('PASS_ATLAS_RELEASE',#handles)
 love.event.quit()
end
