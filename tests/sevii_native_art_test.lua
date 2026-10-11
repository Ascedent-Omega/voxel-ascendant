-- Native-art geometry must work without loading optional replacement models.
local p={props={{tag='B',x=0,y=0,w=2,h=3,doors={}}},nativeTrees={{tag='T',x=2,y=0,w=1,h=3}}}
local m={def={width=3,height=3},tileset={imageWidth=96}}
function m:tileAt(x,y)return y*12+x end
function m:isWalkableCell()return true end
function m:isWaterCell()return false end
local source={profile=function(map)return map==m and p or nil end,token=function(_,x,y)return x>=6 and'G'or'B'end}
local pixels={getPixel=function(_,x,y)
 local tile=math.floor(y/8)*12+math.floor(x/8)
 if tile%12>=6 then return .2,.6,.3,1 end
 return .6,.2,.7,1
end}
local sea=assert(loadfile('lib/SeviiSeaRocks.lua'))()
local V={require=function(name)if name=='SeviiSeaRocks'then return sea end;assert(name=='KascSeviiScenery');return source end}
local N=assert(loadfile('lib/SeviiNativeVoxel.lua'))(V)
assert(N.templates({},pixels)==nil,'foreign map accepted')
local list=assert(N.templates(m,pixels));assert(#list==2)
local house,tree=list[1],list[2]
assert(house.roofRows==32 and house.nativeGable and house.solidFacade,'native house roof/facade bands')
assert(not house.background(.6,.2,.7,1),'shared ground paint erased a coloured roof')
assert(house.heightScale==1.4,'compact house lost existing Gen1 height correction')
assert(house.positions[1]==0 and #house.tiles==6 and #house.tiles[1]==4)
assert(tree.silhouette and tree.nativeRound,'native tree is still a constant-depth cutout')
assert(tree.background(.2,.6,.3,1)and not tree.background(.6,.2,.7,1),'coloured silhouette mask')
assert(tree.background(1,1,1,0),'alpha outside silhouette')
assert(N.templates(m,pixels)==list,'native template cache churn')
-- Rebuild from changed atlas data, preserving discrete chairs and real depth.
p.props={{tag='s',x=0,y=0,w=1,h=1},{tag='e',x=1,y=0,w=1,h=1},{tag='k',x=0,y=2,w=1,h=3}}
p.nativeTrees={}
local other={getPixel=pixels.getPixel};list=N.templates(m,other)
assert(#list==3 and #list[1].parts==6 and #list[2].parts==6,'seat/backrest/four legs')
assert(list[1].parts[1].x[1]~=list[2].parts[1].x[1],'chair facing lost')
assert(list[3].solidFacade and list[3].depthPx==16 and list[3].offsetZ==32,'device wraps over entire drawing footprint')
-- Source components crossing runtime fragments are cropped to owned cells.
p.props={{tag='B',x=-1,y=-1,w=3,h=3}};list=N.templates(m,{getPixel=pixels.getPixel})
assert(#list==1 and #list[1].tiles==4 and #list[1].tiles[1]==4 and list[1].positions[1]==0)
print('PASS Sevii native art: exact ownership, roof/facade bands, coloured cutouts, independent chair parts, shallow devices, cache and partition bounds')
-- Exercise the actual renderer, not just template labels. A façade colour
-- may also occur in the ground palette; it must remain a solid wall.
local B=assert(loadfile('lib/Buildings.lua')){require=function(name)
 if name=='BuildBudget'then return{tick=function()end,check=function()end}end
 if name=='GateDoors'then return{forBuilding=function()return{}end}end
 if name=='SeviiSeaRocks'then return sea end
 error(name)
end}
local function up(name)
 for i=1,100 do local k,v=debug.getupvalue(B.build,i);if k==name then return v end;if not k then break end end
 error('missing renderer '..name)
end
local atlas={getPixel=function(_,x,y)if y<16 then return .6,.2,.7,1 end;return .2,.6,.3,1 end}
local template={tiles={{0},{1},{2},{3}},roofRows=16,roofBack=15,roofFront=1,roofCycle={8,14},slab=3,frontEave=2,panes=false,seal='s',
 nativeGable=true,solidFacade=true,silhouette=true,background=function(r,g,b)return g>.5 end}
local sprite=up('read')(template,atlas,1)
for i=16*8,32*8-1 do assert(sprite.inside[i],'native façade erased as floor')end
local measured=up('measure')(sprite,template,false)
local model=up('model')(sprite,measured,template)
for y=0,model.ytop do for x=0,model.W-1 do
 local ranges=model.ranges(x,y)
 for z=model.zmin,model.zmax do
  local covered=false;if ranges then for i=1,#ranges,2 do if z>=ranges[i]and z<=ranges[i+1]then covered=true end end end
  assert(covered==(model.at(x,y,z)~=nil),'analytical pitched roof differs from native solid')
 end
end end
assert(model.at(4,24,15)and not model.at(4,24,0),'roof is still a flat box')
local quads=up('emit')(model,sprite,8,32)
assert(#quads>0 and quads.voxels>0,'native roof produced no mesh')
-- Equal edge paint is the background stripe through a pot, not a lid.
local pot={tiles={{0},{1}},roofRows=0,seal='',silhouette=true,rowBackground=true,background=function()return false end}
local potAtlas={getPixel=function(_,x,y)if x==0 or x==7 or y==0 then return .5,.5,.5,1 end;return .1,.8,.2,1 end}
local cut=up('read')(pot,potAtlas,1)
assert(not cut.inside[0]and not cut.inside[3],'plant got an opaque grey cap')
assert(cut.inside[8+3],'plant leaf removed with floor margin')
print('PASS native renderer: solid coloured façade, sloped roof occupancy, exact interval exposure, real mesh and open plant silhouette')

-- A native ferry may occupy the same drawing rectangle as its gangway.
-- The gangway and warp stay at their original floor, with no deck above them.
source.portalAt=function()end
p.props={{tag='Z',x=0,y=3,w=5,h=1}};p.nativeTrees={}
local ship=N.templates(m,{getPixel=pixels.getPixel})[1]
assert(ship.roofRows==40 and ship.groundLine==48 and ship.planCut[0]and #ship.keep>0,'native ferry footprint/cutout')
assert(ship.background(.2,.4,.8,1)and not ship.background(.6,.3,.1,1),'ship water became an opaque hull')
template.planCut={[0]=true}
model=up('model')(sprite,measured,template)
assert(model.at(4,18,0)==nil and model.at(4,24,15),'gangway cut also erased unrelated roof')
local grid={shapeAt={},tileAt={},ground={},skip={}}
local k=(0+64)*4096+0+64;grid.shapeAt[k]={class='ground',flat=true};grid.tileAt[k]=5
B.stamp(grid,m,{},0,0,1,1,{keep={5},planCut={[0]=true}})
assert(not grid.skip[k]and grid.ground[k]==nil and grid.shapeAt[k].class=='ground','native gangway floor repainted or claimed')
print('PASS native ferry: water removed from hull, gangway volume cut, native floor and warp ownership retained')
template.nativeGable=false;model=up('model')(sprite,measured,template)
for y=0,model.ytop do for x=0,model.W-1 do
 local ranges=model.ranges(x,y)
 for z=model.zmin,model.zmax do
  local covered=false;if ranges then for i=1,#ranges,2 do if z>=ranges[i]and z<=ranges[i+1]then covered=true end end end
  assert(covered==(model.at(x,y,z)~=nil),'gangway interval claims empty native volume')
 end
end end
assert(#up('emit')(model,sprite,8,32)>0,'cut deck produced no shell')
print('PASS clipped native deck: exact occupied intervals and retained shell')

-- A wide crown and a narrow trunk must have different depth sections.
-- The whole source silhouette may never be copied as parallel flat faces.
local treeArt={tiles={{0,1},{2,3},{4,5},{6,7}},roofRows=0,roofBack=0,roofFront=0,roofCycle={0,0},slab=0,
 seal='',silhouette=true,nativeRound=true,depthPx=16,panes=false,
 background=function(r)return r==1 end}
local treeAtlas={getPixel=function(_,x,y)
 local sx=x%16;local lo=y<24 and 1 or 6;local hi=y<24 and 14 or 9
 if sx>=lo and sx<=hi then return .1,.7,.2,1 end;return 1,1,1,1
end}
local crown=up('read')(treeArt,treeAtlas,2);local crownMeasure=up('measure')(crown,treeArt,false)
local round=up('model')(crown,crownMeasure,treeArt)
assert(round.at(8,20,1)and not round.at(8,1,1),'trunk extruded to crown depth')
assert(round.at(1,20,7)and not round.at(1,20,1),'crown retains a flat rectangular section')
for y=0,round.ytop do for x=0,round.W-1 do for z=round.zmin,round.zmax do
 local r=round.ranges(x,y);local covered=r and z>=r[1]and z<=r[2]or false
 assert(covered==(round.at(x,y,z)~=nil),'round plant interval differs from actual volume')
end end end
assert(#up('emit')(round,crown,16,32)>0,'round native crown has no shell')
-- A plant drawn over a multicoloured rug border still has a free crown.
-- The plain timber palette alone cannot identify these painted margins.
p={kind='room',props={{tag='p',x=0,y=0,w=1,h=2}},nativeTrees={}}
source.token=function(_,x)return x<2 and'p'or x<4 and'G'or'P'end
local rugPlantAtlas={getPixel=function(_,x,y)
 if x>=32 or x<3 then return x%2==0 and .7 or .2,.6,.8,1 end
 if x>=16 then return .5,.5,.5,1 end
 return .1,.8,.2,1
end}
local plant=N.templates(m,rugPlantAtlas)[1]
assert(plant.nativeRound and plant.connectedBackground,'plant is a rectangular floor slab')
assert(plant.background(.7,.6,.8,1)and plant.background(.2,.6,.8,1),'rug border absent from native plant margin mask')
local plantSprite=up('read')(plant,rugPlantAtlas,12)
assert(not plantSprite.inside[1]and not plantSprite.inside[2],'rug stripes stood up beside native foliage')
assert(plantSprite.inside[7],'free native foliage removed with the rug')
print('PASS native potted plants: multicoloured rug margins removed, crown and pot retained as a round source volume')
local coastProfile={exterior=true,props={{tag='C',x=0,y=0,w=1,h=1}}}
p=coastProfile;source.profile=function(map)return map==m and p or nil end
-- Exterior coastal cells are normally appended from token/adjacency scans.
source.token=function()return'C'end;m.isWalkableCell=function()return false end;m.isWaterCell=function(_,x)return x==1 end
list=N.templates(m,{getPixel=pixels.getPixel})
assert(list[1].background(.18,.36,.55,1)and not list[1].background(.6,.3,.1,1),'wave shade absent from open sea became a rock face')
template.nativeGable=true;template.planCut=nil;model=up('model')(sprite,measured,template)
local gable=model.at(4,20,15)
assert(gable and math.floor(gable/sprite.W)>=template.roofRows,'roof paint leaked onto the vertical gable')
print('PASS native refinements: rounded crown/trunk depth, exact plant shell, unlisted bank-wave cutout and facade-only gable')
-- Roof bands appear once on each slope, with the ridge at the summit.
for z=1,14 do
 local y=18+math.floor(math.min(16,10,8)*math.max(0,1-math.abs(2*(z+.5)/32-1)))
 local i=model.at(4,y,z)
 assert(i and math.floor(i/sprite.W)==math.floor(math.abs(2*(z+.5)/32-1)*16),'repeated eave or misplaced native roof ridge')
end
print('PASS native roof material: one source band per slope and ridge at summit')
template.nativeRoofTop=8;model=up('model')(sprite,measured,template)
assert(math.floor(model.at(4,25,15)/sprite.W)>=8,'terrace behind Center became its roof ridge')
print('PASS Center source margin: terrain course excluded from roof material')

-- A Center crosses two runtime atlases. Source ownership partitions its
-- surfaces, while geometry uses the complete 80px footprint in both maps.
local function fragment(first,count)
 local t={tiles={},roofRows=math.max(0,math.min(count*8,56-first)),roofBack=0,roofFront=0,roofCycle={0,0},
  slab=3,frontEave=2,seal='',silhouette=true,solidFacade=true,panes=false,depthPx=80,
  background=function()return false end,nativeBands={height=80,roof=56,first=16,x=0,y=first,width=8}}
 for i=first/8,first/8+count-1 do t.tiles[#t.tiles+1]={i}end
 local sp=up('read')(t,{getPixel=function()return .6,.3,.1,1 end},1)
 return up('model')(sp,up('measure')(sp,t,false),t),sp
end
local whole,wholeSp=fragment(0,10);local upper,upperSp=fragment(0,6);local lower,lowerSp=fragment(48,4)
for y=0,whole.ytop do for x=0,7 do for z=0,whole.zmax do
 local a,b,expected=upper.at(x,y,z),lower.at(x,y,z),whole.at(x,y,z)
 assert(not(a and b),'atlas fragments overlap source ownership')
 assert((a~=nil or b~=nil)==(expected~=nil),'partition turned one Center into two partial houses')
 if a then assert(a==expected,'upper fragment source band changed')end
 if b then assert(b+48*8==expected,'lower facade became roof material')end
end end end
assert(#up('emit')(upper,upperSp,8,80)>0 and #up('emit')(lower,lowerSp,8,80)>0,'partition fragment has no shell')
p={props={{tag='B',x=0,y=-3,w=2,h=5,nativeRoofRows=56,nativeRoofStart=16,nativeSourceBase=6}},nativeTrees={}}
list=N.templates(m,{getPixel=pixels.getPixel})
assert(list[1].depthPx==80 and list[1].offsetZ==-48 and list[1].nativeBands.y==48 and list[1].roofRows==8,'partition rebased the original house')
assert(list[1].nativeSourceBase==6,'fragment without door lost source terrace datum')
print('PASS native source partitions: complete-house volume, disjoint source surfaces, exact atlas bands, shared depth/origin and proven entrance course')

p={props={{tag='B',x=0,y=0,w=2,h=3}},nativeTrees={}}
local redGround={getPixel=function()return .9,.4,.3,1 end}
source.token=function(_,x,y)return y>=6 and 'G'or'B'end
m.def.height=4
list=N.templates(m,redGround)
assert(not list[1].background(.9,.4,.3,1),'roof colour inherited from ground must remain solid')
print('PASS native roof palette: neighbouring ground cannot erase matching red roof texels')

-- A crown's enclosed fill may share the surrounding grass colour. Cutting
-- every matching pixel hollows it into stripes instead of free foliage.
treeArt.connectedBackground=true
local outlined={getPixel=function(_,x,y)
 local sx=x%16
 if y>=2 and y<=22 and sx>=2 and sx<=13 and (y==2 or y==22 or sx==2 or sx==13)then return .1,.3,.1,1 end
 return 1,1,1,1
end}
crown=up('read')(treeArt,outlined,2)
assert(not crown.inside[0] and crown.inside[10*16+8],'outlined leaf fill erased with external ground')
local grass=assert(N.grassMask(m))
for _,c in ipairs{{58,90,16},{58,148,49},{132,214,99},{189,255,140}}do assert(grass(c[1]/255,c[2]/255,c[3]/255,1),'native blade erased')end
for _,c in ipairs{{25,165,107},{66,181,140},{115,206,165},{165,230,197}}do assert(not grass(c[1]/255,c[2]/255,c[3]/255,1),'native grass floor stood as a solid slab')end
assert(not grass(.2,.6,.1,0)and N.grassMask({})==nil,'grass alpha/foreign contract')
print('PASS native foliage: enclosed crown fill, external margin cut and grass blades without blue-green floor slabs')

local smooth=up('read')(treeArt,treeAtlas,2);treeArt.nativeCrown=true
local cap=up('model')(smooth,up('measure')(smooth,treeArt,false),treeArt)
assert(cap.at(8,31,7)and not cap.at(1,31,7)and not cap.at(8,31,1),'crown still has a broad flat cap')
assert(cap.at(1,20,7),'rounding erased the broad lower crown')
print('PASS native crown: curved top in width and depth, broad foliage below and original texture ownership')

-- Primary $0BB boulders are labelled D but are blocked source drawings.
-- Their paint must not enter the floor mask or become a rectangular prism.
p={exterior=true,props={},nativeTrees={}}
source.token=function(_,x,y)return x>=2 and x<4 and y>=2 and y<4 and'D'or'G'end
source.portalAt=function()end
m.isWalkableCell=function(_,x,y)return x~=1 or y~=1 end
m.isWaterCell=function()return false end
local rockPixels={getPixel=function(_,x,y)
 if x>=16 and x<32 and y>=16 and y<32 and ((x-23.5)/6)^2+((y-23.5)/6)^2<1 then return .55,.35,.3,1 end
 return .8,.7,.5,1
end}
local rocks=N.templates(m,rockPixels);assert(#rocks==1,'blocked original boulder not dimensionalized')
local rock=rocks[1];assert(rock.nativeRound and rock.connectedBackground and rock.depthPx==12)
assert(rock.background(.8,.7,.5,1)and not rock.background(.55,.35,.3,1),'boulder colors treated as floor')
local sp=up('read')(rock,rockPixels,12);local pr=up('measure')(sp,rock,false);local round=up('model')(sp,pr,rock)
assert(round.at(7,7,6),'original boulder lost its core')
assert(not round.at(0,7,0)and not round.at(7,15,6),'boulder retained opaque bounding cube')
assert(#up('emit')(round,sp,8,32)>0,'original boulder mesh absent')
print('PASS normal Sevii boulders: blocked source role, isolated original colors, elliptical volume, free silhouette and actual mesh')

-- The four source cells of one ocean rock form one silhouette. Wave shades
-- around it stay water, including under the rock's claimed drawing margin.
p={exterior=true,props={{tag='o',x=0,y=0,w=2,h=2}},nativeTrees={}}
source.token=function(_,x,y)return x<4 and y<4 and'o'or'W'end
m.isWalkableCell=function()return false end;m.isWaterCell=function(_,x,y)return x>=2 or y>=2 end
local ocean={getPixel=function(_,x,y)
 if x<32 and y<32 and ((x-15.5)/12)^2+((y-16)/7)^2<1 then return .55,.57,.59,1 end
 return .2,.4,.8,1
end}
local rock=N.templates(m,ocean)[1]
assert(rock.nativeRound and rock.waterUnderlay and rock.useWaterGround and #rock.tiles==4 and #rock.tiles[1]==4,'sea rock split into cliff strips')
assert(rock.background(.2,.4,.8,1)and not rock.background(.55,.57,.59,1),'rock erased or waves raised')
for _,c in ipairs{{90,90,115},{123,123,132},{173,189,206},{206,222,239},{66,74,107}}do
 assert(not rock.background(c[1]/255,c[2]/255,c[3]/255,1),'actual blue-tinted rock face stripped with ocean')
end
for _,c in ipairs{{49,99,181},{66,123,189},{74,123,222},{74,148,222}}do
 assert(rock.background(c[1]/255,c[2]/255,c[3]/255,1),'actual ocean margin extruded')
end
local sprite=up('read')(rock,ocean,12);local shape=up('model')(sprite,up('measure')(sprite,rock,false),rock)
assert(shape.at(16,6,12)and not shape.at(0,6,0),'sea rock remains a bounding slab')
local key=function(x,y)return(y+64)*4096+x+64 end
local terrain={shapeAt={[key(4,1)]={class='water',flat=true,h=-2}},tileAt={[key(4,1)]=77},ground={},skip={}}
local wet=assert(sea.waterAt(terrain,0,0,4,4));assert(wet.tile==77 and wet.h==-2)
B.stamp(terrain,m,{},0,0,4,4,rock)
assert(terrain.furnitureWater[key(3,3)]==wet or terrain.furnitureWater[key(3,3)].tile==77)
assert(terrain.ground[key(0,0)]==nil and terrain.skip[key(0,0)],'water under native rock painted as dry floor')
local P={models={kanto_plateau_rock_1={w=16,h=16,boxes={{2,0,3,10,8,9,14}}}}}
local kind=sea.kind(P,1,32,32);local replacement=P.models[kind]
assert(replacement.waterUnderlay and replacement.boxes[1][1]==4 and replacement.boxes[1][4]==20 and replacement.boxes[1][5]==8,'replacement lost Kanto silhouette or source footprint')
print('PASS ocean rocks: whole 32px silhouette, round actual mesh, wave cutout, real water underlay and scaled Kanto replacement')
