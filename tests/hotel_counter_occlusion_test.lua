local M=assert(loadfile('lib/Gen1CounterOcclusion.lua'))()
local tiles={8,8,24,25}
local map={id='CELADON_HOTEL',def={tileset='POKECENTER',width=7,height=4},
 isWalkableCell=function(_,x,y)return y==1 end,inBounds=function(_,x,y)return y>=0 and y<8 end,
 tileAt=function(_,x,y)return tiles[(y-4)*2+x-6+1]end}
local e={def={sprite='SPRITE_GRANNY'},cellX=3,cellY=1,px=48,py=16}
assert(M.pull(map,e,0,false)==0,'floor clerk still bypasses counter depth')
assert(M.pull(map,e,0,true)==nil and M.pull(map,e,8,false)==nil)
e.moving=true;assert(M.pull(map,e,0,false)==nil);e.moving=false
e.px=49;assert(M.pull(map,e,0,false)==nil);e.px=48
e.def.sprite='SPRITE_BEAUTY';assert(M.pull(map,e,0,false)==nil);e.def.sprite='SPRITE_GRANNY'
for _,id in ipairs{'VIRIDIAN_POKECENTER','CELADON_MANSION_1F','CUSTOM_HOTEL'}do
 map.id=id;assert(M.pull(map,e,0,false)==nil)
end
map.id='CELADON_HOTEL';map.def.generation=2;assert(M.pull(map,e,0,false)==nil);map.def.generation=nil
map.def.width=8;assert(M.pull(map,e,0,false)==nil);map.def.width=7
map.def.connections={north={}};assert(M.pull(map,e,0,false)==nil);map.def.connections=nil
for i=1,4 do local old=tiles[i];tiles[i]=40;assert(M.pull(map,e,0,false)==nil,'different furniture/wall was claimed');tiles[i]=old end
-- Verify the guard against current imported Gen-I data, including all raw tiles.
local host=assert(os.getenv('QA_GAME_HOST'))..'/'
local Map=dofile(host..'src/world/Map.lua')
local maps=dofile(host..'red/data/generated/maps.lua');local sets=dofile(host..'red/data/generated/tilesets.lua')
local native=Map.new(maps.CELADON_HOTEL,sets.POKECENTER)
assert(M.pull(native,e,0,false)==0,'actual hotel reception pattern is not matched: '..table.concat({native:tileAt(6,4),native:tileAt(7,4),native:tileAt(6,5),native:tileAt(7,5)},','))
assert(e.cellX==3 and e.cellY==1 and e.px==48 and e.py==16,'clerk position mutated')
print('PASS actual hotel counter: native floor clerk depth, exact furniture/room guard, walking/hop/raised actor/other room fallback')
