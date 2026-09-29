-- The shared grid now embeds static-field shader code at module load. Missing
-- dependencies must not abort both Gen-2 3D renderer entry points.
local f=assert(io.open('main.lua'));local source=f:read('*a');f:close()
local a=assert(source:find('local GEN2_A21_SHARED_UI',1,true))
local b=assert(source:find('local gen2 = setmetatable',a,true))
local resolve=assert(loadstring(source:sub(a,b-1)..'return privatePath'))()
for _,name in ipairs{'LocalLightGrid','LightVisibility','StaticLightField','StaticLightDiskCache','StaticLightCacheWorker'}do
 local path='lib/'..name..'.lua';assert(resolve(path)==path,'missing shared light dependency '..name)
 assert(loadfile(path),'missing actual module '..name)
end
for _,name in ipairs{'LocalLights','VoxelScene','Structures','BuildBudget'}do
 assert(resolve('lib/'..name..'.lua')=='gen2/lib/'..name..'.lua','generation-owned scene changed '..name)
end
print('PASS Gen-2 shared static-light dependencies and generation-owned scene paths')
