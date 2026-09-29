local noop=setmetatable({register=function()end},{__call=function()end})
local mods={VoxelItems={models={}},Voxel3D={},Mat4={},BuildBudget={}}
package.loaded['src.render.Assets']={register=function()end}
local V={require=function(n)return mods[n] or noop end}
local F=assert(loadfile('lib/VoxelFurniture.lua'))(V)
local a,b,c={},{},{}
local scenes={[a]={_voxelStaticSnapshot=true},[b]={_voxelStaticSnapshot=true},[c]={_voxelStaticSnapshot=true}}
F.snapshot=function(state)if state.healAnim then return nil end;return scenes[state.map]end
local state={map=a,neighbors={{map=b,ox=32},{map=b,ox=32}}}
local receipt=assert(F.batchReceipt(state))
assert(#receipt==2,'duplicate neighbor changes batch counts')
state.neighbors={{map=b,ox=64}}
assert(F.batchReceipt(state)==receipt,'translation-only change invalidated capacities')
scenes[b]={_voxelStaticSnapshot=true}
assert(F.batchReceipt(state)~=receipt,'new geometry reused stale preparation')
receipt=F.batchReceipt(state);state.neighbors={{map=c}}
assert(F.batchReceipt(state)~=receipt,'map change reused preparation')
state.healAnim=true;assert(F.batchReceipt(state)==nil,'dynamic view cached')
state.healAnim=nil;state.landmarkCutaway=true;assert(F.batchReceipt(state)==nil)
state.landmarkCutaway=nil;state.sightFurniture={};assert(F.batchReceipt(state)==nil)
state.sightFurniture=nil;scenes[c]={}
assert(F.batchReceipt(state)==nil,'unresolved template failure cached')
print('PASS batch receipts: geometry changes, neighbors, duplicates, transforms and dynamic/failure bypass')
