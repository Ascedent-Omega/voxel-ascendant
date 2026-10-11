local Map={}
function Map.new(def,ts)return{def=def,tileset=ts,waterTiles={[50]=true,[72]=true,[90]=true}}end
function Map.defCellTile(def,ts,x,y)return def.tiles[x+y*2+1]end
function Map.defIsWaterCell(def,ts,x,y)local tile=Map.defCellTile(def,ts,x,y);return tile==50 or tile==72 or tile==90 end
package.loaded['src.world.Map']=Map
local def={id='KA_SEVII_TEST',kaOwner='kasc.sevii-expedition/v1',tiles={50,72,90,91}}
local ts={waterTiles={90},sourceCellCollision={}}
local source={profile=function(m)return m.def==def and m.tileset==ts and m.def.kaOwner=='kasc.sevii-expedition/v1'and{}or nil end}
local W=assert(loadfile('lib/SeviiSourceWater.lua')){require=function(n)assert(n=='KascSeviiScenery');return source end}
W.install();local ctor=Map.new;W.install();assert(Map.new==ctor,'duplicate wrapper')
local m=Map.new(def,ts);assert(not m.waterTiles[50]and not m.waterTiles[72]and m.waterTiles[90],'Kanto fallback shore still replaces Sevii grass')
for y=0,1 do for x=0,1 do assert(Map.defIsWaterCell(def,ts,x,y)==(def.tiles[x+y*2+1]==90),'connected-map water differs from loaded lookup')end end
assert(ts.shoreTiles==nil and def.tiles[1]==50,'source metadata changed')
ts.shoreTiles={91};m=Map.new(def,ts);assert(m.waterTiles[91]and Map.defIsWaterCell(def,ts,1,1),'explicit shore lost')
def.kaOwner='foreign';m=Map.new(def,ts);assert(m.waterTiles[50]and m.waterTiles[72]and Map.defIsWaterCell(def,ts,0,0),'foreign water behavior changed')
def.kaOwner='kasc.sevii-expedition/v1';local unproven={waterTiles={90}};m=Map.new(def,unproven);assert(m.waterTiles[50]and Map.defIsWaterCell(def,unproven,0,0),'unproven import changed')
print('PASS imported water lookup: no inherited Kanto shore in Sevii grass, loaded/connected agreement, native water/explicit shore and foreign contracts retained')
