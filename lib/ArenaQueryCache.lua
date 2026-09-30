-- A bounded cache of arena results with live query proofs. No map revision is
-- assumed to cover arbitrary collision callbacks: every fact that selected or
-- rejected a placement is rechecked before reusing the result.
local M={}
local NIL={}
local function copy(v,seen,key)
 if type(v)~='table' or key=='map' or key=='pick' or key=='trainerOffsets' then return v end
 seen=seen or {};if seen[v]then return seen[v]end
 local out={};seen[v]=out
 for k,x in pairs(v)do out[k]=copy(x,seen,k)end
 return out
end
local function tree(v,seen,root)
 if type(v)~='table'then
  assert(type(v)~='function'and type(v)~='userdata'and type(v)~='thread','opaque configuration')
  return v
 end
 assert(getmetatable(v)==nil and not seen[v],'dynamic configuration')
 seen[v]=true;local node={ref=not root and v or nil,fields={},count=0}
 for k,x in pairs(v)do
  assert(type(k)=='string'or type(k)=='number','opaque configuration key')
  node.fields[k]=tree(x,seen);node.count=node.count+1
 end
 seen[v]=nil;return node
end
local function same(node,v)
 if type(node)~='table'then return v==node end
 if type(v)~='table'or getmetatable(v)~=nil or node.ref and node.ref~=v then return false end
 local n=0
 for k,x in pairs(v)do
  n=n+1;if node.fields[k]==nil or not same(node.fields[k],x)then return false end
 end
 return n==node.count
end
local function mapState(map)
 return {map.id,map.widthCells,map.heightCells,map.def,map.tileset,
  map.def and map.def.tileset,map.tileset and map.tileset.id}
end
local function mapSame(map,s)
 return map.id==s[1]and map.widthCells==s[2]and map.heightCells==s[3]
  and map.def==s[4]and map.tileset==s[5]
  and (map.def and map.def.tileset)==s[6]
  and (map.tileset and map.tileset.id)==s[7]
end
function M.new(readers)
 local C={hits=0,misses=0,rejected=0,enabled=true,recording=false,limit=8,maxFacts=8192}
 local entries,active={},nil
 local function registerMap(map)
  if type(map)=='table'and not active.maps[map]then active.maps[map]=mapState(map)end
 end
 function C.read(kind,a,b,c,d)
  local x,y,z,w=readers[kind](a,b,c,d)
  if active and not active.unsafe then
   if kind=='foreign'then registerMap(x)
   elseif kind~='camera'then registerMap(a)end
   local row
   if kind~='camera'and kind~='geometryRay'then
    -- Spatial readers use scalar cell/world coordinates. Keep their lookup
    -- rows directly, without a temporary key array or a table per nil arg.
    local slot=kind=='open'and(d and 'openWater' or 'openLand')or kind
    local index=active.index[slot]
    if not index then index={};active.index[slot]=index end
    local owner=a==nil and NIL or a
    if b~=nil or c~=nil then
      local child=index[owner];if not child then child={};index[owner]=child end
      index=child;owner=b==nil and NIL or b
      if c~=nil then
        child=index[owner];if not child then child={};index[owner]=child end
        index=child;owner=c
      end
    end
    row=index[owner]
    if row then
     if row.x~=x or row.y~=y or row.z~=z or row.w~=w then active.unsafe=true;C.recording=false end
     return x,y,z,w
    end
    row={};index[owner]=row
   else row={}end
   if #active.facts>=C.maxFacts then active.unsafe=true;C.recording=false;return x,y,z,w end
   row.kind,row.a,row.b,row.c,row.d=kind,a,b,c,d
   if kind=='camera'then row.a=copy(a)
   elseif kind=='geometryRay'then row.b,row.c=copy(b),copy(c)end
   row.x,row.y,row.z,row.w=x,y,z,w
   active.facts[#active.facts+1]=row
  end
  return x,y,z,w
 end
 local function validate(entry,configuration)
  if not same(entry.configuration,configuration)then return false end
  for map,state in pairs(entry.maps)do if not mapSame(map,state)then return false end end
  for _,r in ipairs(entry.facts)do
   local x,y,z,w=readers[r.kind](r.a,r.b,r.c,r.d)
   if x~=r.x or y~=r.y or z~=r.z or w~=r.w then return false end
  end
  return true
 end
 local function compute(fn,...)
  local function pack(...)return {n=select('#',...),...}end
  local result=pack(pcall(fn,...));active=nil;C.recording=false
  if not result[1]then error(result[2],0)end
  local n=result.n
  for i=1,n-1 do result[i]=result[i+1]end
  result[n]=nil;result.n=n-1
  return result
 end
 function C.run(key,configuration,fn,...)
  if not C.enabled or not key or active then return fn(...)end
  for i,entry in ipairs(entries)do
   if entry.key==key then
    local ok,valid=pcall(validate,entry,configuration)
    if ok and valid then
     C.hits=C.hits+1
     local result=copy(entry.result)
     return unpack(result,1,result.n)
    end
    table.remove(entries,i);C.rejected=C.rejected+1;break
   end
  end
  C.misses=C.misses+1
  local ok,configurationTree=pcall(tree,configuration,{},true)
  if not ok then return fn(...)end
  local record={key=key,configuration=configurationTree,facts={},maps={},index={}}
  active=record;C.recording=true
  local result=compute(fn,...)
  if not record.unsafe then
   record.result=copy(result);record.index=nil
   entries[#entries+1]=record
   if #entries>C.limit then table.remove(entries,1)end
  end
  return unpack(result,1,result.n)
 end
 function C.clear()entries={}end
 return C
end
return M
