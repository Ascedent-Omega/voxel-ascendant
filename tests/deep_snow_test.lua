local selected='deep';local W={}
local modules={ModSetting={new=function()return{get=function()return selected end}end},WorldWeather=W}
local D=assert(loadfile('shared/DeepSnow.lua')){require=function(n)return assert(modules[n],n)end}
local map={inBounds=function(_,x,z)return x>=0 and x<20 and z>=0 and z<20 end,isWarpTileCell=function(_,x,z)return x==8 and z==8 end}
local function ground(_,x,z)return 0,true,0,x<144 and not(x>30 and x<48 and z<100)end
local verts,n=D.build({map=map},{80,0,80},ground)
assert(n>0 and n<=D.MAX_QUADS and #verts==n*6)
for i=1,#verts,6 do
 local q=verts[i]
 if q[5]>.9 then -- top faces, not sides
  assert(q[1]<144,'snow on water/blocked cell')
  local cx,cz=math.floor(q[1]/16),math.floor(q[3]/16)
  assert(math.abs(cx-8)+math.abs(cz-8)>1,'snow blocks entrance')
  assert(q[4]==2 or q[4]==3 or q[4]==4,'non-voxel drift depth')
 end
end
local anchor=D.anchor({160,15,110},{160,45,290})
assert(anchor[3]==192,'foreground camera excluded from drift coverage')
local capped=D.anchor({0,0,0},{0,0,10000});assert(capped[3]==96,'unbounded vista patch')
local empty,m=D.build({map=map},{80,0,80},function()return 20,false,0,false end)
assert(m==0 and #empty==0,'snow underneath roof')
local step,l=D.build({map=map},{80,0,80},function(_,x,z)return 0,true,x%8<4 and 0 or 8,true end)
assert(l==0,'snow bridges elevation edge')
selected='normal';assert(not D.draw({map=map},'snow') and D.last.draws==0,'normal mode allocates')
print('PASS deep snow bounds, terraced levels, entrances, roofs, water and elevation edges')
-- Same surface result with far fewer expensive native terrain lookups.
local shapeCalls=0
local C={height=function(_,x,z)return x<32 and 24 or nil end}
local terrain={def={},inBounds=function()return true end,tileAt=function()return 1 end,isWalkableCell=function()return true end}
local ms={WeatherCover=C,TileShape={forMap=function()return{}end,at=function()shapeCalls=shapeCalls+1;return{art='flat',h=0}end},LedgeElevation={map=function()return{at=function()return 0 end}end}}
local R=assert(loadfile('shared/WorldWeather.lua')){require=function(n)return assert(ms[n],n)end}
local stats={};local sample=R.sampler(terrain,stats)
for z=0,31 do for x=0,63 do
 local a,b,c,d=R.surface(terrain,x,z);local aa,bb,cc,dd=sample(terrain,x,z)
 assert(a==aa and b==bb and c==cc and d==dd,'memoized sampler changed surface')
end end
assert(stats.samples==2048 and stats.groundCells==8)
print('PASS exact sampler parity',stats.samples,'samples /',stats.groundCells,'native cell resolutions')

local C=assert(loadfile('shared/WeatherCover.lua'))()
local calls=0;C.provider=function()calls=calls+1 end
C.prepare({map=terrain},'clear');assert(calls==0 and C.active==false,'dry frame scans roof props')
local uniforms={};C.bind({hasUniform=function()return true end,send=function(_,k,v)uniforms[k]=v end})
assert(uniforms.weatherCoverOn==0,'dry frame leaves cover sampling enabled')
print('PASS dry weather skips roof preparation and disables texture sampling')
local setting='normal';local outdoor=true;local amount=.8;local mode='snow';local revision=1
local draws,uploads,builds,releases,pushes,pops=0,0,0,0,0,0
local fail=false
love={image={newImageData=function()return{setPixel=function()end,release=function()end}end},graphics={
 newMesh=function()return{setVertices=function()uploads=uploads+1 end,setDrawRange=function()end,release=function()releases=releases+1 end}end,
 newImage=function()return{setFilter=function()end,release=function()releases=releases+1 end}end,
 push=function()pushes=pushes+1 end,pop=function()pops=pops+1 end,setDepthMode=function()end,setMeshCullMode=function()end,setColor=function()end}}
local no=function()end
local g={vp={},focus={0,0,0},FORMAT={},weatherGround=no,weatherGrass=no,glass=no,seams=no,
 draw=function()if fail then error('injected snow upload/draw failure')end;draws=draws+1 end}
local mods={SnowTracks={draw=function()end},ModSetting={new=function()return{get=function()return setting end}end},Weather={isOutdoor=function()return outdoor end},
 WeatherTweak={groundMode=function()return mode end,groundAmount=function()return amount end},Voxel3D=g,WeatherCover={revision=function()return revision end}}
local X=assert(loadfile('shared/DeepSnow.lua')){require=function(n)return assert(mods[n],n)end}
X.build=function()builds=builds+1;return{{0,0,0,4,3},{8,0,0,4,3},{0,0,8,4,3},{0,0,0,4,3},{8,0,0,4,3},{0,0,8,4,3}},1 end
local state={map={}}
assert(not X.draw(state,mode) and builds==0)
setting='deep';assert(X.draw(state,mode));assert(X.draw(state,mode));assert(builds==1 and uploads==1 and draws==2)
amount=.45;assert(X.draw(state,mode));assert(builds==1 and uploads==2,'thaw rebuilds terrain rather than updating heights')
mode='clear';assert(not X.draw(state,mode) and draws==3)
mode='snow';outdoor=false;assert(not X.draw(state,mode));outdoor=true
revision=2;assert(X.draw(state,mode));assert(builds==2,'roof revision ignored')
fail=true;assert(not X.draw(state,mode) and X.error and pushes==pops)
fail=false;assert(not X.draw(state,mode),'failed renderer retried every frame')
X.invalidate();assert(releases==2);assert(X.draw(state,mode),'renderer did not recover')
print('PASS normal/indoor/melt zero work, retained geometry, buildup uploads, roof revision and context recovery')
local a={player={64,64},enemy={128,64}}
local banks,m=D.build({map=map,snowArena=a},{80,0,80},ground)
local normal,count=D.build({map=map},{80,0,80},ground)
local tops,plain={},{}
for i=1,#banks,6 do local q=banks[i];if q[5]>1.5 then
 assert(q[4]==4,'battle surface differs from foot support');tops[q[1]..':'..q[3]]=true
end end
for i=1,#normal,6 do local q=normal[i];if q[5]>1.5 then plain[q[1]..':'..q[3]]=true end end
for k in pairs(plain)do assert(tops[k],'battle cutout or camera corridor remains')end
for k in pairs(tops)do assert(plain[k],'battle snow ignores roof/terrain restrictions')end
local bare,m=D.build({map=map},{80,0,80},function()return 0,true,0,true,true end)
assert(m==0,'jump approach covered')
mods.Weather.setting={get=function()return 'snow'end};mods.Weather.modeAt=function()return mode end
amount=1;mode='snow';assert(X.battleLift(state.map,a)==4.045 and X.buriesFlowers(state.map))
amount=.45;assert(X.battleLift(state.map,a)==1.295 and not X.buriesFlowers(state.map),'thaw support out of sync')
assert(X.battleLift(state.map,{discs=true})==0 and X.battleLift(state.map,{portableStage=true})==0)
setting='normal';assert(X.battleLift(state.map,a)==0 and not X.buriesFlowers(state.map))
setting='deep';outdoor=false;assert(X.battleLift(state.map,a)==0 and not X.buriesFlowers(state.map))
ms.TileShape.at=function()return{art='flower',flat=true,class='flower',h=0}end
local _,_,h,land=R.surface(terrain,48,0);assert(h==0 and land,'flower ground leaves snow holes')
local _,_,h,land=R.surface(terrain,16,0);assert(not land,'flower classification bypasses roof cover')
print('PASS continuous battle surface, matching actor support/thaw, buried flowers and protected ledges')

-- Authored voxel flowers use the prop batch in both sun and colour passes.
local buried=true;local calls=0
package.loaded["src.render.Assets"]={register=function()end}
local B=assert(loadfile('lib/VoxelPropBatch.lua')){require=function(n)
 if n=='Voxel3D'then return{}end
 if n=='DeepSnow'then return{buriesFlowers=function()return buried end}end
 error(n)
end}
local function each(_,draw)
 draw('flower',nil,nil,1,{frost=true,snowBuried=true})
 draw('tree',nil,nil,1,{seasonalFoliage=true})
end
for _,pass in ipairs{'color','shadow','battle-color','battle-shadow'}do
 calls=0;B.draw({map={}},each,function(mesh)assert(mesh=='tree');calls=calls+1 end,pass)
 assert(calls==1,'buried voxel flower still draws/casts')
end
buried=false;calls=0;B.draw({map={}},each,function()calls=calls+1 end)
assert(calls==2,'flowers do not return after thaw')
print('PASS voxel flower burial in colour/shadow fallback and restoration')
