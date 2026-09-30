local root=assert(os.getenv('QA_PERF_REFERENCE'))
local old=assert(loadfile(root..'/lib/BattlePics.lua'))({})
local new=assert(loadfile('lib/BattlePics.lua'))({})
local g=love.graphics
local function bytes(img)
 local w,h=img:getDimensions();local c=g.newCanvas(w,h,{dpiscale=1})
 g.push('all');g.setCanvas(c);g.origin();g.setShader();g.setScissor();g.setDepthMode();g.setBlendMode('replace','premultiplied');g.setColor(1,1,1,1);g.clear(0,0,0,0);g.draw(img);g.pop()
 local d=c:newImageData();local s=d:getString();d:release();c:release();return s
end
local n=0
for _,sealed in ipairs{false,true}do
 for _,color in ipairs{{1,1,1},{.9,.6,.2},{0,0,0}}do
  for _,opening in ipairs{0,3,8}do
   local d=love.image.newImageData(16,16)
   for y=2,13 do for x=2,13 do
    local ink=x==2 or x==13 or y==2 or(y==13 and(x<7 or x>=7+opening))
    if ink then d:setPixel(x,y,color[1],color[2],color[3],1)end
   end end
   local image=g.newImage(d);image:setFilter('nearest','nearest');d:release()
   local expected=old.filled(image,sealed);local before=new.readbacks
   local actual=new.filled(image,sealed);assert(bytes(actual)==bytes(expected),'filled sprite changed')
   assert(new.readbacks==before+1,'unexpected fill read count')
   local count=new.readbacks
   for _,pic in ipairs{image,actual}do
    local a,b,c,e=new.inkBounds(pic,pic)
    local x,y,z,w=old.inkBounds(pic,pic)
    assert(a==x and b==y and c==z and e==w,'shared bounds changed')
    assert(new.inkBounds(pic)==a,'nil-identity bounds differ')
   end
   assert(new.readbacks==count,'bounds triggered duplicate readback')
   n=n+1
  end
 end
end
-- Reused canvases stay on identity/transient rules; source metadata cannot
-- freeze a grow-in frame or a second producer that uses another identity.
local canvas=g.newCanvas(8,8,{dpiscale=1})
local function content(x)
 g.setCanvas(canvas);g.clear(0,0,0,0);g.setColor(1,1,1,1);g.rectangle('fill',x,2,2,3);g.setCanvas()
end
content(1);local x=new.inkBounds(canvas,'sprite',true);assert(x==1)
content(4);x=new.inkBounds(canvas,'sprite',true);assert(x==4,'transient canvas frozen')
local before=new.readbacks;new.inkBounds(canvas,'other');assert(new.readbacks==before+1,'foreign identity reused')
local d=love.image.newImageData(4,4);local blank=g.newImage(d);d:release()
assert(new.filled(blank)==blank);local count=new.readbacks;assert(new.inkBounds(blank)==nil and new.readbacks==count)
new.invalidate();new.inkBounds(blank);assert(new.readbacks==count+1,'invalidate retained source receipt')
print('PASS',n,'pixel-identical sprite fills; shared bounds avoid duplicate readbacks; live canvases and invalidation preserved')
