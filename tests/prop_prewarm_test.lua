local created,released,vertices,clock=0,0,0,0
local function mesh(count)
 return {getVertexCount=function()return count end,getVertex=function()vertices=vertices+1;return 0,0,0,0,0,1 end,
 getVertexMap=function()return nil end,attachAttribute=function()end,setVertices=function()end,release=function()released=released+1 end}
end
love={timer={getTime=function()clock=clock+.0001;return clock end},graphics={newMesh=function()created=created+1;return mesh(0)end}}
package.loaded['src.render.Assets']={register=function()end}
local G={canInstance=function()return true end,newMesh=function(v)created=created+1;return mesh(#v)end}
local itemMetadata={}
local budget=assert(loadfile('lib/BuildBudget.lua'))()
local V={require=function(n)if n=='VoxelItems'then return itemMetadata end;if n=='BuildBudget'then return budget end;assert(n=='Voxel3D');return G end}
local B=assert(loadfile('lib/VoxelPropBatch.lua'))(V)
local original=mesh(8000);local glass=mesh(400);local tex={};local map={}
local function each(_,draw)
 for i=1,9 do draw(original,tex,{1,0,0,i,0,1,0,0,0,0,1,0,0,0,0,1},1,{mesh=glass,tex=tex,glow=1})end
end
local ticks=0
while not B.prewarm({map=map},each,.0005)do ticks=ticks+1;assert(ticks<150,'prewarm stuck')end
assert(ticks>2 and B.prepared(map),'did not spread vertex copying')
assert(created==8,'expected separate body/glass color/shadow template+stream')
local built,read=created,vertices
local draws=0
for _,pass in ipairs{'color','shadow'}do
 B.draw({map=map},each,function(bundle)assert(bundle.__voxelMeshBundle);draws=draws+1 end,pass)
end
assert(created==built and vertices==read,'draw cloned a warmed template')
assert(draws==4,'batching lost body/glass pass')
B.clear();assert(not B.prepared(map)and released==8,'reset leaked resources or retained readiness')
print('PASS batch prewarm: bounded copy slices, all directions, separate passes, zero first-draw clones, reset')

local extra={seasonalFoliage=true,blossomSource={}}
local function trees(_,draw)
 for i=1,6 do draw(original,tex,{1,0,0,i,0,1,0,0,0,0,1,0,0,0,0,1},1,extra)end
end
while not B.prewarm({map=map},trees,.001)do end
local before=created
for _,pass in ipairs{'color','shadow'}do B.draw({map=map},trees,function(bundle)assert(bundle.__voxelMeshBundle)end,pass)end
assert(before==created,'blossom palette batch was not prepared')
B.clear()
print('PASS seasonal tree palette prewarm')

local lower=mesh(80)
itemMetadata.distant=function(m)if m==original then return lower end end
local started=created
while not B.prewarm({map=map},each,.001)do end
assert(created-started==10,'distant body should prewarm only color, original body/glass both passes')
local before=created
local function distant(_,draw)for i=1,9 do draw(lower,tex,{1,0,0,i,0,1,0,0,0,0,1,0,0,0,0,1},1)end end
B.draw({map=map},distant,function()end)
assert(created==before,'first distant draw allocated instance resources')
B.clear()
print('PASS distant template: prepared color only and zero first-draw allocation')

-- Two prefetch callers cannot spend two budgets or discover twice per frame.
local visits=0
local function counted(state,draw)visits=visits+1;return each(state,draw)end
B.beginFrame(true)
assert(not B.prewarm({map=map},counted,.0005))
local reads=vertices
assert(not B.prewarm({map=map},counted,.0005))
assert(visits==1 and vertices==reads,'second probe repeated preparation')
local allocation=created;local originals=0
B.draw({map=map},each,function(m)
 -- Iteration order may already finish a small glass group while the body
 -- is still pending. Count visible instances, not an assumed group order.
 originals=originals+(m.__voxelMeshBundle and m.instances[1].count or 1)
end)
assert(created==allocation and originals==18 and not B.lastError,'cold draw allocated, hid originals or failed')
for i=1,150 do B.beginFrame(true);if B.prewarm({map=map},counted,.0005)then break end end
assert(B.prepared(map),'bounded preparation did not finish')
allocation=created
B.draw({map=map},each,function(m)assert(m.__voxelMeshBundle)end)
assert(created==allocation,'prepared draw allocated')
B.clear()
print('PASS shared per-frame preparation and allocation-free cold fallback')

local receipt={}
local discoveryBefore=visits
for i=1,150 do B.beginFrame(true);if B.prewarm({map=map},counted,.001,receipt)then break end end
assert(visits==discoveryBefore+1,'unchanged in-progress neighborhood enumerated again')
local previousVisits=visits
for i=1,10 do B.beginFrame(false);assert(B.prewarm({map=map},counted,.001,receipt))end
assert(visits==previousVisits,'unchanged complete neighborhood was enumerated again')
B.beginFrame(true);assert(B.prewarm({map=map},counted,.001,{}))
assert(visits==previousVisits+1,'changed snapshot did not trigger rediscovery')
B.clear()
print('PASS immutable neighborhood receipt skips repeated discovery')

local receiptCalls=0
local function lazyReceipt()receiptCalls=receiptCalls+1;return receipt end
B.beginFrame(true);B.prewarm({map=map},counted,.0005,lazyReceipt)
B.prewarm({map=map},counted,.0005,lazyReceipt)
assert(receiptCalls==1,'duplicate query validated scene twice')
B.clear();G.canInstance=function()return false end
B.beginFrame(false);assert(B.prewarm({map=map},counted,.0005,lazyReceipt))
assert(receiptCalls==1,'non-instanced/mobile driver paid for batch discovery')
print('PASS lazy receipt: one validation per frame, no mobile discovery overhead')
