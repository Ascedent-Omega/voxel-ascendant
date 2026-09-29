-- Exercise the actual height-field rasterizer and encoding with a clocked
-- ImageData stand-in. Cooperative and synchronous outputs must match exactly.
local clock,allocations,uploads=0,{},{}
love={timer={getTime=function()clock=clock+.00005;return clock end},image={},graphics={}}
function love.image.newImageData(w,h)
 local data={pixels={},w=w,h=h}
 function data:getPixel(x,y)clock=clock+.00001;local p=self.pixels[x..':'..y];return p and p[1]or 0,p and p[2]or 0 end
 function data:setPixel(x,y,r,g,b,a)self.pixels[x..':'..y]={r,g,b,a}end
 function data:release()assert(not self.released);self.released=true end
 allocations[#allocations+1]=data;return data
end
function love.graphics.newImage(data)
 assert(not data.released)
 local image={pixels=data.pixels}
 function image:setFilter()end
 function image:release()assert(not self.released);self.released=true end
 uploads[#uploads+1]=image;return image
end
local function create()
 local C=assert(loadfile('shared/WeatherCover.lua'))()
 local receipts={}
 C.provider=function(map)
  if receipts[map]then return end
  local f=C.begin(map,'props')
  for i=0,299 do
   local x,z=i%20*8,math.floor(i/20)*8
   f:add({{x,10,z},{x+8,18,z},{x+8,18,z+8},{x,10,z+8}})
  end
  f:publish();receipts[map]=true
 end
 return C
end
local map={def={width=5,height=5}},other
local state={map=map,neighbors={{map={def={width=5,height=5}},ox=160,oy=0}}}
local sync=create();sync.prepare(state,'rain');local expected=uploads[#uploads].pixels
local C=create();local n=#uploads;local frames=0
repeat
 local before=clock
 C.beginFrame(true);C.prepare(state,'rain');frames=frames+1
 assert(clock-before<.0025,'one slice exceeds the cooperative budget tolerance')
 local time=clock;C.prepare(state,'rain');assert(clock==time,'multiple view passes spend another budget')
 if #uploads==n then assert(C.pending(),'cold preparation releases cover')end
 assert(frames<1000,'preparation does not finish')
until #uploads>n
assert(frames>1 and not C.pending(),'preparation not sliced or reveal remains blocked')
local actual=uploads[#uploads].pixels
for k,p in pairs(expected)do local q=assert(actual[k],k);for i=1,4 do assert(p[i]==q[i],'encoding changed')end end
for k in pairs(actual)do assert(expected[k],'extra occlusion pixel')end
-- Same-map validation retains a complete usable image, never a partial mask.
C.beginFrame(false);C.prepare(state,'rain');assert(not C.pending())
-- A different neighborhood cannot inherit the old mask; cancel its unfinished
-- raster allocation explicitly when changing context or invalidating resources.
local nextState={map={def={width=5,height=5}}}
local oldImage=uploads[#uploads];local startAlloc=#allocations
repeat C.beginFrame(true);C.prepare(nextState,'snow')until #allocations>startAlloc
assert(oldImage.released and C.pending(),'old location image leaks into new location')
local abandoned=allocations[#allocations];assert(not abandoned.released)
C.invalidate();assert(abandoned.released and not C.pending(),'cancelled ImageData leaks')
C.beginFrame(true);C.prepare(state,'rain');C.prepare(state,'clear');assert(not C.pending()and not C.active,'dry weather retains job')
-- Resource errors fail open once, instead of retrying every frame indefinitely.
local fail=create();local calls=0
fail.provider=function()calls=calls+1;error('injected')end
for i=1,5 do fail.beginFrame(true);fail.prepare(state,'rain')end
assert(calls==1 and fail.lastError:find('injected')and not fail.pending())
fail.invalidate();fail.beginFrame(true);fail.prepare(state,'rain');assert(calls==2)
print('PASS weather cover: cooperative/synchronous pixel parity, one slice per frame, atomic reveal, context cancellation, dry mode and failure cleanup; '..frames..' slices')
