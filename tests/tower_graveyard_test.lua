-- Exercise admission and protected-cell boundaries independently of rendering.
local deps={HorizonWall={BELT=32},BuildBudget={tick=function()end}}
local G=assert(loadfile('lib/Gen1TowerGraveyard.lua'))({require=function(k)return assert(deps[k],k)end})
local P={models={},decorColors={hauntedMortar=1,hauntedSlate=2}}
for i=0,1 do P.models['memorial_stone_'..i]={boxes={{3,0,7,10,17,5,3}}}end
local map={id='POKEMON_TOWER_3F',def={width=10,height=9,tileset='CEMETERY',
 warps={{x=10,y=17}},objects={{x=6,y=5}},signs={{x=7,y=5}}}}
function map:tileAt(x,y)
 local cx,cy=math.floor(x/2),math.floor(y/2)
 if cx==4 and cy==5 then return 1 end -- ordinary floor
 if cx==8 and cy==5 then return 99 end -- unknown art must survive
 if cx==9 and cy==5 then return y%2==0 and(x%2==0 and 5 or 6)or(x%2==0 and 21 or 22)end
 if cx==11 and cy==5 then return 17 end -- native void
 return y%2==0 and(x%2==0 and 9 or 10)or(x%2==0 and 25 or 26)
end
function map:isWalkableCell(x,y)return x==3 and y==5 end
function map:isWarpTileCell(x,y)return x==5 and y==5 end
local function occupied(x,y)return math.floor(x/2)==10 and math.floor(y/2)==5 end
local function check()
 local cells,count={},0
 for _,p in ipairs(G.find(P,map,occupied))do
  assert(p.voxelOnly and p.groundTile==1)
  local m=assert(P.models[p.kind]);assert(m.directBoxes and not m.glassKind and not m.lightSource)
  for y=p.ty/2,(p.ty+p.h)/2-1 do for x=p.tx/2,(p.tx+p.w)/2-1 do
   local key=x..','..y;assert(not cells[key],'overlapping batches');cells[key]=p;count=count+1
  end end
  for _,b in ipairs(m.boxes)do
   assert(b[1]>=0 and b[3]>=0 and b[1]+b[4]<=p.w*8 and b[3]+b[6]<=p.h*8,'geometry exceeds claim')
  end
 end
 for x=3,10 do assert(not cells[x..',5'],'protected cell replaced: '..x)end
 assert(cells['11,5'],'void unfilled');assert(cells['12,5'],'border unfilled')
 assert(not cells['10,17'],'warp object buried')
 assert(cells['10,18'].graveCount==0 and cells['10,19'].graveCount==0,'entrance apron obstructed')
 for x=-2,21 do assert(cells[x..',-2']and cells[x..',19'],'panorama gap north/south')end
 for y=-2,19 do assert(cells['-2,'..y]and cells['21,'..y],'panorama gap east/west')end
 return count
end
for floor=1,7 do map.id='POKEMON_TOWER_'..floor..'F';assert(check()==519)end
for _,id in ipairs{'SPROUT_TOWER_3F','POKEMON_TOWER_8F','KA_POKEMON_TOWER_3F'}do
 map.id=id;assert(#G.find(P,map,occupied)==0,'unrelated map admitted')
end
map.id='POKEMON_TOWER_3F'
for k,v in pairs{generation=2,width=11,height=10,tileset='INTERIOR',connections={north={}}}do
 local old=map.def[k];map.def[k]=v;assert(#G.find(P,map,occupied)==0,'unsupported layout admitted: '..k);map.def[k]=old
end
print('PASS Tower graveyard: all seven floors, protected cells, full panorama apron and entrance corridor')
