-- Run under native LÖVE: exercise its real binary pack/unpack/hash contract.
return function(V)
 local files={};local fail=false;local reads=0;local codeSource='code'
 local fs={info=function(_,p)return files[p]and{size=#files[p]}end,
  read=function(_,p)reads=reads+1;return files[p]end,
  write=function(_,p,b)if fail then return nil,'full'end;files[p]=b;return true end}
 local function fresh()
  local source=assert(V.mod:read('lib/TerrainDiskCache.lua'))
  return assert(loadstring(source))({mod={cache=fs,version='qa',read=function()return codeSource end},
   require=function(n)if n=='BuildBudget'then return{tick=function()end,check=function()end}end
    return{hex=function(d,s)return love.data.encode('string','hex',d.hash('sha256',s))end}end})
 end
 local C=fresh();local d=love.data
 local a={z=3,a={1,2}};local b={a={1,2},z=3}
 local key=C.key('TEST','body',false,true,a)
 assert(key==C.key('TEST','body',false,true,b),'table order in key')
 local shared={2,3};assert(C.key('TEST','body',false,true,{shared,shared})==C.key('TEST','body',false,true,{{2,3},{2,3}}),'template sharing changed key')
 codeSource='changed producer';assert(key~=fresh().key('TEST','body',false,true,a),'producer edit reused old key');codeSource='code'
 b.z=4;assert(key~=C.key('TEST','body',false,true,b),'edited source reused')
 assert(key~=C.key('TEST','full',false,true,a));assert(key~=C.key('TEST','body',true,true,a))
 assert(key~=C.key('TEST','body',false,false,a))
 local values={};for i=1,24 do values[i]=i/16 end
 local quad={quads=1,pages={{count=4,packed=d.pack('string','='..string.rep('f',24),unpack(values))}},
  indexPieces={d.pack('string','=I4I4I4I4I4I4',0,1,2,0,2,3)}}
 local empty={quads=0,pages={},indexPieces={}}
 local bundle={mobile=false,land=quad,water=empty,groups={{mesh=quad,offsets={{1,2,3},{4,5,6}}}}}
 assert(not C.get(key));assert(C.put(key,bundle));C=fresh()
 local got=assert(C.get(key));assert(got.land.pages[1].packed==quad.pages[1].packed and #got.groups==1 and got.groups[1].offsets[2][3]==6)
 assert(not C.get(key,true,true),'wrong platform layout accepted')
 assert(not C.get(key,false,false),'unexpected instances accepted')
 local path,raw;for p,r in pairs(files)do if r:sub(1,4)=='TPC1'and r:sub(5,68)==key then path,raw=p,r end end;assert(path);files[path]=raw:sub(1,-2)..'!';assert(not C.get(key),'corruption accepted')
 files[path]=raw:sub(1,100);assert(not C.get(key),'partial write accepted')
 files[path]=raw;fs.info=function()return{size=C.MAX_BYTES+1}end
 local before=reads;assert(not C.get(key)and reads==before,'oversized file read')
 fs.info=function(_,p)return files[p]and{size=#files[p]}end
 fail=true;assert(not C.put(key,bundle));assert(C.get(key),'failed write destroyed valid entry');fail=false
 local mobile={mobile=true,land={quads=1,pages={{count=6,packed=string.rep('\0',6*24)}},indexPieces={}},water=empty,groups={}}
 local mk=C.key('TEST','body',true,false,a);assert(C.put(mk,mobile));assert(C.get(mk).mobile)
 -- More keys than slots never create an unbounded manifest or orphan files.
 local lastKey
 for i=1,C.SLOTS*2 do lastKey=C.key('TEST'..i,'body',false,true,a);assert(C.put(lastKey,bundle))end
 assert(fresh().get(lastKey),'LRU index did not survive restart')
 assert(not fresh().get(key),'oldest entry was not evicted')
 files['terrain-pages-v1/index.bin']='interrupted metadata'
 local recovered=fresh();assert(not recovered.get(lastKey));assert(recovered.put(lastKey,bundle));assert(fresh().get(lastKey),'bad index did not recover')
 local count=0;for _ in pairs(files)do count=count+1 end;assert(count<=C.SLOTS+1)
 local adaptive=fresh();local policy=assert(adaptive.policy('cheap','body',false,true))
 assert(not adaptive.allowStore(policy,10,2));assert(not fresh().policy('cheap','body',false,true),'expensive cache decision lost on restart')
 assert(fresh().policy('cheap','body',false,false),'layout-specific decision leaked')
 assert(adaptive.allowStore(adaptive.policy('costly','body',false,true),1,20),'useful cache rejected')
 print('PASS terrain disk cache: process-local restart, exact bytes/instances, input/layout invalidation, corruption/partial/oversize/full-disk recovery, bounded slots, mobile stream')
end
