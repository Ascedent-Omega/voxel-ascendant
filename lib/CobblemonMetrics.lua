-- Optional package-time pose measurements, bound to both the model hash and
-- the exact measuring algorithms. Stale/missing data simply uses live bounds.
local V=...
local M={}
M.sources={'gen2/lib/StadiumRig.lua','lib/CobblemonGeometry.lua','lib/CobblemonExpression.lua',
 'lib/CobblemonSize.lua','lib/CobblemonOverworldSize.lua'}
local raw,offsets,loaded
local function loadMetrics()
 loaded=true
 local ok=pcall(function()
  local d=assert(love and love.data);assert(d.unpack and d.hash and d.decode)
  local bytes=V.mod:read('assets/cobblemon-binary/metrics.bin')
  assert(type(bytes)=='string'and #bytes>=72 and #bytes<=512*1024 and bytes:sub(1,4)=='CMM1')
  local parts={}
  for _,path in ipairs(M.sources)do parts[#parts+1]=d.hash('sha256',assert(V.mod:read(path)))end
  assert(d.hash('sha256',table.concat(parts))==bytes:sub(5,36),'stale metrics')
  local body=bytes:sub(73)
  assert(d.hash('sha256',body)==bytes:sub(37,68),'metrics checksum')
  local n=d.unpack('<I4',bytes,69);assert(n<=4096 and #body==80*n)
  local index={}
  for at=73,#bytes,80 do
   local key=d.encode('string','hex',bytes:sub(at,at+31))
   assert(not index[key],'duplicate metrics');index[key]=at+32
  end
  raw,offsets=bytes,index
 end)
 if not ok then raw,offsets=nil,nil end
end
function M.get(hash)
 if not loaded then loadMetrics()end
 local at=offsets and offsets[hash];if not at then return nil end
 local a,b,c,d,e,f=love.data.unpack('<dddddd',raw,at)
 for _,n in ipairs{a,b,c,d,e,f}do if n~=n or n<0 or n>=1e6 then return nil end end
 if a<=0 or b<=0 or c<=0 or d<=0 then return nil end
 return {battleHeight=a,battleSpan=b,height=c,span=d,bodyHeight=e,bodySpan=f}
end
return M
