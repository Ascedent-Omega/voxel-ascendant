local root=arg and arg[1]or '.'
local style=assert(loadfile(root..'/shared/SkyStyle.lua'))()
local stars,ys={},{};local bins={0,0,0,0,0,0,0,0};local bands={0,0,0,0}
for i=1,224 do
 local d,az,el=style.star(i);stars[i]=d
 assert(math.abs(d[1]^2+d[2]^2+d[3]^2-1)<1e-10)
 assert(d[2]>.03 and d[2]<1)
 assert(not ys[d[2]],'repeated elevation creates latitude rows');ys[d[2]]=true
 local k=math.min(8,math.floor((az+math.pi)/(2*math.pi)*8)+1);bins[k]=bins[k]+1
 k=math.min(4,math.floor(d[2]*4)+1);bands[k]=bands[k]+1
end
for _,n in ipairs(bins)do assert(n>=12 and n<=44,'empty/dense azimuth sector')end
for _,n in ipairs(bands)do assert(n>=35 and n<=78,'hemisphere density distorted')end
local again=assert(loadfile(root..'/shared/SkyStyle.lua'))()
for i=224,1,-1 do
 local d=again.star(i);assert(d[1]==stars[i][1] and d[2]==stars[i][2],'sample order changes sky')
 for j=1,i-1 do local p=stars[j];assert(d[1]*p[1]+d[2]*p[2]+d[3]*p[3]<.9991,'coincident stars')end
end
local V={require=function()error('unexpected runtime module')end}
local W=assert(loadfile(root..'/shared/WorldWeather.lua'))(V)
local map={inBounds=function(_,x,z)return x>=0 and z>=0 and x<100 and z<100 end}
local function ground(_,x,z)return (x<160 and 0 or 16),z<180 end
local rain,n=W.build(map,{160,0,160},false,nil,ground)
assert(#rain==n*6 and n<=W.MAX_QUADS)
local storm,sn=W.build(map,{160,0,160},true,nil,ground)
assert(sn>n and sn<=W.MAX_QUADS)
local splashes=0
for i=1,#rain,6 do
 local p=rain[i];assert(p[2]==(p[1]<160 and 0 or 16),'wrong ground height')
 if p[9]==1 then splashes=splashes+1;assert(p[3]<180,'splash on excluded surface')end
end
assert(splashes>0)
-- Shared lattice addresses stay exactly in place after a camera cell crossing.
local moved=W.build(map,{193,0,160},false,nil,ground)
local original={};for i=1,#rain,6 do local p=rain[i];original[p[1]..':'..p[3]..':'..p[9]]=p end
local common=0
for i=1,#moved,6 do local p=moved[i];local o=original[p[1]..':'..p[3]..':'..p[9]]
 if o then common=common+1;assert(p[2]==o[2]and p[6]==o[6])end
end
assert(common>n*.70,'rain swims with camera')
local t=W.advance(100,false);local t2=W.advance(100.1,true);assert(t2>t)
assert(W.advance(100.1,true)==t2,'VR eyes advance the same clock twice')
assert(W.advance(0,false)==t2,'reset makes rain rise')
assert(W.advance(.1,false)>t2,'rain failed to resume')
print('PASS weather sky: spherical distribution, stable samples, bounded rain, surfaces, seams, monotonic clock')
-- Failure must restore graphics state and retain the 2D fallback; successful
-- static-camera frames reuse the uploaded mesh instead of growing GPU state.
local oldLove=love;local pushes,pops,uploads,draws,compiles=0,0,0,0,0
local throwDraw=false
love={graphics={newShader=function()compiles=compiles+1;return{send=function()end,release=function()end}end,
 newMesh=function()return{setVertices=function()uploads=uploads+1 end,setDrawRange=function()end,release=function()end}end,
 push=function()pushes=pushes+1 end,pop=function()pops=pops+1 end,
 setShader=function()end,setDepthMode=function()end,setMeshCullMode=function()end,setBlendMode=function()end,setColor=function()end,
 draw=function()if throwDraw then error('injected context loss')end;draws=draws+1 end}}
local weather={clock=1,isOutdoor=function(m)return m.outdoor end}
local G={vp={1,0,0,0,0,1,0,0,0,0,1,0,0,0,0,1},focus={160,0,160},eye={160,30,200}}
local modules={RainStrength={profile=function()return{key="normal",drops=3,alpha=1}end},Weather=weather,Voxel3D=G,WeatherCover={revision=function()return 0 end}}
local R=assert(loadfile(root..'/shared/WorldWeather.lua')){require=function(n)return assert(modules[n],n)end}
R.build=function()return rain,n end
local scene={map={outdoor=true}}
assert(R.draw(scene,'clear')==false and compiles==0)
assert(R.draw(scene,'rain'));weather.clock=1.1;assert(R.draw(scene,'rain'))
assert(uploads==1 and draws==2 and pushes==pops,'mesh reuse/state failure')
scene.map.outdoor=false;assert(not R.draw(scene,'rain')and draws==2)
scene.map.outdoor=true;throwDraw=true;assert(not R.draw(scene,'rain')and pushes==pops)
throwDraw=false;assert(not R.draw(scene,'rain'),'failed program retried every frame')
R.invalidate();assert(R.draw(scene,'rain')and compiles==2,'context recovery failed')
love=oldLove
print('PASS retained batch, indoor/off zero-work, graphics restoration and context recovery')
local starters=assert(loadfile(root..'/shared/StarterConstellations.lua'))()
local expected={{'SQUIRTLE','BULBASAUR','CHARMANDER'},{'CHIKORITA','CYNDAQUIL','TOTODILE'}}
for gen,defs in ipairs(starters)do
 assert(#defs==3)
 for i,def in ipairs(defs)do
  assert(def.id==expected[gen][i]);assert(#def.points<=36 and #def.segments<=38)
  for _,seg in ipairs(def.segments)do
   assert(def.points[seg[1]] and def.points[seg[2]] and seg[1]~=seg[2])
  end
  for _,p in ipairs(def.points)do assert(math.abs(p[1])<=7 and math.abs(p[2])<=6)end
  if gen==2 then assert(def.az==starters[1][i].az and def.el==starters[1][i].el)end
 end
end
for _,night in ipairs{0,.5,1}do
 local r,g,b=style.wetCloudTint('rain',night)
 local s=style.wetCloudTint('storm',night)
 assert(r==g and g==b and r<=.52 and s<r and s>0)
end
assert(style.wetCloudTint('rain',1)<style.wetCloudTint('storm',0),'night cloud is too bright')
print('PASS regional starter identities, shared positions, geometry budgets and neutral wet-cloud palette')
