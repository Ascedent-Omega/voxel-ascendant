local platform={mobile=false};package.loaded['src.core.Platform']={detect=function()return platform end}
local setting={value='auto'};function setting:get()return self.value end
local M=assert(loadfile('lib/WorldResidency.lua')){require=function(n)assert(n=='ModSetting');return{new=function()return setting end}end}
local MB=1024*1024
assert(M.budget()==512*MB and M.capacity()==16)
local function allocation(bytes)return{typeOf=function(_,t)return t=='Mesh'end,getVertexCount=function()return bytes/80 end}end
local shared=allocation(4*MB)
assert(M.measure({shared,shared,{mesh=shared}})==4*MB,'shared mesh counted more than once')
local image={getDimensions=function()return 128,128 end}
assert(M.measure({{texture=image,ownsTexture=true,materialMask=image},{texture=image,ownsTexture=true}})==128*128*8,'owned images not counted exactly once')
assert(M.measure({texture=image})==0,'shared Assets image charged to cache')
local a={};a.self=a;assert(M.measure(a)==0,'cycle')
for i=1,10 do local id='town'..i;M.record(id,{allocation(8*MB)});M.keep({[id]=true})end
assert(M.retained().town1 and M.retained().town10,'recent towns discarded despite spare allowance')
M.keep({town1=true});setting.value=128;M.keep({town1=true})
assert(M.retained().town1 and M.retained().town10 and not M.retained().town2,'LRU or smaller budget ignored')
assert(M.last.maps==4)
M.reset();setting.value=512
for i=1,5 do local id='large'..i;M.record(id,{allocation(100*MB)});M.keep({[id]=true})end
assert(M.last.maps==3 and M.last.estimatedTerrainBytes==300*MB,'byte allowance ignored')
M.record('required',{allocation(400*MB)});M.keep({required=true})
assert(M.retained().required and M.last.maps==1,'visible world evicted for history')
M.reset();assert(next(M.retained())==nil)
print('PASS cache: byte budget, unique allocations, pinned live maps, LRU, budget decrease, reset')
