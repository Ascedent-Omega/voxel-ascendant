-- Exercise the shared Kanto grass mesher with opaque RGB Sevii art. Floor
-- texels must never become standing quads, while spacing/height stay native.
package.loaded['src.render.Assets']={register=function()end}
package.loaded['src.world.Map']={}
local sevii={};local foreign={}
local N=assert(loadfile('lib/SeviiNativeVoxel.lua')){require=function(name)
 assert(name=='KascSeviiScenery');return{profile=function(m)return m==sevii and{}or nil end}
end}
local S=assert(loadfile('lib/Structures.lua')){require=function(name)
 if name=='SeviiNativeVoxel'then return N end
 if name=='BuildBudget'then return{tick=function()end}end
 return{}
end}
local function template(map,pixels)
 for i=1,50 do local name,fn=debug.getupvalue(S.buildGrass,i)
  if name=='grassTemplate'then return fn(map,pixels,0)end
 end
 error('missing grass mesher')
end
sevii.tileset={imageWidth=8,imageHeight=8,tilesPerRow=1};foreign.tileset=sevii.tileset
local blade={58/255,148/255,49/255,1};local floor={115/255,206/255,165/255,1}
local pixels={getPixel=function(_,x,y)return unpack(x>=2 and x<=4 and y>=2 and blade or floor)end}
local quads=template(sevii,pixels);assert(#quads>0)
local maxHeight=0
for _,q in ipairs(quads)do
 for _,v in ipairs(q)do assert(v[1]>=2 and v[1]<=5,'background became a standing sheet');maxHeight=math.max(maxHeight,v[2]);assert(v[3]>=3 and v[3]<=5,'Kanto tuft depth changed')end
 for _,uv in ipairs(q.uv)do assert(N.grassMask(sevii)(pixels:getPixel(math.floor(uv[1]*8),math.floor(uv[2]*8))),'grass face samples floor')end
end
assert(maxHeight==6,'native blade height changed')
assert(#template(sevii,{getPixel=function()return unpack(floor)end})==0,'background-only art is a slab')
assert(#template(foreign,{getPixel=function()return .1,.1,.1,1 end})>0,'ordinary Kanto grass altered')
assert(#template(foreign,{getPixel=function()return 1,1,1,1 end})==0,'Kanto white transparency altered')
local grid={shapeAt={},tileAt={}};sevii.def={width=1,height=1}
sevii.isGrassCell=function(_,x,y)return x==0 and y==0 end
for y=0,3 do for x=0,3 do local key=(y+64)*4096+x+64;grid.shapeAt[key]={art='grass'};grid.tileAt[key]=0 end end
S.buildGrass(grid,sevii,0,3,0,3,pixels)
assert(#grid.grassGroups==1 and #grid.grassGroups[1].placements==8,'decorative lawn grew encounter tufts')
local p=grid.grassGroups[1].placements
assert(p[1]==0 and p[2]==0 and p[3]==8 and p[4]==0 and p[5]==0 and p[6]==8 and p[7]==8 and p[8]==8,'four Kanto tuft positions changed')
print('PASS Sevii RGB grass: shared Kanto mesh, free blade silhouette, no floor sheets, native spacing/height, foreign masks and encounter ownership')

local canonical={getWidth=function()return 128 end,getHeight=function()return 48 end,
 getPixel=function(_,x,y)if x%8==3 and y>=42 then return .1,.1,.1,1 end;return 1,1,1,1 end}
package.loaded['src.render.Assets'].imageData=function()return canonical end
local tuft=assert(S.kantoGrassTemplate());assert(#tuft>0 and S.kantoGrassTemplate()==tuft,'canonical tuft cache')
local enabled=true
local O=assert(loadfile('lib/Gen1OutdoorScenery.lua')){require=function(name)
 if name=='ModSetting'then return{new=function()return{get=function()return enabled end}end}end
 if name=='KascSeviiScenery'then return{profile=function(m)return m==sevii and{exterior=true,kind='canopy',source='ThreeIsland_BerryForest'}or nil end}end
 if name=='SeviiLandscape'then return assert(loadfile('lib/SeviiLandscape.lua'))()end
 if name=='Structures'then return S end
 error(name)
end}
sevii.def.kaOwner='kasc.sevii-expedition/v1'
local original=grid.grassGroups;local full=O.grassGroups(sevii,original)
assert(#full[1].placements==#original[1].placements and #full[1].quads==#tuft,'replacement changed field density')
for i,v in ipairs(original[1].placements)do assert(full[1].placements[i]==v,'replacement moved grass')end
for i,q in ipairs(full[1].quads)do
 assert(q.uv[1][1]==-166 and q.shade==tuft[i].shade,'Kanto tuft material/shading differs')
 for j=1,4 do for k=1,3 do assert(q[j][k]==tuft[i][j][k],'Sevii full geometry differs from Kanto')end end
end
enabled=false;assert(O.grassGroups(sevii,original)==original,'overhaul OFF lost original grass')
print('PASS full Sevii grass: exact existing Kanto tuft geometry/material/shading, shared placements and independent original mode')
