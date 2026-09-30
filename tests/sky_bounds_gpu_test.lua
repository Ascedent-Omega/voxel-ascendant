local B=assert(loadfile('lib/SkyBounds.lua'))()
local f=assert(io.open('lib/Sky.lua'));local code=f:read('*a');f:close()
local source=assert(code:match('local SHADER_SRC = %[%[(.-)%]%]'))
local g=love.graphics;local shader=g.newShader(source)
local d=love.image.newImageData(4,1);for x=0,3 do d:setPixel(x,0,.1+x*.2,.2+x*.1,.5,1)end
local ramp=g.newImage(d);ramp:setFilter('nearest','nearest')
local w,h=97,73;local c=g.newCanvas(w,h,{dpiscale=1})
shader:send('ramp',ramp);shader:send('count',4);shader:send('edge',h);shader:send('top',0)
shader:send('cell',3);shader:send('start',.5);shader:send('alpha',1);shader:send('useRay',1)
shader:send('raySpan',1.3);shader:send('invSize',{1/w,1/h});shader:send('cellAng',.02);shader:send('glowAmt',0)
local function paint(ray,bounded)
 g.setCanvas(c);g.clear(.3,.2,.1,1);g.origin();g.setColor(1,1,1,1);g.setShader(shader)
 shader:send('rayBase',ray.base);shader:send('rayDu',ray.du);shader:send('rayDv',ray.dv)
 local y,n=0,h;if bounded then y,n=B.rows(h,ray)end
 if n>0 then g.rectangle('fill',0,y,w,n)end
 g.setShader();g.setCanvas();local pixels=c:newImageData();local bytes=pixels:getString();pixels:release();return bytes,n
end
local count,saved=0,0
for _,b in ipairs{-2,-.4,-.001,0,.001,.4,2}do
 for _,u in ipairs{-2,-.3,0,.3,2}do
  for _,v in ipairs{-3,-1,-1e-8,0,1e-8,1,3}do
   local ray={base={-.5,b,1},du={1,u,0},dv={0,v,.01}}
   local all=paint(ray,false);local cut,n=paint(ray,true)
   assert(all==cut,('sky mismatch b=%g u=%g v=%g'):format(b,u,v));count=count+1;saved=saved+h-n
  end
 end
end
assert(saved>0,'no fragment area saved')
local y,n=B.rows(h,{base={0,0/0,0},du={0,0,0},dv={0,0,0}});assert(y==0 and n==h)
print('PASS exact ray sky bounds',count,'GPU frames;',saved,'rows avoided')
