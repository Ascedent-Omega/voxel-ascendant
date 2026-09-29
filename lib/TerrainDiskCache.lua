-- Disposable installation-local CPU geometry. Fixed slots with an LRU index bound storage even
-- after interrupted writes; no executable cache, directory scan or save data.
local V=...
local B=V.require('BuildBudget')
local Digest=V.require('GeometryDigest')
local C={hits=0,misses=0,writes=0,rejected=0,errors=0,bypasses=0,MAX_BYTES=4*1024*1024,SLOTS=128}
local PREFIX='terrain-pages-v1/'
local index,sequence
local sourceStamp
local function api()
 local d=love and love.data;local fs=V.mod and V.mod.cache
 if d and d.hash and d.pack and d.unpack and fs and fs.read and fs.write and fs.info then return d,fs end
end
function C.available()return api()~=nil end
local function hash(d,s)
 if #s<1024*1024 and d.encode then return d.encode('string','hex',d.hash('sha256',s))end
 return assert(Digest.hex(d,s))
end
-- Sorted, scoped graph encoding. Shared templates are visited once. Separate
-- top-level fields have separate reference scopes, so warm helper caches do
-- not change keys merely by sharing tables between map/tileset/structure data.
local function signature(d,value)
 local out,seen,serial,bytes={},{},0,0
 local function add(s)bytes=bytes+#s;assert(bytes<=32*1024*1024,'input too large');out[#out+1]=s end
 local function numbers(values)
  if #values>0 then add(d.pack('string','<'..string.rep('d',#values),unpack(values)))end
 end
 local function visit(v)
  B.tick();local t=type(v)
  if t=='nil'then add('z')
  elseif t=='boolean'then add(v and't'or'f')
  elseif t=='string'then add('s'..#v..':'..v)
  elseif t=='number'then assert(v==v and math.abs(v)<math.huge);add('n'..d.pack('string','<d',v))
  elseif t=='table'then
   if seen[v]then add('r'..seen[v]..':');return end
   serial=serial+1;seen[v]=serial
   local keys={};local numericKeys=true;local numericValues=true
   for k,n in pairs(v)do
    assert(type(k)=='number'or type(k)=='string','unsupported key')
    keys[#keys+1]=k;numericKeys=numericKeys and type(k)=='number';numericValues=numericValues and type(n)=='number'
   end
   if numericKeys then table.sort(keys)
   else table.sort(keys,function(a,b)if type(a)~=type(b)then return type(a)<type(b)end;return a<b end)end
   if numericKeys then
    add((numericValues and 'v' or 'a')..#keys..':');local values={}
    for _,k in ipairs(keys)do
     assert(k==k and math.abs(k)<math.huge);values[#values+1]=k
     if numericValues then local n=v[k];assert(n==n and math.abs(n)<math.huge);values[#values+1]=n end
     if #values>=256 then numbers(values);values={};B.check()end
    end
    numbers(values)
    if not numericValues then for _,k in ipairs(keys)do visit(v[k])end end
   else
    add('{'..#keys..':');for _,k in ipairs(keys)do visit(k);visit(v[k])end
   end
  else error('unsupported input '..t)end
 end
 visit(value);B.check();return hash(d,table.concat(out))
end
local function fields(d,value)
 local result={}
 for k,v in pairs(value)do B.check();result[k]=signature(d,v)end
 return signature(d,result)
end
function C.fingerprint(value)
 local d=api();if not d then return end
 return fields(d,value)
end
local function codeStamp(d)
 if sourceStamp then return sourceStamp end
 local parts={tostring(V.mod.version or''),'terrain-pages-v1'}
 -- Terrain material decisions run after Structures has been resolved. Other
 -- authored geometry changes already alter the resolved structure signature.
 for _,name in ipairs{'TerrainDiskCache','ChunkMesher','Gen1CaveCaps','Gen1CaveWalls','Gen1CaveSurfaces',
  'Gen1InteriorFloors','Gen1OutdoorScenery','Gen1Stairs','WalkableGrades','Gen1CavePanoramas'}do
  B.check();local raw=V.mod:read('lib/'..name..'.lua');assert(type(raw)=='string');parts[#parts+1]=hash(d,raw)
 end
 sourceStamp=hash(d,table.concat(parts,'|'));return sourceStamp
end
-- Learn when fingerprinting is more expensive than this device's already
-- instanced mesher. Negative decisions survive restarts; they only choose the
-- normal renderer, never admit stale geometry. A code revision retries them.
local policies={}
function C.policy(id,slot,mobile,instanced)
 local d,fs=api();if not d then return end
 local key=hash(d,codeStamp(d)..signature(d,{id,slot,mobile,instanced}))
 if policies[key]==nil then
  local path=PREFIX..'skip-'..tostring(tonumber(key:sub(1,8),16)%C.SLOTS)..'.bin'
  local info=fs:info(path)
  policies[key]=not(info and info.size==68 and fs:read(path)=='TPS1'..key)
 end
 if policies[key]then return key end
 C.bypasses=C.bypasses+1
end
function C.allowStore(policy,checkMs,buildMs)
 if not policy or buildMs>checkMs*2+4 then return true end
 local d,fs=api();if not d then return false end
 policies[policy]=false;C.bypasses=C.bypasses+1
 local path=PREFIX..'skip-'..tostring(tonumber(policy:sub(1,8),16)%C.SLOTS)..'.bin'
 -- An unwritable marker merely repeats the experiment next start.
 pcall(fs.write,fs,path,'TPS1'..policy)
 return false
end
function C.key(id,slot,mobile,instanced,inputs)
 local d=api();if not d then return end
 local ok,key=pcall(function()
  return hash(d,codeStamp(d)..d.pack('string','=I4',0x01020304)..signature(d,{id,slot,mobile,instanced,fields(d,inputs)}))
 end)
 if ok then return key end
 C.errors=C.errors+1;C.lastError=tostring(key)
end
local function path(slot)return PREFIX..tostring(slot)..'.bin'end
local function loadIndex(d,fs)
 if index then return end
 index={};sequence=0
 local info=fs:info(PREFIX..'index.bin')
 if not info or info.size~=68+C.SLOTS*68 then return end
 local raw=fs:read(PREFIX..'index.bin')
 if type(raw)~='string'or #raw~=info.size or raw:sub(1,4)~='TPI1' then return end
 local body=raw:sub(69)
 if hash(d,body)~=raw:sub(5,68)then return end
 for slot=0,C.SLOTS-1 do
  local pos=slot*68+1;local key=body:sub(pos,pos+63)
  local age=d.unpack('<I4',body,pos+64)
  if age>0 and not key:find('[^0-9a-f]')then
   index[slot]={key=key,age=age};sequence=math.max(sequence,age)
  end
 end
end
local function tickAge()
 sequence=sequence+1
 if sequence>=4294967295 then
  sequence=1;for _,entry in pairs(index)do entry.age=1 end
 end
 return sequence
end
local function saveIndex(d,fs)
 local parts={}
 for slot=0,C.SLOTS-1 do
  local entry=index[slot]
  parts[#parts+1]=(entry and entry.key or string.rep('0',64))..d.pack('string','<I4',entry and entry.age or 0)
 end
 local body=table.concat(parts)
 return fs:write(PREFIX..'index.bin','TPI1'..hash(d,body)..body)
end
local function locate(key)
 assert(type(key)=='string'and #key==64 and not key:find('[^0-9a-f]'))
 for slot,entry in pairs(index)do if entry.key==key then return slot end end
end
local function validSnapshot(s,mobile)
 if type(s)~='table'or type(s.quads)~='number'or s.quads<0 or s.quads%1~=0 or s.quads>100000 then return false end
 local expected=s.quads*(mobile and 6 or 4);local count=0
 for _,p in ipairs(s.pages or{})do
  if type(p.packed)~='string'or p.count<1 or p.count%1~=0 or p.count>1536 or #p.packed~=p.count*24 then return false end
  count=count+p.count
 end
 if count~=expected then return false end
 local indices=table.concat(s.indexPieces or{})
 return #indices==(mobile and 0 or s.quads*24)
end
local function encode(d,bundle)
 local parts={d.pack('string','<I4I4',bundle.mobile and 1 or 0,#bundle.groups)}
 local bytes=8
 local function add(s)bytes=bytes+#s;assert(bytes<=C.MAX_BYTES-132,'entry too large');parts[#parts+1]=s end
 local function mesh(s)
  assert(validSnapshot(s,bundle.mobile),'invalid upload snapshot')
  add(d.pack('string','<I4I4',s.quads,#s.pages))
  for _,p in ipairs(s.pages)do B.check();add(d.pack('string','<I4',p.count));add(p.packed)end
  local indices=table.concat(s.indexPieces);add(d.pack('string','<I4',#indices));add(indices)
 end
 mesh(bundle.land);mesh(bundle.water)
 for _,g in ipairs(bundle.groups)do
  mesh(g.mesh);add(d.pack('string','<I4',#g.offsets))
  for _,p in ipairs(g.offsets)do B.tick();add(d.pack('string','<ddd',p[1],p[2],p[3]))end
 end
 return table.concat(parts)
end
local function decode(d,body)
 local pos=1
 local function read(fmt)
  local a,b,nextPos=d.unpack(fmt,body,pos)
  if fmt=='<I4I4'then pos=nextPos;return a,b end
  pos=b;return a
 end
 local mobile,count=read('<I4I4');assert(mobile<=1 and count<=2048);mobile=mobile==1
 local function mesh()
  local quads,n=read('<I4I4');assert(quads<=100000 and n<=4096)
  local s={quads=quads,pages={},indexPieces={}}
  for i=1,n do
   B.check();local size=read('<I4');assert(size>0 and size<=1536)
   local last=pos+size*24-1;assert(last<=#body)
   s.pages[i]={count=size,packed=body:sub(pos,last)};pos=last+1
  end
  local size=read('<I4');assert(size<=C.MAX_BYTES and pos+size-1<=#body)
  s.indexPieces[1]=body:sub(pos,pos+size-1);pos=pos+size
  assert(validSnapshot(s,mobile));return s
 end
 local bundle={mobile=mobile,land=mesh(),water=mesh(),groups={}}
 for i=1,count do
  local g={mesh=mesh(),offsets={}};local n=read('<I4');assert(n>0 and n<=100000)
  for j=1,n do
   B.tick();local x,y,z,np=d.unpack('<ddd',body,pos);pos=np
   for _,v in ipairs{x,y,z}do assert(v==v and math.abs(v)<1000000)end
   g.offsets[j]={x,y,z}
  end
  bundle.groups[i]=g
 end
 assert(pos==#body+1,'trailing data');return bundle
end
function C.get(key,mobile,instanced)
 local d,fs=api();if not d or not key then return end
 local ok,bundle=pcall(function()
  B.check();loadIndex(d,fs);local slot=locate(key);if slot==nil then return end
  local p=path(slot);local info=fs:info(p)
  if not info then return end
  if type(info.size)~='number'or info.size<140 or info.size>C.MAX_BYTES then C.rejected=C.rejected+1;return end
  local raw=fs:read(p)
  if type(raw)~='string'or #raw~=info.size or raw:sub(1,4)~='TPC1'or raw:sub(5,68)~=key then return end
  local body=raw:sub(133)
  if hash(d,body)~=raw:sub(69,132)then C.rejected=C.rejected+1;return end
  local saved=decode(d,body)
  assert(mobile==nil or saved.mobile==mobile,'layout mismatch')
  assert(instanced~=false or #saved.groups==0,'unexpected instances')
  index[slot].age=tickAge();return saved
 end)
 if ok and bundle then C.hits=C.hits+1;return bundle end
 if not ok then C.rejected=C.rejected+1;C.lastError=tostring(bundle)end
 C.misses=C.misses+1
end
function C.put(key,bundle)
 local d,fs=api();if not d or not key then return false end
 local ok,result=pcall(function()
  local body=encode(d,bundle);local raw='TPC1'..key..hash(d,body)..body
  B.check();loadIndex(d,fs);local slot=locate(key)
  if slot==nil then
   for i=0,C.SLOTS-1 do
    if not index[i]then slot=i;break end
    if slot==nil or index[i].age<index[slot].age then slot=i end
   end
  end
  if not fs:write(path(slot),raw)then return false end
  index[slot]={key=key,age=tickAge()}
  return saveIndex(d,fs)
 end)
 if ok and result then C.writes=C.writes+1;return true end
 if not ok and tostring(result):find('entry too large',1,true)then C.bypasses=C.bypasses+1;return false end
 C.errors=C.errors+1;C.lastError=tostring(result);return false
end
function C.status()return{hits=C.hits,misses=C.misses,writes=C.writes,rejected=C.rejected,errors=C.errors,bypasses=C.bypasses,lastError=C.lastError,maxBytes=C.MAX_BYTES*C.SLOTS}end
return C
