-- A packaged window cache must not remove landmarks outside the near crop.
local active=true
local house={source='CELADON_CITY',width=96,depth=64,height=70}
local modules={}
local V={require=function(k)return assert(modules[k],k)end}
modules.ModSetting={new=function()return{get=function()return true end}end}
modules.HouseWindows={describe=function()return house end,source=function()return house and house.source end,
 anchor=function()return house and{x=-100,y=-house.height,z=-200}end,mask=function()end}
modules.SilphElevator={matches=function()return false end}
modules.VoxelItems={models={silph={template='silph_co',frameW=128,depth=192}},palette={}}
modules.VoxelFurniture={findBuildings=function()return{{kind='silph',tx=32,ty=20}}end}
modules.Voxel3D={}
local baked={bakedWindow=true}
modules.WindowImageCache={load=function()return{},{baked}end}
modules.RooftopWorld={geometry=function()error('cache hit rebuilt city')end,texture=function()end}
local sourceId,coords
modules.CinnabarVolcano={active=function()return active end,
 position=function(id)sourceId=id;return -2000,3000 end,
 meshes=function(x,z,y,yieldStep,out)coords={x,y,z};out=out or{};
  out[#out+1]={magma=false};out[#out+1]={magma=true};return out end}
package.loaded['src.core.Game']={data={maps={CELADON_CITY={tileset='OVERWORLD'},CINNABAR_ISLAND={tileset='OVERWORLD'},SAFFRON_CITY={tileset='OVERWORLD'}},tilesets={OVERWORLD={}}}}
package.loaded['src.world.Map']={new=function(d)return{def=d}end}
local W=assert(loadfile('lib/SilphWindows.lua'))(V)
local entry={map={id='CELADON_MART_5F'},w=320,h=128}
local parts=W.build(entry)
assert(sourceId=='CELADON_CITY'and #parts==3 and parts[3]==baked)
assert(coords[1]==-2212 and coords[2]==-70 and coords[3]==2832,'wrong house plot transform')
for i=1,2 do assert(parts[i].windowLandmark=='cinnabar_volcano'and parts[i].class=='silph_exterior')end
house.source='CINNABAR_ISLAND';house.height=0
W.build(entry);assert(sourceId=='CINNABAR_ISLAND'and coords[2]==0,'house source hard-coded to Saffron')
house=nil;entry.map={id='SILPH_CO_11F',def={width=9,height=9,tileset='INTERIOR'}};entry.w,entry.h=288,288
W.build(entry);assert(sourceId=='SAFFRON_CITY'and coords[2]==-248,'Silph floor altitude changed')
active=false;parts=W.build(entry);assert(#parts==1 and parts[1]==baked,'classic panorama retained volcano')
print('PASS window volcano on cache hits, house source/plot/floor, Silph floor and classic toggle')
