local profiles=assert(loadfile('data/sevii_voxel_profiles.lua'))()
local L=assert(loadfile('lib/SeviiLandscape.lua'))()
local volcano,roof,ice=0,0,0
for id,p in pairs(profiles)do
 if p.source=='MtEmber_Exterior'or p.source=='MtEmber_Summit'then
  volcano=volcano+1
  assert(p.exterior and not p.outdoor and p.kind=='mountain',id..' remains an interior')
  assert(p.courses and not p.nativeWallSource,'volcano has no source terraces or retained house shell')
  assert(L.region(p)=='volcano'and L.stoneMaterial(p)==-180)
  for _,tags in ipairs(p.blocks)do assert(not tags:match('[BZ]'),'volcanic cliffs became houses or ferries')end
  assert(L.groundMaterial(p,'g')==-159,'volcano meadow lost Kanto grass')
 elseif p.source=='TrainerTower_Roof'then
  roof=roof+1;assert(p.exterior and not p.outdoor and p.kind=='water')
  assert(not p.nativeWallSource and L.region(p)=='tower_roof')
 elseif p.source:find('IcefallCave',1,true)then
  ice=ice+1;assert(p.kind=='cave'and not p.exterior and p.cave=='seafoam')
  if p.source=='FourIsland_IcefallCave_Entrance'then
   assert(p.waterfallRelief and p.courses,'source cascade has no relief')
   local high=0;for _,row in ipairs(p.courses)do for i=1,#row do high=math.max(high,(row:byte(i)-33)*6)end end
   assert(high>12,'upper and lower waterfall ponds still at the same height')
  end
 elseif p.source=='OneIsland_KindleRoad_EmberSpa'then
  assert(p.waterfallRelief and p.courses,'map-edge hot-spring cascade lost its relief')
 end
