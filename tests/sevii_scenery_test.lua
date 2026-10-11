local recipes=assert(loadfile('data/sevii_voxel_profiles.lua'))()
local M=assert(loadfile('lib/KascSeviiScenery.lua')){data=function(name)assert(name=='sevii_voxel_profiles');return recipes end,
 require=function(name)assert(name=='SeviiLandscape');return assert(loadfile('lib/SeviiLandscape.lua'))()end}
local function map(id)
 local p=assert(recipes[id]);local ts={id='KA_SEVII_TILES_'..id:sub(10),trueColor=true,imageWidth=p.atlas[1],imageHeight=p.atlas[2],blocks={},sourceCellCollision={}}
 local kinds={X='WALL',G='FLOOR',W='WATER',g='GRASS'}
 for b=1,#p.blocks do
  local row,collision={},{}
  for y=0,3 do for x=0,3 do row[#row+1]=math.floor((b-1)/16)*256+(b-1)%16*4+y*64+x end end
  for q=1,4 do collision[q]=kinds[p.collision[b]:sub(q,q)]end
  ts.blocks[b]=row;ts.sourceCellCollision[b]=collision
 end
 return{id=id,tileset=ts,def={kaOwner='kasc.sevii-expedition/v1',tileset=ts.id,kaSeviiSource=p.source,kaSeviiSourceOrigin={unpack(p.origin)},width=p.size[1],height=p.size[2],outdoor=p.outdoor}}
end
local count=0
for id,p in pairs(recipes)do local a=map(id);assert(M.profile(a)==p);count=count+1
 for _,field in ipairs{'kaOwner','tileset','kaSeviiSource','width','height','outdoor','kaSeviiSourceOrigin'}do
  local old=a.def[field];a.def[field]=field=='outdoor'and not old or'foreign';assert(not M.profile(a),field..' guard');a.def[field]=old
 end
 a.def.generation=2;assert(not M.profile(a));a.def.generation=nil
 a.tileset.blocks[1][1]=1000;local fresh=assert(loadfile('lib/KascSeviiScenery.lua')){data=function()return recipes end};assert(not fresh.profile(a),'corrupt atlas accepted')
end
assert(count==266)
local home=recipes.KA_SEVII_SEVEN_ISLAND_HOUSE_ROOM1
assert(home.kind=='room'and home.theme=='coastal_home'and not home.cave,'primary-atlas home became ice cavern')
local furniture={};for _,prop in ipairs(home.props)do furniture[prop.tag]=(furniture[prop.tag]or 0)+1 end
assert(furniture.t and furniture.s and furniture.e and furniture.p and furniture.k and furniture.c,'shared Icefall pointer erased actual home furniture')
assert(not furniture.n and not furniture.b,'bookcase/picture became terminal/bed')
assert(#home.nativeWallPictures==1 and home.nativeWallPictures[1].w==2,'wide original picture absent')
for _,prop in ipairs(recipes.KA_SEVII_SEVEN_ISLAND_HOUSE_ROOM2.props)do assert(prop.tag~='b','source rug became bed')end
for _,prop in ipairs(recipes.KA_SEVII_FIVE_ISLAND_RESORT_GORGEOUS_HOUSE.props)do assert(prop.tag~='b','resort rug became bed')end
local resortPlants=0
for _,prop in ipairs(recipes.KA_SEVII_FIVE_ISLAND_RESORT_GORGEOUS_HOUSE.props)do if prop.tag=='p'then
 resortPlants=resortPlants+1;assert(prop.w==1 and prop.h==2,'plant crown left on floor or detached from pot')
end end
assert(resortPlants==8,'Resort needs eight separate complete potted plants')
for _,id in ipairs{'KA_SEVII_FIVE_ISLAND_RESORT_GORGEOUS_HOUSE','KA_SEVII_FOUR_ISLAND_LORELEIS_HOUSE','KA_SEVII_FOUR_ISLAND_POKEMON_DAY_CARE'}do
 local tableFound=false
 for _,prop in ipairs(recipes[id].props)do tableFound=tableFound or prop.tag=='t' end
 assert(tableFound,'secondary furniture list erased primary table '..id)
end
for _,id in ipairs{'KA_SEVII_FOUR_ISLAND_POKEMON_DAY_CARE','KA_SEVII_TWO_ISLAND_JOYFUL_GAME_CORNER'}do
 local actual=false
 for _,prop in ipairs(recipes[id].props)do actual=actual or prop.tag=='t'and prop.w==2 and prop.h==2 end
 assert(actual,'original display table became an opaque wall '..id)
end
local cornerFront=false
for _,prop in ipairs(recipes.KA_SEVII_TWO_ISLAND_JOYFUL_GAME_CORNER.props)do
 cornerFront=cornerFront or prop.tag=='q'and prop.w==3 and prop.y==3
end
assert(cornerFront,'original game-corner counter became a room wall')
local beds=0
for _,prop in ipairs(recipes.KA_SEVII_FOUR_ISLAND_LORELEIS_HOUSE.props)do if prop.tag=='b'then
 beds=beds+1;assert(prop.w==1 and prop.h==2,'bed includes surrounding floor')
end end
assert(beds==1,'Lorelei needs one actual bed')
local resort=map('KA_SEVII_FIVE_ISLAND_RESORT_GORGEOUS_HOUSE')
local floorId
for block,tags in ipairs(recipes[resort.id].blocks)do if tags:sub(1,1)=='G'then floorId=resort.tileset.blocks[block][1];break end end
assert(floorId)
resort.tileAt=function()return floorId end
resort.isWalkableCell=function(_,x,y)return x>=1 and x<=9 and y>=2 and y<=7 end
resort.warpAtCell=function()end
local enclosure=M.bounds(resort)
assert(enclosure.north==16,'north bookcase hidden behind walkable-only enclosure')
for _,id in ipairs{'KA_SEVII_THREE_ISLAND_HOUSE1','KA_SEVII_FOUR_ISLAND_LORELEIS_HOUSE','KA_SEVII_SIX_ISLAND_WATER_PATH_HOUSE1'}do
 local found=false
 for _,art in ipairs(recipes[id].nativeWallPictures)do found=found or art.w==1 and art.h==2 and art.cropTop==8 end
 assert(found,'original wall window absent '..id)
end
assert(not M.profile({id='KA_SEVII_ONE',def={tileset='OVERWORLD'}}))
local a=map('KA_SEVII_ONE');a.tileAt=function()return 0 end;a.isWaterCell=function()return true end;a.isWalkableCell=function()return false end;a.warpAtCell=function()end
assert(M.shape(a,0,0,0).class=='water');a.isWaterCell=function()return false end;a.warpAtCell=function()return{}end
assert(M.shape(a,0,0,0).flat,'door blocked by render recipe')
assert(M.shape(a,0,-1,0).class=='void','invented outside apron')
a=map('KA_SEVII_CENTER');assert(M.room(a).theme=='center');assert(M.nativeRoom(a).nativeSourceWalls and M.nativeRoom(a).shellHeight==48);
assert(M.material(a,0)==nil,'Center floor palette was repainted')
for id,p in pairs(recipes)do if p.kind=='room'then
 local donor=assert(p.nativeWallSource,id);assert(donor.x>=0 and donor.y>=0 and donor.x+donor.w<=p.size[1]*2 and donor.y+donor.h<=p.size[2]*2,id..' foreign wall texels')
 if p.source~='OneIsland_House1'then
  local room=map(id);assert(M.material(room,0)==nil,'room floor escaped source ownership '..id)
 end
end end
a.def.connections={east={map='OTHER'}};assert(not M.room(a),'shell blocks streaming connection')
print('PASS Sevii: 266 exact atlas contracts; foreign/Gen2/corrupt maps excluded; water, warps and outside bounds; closed-room ownership')

for _,r in ipairs{
 {'KA_SEVII_LIFE_PC_1','SPRITE_POKEDEX','terminal'},
 {'KA_SEVII_STATION_CONSOLE','SPRITE_POKEDEX','terminal'},
 {'KA_SEVII_DREAM_LANTERN','SPRITE_POKEDEX','lantern'},
 {'KA_SEVII_TS_CLOCK','SPRITE_POKEDEX','clock'},
 {'KA_SEVII_TS_PULSE_1','SPRITE_POKEDEX','clock'},
 {'KA_SEVII_TIDE_NORTH','SPRITE_POKEDEX','gauge'},
 {'KA_SEVII_FINALE_RADIO','SPRITE_POKEDEX','radio'},
 {'KA_SEVII_GARDEN_GATE','SPRITE_POKEDEX','gate'},
 {'KA_SEVII_HEATRAN_VENT','SPRITE_POKEDEX','vent'},
 {'KA_SEVII_GARDEN_BED','SPRITE_PAPER','garden'},
 {'KA_SEVII_DREAM_FEATHER','SPRITE_PAPER','feather'},
 {'KA_SEVII_TIDE_PLANK','SPRITE_PAPER','plank'},
 {'KA_SEVII_TESTIMONY_BOOK_1','SPRITE_PAPER','journal'},
 {'KA_SEVII_MIRROR_STONE','SPRITE_BOULDER','mirror'},
 {'KA_SEVII_GARDEN_SHAYMIN','SPRITE_BOULDER','altar_garden'},
 {'KA_SEVII_GIANT_ICE','SPRITE_BOULDER','altar_ice'},
 {'KA_SEVII_GIANT_STEEL','SPRITE_BOULDER','altar_steel'},
 {'KA_SEVII_BUOY_heat','SPRITE_POKE_BALL','buoy'},
 {'KA_SEVII_LIFE_BEACH_PEARL','SPRITE_POKE_BALL','pearl'},
 {'KA_SEVII_LIFE_BRIDGE_MUSHROOM','SPRITE_POKE_BALL','mushroom'},
}do assert(M.objectStyle(r[1],r[2])==r[3],r[1])end
assert(not M.objectStyle('KA_SEVII_NURSE','SPRITE_NURSE'),'living actor converted into furniture')
print('PASS Sevii: appropriate interactive object families; living actor owner retained')

local function nativeTree(id,x,y,w,h)
 for _,t in ipairs(recipes[id].nativeTrees)do if t.x==x and t.y==y then assert(t.w==w and t.h==h,'source crown merged with neighbouring tree');return end end
 error('reviewed native tree absent '..id)
end
nativeTree('KA_SEVII_THREE_ISLAND_BERRY_FOREST',0,0,3,2)
nativeTree('KA_SEVII_THREE_ISLAND_BERRY_FOREST',3,2,3,3)
nativeTree('KA_SEVII_SIX',1,7,2,2)
print('PASS native tree courses: three-column forest crowns, separate repeating border crowns and original complete tree footprint')

for id,p in pairs(recipes)do if p.exterior then
 local m=map(id)
 for b,labels in ipairs(p.blocks)do local q=labels:find('g',1,true)
  if q then
   local tile=m.tileset.blocks[b][math.floor((q-1)/2)*8+((q-1)%2)*2+1]
   assert(M.material(m,tile)==(p.kind=='canopy'and -161 or -159),'encounter floor retains the imported blue-green paint')
  end
 end
end end
print('PASS full grass ground: existing Kanto meadow/forest materials across every exact exterior atlas')
