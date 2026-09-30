local g=love.graphics
local originalUpload=g.newImage
local savedAssets=package.loaded['src.render.Assets']
local rgba={1,1,1};local opening=3;local size=16;local partial=false
local Assets={}
function Assets.imageData(path)
 local d=love.image.newImageData(size,size)
 for y=2,13 do for x=2,13 do
  if x==2 or x==13 or y==2 or (y==13 and(x<7 or x>=7+opening)) then
   d:setPixel(x,y,rgba[1],rgba[2],rgba[3],1)
  end
 end end
 if partial then
  for y=3,12 do for x=3,12 do local a=({0,127/255,128/255,1})[(x+y)%4+1];d:setPixel(x,y,x/16,y/16,(x+y)/32,a)end end
 end
 return d,'sentinel',nil,'tail'
end
local originalData=Assets.imageData
package.loaded['src.render.Assets']=Assets
local Sources=assert(loadfile('lib/BattleImageSources.lua'))()
local Pics=assert(loadfile('lib/BattlePics.lua'))({require=function(n)assert(n=='BattleImageSources');return Sources end})
local reference=assert(loadfile(assert(os.getenv('QA_PERF_REFERENCE'))..'/lib/BattlePics.lua'))({})
-- Same upload seam as the host's native loader; foreign code is separately
-- exercised below and must not gain an immutable-source receipt.
local native=assert(loadstring([[
 return function(path,settings)
  path='assets/generated/battle/'..path
  local d,a,b,c=require('src.render.Assets').imageData(path)
  assert(a=='sentinel' and b==nil and c=='tail','asset returns changed')
  local img=love.graphics.newImage(d,settings)
  img:setFilter('nearest','nearest');d:release();return img,nil,'tail'
 end
]],'@src/battle/BattleState.lua'))()
local function bytes(img)
 local w,h=img:getDimensions();local c=g.newCanvas(w,h,{dpiscale=1})
 g.push('all');g.setCanvas(c);g.origin();g.setShader();g.setScissor();g.setDepthMode();g.setBlendMode('replace','premultiplied');g.setColor(1,1,1,1);g.clear(0,0,0,0);g.draw(img);g.pop()
 local d=c:newImageData();local s=d:getString();d:release();c:release();return s
end
local count=0
for _,sealed in ipairs{false,true}do
 for _,color in ipairs{{1,1,1},{.9,.6,.2},{0,0,0},{.17,.51,.83}}do
  for _,hole in ipairs{0,3,8}do
   rgba,opening=color,hole
   local img,empty,tail=Pics.capture(native,'sprite-'..hole)
   assert(empty==nil and tail=='tail','capture return values changed')
   assert(Sources.get(img),'native upload not captured')
   assert(g.newImage==originalUpload and Assets.imageData==originalData,'scope leaked')
   local before=Pics.readbacks
   assert(bytes(Pics.filled(img,sealed))==bytes(reference.filled(img,sealed)),'CPU sprite fill differs')
   assert(Pics.readbacks==before,'CPU source triggered GPU readback')
   local a,b,c,d=Pics.inkBounds(img,img);local e,f,h,i=reference.inkBounds(img,img)
   assert(a==e and b==f and c==h and d==i)
   count=count+1
  end
 end