end
assert(volcano>1 and roof>0 and ice>=4,'incomplete source features')
local P={models={},decorColors={silphGlass=68}}
assert(loadfile('lib/SeviiIce.lua'))().register(P)
for variant=1,4 do
 local model=assert(P.models['sevii_iceberg_'..variant]);local low,high=100,0
 assert(#model.boxes>10,'iceberg is a single box')
 for _,b in ipairs(model.boxes)do
  assert(b[1]>=0 and b[3]>=0 and b[1]+b[4]<=16 and b[3]+b[6]<=16,'ice blocks neighbouring plot')
  assert(b[4]>0 and b[5]>0 and b[6]>0)
  high=math.max(high,b[2]+b[5]);low=math.min(low,b[2]+b[5])
 end
 assert(high>low+2,'ice silhouette has a flat lid')
end
print('PASS source landscapes: open Glutberg/summit and tower roof, cave-only glacier, bounded faceted ice, Kanto meadow preservation')
local landforms=assert(loadfile('lib/SeviiLandforms.lua'))()
local map={def={width=1,height=1},isWalkableCell=function()return false end,isWaterCell=function()return false end}
local palette={looseRock1=40,looseRock2=41,looseRock3=42,looseRock4=43,looseRock6=45,leafDark=10,iceMid=80,iceFrost=82}
local models={models={},decorColors=palette}
local a={origin={0,0},cliffMasks={string.char(48)..string.char(48)}}
local function token()return'C'end
local function portal()end
local kind=landforms.kind(models,a,map,0,0,token,portal,'basalt')
assert(kind:find('_15_',1,true),'runtime fragment edge bevel replaced full source neighbour mask')
local b={origin={-1,0},cliffMasks={string.char(48)..string.char(48)}}
assert(kind==landforms.kind(models,b,map,1,0,token,portal,'basalt'),'model phase changes across runtime partitions')
for _,box in ipairs(models.models[kind].boxes)do
 assert(box[1]>=0 and box[3]>=0 and box[1]+box[4]<=16 and box[3]+box[6]<=16,'cliff spills into walking plot')
end
local iceKind=landforms.kind(models,a,map,0,0,token,portal,'ice')
assert(iceKind~=kind and models.models[iceKind].boxes[1][7]==80,'glacier reused basalt palette')
print('PASS cohesive landforms: source seam masks, stable global phase, bounded cliff courses and separate ice palette')

-- The actual source cliff chain must stay connected when split into runtime
-- maps. Adjacent joined caps may step by one voxel, never fall to ground.
local function top(model,x,z)
 local height=0
 for _,box in ipairs(model.boxes)do
  if x>=box[1]and x<box[1]+box[4]and z>=box[3]and z<box[3]+box[6]then
   height=math.max(height,box[2]+box[5])
  end
 end
 return height
end
for _,family in ipairs{'coastal','canyon','forest','basalt','ice'}do
 for px=0,3 do for pz=0,3 do
  local left={origin={px,pz},cliffMasks={string.char(48)..string.char(48)}}
  local right={origin={px+1,pz},cliffMasks={string.char(48)..string.char(48)}}
  local l=models.models[landforms.kind(models,left,map,0,0,token,portal,family)]
  local r=models.models[landforms.kind(models,right,map,0,0,token,portal,family)]
  for z=1,15,2 do
   assert(top(l,15,z)>10 and top(r,1,z)>10,'source ridge has a gap')
   assert(math.abs(top(l,15,z)-top(r,1,z))<=2,'visible source seam step')
  end
 end end
end
local exteriors=0
for id,p in pairs(profiles)do if p.exterior then
 exteriors=exteriors+1;assert(p.cliffMasks and #p.cliffMasks==p.size[2]*2,'missing whole-source cliff mask '..id)
 for _,row in ipairs(p.cliffMasks)do assert(#row==p.size[1]*2,'truncated cliff mask '..id)end
end end
assert(exteriors>100,'incomplete island ridge coverage')
print('PASS regional cliff chains: every island exterior, joined cap continuity, original fragment phase and separate material families')

local quays,crates=0,0
for id,p in pairs(profiles)do
 if p.source:match('Island_Harbor$')then
  quays=quays+1;assert(p.exterior and not p.outdoor and not p.nativeWallSource,'ferry quay still classified as a room '..id)
  assert(L.region(p)=='ferry_quay'and L.groundMaterial(p,'G')==-162)
  local fronts=0
  for _,s in ipairs(p.props)do if s.tag=='j'then
   fronts=fronts+1;assert(#s.doors==1 and #s.windows>0,'unverified ferry terminal front '..id)
   local model={models={},decorColors={stone=1,clay=2,slate=3,silver=4}}
   local kind=assert(loadfile('lib/SeviiHarbor.lua'))().facade(model,p,s)
   local door=s.doors[1];local x=(door.x-s.x)*16+8;local z=(door.y-s.y)*16+8
   for _,b in ipairs(model.models[kind].boxes)do
    assert(b[1]>=0 and b[3]>=0 and b[1]+b[4]<=s.w*16 and b[3]+b[6]<=s.h*16,'front exceeds source footprint')
    assert(not(x>=b[1]and x<b[1]+b[4]and z>=b[3]and z<b[3]+b[6]and b[2]<24),'blocked ferry doorway')
   end
  end end
  assert(fronts==1,'terminal split into independent wall cubes '..id)
 end
 if p.source=='FiveIsland_RocketWarehouse'then
  for _,s in ipairs(p.props)do if s.tag=='z'then
   crates=crates+1;assert(s.w==2 and s.h==2,'merged adjacent shipping crates')
  end end
 end
end
assert(quays==7 and crates==7,'incomplete quays or source crate footprints')
print('PASS open ferry quays: seven exact source fronts, original windows, clear entrances and seven independent warehouse crates')

local barriers=0
for id,p in pairs(profiles)do if p.source=='FiveIsland_RocketWarehouse'then
 for _,prop in ipairs(p.props)do if prop.tag=='i'then
  barriers=barriers+1
  assert(prop.w==1 and prop.h==1,'L-shaped barrier filled a walking path')
 end end
end end
assert(barriers>50,'warehouse puzzle blocks still become full room walls')
print('PASS source warehouse puzzle: separate blocked cargo cells, unchanged paths and machinery excluded from wall partitions',barriers)
