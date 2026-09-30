local V={require=function(n)
 if n=='Gen1DoorStyles'then return assert(loadfile('lib/Gen1DoorStyles.lua'))()end
 if n=='Gen1GlassDoors'then return{interior=function()return false end,wooden=function()return false end}end
 if n=='Gen1RoomBounds'then return assert(loadfile('lib/Gen1RoomBounds.lua'))()end
 if n=='Gen1SecurityDoors'then return{addPanels=function()end}end
 if n=='Gen1Stairs'then return{perimeterShaft=function()end,classForWarp=function()end}end
 if n=='Gen1StairCells'then return{classForWarp=function()end}end
 if n=='Gen1BreachExterior'then return{opening=function()end}end
 error(n)
end}
local L=assert(loadfile('lib/Gen1InteriorLayout.lua'))(V)
for _,set in ipairs{'FACILITY','INTERIOR'}do
 local tiles={};local width,height=8,8
 for y=0,31 do for x=0,31 do
  local value=1
  if y==30 then value=87 end
  if x==0 then value=set=='FACILITY'and 43 or 89 end
  if x==1 then value=set=='FACILITY'and 44 or 90 end
  if y==12 and x>=8 and x<20 then value=87 end
  tiles[y*32+x]=value
 end end
 local d={tileset=set,width=width,height=height,blocks={},warps={{x=5,y=5,destMap='SILPH_CO_3F'},{x=8,y=5,destMap='SILPH_CO_ELEVATOR'}}}
 local blocks={}
 for by=0,7 do for bx=0,7 do
  local b={};for y=0,3 do for x=0,3 do b[#b+1]=tiles[(by*4+y)*32+bx*4+x]end end
  blocks[#blocks+1]=b;d.blocks[#d.blocks+1]=#blocks-1
 end end
 local panels=L.panelsFor({id=set=='INTERIOR'and 'SILPH_CO_11F'or 'SILPH_CO_1F',def=d,tileset={blocks=blocks}},{shellHeight=80,theme='corporate'})
 local partition,entrance=false,false;local columns=0
 for _,p in ipairs(panels)do
  if p.column then columns=columns+1 end
  if p.at==96 and p.edge=='south'then for _,o in ipairs(p.openings)do
   assert(o.from~=80,'floor teleporter punched a doorway into a wall')
   if o.from==128 then entrance=true end
  end end
  assert(p.at~=240,'southern boundary built a second room wall')
  assert(not(p.edge=='west'and p.at==16),'western boundary built a second room wall')
  if p.at==96 and p.wallThickness then partition=true end
 end
 assert(partition,'real interior partition lost')
 assert(columns==8,'four structural corner piers missing')
 assert(entrance,'real elevator doorway lost')
end
print('PASS four corner piers, floor teleporter versus real entrance, perimeter courses suppressed, native interior partitions retained in FACILITY and Silph office')
-- Shared warp recesses must not grow a wall between adjacent exit cells.
local map={id='CELADON_MART_2F',def={tileset='LOBBY',width=10,height=4,warps={{x=2,y=1},{x=3,y=1}}},tileset={blocks={}}}
map.isWalkableCell=function(_,x,y)return y>=2 or y==1 and (x==2 or x==3)end
local panels=L.panelsFor(map,{shellHeight=50,theme='retail'})
local recess=false
for _,p in ipairs(panels)do
 if p.edge=='north'and p.at==16 and p.from==32 and p.upto==64 then recess=true end
 assert(not((p.edge=='east'or p.edge=='west')and p.at==48 and p.from<32),'wall divides adjacent warp niche')
 if p.edge=='north'and p.at==32 then assert(p.upto<=32 or p.from>=64,'front wall blocks warp niche')end
end
assert(recess,'native warp niche lost')
print('PASS perimeter at blocked-course boundary, joined warp niches and unobstructed entrances')
