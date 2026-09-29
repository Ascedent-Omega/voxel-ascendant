-- Disposable, versioned irradiance pixels. Fixed slots bound disk use.
-- Called only under loading cover: readback/compression never runs in play.
local V=...
local C={hits=0,writes=0,misses=0,errors=0,SLOTS=16,MAX_BYTES=16*1024*1024}
local stamp
local workers={}
local workerSource,threadApi
local function workerAvailable()
 if workerSource==nil then
  local ok,value=pcall(function()
   local api=love.thread;assert(api and api.newThread and api.newChannel)
   local source=V.mod:read('lib/StaticLightCacheWorker.lua');assert(type(source)=='string')
   threadApi=api;return source
  end)
  workerSource=ok and value or false
 end
 return workerSource~=false
end
local function reap()
 local count=0
 for worker in pairs(workers)do
  if worker.thread:isRunning()then count=count+1 else workers[worker]=nil end
 end
 return count
end
local function api()
 local d=love and love.data;local fs=V.mod and V.mod.cache
 if d and d.hash and d.compress and d.decompress and fs and fs.read and fs.write and fs.info then return d,fs end
end
local function hash(d,s)return (d.hash('sha256',s):gsub('.',function(c)return('%02x'):format(c:byte())end))end
function C.key(signature)
 local d=api();if not d then return end
 if not stamp then
  local parts={'static-light-field-v1'}
  for _,name in ipairs{'StaticLightField','StaticLightDiskCache','StaticLightCacheWorker','LocalLightGrid','LightVisibility','LocalLights'}do
   local s=V.mod:read('lib/'..name..'.lua');if not s then return end;parts[#parts+1]=hash(d,s)
  end
  stamp=hash(d,table.concat(parts))
 end
 return hash(d,stamp..signature)
end
local function path(key)return 'static-light-v1/slot-'..(tonumber(key:sub(1,8),16)%C.SLOTS)..'.bin'end
function C.read(key,width,height)
 if not key then return end
 local d,fs=api();local expected=width*height*4
 if not d or expected>C.MAX_BYTES then return end
 local ok,result=pcall(function()
  local info=fs:info(path(key));if not info or info.size>C.MAX_BYTES+1024 or info.size<152 then return end
  local bytes=fs:read(path(key));if not bytes then return end
  local header=('SLF1%s%08x%08x'):format(key,width,height)
  if bytes:sub(1,84)~=header then return end
  -- Check the LZ4 declared output length before native decompression.
  local packed=bytes:sub(149)
  if #packed<4 then return end
  local a,b,c,e=packed:byte(1,4)
  if a+b*256+c*65536+e*16777216~=expected then return end
  local raw=d.decompress('string','lz4',packed)
  if #raw~=expected or hash(d,raw)~=bytes:sub(85,148)then return end
  local pixels=love.image.newImageData(width,height,'rgba8',raw)
  local image=love.graphics.newImage(pixels);pixels:release();image:setFilter('linear','linear')
  return image
 end)
 if not ok then C.errors=C.errors+1 elseif result then C.hits=C.hits+1;return result end
 C.misses=C.misses+1
end
-- Runtime cache reads validate/decompress on the same bounded worker path.
-- The synchronous reader above is kept for offline tools only.
function C.beginRead(key,width,height)
 if not key or width*height*4>C.MAX_BYTES or not api() or not workerAvailable() or reap()>=2 then return end
 return {key=key,width=width,height=height,phase='read'}
end
function C.stepRead(task)
 if task.done then return true end
 local ok,image=pcall(function()
  local _,fs=api();assert(fs,'cache unavailable')
  if task.phase=='read' then
   local info=fs:info(path(task.key))
   if not info or info.size>C.MAX_BYTES+1024 or info.size<152 then task.done=true;return end
   local bytes=fs:read(path(task.key))
   if type(bytes)~='string' or #bytes~=info.size or bytes:sub(1,84)~=('SLF1%s%08x%08x'):format(task.key,task.width,task.height)then task.done=true;return end
   if reap()>=2 then task.done=true;return end
   local worker={thread=threadApi.newThread(workerSource),channel=threadApi.newChannel()}
   worker.thread:start(bytes:sub(85),worker.channel,'read',task.width*task.height*4)
   workers[worker]=true;task.worker=worker;task.phase='worker'
  elseif task.phase=='worker' then
   local worker=task.worker;local raw=worker.channel:pop()
   if raw~=nil then
    task.worker=nil;reap()
    if type(raw)~='string' or #raw~=task.width*task.height*4 then task.done=true;return end
    task.raw=raw;task.phase='upload'
   elseif not worker.thread:isRunning()then error('cache worker exited without data')end
  elseif task.phase=='upload' then
   local pixels=love.image.newImageData(task.width,task.height,'rgba8',task.raw)
   local made,value=pcall(love.graphics.newImage,pixels);pixels:release();assert(made,value)
   value:setFilter('linear','linear');task.raw=nil;task.done=true;return value
  end
 end)
 if not ok then C.errors=C.errors+1;C.lastError=tostring(image);C.cancelWrite(task);image=nil end
 if task.done then
  task.worker,task.raw=nil,nil
  if image then C.hits=C.hits+1 else C.misses=C.misses+1 end
 end
 return task.done==true,image
end
-- Read a bounded strip per covered frame. Deferring the first readback also
-- separates the final bake commands from their GPU synchronization point.
function C.beginWrite(key,canvas)
 if not key or not api() or not workerAvailable() or reap()>=2 then return end
 local width,height=canvas:getDimensions()
 if width*height*4>C.MAX_BYTES then return end
 return {key=key,canvas=canvas,width=width,height=height,y=0,parts={},phase='defer'}
end
function C.cancelWrite(task)
 if task then task.canvas,task.parts,task.raw,task.bytes,task.worker=nil,nil,nil,nil,nil;task.done=true end
end
function C.stepWrite(task)
 if not task or task.done then return true end
 local phase=task.phase
 local start=love.timer.getTime()
 local ok,err=pcall(function()
  local d,fs=api();assert(d,'cache unavailable')
  if phase=='defer' then task.phase='readback'
  elseif phase=='readback' then
   local rows=math.min(task.height-task.y,math.max(1,math.floor(512*1024/(task.width*4))))
   local pixels=task.canvas:newImageData(1,1,0,task.y,task.width,rows)
   local copied,raw=pcall(pixels.getString,pixels);pixels:release();assert(copied,raw)
   task.parts[#task.parts+1]=raw;task.y=task.y+rows
   if task.y==task.height then task.canvas=nil;task.phase='assemble' end
  elseif phase=='assemble' then
   assert(reap()<2,'cache workers busy')
   local worker={thread=threadApi.newThread(workerSource),channel=threadApi.newChannel()}
   worker.thread:start(task.parts,worker.channel)
   workers[worker]=true;task.worker=worker;task.parts=nil;task.phase='worker'
  elseif phase=='worker' then
   local worker=task.worker;local result=worker.channel:pop()
   if result~=nil then
    assert(type(result)=='string','cache worker failed')
    task.bytes=('SLF1%s%08x%08x'):format(task.key,task.width,task.height)..result
    assert(#task.bytes<=C.MAX_BYTES+1024,'cache entry too large')
    task.worker=nil;task.phase='write';reap()
   elseif not worker.thread:isRunning()then error('cache worker exited without data') end
  elseif phase=='write' then
   assert(fs:write(path(task.key),task.bytes)~=false,'cache write failed')
   C.writes=C.writes+1;C.cancelWrite(task)
  end
 end)
 C.stageMaxMs=C.stageMaxMs or {}
 C.stageMaxMs[phase]=math.max(C.stageMaxMs[phase]or 0,(love.timer.getTime()-start)*1000)
 if not ok then C.errors=C.errors+1;C.lastError=tostring(err);C.cancelWrite(task) end
 return task.done==true
end
return C
