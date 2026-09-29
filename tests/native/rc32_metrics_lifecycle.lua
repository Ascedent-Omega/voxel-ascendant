return function(game)
 assert(os.getenv('POKEPORT_IDENTITY')=='vasc-video-polish-qa');love.audio.setVolume(0);io.stdout:setvbuf('no')
 local root=assert(os.getenv('QA_VASC_ROOT'));local function read(p)local f=assert(io.open(root..'/'..p,'rb'));local b=f:read('*a');f:close();return b end
 local original=read('assets/cobblemon-binary/metrics.bin');local hash=love.data.encode('string','hex',original:sub(73,104))
 local source=assert(loadfile(root..'/lib/CobblemonMetrics.lua'))
 local reads,fault,blob=0,nil,original
 local V={mod={read=function(_,path)
  reads=reads+1
  if path=='assets/cobblemon-binary/metrics.bin'then
   if fault=='missing'then return end
   if fault=='throw'then error('QA read failure')end
   return blob
  end
  local raw=read(path);if fault=='stale'then return raw..'\n-- changed algorithm'end;return raw
 end}}
 local module=source(V);local first=assert(module.get(hash));local n=reads
 for i=1,100 do assert(module.get(hash).height==first.height)end;assert(reads==n,'repeat disk reads')
 assert(not module.get(string.rep('0',64)),'unknown hash has metrics')
 for _,case in ipairs{'missing','throw','stale'}do
  fault=case;local m=source(V);assert(not m.get(hash),case);local count=reads
  assert(not m.get(hash)and reads==count,'failure repeats IO '..case)
 end
 fault=nil
 local function reject(bytes)
  blob=bytes;local m=source(V);assert(not m.get(hash),'invalid metrics accepted')
 end
 for _,length in ipairs{0,3,40,71,72,#original-1}do reject(original:sub(1,length))end
 reject('BAD1'..original:sub(5));reject(original:sub(1,100)..'x'..original:sub(102))
 reject(original:sub(1,68)..love.data.pack('string','<I4',4097)..original:sub(73))
 -- Valid checksum but invalid first record values must not bypass live sizing.
 for _,value in ipairs{0,-1,math.huge,0/0}do
  local body=original:sub(73,104)..love.data.pack('string','<d',value)..original:sub(113)
  reject(original:sub(1,36)..love.data.hash('sha256',body)..original:sub(69,72)..body)
 end
 blob=original;assert(source(V).get(hash),'new loader did not recover')
 print('PASS_METRICS_LIFECYCLE');love.event.quit(0)
end
