local Sea=dofile('integrated/terarrium/SeaTerrarium.lua')
local factory=dofile('integrated/terarrium/Terarrium.lua')
local live,built,draws,domes,failures=0,0,0,0,0
local function resource()
 live=live+1
 return {release=function(self)assert(not self.freed);self.freed=true;live=live-1 end,
  setFilter=function()end,setWrap=function()end}
end
love={image={newImageData=function()local p=resource();p.setPixel=function()end;return p end},
 graphics={newImage=function()return resource()end}}
local minY=0
local G={newMesh=function(verts,indices)
 for _,p in ipairs(verts)do for _,n in ipairs(p)do assert(n==n and math.abs(n)<1e6)end;minY=math.min(minY,p[2])end
 for _,i in ipairs(indices)do assert(i>=1 and i<=#verts)end
 built=built+1;return resource()
end}
for _,k in ipairs{'draw','seams','glass','shadowReception'}do G[k]=function()end end
local api={Voxel3D=G,Mat4={translate=function()return{}end},sea=Sea,
 resolveStyle=function()return{id='grass'}end,drawDome=function()domes=domes+1 end,
 reportEffectFailure=function(name)assert(name=='sea-water');failures=failures+1 end}
local service=factory(api)
local maps={'ROUTE_20','ROUTE_19','ROUTE_21','PALLET_TOWN','CINNABAR_ISLAND','VERMILION_CITY','ROUTE_12','ROUTE_13'}
local mods={VoxelBattleStage={arena=function(map)return{mid={100,200},map=map}end}}
local host=assert(loadfile('lib/TerarriumHost.lua')){require=function(n)return assert(mods[n],n)end}
host.service=service
for _,id in ipairs(maps)do
 local map={id=id,def={generation=1}}
 assert(not host.stage(map,'side',false).terarrium.seaDesign,'sea replaced land: '..id)
 for _,mode in ipairs{'side','behind'}do
  local a=host.stage(map,mode,true);local s=a.terarrium
  assert(a.map==map and map.sceneryKey==nil and s.id==id and s.family=='coast'and not s.gymDesign and not s.theme)
  assert(s.seaDesign==Sea and s.seaActorHeight)
  assert(s.actors.player[2]==(mode=='side'and -30 or -38))
  assert(s.actors.player[3]==(mode=='side'and -36 or 20))
  service.draw(a,0);local n=built;service.draw(a,0);assert(n==built,'rebuilt while idle')
  assert(minY<-50,'reef lacks depth');assert(live<=12,'unbounded scenery cache')
 end
 map.def.generation=2;assert(not host.stage(map,'side',true).terarrium.seaDesign)
end
for _,id in ipairs{'ROUTE_1','CERULEAN_CITY','SEAFOAM_ISLANDS_B4F','SS_ANNE_BOW'}do
 assert(not host.stage({id=id},'side',true).terarrium.seaDesign,'ocean selected inland/interior')
end
-- Optional shader failure is reported once and does not destroy the reef.
local saved=Sea.newWaterRenderer
Sea.newWaterRenderer=function()return {draw=function()draws=draws+1;error('shader fixture')end,release=function()end}end
local a=host.stage({id='ROUTE_20'},'side',true)
service.overlay(a,0);service.overlay(a,0)
assert(draws==1 and failures==1 and domes==0,'repeated failure or closed sea dome')
service.release();assert(live==0)
service.overlay(a,0);assert(draws==2 and failures==2,'release did not reset failure latch')
service.release();Sea.newWaterRenderer=saved
local waterTriangles=0
Sea.buildWater{quad=function(a,b,c,d,color,alpha)
 assert(alpha>0 and alpha<1 and a[2]==Sea.waterY and b[2]==Sea.waterY)
 waterTriangles=waterTriangles+1
end}
assert(waterTriangles==96)
print('PASS Sea: exact ocean/surf dispatch, land/Gen2 guards, two depths/layouts, finite geometry, bounded cache, failure latch/release, one 96-triangle surface')
-- Imported renderer retains one mesh/program and restores state on draw errors.
local meshes,programs,pushed,waterDraws=0,0,0,0
local fault
local g=love.graphics
function g.newMesh(...)meshes=meshes+1;return resource()end
function g.newShader(...)programs=programs+1;if fault=='compile'then error('compile')end;local r=resource();r.send=function()end;return r end
function g.push()pushed=pushed+1 end
function g.pop()pushed=pushed-1 end
for _,key in ipairs{'setShader','setColor','setBlendMode','setMeshCullMode','setDepthMode'}do g[key]=function()end end
function g.draw()waterDraws=waterDraws+1;if fault=='draw'then error('draw')end end
local renderer=Sea.newWaterRenderer(api)
for i=1,120 do renderer.draw(a,0,i/60)end
assert(meshes==1 and programs==1 and waterDraws==120 and live==2 and pushed==0)
fault='draw';assert(not pcall(renderer.draw,a,0,0)and pushed==0);renderer.release();assert(live==0)
fault='compile';assert(not pcall(renderer.draw,a,0,0)and live==0 and pushed==0)
renderer.release()
-- Execute the actual presentation adapter: only Sea applies actor Y offsets.
local f=assert(io.open('lib/VoxelBattleStage.lua'));local src=f:read('*a');f:close()
local first=assert(src:find('function VoxelBattleStage.presentationPosition',1,true))
local last=assert(src:find('function VoxelBattleStage.presentationGroundY',first,true))
local env={VoxelBattleStage={},finite=function(n)return type(n)=='number'end,authoredSpec=function()end}
local chunk=assert(loadstring(src:sub(first,last-1)));setfenv(chunk,env);chunk()
a.terarriumService=service
local pos=env.VoxelBattleStage.presentationPosition
local x,y,z=pos(a,'player',10);assert(x==75 and y==-20 and z==164)
x,y,z=pos(a,'player',10,true);assert(x==47 and y==12.4 and z==212)
a.terarrium.seaActorHeight=nil;assert(select(2,pos(a,'player',10))==10)
print('PASS Sea water one retained mesh/program, balanced state on failure, partial-allocation cleanup, actor/trainer heights and non-Sea unchanged')
