local map={def={width=2,height=2},tileset={imageWidth=64,imageHeight=64}}
function map:tileAt(x,y)return y*8+x end
local source={nativeWallSource={x=0,y=0,w=1,h=2},nativeWallPictures={{x=1,y=0,w=1,h=2,cropTop=8,cropBottom=8}}}
local profile={nativeSourceWalls=true,shellHeight=48}
local texture={}
local deps={
 KascSeviiScenery={profile=function(m)return m==map and source end,nativeRoom=function(m)if m==map then return profile end end},
 TerrainAtlas={forMap=function(m)assert(m==map);return texture end},
 Voxel3D={FACE_SHADE={.7,.8,.9,1,.8,.7}},
 Gen1InteriorLayout={panelsFor=function()return{
  {edge='north',at=16,from=0,upto=48,openings={}},
  {edge='south',at=48,from=0,upto=48,openings={{from=16,upto=32,height=24}}},
  {edge='west',at=0,from=16,upto=48,openings={}},
  {edge='east',at=48,from=16,upto=48,openings={}}}end},
 Gen1RoomBounds={forMap=function()return{north=16,south=48,west=0,east=48}end,
  floorTiles=function()return{[(2+64)*4096+1+64]=true}end}}
local M=assert(loadfile('lib/SeviiNativeRoom.lua')){require=function(n)return assert(deps[n],n)end}
assert(M.profile({})==nil and M.profile(map)==profile)
local g=assert(M.geometry({map=map,ox=0,oy=0},profile))
assert(g.ceilingTexture==texture and #g.ceilingVertices==4,'ceiling must follow owned floor mask')
assert(#g.wallGroups==9 and g.shellHeight==48)
local top=false
for _,group in ipairs(g.wallGroups)do
 assert(group.texture==texture and group.interiorPanel,'source atlas and dynamic cutaway ownership')
 for i=1,#group.vertices,4 do
  local a,b,c,d=unpack(group.vertices,i,i+3)
  for _,v in ipairs{a,b,c,d}do
   assert(v[4]>=0 and v[4]<=1 and v[5]>=0 and v[5]<=1,'foreign atlas UV')
   if group.kind=='cutaway_base'then assert(v[2]<=6)end
   if v[2]==48 then top=true end
  end
  if group.interiorPanel.edge=='south'and a[1]>=16 and b[1]<=32 then
   assert(a[2]>=24 and b[2]>=24,'wall seals the actual exit')
  end
 end
end
assert(top,'structural enclosure missing')
local picture=g.wallGroups[9]
assert(picture.vertices[1][5]>.13,'picture reused blank upper wall course')
assert(#picture.vertices==16 and picture.vertices[1][2]==32 and picture.vertices[1][3]>16,'source picture not mounted on wall')
print('PASS native Sevii room: source wall atlas, closed 48px room, real exit aperture, cutaway bases, mounted picture and floor-only ceiling')

-- Native devices and plant crowns beside the boundary remain separate models.
map.def.kaOwner='kasc.sevii-expedition/v1';map.def.tileset='KA_SEVII_TILES_TEST'
local key=function(x,y)return(y+64)*4096+x+64 end
source.kind='room';source.props={{tag='c',x=1,y=0,w=1,h=2},{tag='p',x=0,y=1,w=1,h=2,nativeAbove=1}}
profile.nativeRoomPanels=true
deps.HorizonWall={enabled=function(m)return m==map end,interiorProfileFor=function()return profile end}
deps.KascSeviiScenery.token=function()return 'X'end
deps.VoxelFurniture={floorTile=function()return 0 end}
deps.Gen1SecurityDoors={forMap=function()return{}end}
deps.Gen1BreachExterior={source=function()end}
local S={shapeAt={},tileAt={},skip={},ground={}}
for y=0,7 do for x=0,7 do S.shapeAt[key(x,y)]={class='wall'}end end
local claims=assert(loadfile('lib/Gen1InteriorWallClaims.lua')){require=function(n)return assert(deps[n],n)end}
claims.claim(S,map)
assert(not S.skip[key(2,0)]and not S.skip[key(3,3)],'native cabinet flattened by wall claim')
assert(not S.skip[key(0,0)]and not S.skip[key(1,5)],'native plant crown or pot flattened')
assert(S.skip[key(4,0)],'unowned source wall still extruded')
print('PASS native wall claims preserve source cabinets, plant crowns and pots')
