local modules={
 CompactBackgroundAssets={},Voxel3D={},WorldPlacement={},Gen1CavePanoramas={},GymSkylights={},
 Gen1InteriorPanoramas={assets={}},Gen1GymInteriors={profiles={}},
 ModSetting={new=function()return{get=function()return'full'end}end},
 HorizonAddressCache={new=function()return{}end}}
package.loaded['src.render.TileRenderer']={}
local now=0;love={timer={getTime=function()return now end}}
modules.BackgroundBudget=assert(loadfile('lib/BackgroundBudget.lua'))()
local H=assert(loadfile('lib/HorizonWall.lua')){require=function(n)return assert(modules[n],n)end}
local advance
for i=1,100 do local n,v=debug.getupvalue(H.meshes,i);if not n then break end;if n=='advanceJob'then advance=v end end
assert(advance,'scheduler unavailable')
local function job(cost)
 local j={resumes=0}
 j.co=coroutine.create(function()while true do now=now+cost;coroutine.yield()end end)
 return j
end
local j=job(.0001);advance(j);assert(j.resumes==1,'legacy standalone caller changed')
H.beginFrame(false,false);j=job(.0001);advance(j);advance(j)
assert(j.resumes==1,'foreground work multiplied across probes')
H.beginFrame(true,false);j=job(.0001);advance(j);advance(j)
assert(j.resumes>=79 and j.resumes<=81,'covered loading must use its 8ms budget')
H.beginFrame(false,true);j=job(.0001);advance(j)
assert(j.resumes>=79 and j.resumes<=81,'cold loading must use its 8ms budget')
H.beginFrame(true,true);j=job(.003);advance(j);advance(j)
assert(j.resumes==3,'covered work ignored the shared 8ms deadline')
H.beginFrame(false,false);j=job(.02);advance(j);advance(j)
assert(j.resumes==1,'slow graphics call allowed more foreground work')
-- Phone foreground must progress even when the last visible frame took 33ms.
love.timer.getDelta=function()return 1/30 end
H.beginFrame(false,false,true);j=job(.0001);advance(j);advance(j)
assert(j.resumes==8,'mobile foreground progress/cap changed')
H.beginFrame(true,false,true);j=job(0);advance(j);advance(j)
assert(j.resumes==128,'zero-cost yields need a finite per-frame cap')
H.beginFrame(true,false,true);j=job(.02);advance(j);advance(j)
assert(j.resumes==1,'phone slow upload allowed more work past deadline')
H.beginFrame(true,false,true);j=job(.0001);local other=job(.0001)
advance(j);advance(other)
assert(j.resumes+other.resumes>=79 and j.resumes+other.resumes<=81,'two maps multiplied the loading budget')
-- A source fragment with ready BODY/aux/atlas is required visible work,
-- even when sustained 30-Hz frames leave no optional spare-time allowance.
modules.BackgroundBudget.reset()
for frame=1,120 do
 H.beginFrame(false,false,false);j=job(.0001);local other=job(.0001)
 advance(j,false);local optional=j.resumes
 advance(j,true);advance(other,true)
 assert(j.resumes+other.resumes==1,'direct expansion stalled or multiplied foreground slices')
 if frame%60~=0 then assert(optional==0,'optional throttle unexpectedly disabled')end
end
H.beginFrame(false,false,false);j=job(.02);local other=job(.0001)
advance(j,true);advance(other,true)
assert(j.resumes==1 and other.resumes==0,'slow required step grew the next budget')
print('PASS horizon budget: bounded phone/desktop progress, shared deadlines, zero-time yield cap, slow-step stop')

print('PASS ready direct horizons: guaranteed progress at 30 Hz, optional throttle retained, one shared foreground slice and slow-step stop')