end
assert(Pics.topologyBuilds==6 and Pics.topologyHits==18,'palette-independent topology not reused')
-- A changed fill rule must not reuse a mask computed for another threshold.
local drain=Sources.capture(native,'sprite-8');local threshold=Pics.DRAIN
Pics.DRAIN=20;reference.DRAIN=20
assert(bytes(Pics.filled(drain))==bytes(reference.filled(drain)))
Pics.DRAIN=threshold;reference.DRAIN=threshold
partial=true;local alpha=Sources.capture(native,'fractional-alpha');partial=false
assert(bytes(Pics.filled(alpha))==bytes(reference.filled(alpha)))
local beforeEdits= Pics.topologyBuilds
-- The same path can acquire different alpha, including an entirely blank pic.
opening=8;local altered=Sources.capture(native,'sprite-3');Pics.filled(altered)
assert(Pics.topologyBuilds==beforeEdits+1,'same-path alpha changes reused old fill mask')
local oldLoader=Assets.imageData
Assets.imageData=function()error('foreign loader must retain ownership')end
local ok=pcall(Sources.capture,native,'foreign');assert(not ok)
assert(g.newImage==originalUpload and Assets.imageData~=originalData)
Assets.imageData=oldLoader
-- Nested scopes preserve all values and restore both entry points on failure.
local sentinel={}
local ok,err=pcall(Sources.capture,function()
 Sources.capture(function()error(sentinel)end)
end)
assert(not ok and err==sentinel and g.newImage==originalUpload and Assets.imageData==originalData)
-- Unknown producers, DPI-rescaled Images, and existing GPU-only Images must
-- fall back. Source snapshots must never cache a changing Canvas.
local custom=Sources.capture(function()
 local d=Assets.imageData('custom');local img=g.newImage(d);d:release();return img
end)
assert(Sources.get(custom)==nil)
local before=Pics.readbacks;Pics.filled(custom);assert(Pics.readbacks==before+1)
local scaled=Sources.capture(native,'scaled',{dpiscale=2});assert(not Sources.get(scaled))
-- Capture failures are optional; successful uploads still return their Image.
local data=Assets.imageData('manual');local image=g.newImage(data);data:release();assert(not Sources.get(image))
-- Receipts copy bytes at upload and keep neither ImageData nor Image alive.
local weak=setmetatable({},{__mode='v'})
local function disposable()local img=Sources.capture(native,'ephemeral');weak[1]=img;weak[2]=Sources.get(img)end
disposable()
for i=1,4 do collectgarbage('collect')end
assert(not weak[1] and not weak[2],tostring(weak[1])..' '..tostring(weak[2]))
-- Snapshot residency is bounded and eviction only restores the exact fallback.
local resident={}
for i=1,129 do resident[i]=Sources.capture(native,'resident-'..i)end
assert(Sources.get(resident[1])==nil and Sources.get(resident[129]))
before=Pics.readbacks
assert(bytes(Pics.filled(resident[1]))==bytes(reference.filled(resident[1])))
assert(Pics.readbacks==before+1,'evicted source did not use readback fallback')
size=256;local large={}
for i=1,17 do large[i]=Sources.capture(native,'large-'..i)end
size=16
assert(not Sources.get(large[1]) and Sources.get(large[17]),'4 MiB receipt budget not enforced')
-- Foreign hooks installed inside the call retain ownership, and any saved
-- observer delegates inertly after the scope ends.
local retainedData,retainedUpload
local foreignUpload=function(...)return originalUpload(...)end
Sources.capture(function()
 retainedData,retainedUpload=Assets.imageData,g.newImage
 g.newImage=foreignUpload
end)
assert(g.newImage==foreignUpload and Assets.imageData==originalData)
g.newImage=originalUpload
local lateData=retainedData('late');local late=retainedUpload(lateData);lateData:release()
assert(not Sources.get(late),'inactive observer recorded a foreign upload')
local gamma=g.isGammaCorrect;g.isGammaCorrect=function()return true end
local gammaImage=Sources.capture(native,'gamma');g.isGammaCorrect=gamma
assert(not Sources.get(gammaImage),'gamma path certified without an exact color proof')
-- Scoped calls without an upload need no transient receipt tables.
local function noImage(a,b)return a,nil,b end
for i=1,2000 do assert(Sources.capture(noImage,1,2)==1)end
collectgarbage('collect');collectgarbage('stop');local heap=collectgarbage('count')
local start=love.timer.getTime()
for i=1,10000 do assert(Sources.capture(noImage,1,2)==1)end
local elapsed=love.timer.getTime()-start;local delta=collectgarbage('count')-heap
collectgarbage('restart');assert(delta<2,'empty source scopes allocate each frame')
print('PASS 10000 empty capture scopes',delta,'KiB',elapsed,'seconds')
Pics.invalidate();assert(Sources.get(altered)==nil)
package.loaded['src.render.Assets']=savedAssets
print('PASS',count,'exact CPU/GPU sprite fills, 6 shared source masks, same-path alpha invalidation, scoped errors/nesting/returns, foreign/DPI fallback and weak lifetime')
