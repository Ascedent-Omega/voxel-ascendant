io.stdout:setvbuf('no')
function love.load()
 local ok,err=xpcall(function()
  local engine=assert(os.getenv('KASC_ENGINE'));local vasc=assert(os.getenv('HOENN_VASC_ROOT'));local kasc=assert(os.getenv('HOENN_KASC_ROOT'));local out=assert(os.getenv('HOENN_ART_OUTPUT'))
  package.path=engine..'/?.lua;'..package.path
  -- Test-only loader for absolute worktree paths, outside LÖVE's mount root.
  local function fileData(path)
   if type(path)=='string' and path:sub(1,1)=='/'then
    local f=assert(io.open(path,'rb'));local bytes=f:read('*a');f:close()
    return love.filesystem.newFileData(bytes,'sprite.png')
   end
   return path
  end
  local image,imageData=love.graphics.newImage,love.image.newImageData
  love.graphics.newImage=function(path,...)return image(fileData(path),...)end
  love.image.newImageData=function(path,...)return imageData(fileData(path),...)end
  local Renderer=require('src.render.SpriteRenderer');local g=love.graphics;g.setDefaultFilter('nearest','nearest')
  local prefix=vasc..'/integrated/ascendant_pokemon_overworld/assets/characters/'
  local stem='hoenn-visitor-kasc-hd-4x3-walk-sheet-v1.png'
  local styles={{'Gen 1',kasc..'/assets/characters/hoenn_visitor_walk.png'},
   {'HD',prefix..'runtime/npcs/'..stem,prefix..'npcs/'..stem},
   {'Voxel',prefix..'runtime/voxel-npcs/'..stem,prefix..'voxel-npcs/'..stem},
   {'Cobble Human',prefix..'runtime/cobble-npcs/'..stem,prefix..'cobble-npcs/'..stem}}
  local canvas=g.newCanvas(800,340);g.push('all');g.setCanvas(canvas);g.clear(.84,.89,.83,1);g.setColor(1,1,1,1)
  g.setFont(g.newFont(19));local draws=0
  for index,style in ipairs(styles)do
   local def={id='SPRITE_KA_HOENN_VISITOR',image=style[2],frames=6,walker=true,trueColor=index~=1}
   local sprite=Renderer.new(def);sprite.image:setFilter('nearest','nearest')
   for _,dir in ipairs({'down','left','up','right'})do for _,walk in ipairs({0,1})do
    local probe=g.newCanvas(16,20);g.setCanvas(probe);g.clear(0,0,0,0);sprite:draw(0,4,0,0,dir,walk,false)
    g.setCanvas(canvas);local data=probe:newImageData();local opaque=0
    for y=0,19 do for x=0,15 do local r,b,c,a=data:getPixel(x,y);if a>.1 then opaque=opaque+1 end end end
    assert(opaque>30,'Empty native pose '..style[1]..dir);data:release();probe:release();draws=draws+1
   end end
   local x=(index-1)*200;g.setColor(.12,.16,.15,1);g.printf(style[1],x,20,200,'center');g.setColor(1,1,1,1)
   if index==1 then
    g.push();g.translate(x+36,108);g.scale(8,8);sprite:draw(0,4,0,0,'down',0,false);g.pop()
   else
    local atlas=g.newImage(style[3]);atlas:setFilter(index==3 and'nearest'or'linear',index==3 and'nearest'or'linear')
    local w,h=atlas:getDimensions();assert(w==576 and h==1024)
    for row=0,3 do for col=0,2 do
     local q=g.newQuad(col*192,row*256,192,256,w,h)
     local probe=g.newCanvas(192,256);g.setCanvas(probe);g.clear();g.draw(atlas,q);g.setCanvas(canvas)
     local pixels=probe:newImageData();local nonempty=false
     for yy=0,255,8 do for xx=0,191,8 do local _,_,_,a=pixels:getPixel(xx,yy);if a>.1 then nonempty=true end end end
     assert(nonempty,'Empty atlas pose');pixels:release();probe:release();draws=draws+1
    end end
    g.draw(atlas,g.newQuad(0,0,192,256,w,h),x+4,44)
   end
  end
  g.pop();local data=canvas:newImageData();local png=data:encode('png');local f=assert(io.open(out..'/hoenn-visitor-four-styles.png','wb'));f:write(png:getString());f:close()
  print('PASS LOVE GPU render:',draws,'poses; actual engine SpriteRenderer, native fallback and full atlases')
 end,debug.traceback)
 love.graphics.setCanvas();if not ok then print(err)end;love.event.quit(ok and 0 or 1)
end
