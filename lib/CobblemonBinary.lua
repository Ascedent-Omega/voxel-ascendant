-- Data-only accelerator for the hash-verified prepared model records. The
-- caller verifies the complete blob against the package manifest first.
local M={}
local formats={}
for n=1,128 do formats[n]='<'..string.rep('d',n)end
function M.decode(blob,sourceHash,null,checkpoint)
 local function decode()
  assert(type(blob)=='string'and #blob>=41 and #blob<=8*1024*1024,'binary length')
  assert(blob:sub(1,4)=='CMB1','binary version')
  local d=assert(love and love.data)
  local size=d.unpack('<I4',blob,5)
  assert(size>0 and size<=32*1024*1024,'decoded length')
  assert(d.encode('string','hex',blob:sub(9,40))==sourceHash,'source hash')
  local raw=d.decompress('string','zlib',blob:sub(41))
  assert(#raw==size,'decoded length mismatch')
  -- Account for the decoded tree while constructing it. Numeric vectors can
  -- charge all their slots at once, avoiding a second recursive model walk.
  local at,nodes,bytes,nullSeen=1,0,0,false
  local function need(n)assert(n>=0 and at+n-1<=size,'truncated binary')end
  local function count()
   need(4);local n=d.unpack('<I4',raw,at);at=at+4
   assert(n<=1000000,'element count');return n
  end
  local function finite(n)assert(n==n and n~=math.huge and n~=-math.huge,'nonfinite number');return n end
  local value
  value=function(depth)
   assert(depth<=64,'binary depth');nodes=nodes+1;assert(nodes<=2000000,'binary nodes')
   if checkpoint and nodes%128==0 then checkpoint()end
   need(1);local tag=raw:sub(at,at);at=at+1
   if tag=='n' then
    if type(null)=='table'and not nullSeen then bytes=bytes+128;nullSeen=true end
    return null
   end
   if tag=='t' then return true end
   if tag=='f' then return false end
   if tag=='d' then need(8);local n=d.unpack('<d',raw,at);at=at+8;return finite(n)end
   if tag=='s' then local n=count();need(n);local s=raw:sub(at,at+n-1);at=at+n;bytes=bytes+n+24;return s end
   local n=count();local out={}
   bytes=bytes+128+48*n
   if tag=='v' then
    need(n*8)
    for base=1,n,128 do
     if checkpoint then checkpoint()end
     local len=math.min(128,n-base+1);local row={d.unpack(formats[len],raw,at)};at=at+len*8
     for i=1,len do out[base+i-1]=finite(row[i])end
    end
   elseif tag=='a' then
    need(n);for i=1,n do out[i]=value(depth+1)end
   elseif tag=='o' then
    need(n*2)
    for _=1,n do
     local key=value(depth+1);assert(type(key)=='string'and out[key]==nil,'object key')
     out[key]=value(depth+1)
    end
   else error('binary tag')end
   return out
  end
  local out=value(0);assert(at==size+1,'trailing binary');assert(type(out)=='table','model record');return out,bytes
 end
 local ok,result,bytes=pcall(decode)
 if ok then return result,bytes end
 return nil,tostring(result)
end
return M
