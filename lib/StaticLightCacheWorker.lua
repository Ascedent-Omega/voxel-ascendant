-- Bounded fixed local computation, no game state, graphics or filesystem.
require('love.data')
require('love.thread')
local parts,channel,mode,expected=...
local ok,bytes=pcall(function()
 if mode=='read' then
  assert(type(parts)=='string' and #parts<=16*1024*1024+940)
  assert(type(expected)=='number' and expected>0 and expected<=16*1024*1024)
  local packed=parts:sub(65);assert(#packed>=4)
  local a,b,c,d=packed:byte(1,4)
  assert(a+b*256+c*65536+d*16777216==expected,'invalid decompressed size')
  local raw=love.data.decompress('string','lz4',packed)
  assert(#raw==expected and love.data.encode('string','hex',love.data.hash('sha256',raw))==parts:sub(1,64),'invalid cache digest')
  return raw
 end
 assert(type(parts)=='table' and #parts<=256)
 local size=0
 for _,part in ipairs(parts)do
  assert(type(part)=='string');size=size+#part;assert(size<=16*1024*1024)
 end
 local raw=table.concat(parts)
 local digest=love.data.encode('string','hex',love.data.hash('sha256',raw))
 return digest..love.data.compress('string','lz4',raw)
end)
channel:push(ok and bytes or false)
