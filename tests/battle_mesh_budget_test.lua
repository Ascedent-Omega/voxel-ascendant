-- Execute the production scheduler with one suspended urgent job. The arena
-- stays urgent for ordering, but a visible battle must cap its time slice.
local f=assert(io.open('lib/ChunkMesher.lua'));local source=f:read('*a');f:close()
local first=assert(source:find('local URGENT_SLICE =',1,true))
local last=assert(source:find('-- Meshes for `map`, built SYNCHRONOUSLY',first,true))
local budget,dt
local env={ChunkMesher={},jobs={},clock=function()return 0 end,
 love={timer={getDelta=function()return dt end}},
 Budget={begin=function(_,seconds)budget=seconds end,finish=function()end},
 runJob=function()coroutine.yield()end,
 finishJob=function()error('job should suspend')end,
 V={require=function(name)assert(name=='BackgroundBudget');return{allowance=function(x)return x end}end}}
setmetatable(env,{__index=_G})
local chunk=assert(loadstring(source:sub(first,last-1)));setfenv(chunk,env);chunk()
local function run(visible,covered,loading,delta)
 env.jobs={{urgent=true,live=true,entryDeferred=true}};budget=nil;dt=delta
 env.ChunkMesher.pump(covered,false,loading,false,false,false,visible)
 return assert(budget)
end
assert(run(false,false,false,1/120)==.012,'ordinary urgent budget changed')
assert(run(true,false,false,1/120)<=.004,'visible urgent battle gets loading slice')
assert(run(true,false,false,1/25)<=.001,'slow visible battle ignores recovery budget')
assert(run(false,true,false,1/60)==.006,'covered preparation budget changed')
assert(run(false,true,true,1/60)>.006,'cold covered arena cannot progress')
print('PASS battle mesh slices: urgent visible <=4ms, slow visible <=1ms, covered/cold preparation retained')
