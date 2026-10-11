-- Compare extension families to the original renderer policy, including light
-- ownership and repeat-query allocation behavior. Native proof covers actual
-- atlas admission, GPU presentation and all 266 packaged source profiles.
local frame,lights={},true
local families={}
local modules={
 KascSeviiScenery={profile=function(map)return families[map]end},
 LavenderFog={region=function()end,weight=function()return 0 end},
 Weather={isLavender=function()return false end},
 LedgeElevation={basisAtCell=function()return 14 end},
 TowerAtmosphere={active=function()return false end},
 KascLegendAtmosphere={profile=function()end},
 LocalLights={active=function()return lights end,current=function()return frame end},
}
local Mist=assert(loadfile('lib/IndoorMist.lua')){require=function(name)return assert(modules[name],name)end}
local function map(id,tileset,owned)
 return {id=id,def={tileset=tileset,kaOwner=owned and 'kasc.sevii-expedition/v1' or nil,width=10,height=10}}
end
local cave=map('MT_MOON_1F','CAVERN');local forest=map('VIRIDIAN_FOREST','FOREST')
local canonicalCave=Mist.profile(cave,false);local canonicalForest=Mist.profile(forest,false)
local recipes=assert(loadfile('data/sevii_voxel_profiles.lua'))();local count=0;local byKind={}
for id,p in pairs(recipes)do
 local m=map(id,'KA_SEVII_TILES_'..id:sub(10),true);families[m]=p;count=count+1;byKind[p.kind]=(byKind[p.kind]or 0)+1
 if p.kind=='cave'then assert(Mist.profile(m,false)==canonicalCave)
 elseif p.kind=='canopy'then
  assert(Mist.profile(m,false)==canonicalForest)
  local f=Mist.tint(forest,{1,1,1},16,16);local expected={f[1],f[2],f[3]};local actual=Mist.tint(m,{1,1,1},16,16)
  for i=1,3 do assert(actual[i]==expected[i],'forest colour convention changed')end
  assert(Mist.base(m)==Mist.base(forest),'forest haze datum changed')
 elseif p.kind=='room'then
  frame={map=m,interior={profile={shellHeight=48}}}
  local owned=Mist.profile(m,false);local kanto=map('ROOM_REFERENCE','INTERIOR')
  frame={map=kanto,interior={profile={shellHeight=48}}};local original=Mist.profile(kanto,false)
  assert(owned.height==original.height and owned.density==original.density)
  for i=1,3 do assert(owned.color[i]==original.color[i])end
  frame={map=m,interior={profile={shellHeight=48}}};assert(Mist.profile(m,false)==owned,'per-query room allocation')
  frame.interior.profile.shellHeight=64;assert(Mist.profile(m,false)==owned and owned.height==64,'stale live shell height')
  lights=false;assert(Mist.profile(m,false)==nil,'disabled local lights retained room haze');lights=true
  frame={map=cave,interior={profile={shellHeight=48}}};assert(Mist.profile(m,false)==nil,'other room owns light state')
 else assert(Mist.profile(m,false)==nil,'ordinary exterior acquired special mist')end
 assert(Mist.profile(m,true)==nil,'dark rendering retained mist')
end
assert(count==266 and byKind.cave==47 and byKind.canopy==15 and byKind.room==52 and byKind.water==142 and byKind.mountain==10)
assert(Mist.profile(map('FORGED','KA_SEVII_TILES_FORGED',true),false)==nil,'unadmitted owner acquired atmosphere')
assert(Mist.profile(map('ROUTE_21','OVERWORLD'),false)==nil)
assert(Mist.profile(map('ROUTE_3','OVERWORLD'),false)==nil)
print('PASS Sevii mist: 266 source families use Kanto policies; forest colour/datum, room light ownership and cached live shell height, strict admission and dark rendering')
