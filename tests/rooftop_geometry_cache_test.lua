-- Real LÖVE binary/GPU contract; scoped in-memory storage never touches saves.
return function(V)
 local source=assert(V.mod:read('lib/RooftopGeometryCache.lua'))
 local files,fail,reads={},false,0
 local fs={info=function(_,p)return files[p]and{size=#files[p]}end,
  read=function(_,p)reads=reads+1;return files[p]end,
  write=function(_,p,b)if fail then return nil,'full'end;files[p]=b;return true end}
 local function fresh()return assert(loadstring(source))({mod={cache=fs},require=V.require})end
 local C=fresh();local key=string.rep('a',64);local path='roof.bin';local yielded=0
 local function step()yielded=yielded+1 end
 local group={name='world',lit=true,foliage=false,bounds={0,0,0,2,2,0},
  vertices={{0,0,0,0,0,1},{2,0,0,1,0,.5},{2,2,0,1,1,3},{0,2,0,0,1,1}},indices={1,2,3,1,3,4}}
 local peak={x=1,y=2,z=3,height=4}
 assert(not C.get(key,path));assert(C.put(key,path,{group},peak,step));local raw=files[path]
 C=fresh();local groups,p=C.get(key,path,step);assert(groups and #groups==1 and p.height==4)
 assert(groups[1].lit and not groups[1].foliage and groups[1].bounds[4]==2)
 local cold=assert(C.mesh(group));local G=V.require('Voxel3D');local build=G.newMesh
 G.newMesh=function()error('native packed upload unexpectedly fell back')end
 local ok,warm=pcall(C.mesh,groups[1]);G.newMesh=build;assert(ok,warm);assert(warm)
 for i=1,4 do local a,b={cold:getVertex(i)},{warm:getVertex(i)};assert(#a==#b);for j=1,#a do assert(a[j]==b[j],'GPU vertex changed')end end
 local a,b=cold:getVertexMap(),warm:getVertexMap();for i=1,#a do assert(a[i]==b[i],'GPU index changed')end
 cold:release();warm:release()
 -- Emulate a driver that does not support packed vertex/index upload.
 local original=love.graphics.newMesh
 love.graphics.newMesh=function(format,data,...)if type(data)=='userdata'then error('packed unavailable')end;return original(format,data,...)end
 local fallback=C.mesh(groups[1]);love.graphics.newMesh=original;assert(fallback);fallback:release()
 assert(not C.get(string.rep('b',64),path),'stale key accepted')
 files[path]=raw:sub(1,-2)..'!';assert(not C.get(key,path),'corruption accepted')
 files[path]=raw:sub(1,100);assert(not C.get(key,path),'truncated write accepted')
 files[path]=raw;local info=fs.info;fs.info=function()return{size=C.MAX_BYTES+1}end
 local before=reads;assert(not C.get(key,path)and reads==before,'oversized file read');fs.info=info
 fail=true;assert(not C.put(key,path,{group},peak));assert(C.get(key,path),'failed write destroyed valid cache');fail=false
 assert(C.put(key,path,{group},nil));local _,empty=C.get(key,path);assert(empty==nil,'stale volcano retained')
 assert(yielded>0)
 -- Use real map/tileset signatures, with a controlled producer revision.
 local code='producer-A'
 local function keyed()return assert(loadstring(source))({mod={cache=fs,version='qa',read=function()return code end},require=V.require})end
 local near={{0,0,0,1,1,1,1,false,false}}
 local entry={map={id='CELADON_MART_ROOF'},w=640,h=320}
 local K=keyed();local a,slot=K.key(entry,nil,'settings-A',near);assert(a,K.lastError)
 assert(a==keyed().key(entry,nil,'settings-A',near),'restart changed key')
 assert(a~=K.key(entry,nil,'settings-B',near),'settings ignored')
 near[1][4]=2;assert(a~=K.key(entry,nil,'settings-A',near),'near model ignored');near[1][4]=1
 entry.facadeHeight=91;assert(a~=K.key(entry,nil,'settings-A',near),'facade ignored');entry.facadeHeight=nil
 code='producer-B';assert(a~=keyed().key(entry,nil,'settings-A',near),'producer ignored');code='producer-A'
 local maps=require('src.core.Game').data.maps;local map=maps.CELADON_CITY;local old=map.blocks[1]
 map.blocks[1]=old+1;local changed=K.key(entry,nil,'settings-A',near);map.blocks[1]=old
 assert(changed and a~=changed,'map edit ignored')
 local oldwarps=map.warps;map.warps={{x=1,y=2,destMap='QA_ONLY'}}
 changed=K.key(entry,nil,'settings-A',near);map.warps=oldwarps
 assert(changed and a~=changed,'warp edit ignored')
 assert(not K.key({map={id='PALLET_TOWN'}},nil,'settings-A',near),'non-rooftop admitted')
 print('PASS rooftop fingerprint: restart/settings/near geometry/facade/producer/map/warps/scope')
 print('PASS rooftop geometry cache: restart, exact GPU vertices/indices, packed fallback, stale key, corrupt/truncated/oversized cache, failed write, volcano')
end
