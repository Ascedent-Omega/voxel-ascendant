local modules={
 CompactBackgroundAssets={},Voxel3D={},WorldPlacement={},Gen1CavePanoramas={},GymSkylights={},
 Gen1InteriorPanoramas={assets={}},Gen1GymInteriors={profiles={}},
 ModSetting={new=function()return{get=function()return'full'end}end},
 HorizonAddressCache={new=function()return{}end}}
package.loaded['src.render.TileRenderer']={}
local now=0;love={timer={getTime=function()return now end}}
local H=assert(loadfile('lib/HorizonWall.lua')){require=function(n)return assert(modules[n],n)end}
local function up(fn,name,write,value,seen)
 seen=seen or{};if seen[fn]then return end;seen[fn]=true
 for i=1,100 do local n,v=debug.getupvalue(fn,i);if not n then break end
  if n==name then if write then debug.setupvalue(fn,i,value)end;return v,true end
 end
 for i=1,100 do local n,v=debug.getupvalue(fn,i);if not n then break end
  if type(v)=='function'then local found,ok=up(v,name,write,value,seen);if ok then return found,true end end
 end
end
local finish=assert(up(H.meshes,'finishJob'))
local cache=assert(up(H.meshes,'readyCaches'))
local released={}
local function mesh(id,bytes)
 return{bytes=bytes,{mesh={release=function()released[id]=(released[id]or 0)+1 end}}}
end
modules.WorldResidency={measure=function(m)return m.bytes end,capacity=function()return 3 end,
 sceneryBudget=function()return 16 end,budget=function()return 48 end}
cache.visible={key='visible',used=0,meshes=mesh('visible',4)}
cache.history={key='history',used=100,meshes=mesh('history',8)}
local context={keepKey='visible'}
local _,set=up(finish,'optionalPreparation',true,context);assert(set)
local function job(id,bytes)return{key=id,meshes=mesh(id,bytes),maps={},complete=true}end
assert(finish(job('future',10)))
assert(cache.visible and cache.future and not cache.history,'optional build evicted visible room')
assert(released.history==1 and not released.visible)
assert(not finish(job('oversize',20)))
assert(context.rejected and released.oversize==1,'oversized optional allocation not released')
assert(cache.visible and cache.future and not cache.oversize,'budget rejection damaged current cache')
assert(H.buildStatus().failed==0,'optional budget miss poisoned the real destination')
up(finish,'optionalPreparation',true,nil)
assert(finish(job('oversize',20)) and cache.oversize,'actual warp unable to build rejected future map')
print('PASS optional horizon residency: visible scene protected, LRU history evicted first, oversize released once, no failure poison for actual warp')
-- Preparing a region must not churn its first house while warming later rooms.
for key in pairs(cache)do cache[key]=nil end
cache.visible={key='visible',used=0,meshes=mesh('visible2',4)}
cache.house={key='house',used=1,meshes=mesh('house',6)}
context={keepKey='visible',keepKeys={visible=true,house=true}}
up(finish,'optionalPreparation',true,context)
assert(finish(job('next-room',6)),'fitting region rejected')
assert(cache.visible and cache.house and cache['next-room'])
context.keepKeys['next-room']=true
assert(not finish(job('too-far',1)),'region count/byte limit bypassed')
assert(cache.house and cache['next-room']and released['too-far']==1,'region warming evicted nearer room')
print('PASS multi-room optional scenery: previously warmed region protected at byte/count limit')

-- Readiness for the same address cannot authorize an obsolete allocation.
H.enabled=function()return true end
up(H.cachedMeshes,'addressOf',true,function()return'borrowed',{},0,0 end)
local state={map={id='ROUTE_5'}}
assert(H.cachedMeshes(state)==nil,'cold passive lookup started a build')
local before=H.buildStatus()
local old,new={id='old'},{id='new'}
cache.borrowed={meshes={{mesh=old}}}
local borrowed=assert(H.cachedMeshes(state))
assert(borrowed[1].mesh==old)
cache.borrowed=nil;old.released=true
assert(H.cachedMeshes(state)==nil,'evicted mesh was returned')
cache.borrowed={meshes={{mesh=new}}}
assert(H.cachedMeshes(state)[1].mesh==new,'rebuilt address returned released mesh')
assert(H.buildStatus().pending==before.pending,'passive lookup queued work')
print('PASS passive horizon borrowing: cold/evicted misses and current allocation after same-key rebuild')
