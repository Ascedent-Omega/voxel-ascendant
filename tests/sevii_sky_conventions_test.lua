-- Source-family policy uses the admitted presentation contract. Actual atlas
-- admission and rendered day/night/light ownership are covered by native QA.
local families={};local modules={
 CompactBackgroundAssets={},Voxel3D={},WorldPlacement={},Gen1CavePanoramas={},GymSkylights={},
 Gen1InteriorPanoramas={assets={},profileFor=function()end},Gen1GymInteriors={profiles={}},
 ModSetting={new=function()return{get=function()return'full'end}end},
 HorizonAddressCache={new=function()return{}end},
 KascSeviiScenery={profile=function(map)return families[map]end},
 SilphWindows={enabled=function()return false end},
 Gen1Rooftops={matches=function(map)return map.id=='CELADON_MART_ROOF' or map.id=='CELADON_MANSION_ROOF'end},
}
package.loaded['src.render.TileRenderer']={}
local H=assert(loadfile('lib/HorizonWall.lua')){require=function(n)return assert(modules[n],n)end}
local recipes=assert(loadfile('data/sevii_voxel_profiles.lua'))();local count,open,closed,quays,roof=0,0,0,0,0
for id,p in pairs(recipes)do
 local m={id=id,def={kaOwner='kasc.sevii-expedition/v1',outdoor=p.outdoor,tileset='KA_SEVII_TILES_'..id:sub(10)}};families[m]=p
 local expected=p.exterior==true and p.kind~='canopy';count=count+1
 assert(H.hasSky(m)==expected,'source sky convention mismatch '..id)
 assert(H.isOutdoorMap(m)==p.exterior,'source weather/exterior semantics changed '..id)
 if expected then open=open+1 else closed=closed+1 end
 if p.source:match('Island_Harbor$')then assert(expected and not p.outdoor);quays=quays+1 end
 if p.source=='TrainerTower_Roof'then assert(expected and not p.outdoor);roof=roof+1 end
end
assert(count==266 and quays==7 and roof==1 and open+closed==266)
for _,id in ipairs{'VERMILION_DOCK','SS_ANNE_BOW','CELADON_MART_ROOF','CELADON_MANSION_ROOF'}do
 assert(H.hasSky({id=id,def={tileset='INTERIOR',outdoor=false}}),'canonical open-air reference lost sky '..id)
end
assert(not H.hasSky({id='VIRIDIAN_FOREST',def={tileset='FOREST',outdoor=false}}))
assert(not H.hasSky({id='MT_MOON_1F',def={tileset='CAVERN',outdoor=false}}))
assert(not H.hasSky({id='FORGED',def={kaOwner='kasc.sevii-expedition/v1',tileset='INTERIOR',outdoor=false}}))
assert(not H.hasSky(nil))
print('PASS Sevii sky: all 266 source policies, 7 open-air ferry quays, Tower roof; closed canopy/cave and Kanto references preserved')
