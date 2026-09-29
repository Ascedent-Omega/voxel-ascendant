local modules={CanvasPresentation={OS='Linux'},
 ModSetting={new=function()return{get=function()return true end,setGate=function()end}end},
 AccessWayfinding={appendLights=function()end},Halloween={appendLights=function()end},CalendarDecor={lights=function()end},
 HorizonWall={},CaveTorches={eligible=function()return false end},TowerAtmosphere={active=function()return false end},
 DayNight={windowLight=function()return 1 end},Voxel3D={tint={1,1,1}}}
local V={require=function(k)return assert(modules[k],k)end}
modules.StaticLightField=assert(loadfile('lib/StaticLightField.lua'))(V)
modules.LocalLightGrid=assert(loadfile('lib/LocalLightGrid.lua'))(V)
local L=assert(loadfile('lib/LocalLights.lua'))(V);L.sky=function()return{}end
local Grid=modules.LocalLightGrid
local model={terrain=true,glassKind='glass',boxes={{0,0,0,128,48,64}}}
local glass={boxes={}}
for i=1,96 do glass.boxes[i]={i%24*5,math.floor(i/24)*8,64,3,4,1}end
modules.VoxelItems={models={glass=glass}}
local mat={1,0,0,19,0,1,0,3,0,0,1,-17,0,0,0,1}
local extra={lightModel=model,glow=.7}
local props={furniture={{mat=mat,extra=extra}}}
local state={map={id='TEST_CITY',def={}}}
local function reference(frame)
 local raw={};local shape=L.shape(model,glass);local owner=frame.allBlockers and frame.allBlockers[1]
 for _,p in ipairs(shape.panes)do raw[#raw+1]={x=p.position[1]+mat[4],y=p.position[2]+mat[8],z=p.position[3]+mat[12],
  radius=p.radius,power=p.power*extra.glow,normal=p.normal,owner=owner or {lo={0,0,0},hi={128,48,64}}}end
 return raw
end
local function check()
 local frame=L.prepare(state,true,{0,0,0},false,'none',false,props)
 assert(frame.allLights and #frame.allLights<#glass.boxes,'facade still submits every glass box each frame')
 local actual,expected=Grid.sources(frame.allLights),Grid.sources(reference(frame))
 assert(#actual==#expected,'facade aggregation changed number of light groups')
 for i,a in ipairs(actual)do local b=expected[i]
  for _,key in ipairs{'x','y','z','radius','power'}do assert(math.abs(a[key]-b[key])<1e-10,key..' changed')end
  assert(a.owner==b.owner)
  for j=1,3 do assert(a.normal[j]==b.normal[j])end
 end
 return frame.allLights[1].geometryKey
end
local first=check();assert(check()==first,'unchanged building rebuilt light geometry')
extra.glow=.4;assert(check()==first,'dusk rebuilt geometry')
mat[4]=43;assert(check()~=first,'moved instance retained stale geometry')
local battle=L.prepare(state,true,{0,0,0},false,'none',true,props)
assert(not battle.allLights and #battle.lights==L.MAX_BATTLE_LIGHTS,'battle light policy changed')
for _,l in ipairs(battle.lights)do assert(not l.sourceCount,'battle received aggregated lights')end
-- More raw panes than shader slots must stay on the same grid path even if
-- they fit a single aggregate, avoiding an accidental nearest-light switch.
glass.boxes={};for i=1,12 do glass.boxes[i]={i,8,64,1,2,1}end
modules.VoxelItems.models.glass=glass -- replace the model object to invalidate shape
local replacement={boxes=glass.boxes};modules.VoxelItems.models.glass=replacement;glass=replacement
local one=L.prepare(state,true,{0,0,0},false,'none',false,props)
assert(one.allLights and #one.allLights==1 and #one.lights==0,'grouping changed grid policy')
print('PASS facade reuse: identical world-space groups, live dusk power, moved-model invalidation, raw battle lights and small aggregate policy')
