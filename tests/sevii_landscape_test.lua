local L=assert(loadfile('lib/SeviiLandscape.lua'))()
local function p(source,kind,x,y)return{exterior=true,source=source,kind=kind or'water',origin={x or 0,y or 0}}end
assert(not L.region({exterior=false,source='TwoIsland_House'}))
assert(L.region(p('ThreeIsland_BerryForest','canopy'))=='forest')
assert(L.region(p('SevenIsland_SevaultCanyon'))=='canyon')
assert(L.region(p('SevenIsland_SevaultCanyon_Entrance'))=='canyon')
assert(L.region(p('SixIsland_RuinValley'))=='ruins')
assert(L.region(p('SevenIsland_TanobyRuins'))=='ruins')
assert(L.region(p('OneIsland_KindleRoad'))=='volcanic_coast')
assert(L.seed(p('SixIsland',nil,24,10),2,3)==L.seed(p('SixIsland'),26,13),'fragment seam changes model')
local map={def={width=20,height=20},isWaterCell=function(_,x,y)return x==3 and y==3 end,isWalkableCell=function()return false end}
assert(L.nearWater(map,5,3,3));assert(not L.nearWater(map,7,3,3))
local function token()return'T'end;local function portal()end
local island=p('SixIsland');local px,py
for y=0,6 do for x=0,6 do
 local kind=L.treeKind(island,map,x,y,token,portal)
 if kind:match('^cinnabar_palm')then px,py=x,y end
end end
assert(px,'coastal accents never selected')
map.isWalkableCell=function()return true end
assert(not L.treeKind(island,map,px,py,token,portal):match('palm'),'palm planted on walking plot')
map.isWalkableCell=function()return false end
assert(not L.treeKind(island,map,px,py,function()return'B'end,portal):match('palm'),'palm overlaps house')
assert(not L.treeKind(island,map,px,py,token,function()return{}end):match('palm'),'palm overlaps warp')
assert(not L.treeKind(p('ThreeIsland_BerryForest','canopy'),map,px,py,token,portal):match('palm'),'forest converted to palms')
assert(L.rockKind(p('SixIsland_RuinValley'),2,3):match('^kanto_plateau_rock_'))
assert(L.rockKind(p('ThreeIsland_BerryForest','canopy'),2,3):match('^kanto_safari_rock_'))
assert(L.rockKind(p('OneIsland_KindleRoad'),2,3):match('^sevii_basalt_rock_'))
assert(L.groundMaterial(p('SevenIsland_SevaultCanyon'),'G')==-171)
assert(L.groundMaterial(p('SevenIsland_SevaultCanyon'),'g')==-159,'canyon grass stripped')
assert(L.groundMaterial(p('OneIsland_KindleRoad'),'G')==-159,'coastal grass turned to ash')
assert(L.stoneMaterial(p('OneIsland_KindleRoad'))==-180)
local canonical={{{2,0,3},{5,8,3},{5,8,5},{2,0,5},shade=.8,uv={{1,1}}}}
local input={{quads={},placements={48,48,128,128}}}
local result=L.grassGroups(island,map,input,canonical)
assert(#result==2 and #result[1].placements+#result[2].placements==4,'shore variation lost encounter density')
assert(result[1].placements[1]==128 and result[2].placements[1]==48,'grass moved from native plot')
assert(result[1].quads[1][2][2]==8 and result[2].quads[1][2][2]==8*.92,'wrong wind exposure')
assert(canonical[1][2][2]==8 and input[1].placements[1]==48,'shared Kanto geometry mutated')
assert(result[2].quads[1].shade==.8 and result[2].quads[1].uv[1][1]==-166)
local forest=L.grassGroups(p('ThreeIsland_BerryForest','canopy'),map,input,canonical)
assert(#forest==1 and forest[1].quads[1][2][2]==8,'forest lost Kanto height')
local source={terrain=true,boxes={{0,0,0,2,4,2,14},{2,0,0,2,3,2,26}},offsetY=-40}
local models={};for i=1,4 do models['kanto_plateau_rock_'..i]=source end
local P={models=models,decorColors={silver=26,leafDark=10,looseRock1=40,looseRock4=43,oldBeam=31}}
L.register(P);assert(P.models.sevii_basalt_rock_1.boxes[1][7]==40 and P.models.sevii_basalt_rock_1.boxes[2][7]==43)
assert(source.boxes[1][7]==14 and source.boxes[2][7]==26,'shared Kanto rocks recolored')
local dry={def={width=2,height=1},isWalkableCell=function(_,x,y)return y==0 and(x==0 or x==3)end,
 isWaterCell=function(_,x,y)return y==1 end,tileAt=function(_,x)return x==0 and 11 or 22 end}
local floor=L.groundTiles(dry,function()return'G'end,portal)
assert(floor[0]==11 and floor[1]==11 and floor[2]==22 and floor[3]==22,'nearby natural floor not continued under rocks')
assert(floor[4]==nil and floor[5]==nil,'soil crossed native water')
print('PASS Sevii landscapes: source regions, fragment continuity, safe sparse coastal palms, Kanto forest/shore grass density, canyon soil, volcanic shore rock and shared-model isolation')
