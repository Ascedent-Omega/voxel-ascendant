local C=assert(loadfile('shared/WeatherCover.lua'))()
local map={id='QA',def={width=2,height=2,blocks={1}},tileset={id='TilesetJohto'}}
local f=C.begin(map);f:add({{0,32,0},{16,32,0},{16,32,16},{0,32,16}});f:publish()
local store={};local storage={read=function(_,k)return store[k]end,write=function(_,k,v)store[k]=v;return true end}
local uploaded,released=0,0
love={graphics={newMesh=function()uploaded=uploaded+1;return{setVertices=function()end,release=function()released=released+1 end}end},data={newByteData=function()return{release=function()end}end}}
local modules={WeatherCover=C,BuildBudget={phase=function()end,check=function()end},Voxel3D={FORMAT={}},MeshParts={MAX_VERTICES=1000,release=function()end,wrap=function(p)return p[1]end}}
local V={mod={storage=storage},require=function(n)return assert(modules[n],n)end}
local Cache=assert(loadfile('gen2/lib/Gen2MeshCache.lua'))(V)
assert(Cache.enqueue(map,'body',{},string.rep('\0',72),3,'',0))
for i=1,4 do Cache.pump(true)end
assert(Cache.writes==1)
C.invalidate(map);assert(not C.height(map,4,4))
assert(Cache.load(map,'body',{}));assert(uploaded==1 and C.height(map,4,4)==32,'disk hit did not restore roofs')
for k,v in pairs(store)do if k:match('/meta$')then v.weatherCover=nil end end
assert(not Cache.load(map,'body',{}));assert(released==1,'invalid cover cache leaked uploaded mesh')
print('PASS persistent terrain cache restores cover and rejects incomplete metadata')
