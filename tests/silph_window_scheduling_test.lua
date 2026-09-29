local owned,fail={}
local modules={ModSetting={new=function()return{get=function()return true end}end},
 RooftopWorld={texture=function()return{}end},VoxelItems={palette={{1,1,1}}},Voxel3D={},
 HouseWindows={describe=function()return nil end},WindowImageCache={load=function()return{},{}end},
 SilphElevator={matches=function()return false end}}
modules.CinnabarVolcano={meshes=function(x,z,y,yieldStep,out)
 assert(x==10 and z==30 and y==20 and type(yieldStep)=='function'and out==owned,'landmark scheduling/owner lost')
 out[#out+1]={mesh={release=function()end},ox=0,oy=0,class='voxel_horizon'}
 yieldStep()
 if fail then error('QA upload failure')end
 return out
end}
local M=assert(loadfile('lib/SilphWindows.lua'))({require=function(n)return assert(modules[n],n)end})
M.volcanoPosition=function()return 10,20,30 end
local function job()
 return coroutine.create(function()return M.build({map={},ox=7,oy=9},function()coroutine.yield()end,{},owned)end)
end
local co=job();assert(coroutine.resume(co));assert(#owned==1,'suspended upload has no parent owner')
local ok,out=coroutine.resume(co);assert(ok and out==owned and #out==1,'landmark duplicated')
assert(out[1].class=='silph_exterior'and out[1].windowLandmark=='cinnabar_volcano'and out[1].ox==7 and out[1].oy==9)
owned={};fail=true;co=job();assert(coroutine.resume(co));assert(#owned==1)
assert(not coroutine.resume(co));assert(#owned==1,'failed upload lost its cleanup owner')
print('PASS window scheduling: yield forwarded, partial mesh owned before suspension/failure, no duplicate output, landmark transform preserved')
