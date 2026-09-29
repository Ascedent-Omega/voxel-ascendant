return function(game)
 assert(os.getenv('POKEPORT_IDENTITY')=='vasc-video-polish-qa');love.audio.setVolume(0)
 local U=require('tests.drivers.util');local root=assert(os.getenv('QA_VASC_ROOT'))
 local files={};local reject=false
 local fs={write=function(_,p,b)if reject then return false end;files[p]=b;return true end,
  read=function(_,p)return files[p]end,info=function(_,p)return files[p]and{size=#files[p]}end}
 local V={mod={cache=fs,read=function(_,p)local f=assert(io.open(root..'/'..p));local s=f:read('*a');f:close();return s end}}
 local C=assert(loadfile(root..'/lib/StaticLightDiskCache.lua'))(V)
 local g=love.graphics;local c=g.newCanvas(1536,1703,{format='rgba8',dpiscale=1})
 g.push('all');g.setCanvas(c);g.clear(0,0,0,1);g.setShader();g.setBlendMode('replace')
 for y=0,1702 do g.setColor(y%7/6,y%13/12,y%19/18,1);g.rectangle('fill',0,y,1536,1)end
 g.pop();U.wait(1)
 local expected=c:newImageData();local raw=expected:getString();expected:release()
 local key=assert(C.key('native-staging'))
 local t=assert(C.beginWrite(key,c));assert(C.writes==0)
 local steps=0
 while not t.done do C.stepWrite(t);steps=steps+1;assert(steps<100);U.wait(1)end
 assert(C.writes==1 and C.errors==0,C.lastError)
 local reading=assert(C.beginRead(key,1536,1703));local image;local readMax=0
 while not reading.done do
  local start=love.timer.getTime();local done,value=C.stepRead(reading)
  readMax=math.max(readMax,(love.timer.getTime()-start)*1000);image=value or image;U.wait(1)
 end
 assert(image,'staged cache miss')
 local synchronous=assert(C.read(key,1536,1703));synchronous:release()
local copy=g.newCanvas(1536,1703,{format='rgba8',dpiscale=1})
 g.push('all');g.setCanvas(copy);g.setShader();g.origin();g.setColor(1,1,1,1);g.setBlendMode('replace');g.draw(image);g.pop()
 local actual=copy:newImageData();assert(actual:getString()==raw,'staged readback changed pixels');actual:release()
 assert(not C.read(key,1535,1703),'wrong dimensions accepted')
 local cancelled=C.beginWrite(key,c);C.stepWrite(cancelled);C.cancelWrite(cancelled)
 assert(C.stepWrite(cancelled) and C.writes==1 and not cancelled.canvas)
 local cachePath,validBytes=next(files)
 local function rejects(bytes)
  files[cachePath]=bytes;local r=assert(C.beginRead(key,1536,1703))
  for i=1,120 do local done,value=C.stepRead(r);assert(not value,'corrupt cache accepted');if done then return end;U.wait(1)end
  error('corrupt read stuck')
 end
 rejects(validBytes:sub(1,84)..string.rep('0',64)..validBytes:sub(149))
 rejects(validBytes:sub(1,148)..string.rep(string.char(255),4)..validBytes:sub(153))
 rejects(validBytes:sub(1,150))
 files[cachePath]=validBytes
 reject=true;t=C.beginWrite(key,c)
 while not C.stepWrite(t)do U.wait(1)end
 assert(C.errors==1 and C.writes==1 and not t.canvas and not t.raw and not t.bytes)
 print('PASS_STAGED_LIGHT_CACHE',steps,'pixel exact','max read step',readMax,require('src.link.Json').encode(C.stageMaxMs))
 c:release();copy:release();image:release();love.event.quit(0)
end
