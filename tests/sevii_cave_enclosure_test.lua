local profiles=assert(loadfile('data/sevii_voxel_profiles.lua'))()
local count=0
for id,p in pairs(profiles)do if p.kind=='cave'then
 count=count+1
 assert(p.caveEdges and #p.caveEdges==p.size[2]*2,id..' lacks source contour')
 assert(p.caveBody and #p.caveBody==p.size[2]*2,id..' lacks source playfield')
 for _,row in ipairs(p.caveEdges)do
  assert(#row==p.size[1]*2,id..' has incomplete contour')
  for i=1,#row do assert(row:byte(i)>=33 and row:byte(i)<=48)end
 end
 assert(p.caveCeiling>=96 and not p.exterior,id..' has an open cave roof')
end end
assert(count>30,'cavern families omitted')
-- A source border with one real exit, one rock face, one internal pit and
-- one fragment seam. Only the two authored outside edges acquire walls.
local map={def={width=2,height=1}}
map.tileset={imageWidth=512,imageHeight=256}
map.tileAt=function(_,x,y)return y*64+x end
local p={kind='cave',caveCeiling=138,caveEdges={string.char(37,37,33,33),'!!!!'}}
local tags={{'E','C','V','G'},{'G','G','G','G'}}
local S={profile=function()return p end,
 token=function(_,x,y)return tags[y/2+1][x/2+1]end,
 portalAt=function(_,x,y)return x==0 and y==0 end,
 elevation=function()return{at=function()return 42 end}end}
map.isWalkableCell=function(_,x,y)return not(x==1 and y==0)end
map.isWaterCell=function()return false end
local V={require=function(n)
 if n=='KascSeviiScenery'then return S end
 if n=='Gen1CavePanoramas'then return{materialFor=function()return'cave_seafoam'end}end
 if n=='TerrainAtlas'then return{forMap=function()return'original-atlas'end}end
 error(n)
end}
local M=assert(loadfile('lib/SeviiCaveEnclosure.lua'))(V)
local a=M.geometry({map=map,ox=32,oy=64})
assert(a.caveBoundaryPanels==2,'pit or partition seam became an enclosure wall')
assert(a.shellHeight==138 and a.wallGroups[1].family=='cave_seafoam')
assert(a.wallGroups[1].unmaskedRoom,'floor mask still clips the high cave panorama')
assert(a.ceilingFamily=='interior_ceiling'and a.ceilingTextureFamily=='cave_seafoam',
 'cave roof reuses the floor reachability mask or loses its ice material')
local v=a.wallGroups[1].vertices
assert(v[1][2]==74 and v[2][2]==74,'real cave exit blocked below its lintel')
assert(v[5][2]==42 and v[6][2]==42,'rock-wall foot separated from its course')
assert(#a.ceilingVertices==28,'void pit filled or source roof omitted')
assert(p.caveEdges[1]==string.char(37,37,33,33),'source geometry mutated')
local native=M.geometry({map=map,ox=32,oy=64},nil,nil,nil,true)
assert(native.wallGroups[1].texture=='original-atlas'and native.wallGroups[1].family=='native_sevii_cave')
assert(native.ceilingTexture=='original-atlas','normal cave roof lost its original art')
for _,q in ipairs(native.wallGroups[1].vertices)do assert(q[4]>=0 and q[4]<=1 and q[5]>=0 and q[5]<=1,'native cave UV outside live atlas')end
S.profile=function()return{kind='mountain'}end
assert(M.geometry({map=map})==nil,'open-sky volcano acquired a ceiling')
print('PASS '..count..' source cavern contours, Kanto panorama ownership, enclosed roof, native exit clearance, preserved pits/seams and open-sky volcano')
