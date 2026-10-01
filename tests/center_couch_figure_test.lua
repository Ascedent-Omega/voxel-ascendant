-- The replacement owns the couch terrain while keeping exactly its authored
-- sitter. A generic furniture overlap must still suppress unrelated figures.
local tiles={36,37,57,52,53,60}
local fig={w=3,h=2,tiles=tiles,under={52,39,1,52,39,26},
 hdActor='pokecenter_seated_man',mask={}}
for i=0,383 do fig.mask[i]=i%24>=6 and i%24<16 end
package.loaded['src.render.Assets']={register=function()end}
package.loaded['src.world.Map']={}
local mods={Buildings={},TileShape={figures=function()return{fig}end},BuildBudget={tick=function()end}}
local V={require=function(n)return mods[n]or{}end}
local S=assert(loadfile('lib/Structures.lua'))(V)
local map={tileset={id='POKECENTER',tilesPerRow=16},isWalkableCell=function()return false end}
local function key(x,y)return(y+64)*4096+x+64 end
local function state(actor)
 local s={tileAt={},shapeAt={},figures={},voxelFurnitureClaims={},voxelFurnitureFigures={}}
 for i,tile in ipairs(tiles)do local k=key((i-1)%3,math.floor((i-1)/3))
  s.tileAt[k]=tile;s.voxelFurnitureClaims[k]=actor~=false
  if actor then s.voxelFurnitureFigures[k]={actor=actor,height=8}end
 end
 for x=0,2 do s.shapeAt[key(x,2)]={authored=true,art='upright',h=8}end
 return s
end
local good=state(fig.hdActor);S.buildFigures(good,map,0,2,0,1)
assert(#good.figures==1 and good.figures[1].y==8)
assert(good.figures[1].wx==6 and good.figures[1].wz==12)
S.buildFigures(good,map,0,2,0,1);assert(#good.figures==1,'duplicate sitter')
for _,actor in ipairs{'unrelated_actor',''}do
 local bad=state(actor);S.buildFigures(bad,map,0,2,0,1);assert(#bad.figures==0,'unrelated claim bypassed')
end
local native=state(false);S.buildFigures(native,map,0,2,0,1)
assert(#native.figures==1 and native.figures[1].y==8,'OFF native extraction changed')
print('PASS Center couch figure ownership: retained anchor, no duplicates, unrelated claim protection and OFF')
