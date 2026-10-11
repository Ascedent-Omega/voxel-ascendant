local tags={'X','G','a','W','X','G','K','W','X','X','X','W','X','X','X','W'}
local map={def={width=2,height=2}}
function map:tileAt(x,y)return y*100+x end
function map:isWalkableCell(x,y)return tags[y*4+x+1]=='G'or tags[y*4+x+1]=='a'or tags[y*4+x+1]=='K'end
function map:isWaterCell(x,y)return tags[y*4+x+1]=='W'end
local source={profile=function(m)return m==map end,
 token=function(m,x,y)return tags[math.floor(y/2)*4+math.floor(x/2)+1]end,
 portalAt=function(m,x,y)return x==2 and y==1 end}
local M=assert(loadfile('lib/SeviiFloor.lua')){require=function(n)assert(n=='KascSeviiScenery');return source end}
for y=0,7 do for x=0,5 do
 local tile=M.tile(map,x,y)
 local dx,dy=tile%100,math.floor(tile/100)
 assert(dx%2==x%2 and dy%2==y%2,'floor pattern phase lost')
 assert(tags[math.floor(dy/2)*4+math.floor(dx/2)+1]=='G','puzzle/wall/door donor')
end end
assert(M.tile(map,6,6)==606,'water received land donor')
assert(M.tile({},0,0)==nil,'foreign map admitted')
tags[2]='X';tags[6]='X'
local empty=assert(loadfile('lib/SeviiFloor.lua')){require=function()return source end}
assert(empty.tile(map,0,0)==0,'floorless map sampled foreign atlas')
map.def.kaOwner='kasc.sevii-expedition/v1'
source.bounds=function()return{west=8,north=8,east=56,south=56}end
source.warps=function()return{}end
local bounds=assert(loadfile('lib/Gen1RoomBounds.lua')){require=function(n)assert(n=='KascSeviiScenery');return source end}
tags[6]='G';tags[11]='V'
local mask=bounds.floorTiles(map);local key=function(x,y)return(y+64)*4096+x+64 end
assert(mask[key(2,2)],'actual compartment floor missing')
assert(not mask[key(1,1)],'wall footprint became exposed floor')
assert(not mask[key(4,4)],'black source void became exposed floor')
assert(mask[key(4,2)],'actual warp opening removed')
print('PASS Sevii floor donors: original plain floor, four-corner phase, puzzle/warp/water exclusion, blocked-wall fill and foreign guard')
