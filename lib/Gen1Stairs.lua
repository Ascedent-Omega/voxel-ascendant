-- Material finishes and compact store flights within native stair footprints.
-- Collision, warp destinations and the native map remain authoritative.
local V=...
local M={}
-- Explicit visual polish for the three reviewed families. Unknown/custom
-- rooms retain their compact flights and native collision/warp ownership.
function M.reviewedFlight(map)
 local d=map and map.def;local id=map and map.id or ''
 if not d or d.generation==2 or next(d.connections or{})then return false end
 if id=='MUSEUM_1F'then return d.tileset=='MUSEUM'and d.width==10 and d.height==4 end
 if id=='MUSEUM_2F'then return d.tileset=='MUSEUM'and d.width==7 and d.height==4 end
 if id:match('^POKEMON_TOWER_[1-7]F$')then return d.tileset=='CEMETERY'and d.width==10 and d.height==9 end
 local floor=tonumber(id:match('^ROCKET_HIDEOUT_B([1-4])F$'))
 return floor and d.tileset=='FACILITY'and d.width==15 and d.height==(floor==4 and 12 or 14)or false
end
M.setting=V.require('ModSetting').new('voxelStairs','STAIRS',{true,false},{'ON','OFF'},true)
local families={REDS_HOUSE_1=2,REDS_HOUSE_2=2,GATE=2,SHIP=3,
 HOUSE=2,MANSION=2,LOBBY=7,MUSEUM=7,FACILITY=6,INTERIOR=6,
 CEMETERY=8,CAVERN=39,UNDERGROUND=39}
-- Explicit pins published by KASC's scripted route. They are rendering
-- metadata, never extra native warps or changes to collision/height policy.
local scriptedSpecs={CINNABAR_GYM={'FACILITY',10,9,{{3,2,'stair_down_w'}}},KA_BLAINE_GYM_TUNNEL={'FACILITY',24,7,{{45,8,'stair_e'},{5,4,'stair_e'}}},KA_BLAINE_VOLCANO_FOOT={'KA_MOLTRES_VOLCANO_67',16,12,{{15,20,'stair_down_w'}}}}
function M.scripted(map)
 local d=map and map.def;local a=d and d.kaBlaineStairs
 local p=scriptedSpecs[map and map.id]
 if not(p and d.generation~=2 and type(a)=='table' and a.owner=='kasc.blaine-volcano-route/v1'
  and d.tileset==p[1]and d.width==p[2]and d.height==p[3])then return nil end
 if type(a.points)~='table'or #a.points~=#p[4]then return end
 for i,pin in ipairs(a.points)do local expected=p[4][i]
  if type(pin)~="table"or pin.x~=expected[1]or pin.y~=expected[2]or pin.class~=expected[3]then return end
 end
 return a.points
end
function M.material(map)
 local d=map and map.def
 if not d or d.generation==2 or not M.setting:get() then return nil end
 if M.scripted(map)then return -133 end
 if V.require('Gen1InteriorFloors').profile(map)==54 then return -182 end
 local f=families[d.tileset]
 return f and -128-f
end
function M.classForWarp(map,warp)
 local exact=V.require('Gen1StairCells').classForWarp(map,warp)
 if exact then return exact end
 if not V.data or not M.material(map)then return end
 local spec=V.data('voxel_heights')
 local groups=spec and spec.tilesets and spec.tilesets[map.def.tileset]
 if not groups then return end
 for _,class in ipairs{'stair_e','stair_w','stair_down_e','stair_down_w'}do
  local ids=groups[class]
  if ids then
   local allowed={};for _,id in ipairs(ids)do allowed[id]=true end
   local complete=true
   for dy=0,1 do for dx=0,1 do
    local x,y=warp.x*2+dx,warp.y*2+dy
    local b=map.tileset.blocks[(map.def.blocks[math.floor(y/4)*map.def.width+math.floor(x/4)+1]or -1)+1]
    if not(b and allowed[b[y%4*4+x%4+1]])then complete=false end
   end end
   if complete then return class end
  end
 end
end
-- Native CAVERN shelf stairs run north/south across a six-pixel shelf.
-- They are ordinary walkable terrain, not a ladder warp. Recognise the
-- complete motif and its two endpoints before assigning a physical flight.
function M.caveFloorHeight(map,tile)
 if map and map.def and map.def.tileset=='CAVERN' and M.material(map)
  and (tile==5 or tile==41)then return 6 end
end
function M.caveStep(map,cx,cy)
 if not(map and map.def and map.def.tileset=='CAVERN' and M.material(map)
  and type(map.tileAt)=='function' and type(map.cellTile)=='function')then return end
 local x,y=cx*2,cy*2
 if map:tileAt(x,y)~=21 or map:tileAt(x+1,y)~=22
  or map:tileAt(x,y+1)~=21 or map:tileAt(x+1,y+1)~=22 then return end
 if not M.caveFloorHeight(map,map:cellTile(cx,cy-1))then return end
 local south=map:cellTile(cx,cy+1)
 if M.caveFloorHeight(map,south)then return 6,0 end
 if south==20 or south==32 or south==33 or south==42 then return 0,6 end
end
function M.caveSupport(map,cx,cy)
 if not(map and type(map.cellTile)=='function')then return end
 local shelf=M.caveFloorHeight(map,map:cellTile(cx,cy));if shelf then return shelf end
 local base,h=M.caveStep(map,cx,cy);if base then return base+(h>0 and h*2/3 or 0) end
end
function M.claim(S,map)
 if not M.material(map) then return end
 if map.def.tileset=='CAVERN' and map.def.width and map.def.height then
  local budget=V.require('BuildBudget')
  for cy=0,map.def.height*2-1 do
   if budget.check then budget.check()end
   for cx=0,map.def.width*2-1 do
   local base,h=M.caveStep(map,cx,cy)
   if base then
    local free=true
    for dy=0,1 do for dx=0,1 do
     local k=(cy*2+dy+64)*4096+cx*2+dx+64
     if not S.shapeAt[k] or (S.voxelFurnitureClaims and S.voxelFurnitureClaims[k])then free=false end
    end end
    if free then for dy=0,1 do for dx=0,1 do
     local k=(cy*2+dy+64)*4096+cx*2+dx+64
     S.shapeAt[k]={class='stair_n',art='stair',h=h,stairBase=base,authored=true}
    end end end
   end
  end end
 end
 for _,pin in ipairs(M.scripted(map)or{})do
  for dy=0,1 do for dx=0,1 do
   local k=(pin.y*2+dy+64)*4096+pin.x*2+dx+64
   if map.id=='KA_BLAINE_VOLCANO_FOOT'then
    if S.voxelFurnitureClaims then S.voxelFurnitureClaims[k]=nil end
    if S.skip then S.skip[k]=nil end
    if S.ground then S.ground[k]=nil end
   end
   if not(S.voxelFurnitureClaims and S.voxelFurnitureClaims[k])then
    S.shapeAt[k]={class=pin.class,art='stair',h=16,flat=false,authored=true}
   end
  end end
 end
 local cells=V.require('Gen1StairCells')
 for _,warp in ipairs(map.def.warps or {})do
  local class=cells.classForWarp(map,warp)
  if class then
   local occupied=false
   for dy=0,1 do for dx=0,1 do
    local k=(warp.y*2+dy+64)*4096+warp.x*2+dx+64
    if S.voxelFurnitureClaims and S.voxelFurnitureClaims[k] then occupied=true end
   end end
   if not occupied then
    for dy=0,1 do for dx=0,1 do
     local k=(warp.y*2+dy+64)*4096+warp.x*2+dx+64
     S.shapeAt[k]={class=class,art='stair',h=16,flat=false,authored=true}
    end end
   end
  end
 end
end
-- Decide from the native collision grid, including the cell one must stand
-- on to enter a stair warp. Decorations never acquire collision of their own.
local directions={south={0,1},west={-1,0},north={0,-1},east={1,0}}
local turns={south=0,west=1,north=2,east=3}
function M.entrance(map,cx,cy,preferred)
 if not map.isWalkableCell then return preferred end
 local d=map.def
 local function open(side)
  local v=directions[side];local x,y=cx+v[1],cy+v[2]
  return x>=0 and y>=0 and x<d.width*2 and y<d.height*2 and map:isWalkableCell(x,y)
 end
 if open(preferred)then return preferred end
 for _,side in ipairs{'south','west','east','north'}do if open(side)then return side end end
 return preferred
end
function M.orient(map,quads,first,cx,cy,s,original,selected)
 -- Shelf stairs and other terrain are authored slopes, not floor warps.
 local warp=false
 for _,w in ipairs(map.def.warps or{})do if w.x==cx and w.y==cy then warp=true;break end end
 if not warp or not M.material(map)then return end
 if not original then
  local east=s.class=='stair_e'or s.class=='stair_down_e'
  local down=s.class=='stair_down_e'or s.class=='stair_down_w'
  original=s.class=='stair_n'and 'south'or ((east~=down)and 'west'or 'east')
 end
 local side=selected or M.entrance(map,cx,cy,original)
 local n=(turns[side]-turns[original])%4
 for i=first,#quads do
  local q=quads[i];q.stairEntrance=side
  for j=1,4 do local p=q[j];local x,z=p[1]-cx*16,p[3]-cy*16
   for turn=1,n do x,z=16-z,x end
   p[1],p[3]=cx*16+x,cy*16+z
  end
 end
 return side
end
-- A compact north-facing retail flight in the original warp footprint. The
-- native cell and its destination must both agree; LOBBY also owns elevators
-- and casino doors, which must never acquire this model.
local storeFloors={CELADON_MART_1F=1,CELADON_MART_2F=2,CELADON_MART_3F=3,
 CELADON_MART_4F=4,CELADON_MART_5F=5,CELADON_MART_ROOF=6}
function M.storeFlight(map,cx,cy,s)
 local d=map and map.def
 local floor=d and storeFloors[map.id]
 if not floor or d.generation==2 or d.tileset~='LOBBY'
  or d.width~=10 or d.height~=4 or next(d.connections or{})
  or not M.material(map) then return end
 for _,w in ipairs(d.warps or{})do
  if w.x==cx and w.y==cy then
   local target=storeFloors[w.destMap]
   local class=V.require('Gen1StairCells').classForWarp(map,w)
   if target and math.abs(target-floor)==1 and class and class==s.class
    and ((target>floor and class=='stair_e')or(target<floor and class=='stair_down_w'))then
    local flight={down=target<floor,from=floor,to=target}
    -- The enclosed sales floors have two blocked outer courses and a
    -- north-facing stair alcove. Other/native custom approaches stay compact.
    if floor<6 and cy==1 and map.isWalkableCell and M.entrance(map,cx,cy,'south')=='south' then
     flight.shaft=true;flight.count=16;flight.depth=.75;flight.rise=52/16
    end
    return flight
   end
  end
 end
end
function M.buildStore(S,map,cx,cy,s)
 local flight=M.storeFlight(map,cx,cy,s)
 if not flight then return false end
 return M.buildFlight(S,map,cx,cy,s,flight)
end
-- A native stair warp can sit in a perimeter alcove. Its rear wall needs
-- headroom above the landing, rather than closing at the room's floor.
-- Silph's authored north-edge stair pins get a real, enclosed service shaft.
-- The trigger remains its native cell; the visible doorway spans two cells.
function M.silphShaft(map,warp)
 local d=map and map.def;local n=map and tonumber(tostring(map.id):match('^SILPH_CO_(%d+)F$'))
 local to=warp and tonumber(tostring(warp.destMap):match('^SILPH_CO_(%d+)F$'))
 if not n or n<1 or n>11 or not to or math.abs(to-n)~=1 or warp.y~=0
  or d.generation==2 or d.height~=9 or d.width~=(n==10 and 8 or n==11 and 9 or n>=6 and 13 or 15)
  or d.tileset~=(n==11 and 'INTERIOR'or 'FACILITY')or not M.material(map)
  or not M.classForWarp(map,warp)then return end
 return {from=warp.x*16-8,upto=warp.x*16+24,at=0,mouth=16,back=-64,
  down=to<n,height=52,width=32,length=80}
end
-- A shared footprint contract for facade openings and the visibility mask.
function M.perimeterShaft(map,warp)
 local silph=M.silphShaft(map,warp);if silph then return silph end
 if not map or not warp or not storeFloors[map.id]then return end
 local class=M.classForWarp(map,warp)
 local flight=class and M.storeFlight(map,warp.x,warp.y,{class=class})
 if flight and flight.shaft then
  local z=warp.y*16
  return {from=warp.x*16-8,upto=warp.x*16+24,at=z,mouth=z+16,back=z-64,
   down=flight.down,height=52,width=32,length=80}
 end
end
function M.portal(map,cx,cy,flight,profile)
 if not profile or flight.shelf or flight.flat then return end
 if flight.shaft then return {edge='north',at=cy*16,from=cx*16-8,upto=cx*16+24,
  height=profile.shellHeight,open=true,stair=true}end
 local entrance=M.entrance(map,cx,cy,flight.preferred or 'south')
 local height=(flight.count or 5)*(flight.rise or(flight.down and 1.6 or 2.4))
 local top=math.min(profile.shellHeight-2,(flight.down and 0 or height)+28)
 local edge=({south='north',north='south',west='east',east='west'})[entrance]
 local horizontal=edge=='north'or edge=='south'
 return {edge=edge,at=horizontal and(cy+(edge=='south'and 1 or 0))*16
   or(cx+(edge=='east'and 1 or 0))*16,
  from=(horizontal and cx or cy)*16,upto=(horizontal and cx or cy)*16+16,
  height=top,open=true,stair=true}
end
function M.buildFlight(S,map,cx,cy,s,flight)
 local ox,oz=cx*16,cy*16
 local quads=S.objectQuads;local first=#quads+1
 local entrance=flight.shelf and 'south'or M.entrance(map,cx,cy,flight.preferred or 'south')
 local function openSide(localSide)
  if not map.isWalkableCell then return false end
  local side=({'south','west','north','east'})[(turns[localSide]+turns[entrance])%4+1]
  local v=directions[side];local x,y=cx+v[1],cy+v[2]
  return x>=0 and y>=0 and x<map.def.width*2 and y<map.def.height*2 and map:isWalkableCell(x,y)
 end
 local function face(a,b,c,d,material,shade,part)
  local corners={a,b,c,d}
  for _,p in ipairs(corners)do p[1],p[3]=p[1]+ox,p[3]+oz end
  corners.uv={{material,0},{material,0},{material,0},{material,0}}
  -- The recessed well's inward-facing end can lie exactly on the native
  -- map edge. It belongs to this flight, even though border-ring trimming
  -- would otherwise discard that zero-width inward face and expose sky.
  corners.own=true
  corners.stairCellX,corners.stairCellY=cx,cy
  corners.shade=shade;corners.storeStair=flight.store~=false and part or nil;corners.stairPart=part
  if flight.base then for _,p in ipairs(corners)do p[2]=p[2]+flight.base end end
  quads[#quads+1]=corners
 end
 local function top(x0,x1,z0,z1,y,mat,shade,part)
  face({x0,y,z0},{x1,y,z0},{x1,y,z1},{x0,y,z1},mat,shade,part)
 end
 local function box(x,y,z,w,h,d,mat,shade,part)
  local a,b,c=x+w,y+h,z+d
  top(x,a,z,c,b,mat,shade,part)
  face({x,y,c},{a,y,c},{a,b,c},{x,b,c},mat,shade*.82,part)
  face({a,y,z},{x,y,z},{x,b,z},{a,b,z},mat,shade*.68,part)
  face({x,y,z},{x,y,c},{x,b,c},{x,b,z},mat,shade*.72,part)
  face({a,y,c},{a,y,z},{a,b,z},{a,b,c},mat,shade*.88,part)
 end
 -- Existing floor materials keep the stair in the room's lighting/palette:
 -- pale stone, blue-grey enamel and a dark metal edge. No extra atlas/draw.
 local stone,metal=flight.material or -133,flight.trim or -134
 local down=flight.down
 local count,depth,rise=flight.count or 5,flight.depth or 2.6,flight.rise or (down and 1.6 or 2.4)
 local endZ=14-count*depth;local height=count*rise
 -- A flush two-pixel approach, wholly inside the native warp cell.
 top(0,16,14,16,0,stone,.96,'landing')
 local previous=0
 for i=1,count do
  local near=14-(i-1)*depth
  local far=near-depth
  local y=(down and -1 or 1)*i*rise
  top(1.4,14.6,far,near-math.min(.5,depth*.2),y,stone,down and (.98-i*.045)or 1,'tread')
  top(1.4,14.6,near-math.min(.5,depth*.2),near,y,stone,1.16,'nosing')
  if down then
   face({14.6,y,near},{1.4,y,near},{1.4,previous,near},{14.6,previous,near},metal,.60,'riser')
  else
   face({1.4,previous,near},{14.6,previous,near},{14.6,y,near},{1.4,y,near},metal,.78,'riser')
  end
  -- Enclosed cheeks terminate at the same depth as the physical treads.
  for _,x in ipairs({0,14.6})do
   box(x,down and y or 0,far,1.4,down and -y+.8 or y+.8,depth,metal,.85,'cheek')
  end
  previous=y
 end
 top(1.4,14.6,0,endZ,previous,stone,down and .58 or 1,'upper-landing')
 for _,x in ipairs{0,14.6}do
  box(x,down and -height or 0,0,1.4,height+.8,endZ,metal,.85,'landing-cheek')
 end
 if down then
  face({0,-height,0},{16,-height,0},{16,0,0},{0,0,0},metal,.19,'well-end')
 else
  face({16,0,0},{0,0,0},{0,height,0},{16,height,0},metal,.65,'back')
 end
 local H=V.require('HorizonWall')
 local profile=H.enabled()and H.interiorProfileFor(map)
 if profile and not profile.nativeRoomPanels then profile=nil end
 local portal=M.portal(map,cx,cy,flight,profile)
 if flight.shaft then portal=nil end
 if portal then
  local matched=false
  for _,panel in ipairs(V.require('Gen1InteriorLayout').panelsFor(map,profile))do
   if panel.edge==portal.edge and panel.at==portal.at then
    for _,o in ipairs(panel.openings)do
     if o.stair and o.from<portal.upto and o.upto>portal.from then matched=true end
    end
   end
  end
  if not matched then portal=nil end -- freestanding stairs need no fake wall
 end
 if portal then
  -- The destination belongs to the native warp. A shallow enclosed reveal
  -- suggests continuation without exposing the sky or loading another room.
  local h=portal.height
  face({0,previous,.04},{16,previous,.04},{16,h,.04},{0,h,.04},metal,.12,'portal-shadow')
  face({1.4,previous,.04},{1.4,previous,endZ},{1.4,h,endZ},{1.4,h,.04},metal,.60,'portal-return')
  face({14.6,previous,endZ},{14.6,previous,.04},{14.6,h,.04},{14.6,h,endZ},metal,.60,'portal-return')
  top(1.4,14.6,.04,endZ,h,metal,.60,'portal-ceiling')
 end
 -- Thin continuous rails follow the rising flight; a descending opening
 -- has a level guard. Posts remain on the two narrow side cheeks.
 for _,x in ipairs({.3,14.9})do if not flight.shelf and not openSide(x<8 and 'west'or 'east')then
  local frontY,backY=5,down and 5 or height+5
  for _,z in ipairs({1.5,7.5,13.5})do
   local railY=frontY+(backY-frontY)*(14-z)/14
   local base=down and .8 or math.min(height,math.ceil((14-z)/depth)*rise)+.8
   box(x,base,z,.8,math.max(.3,railY-base),.8,metal,.65,'post')
  end
  local a,b=x,x+.8
  face({a,frontY,14},{b,frontY,14},{b,backY,0},{a,backY,0},metal,.68,'rail')
  face({a,backY+.8,0},{b,backY+.8,0},{b,frontY+.8,14},{a,frontY+.8,14},metal,.91,'rail')
  face({a,frontY,14},{a,backY,0},{a,backY+.8,0},{a,frontY+.8,14},metal,.70,'rail')
  face({b,backY,0},{b,frontY,14},{b,frontY+.8,14},{b,backY+.8,0},metal,.82,'rail')
  face({a,frontY,14},{b,frontY,14},{b,frontY+.8,14},{a,frontY+.8,14},metal,.78,'rail')
  face({b,backY,0},{a,backY,0},{a,backY+.8,0},{b,backY+.8,0},metal,.68,'rail')
 end end
 if flight.shaft then
  -- All upper/lower flights live behind the facade. Opaque side walls and
  -- a roof prevent sky leaks without loading the destination floor.
  local bottom=down and -height or 0;local roof=down and 50 or height+28
  face({.05,bottom,16},{.05,bottom,.05},{.05,roof,.05},{.05,roof,16},metal,.68,'shaft-wall')
  face({15.95,bottom,.05},{15.95,bottom,16},{15.95,roof,16},{15.95,roof,.05},metal,.68,'shaft-wall')
  face({.05,bottom,.05},{15.95,bottom,.05},{15.95,roof,.05},{.05,roof,.05},metal,.35,'shaft-end')
  face({0,roof,16},{16,roof,16},{16,roof,0},{0,roof,0},stone,.72,'shaft-roof')
  for i=first,#quads do
   for _,p in ipairs(quads[i])do
    p[1]=ox+8+(p[1]-ox-8)*2
    local z=p[3]-oz
    -- Keep the threshold two pixels deep: stretching it hides a descent
    -- behind a broad floor lip before the native trigger can be reached.
    p[3]=oz+(z>=14 and z or 14+(z-14)*(78/14))
   end
  end
 end
 if not flight.shelf then M.orient(map,quads,first,cx,cy,s,'south',entrance)end
 return true
end

-- One bounded model for authored native flights. Keep ladder art and unknown
-- families with their original renderer; never turn an elevator into stairs.
function M.flight(map,cx,cy,s)
 local material=M.material(map)
 if not material or not s or s.art~='stair' then return end
 local shelf=s.class=='stair_n'
 if shelf then
  local base,height=M.caveStep(map,cx,cy)
  if base==nil then return end
  if height==0 then return {flat=true,base=base,material=material}end
  return {store=false,shelf=true,base=base,material=material,trim=material,count=3,depth=4,rise=height/3}
 end
 if not(s.class=='stair_e'or s.class=='stair_w'or s.class=='stair_down_e'or s.class=='stair_down_w')then return end
 local scripted=false;for _,p in ipairs(M.scripted(map)or{})do if p.x==cx and p.y==cy and p.class==s.class then scripted=true end end
 local warp=scripted;for _,w in ipairs(map.def.warps or{})do if w.x==cx and w.y==cy then warp=true;break end end
 if not warp then return end
 for _,w in ipairs(map.def.warps or{})do if w.x==cx and w.y==cy then
  local shaft=M.silphShaft(map,w)
  if shaft then return {shaft=true,store=false,down=shaft.down,material=-133,trim=-134,
   preferred='south',count=16,depth=.75,rise=shaft.height/16}end
 end end
 local down=s.class=='stair_down_e'or s.class=='stair_down_w'
 local east=s.class=='stair_e'or s.class=='stair_down_e'
 -- A floor-change warp needs a readable descent, not a full-storey shaft
 -- squeezed into one tile. Match the retail descent's eight-pixel depth.
 local polished=M.reviewedFlight(map)
 -- Keep the reviewed flights compact. The taller version squeezed a large
 -- rise into the native one-tile run and looked like a ladder.
 local height=math.min(polished and (down and 6 or 10)or (down and 8 or 16),math.max(4,s.h or 16))
 local wood=material==-130
 if map.def.tileset=='FACILITY'or map.def.tileset=='INTERIOR'then material=-133 end
 return {store=false,down=down,material=material,trim=wood and material or -134,
  preferred=(east~=down)and 'west'or 'east',count=polished and 6 or 4,
  depth=polished and 2 or 3,rise=height/(polished and 6 or 4)}
end
function M.buildGeneral(S,map,cx,cy,s)
 local flight=M.flight(map,cx,cy,s)
 if not flight then return false end
 if flight.flat then
  local x,z,y=cx*16,cy*16,flight.base;local m=flight.material
  S.objectQuads[#S.objectQuads+1]={{x,y,z},{x+16,y,z},{x+16,y,z+16},{x,y,z+16},
   uv={{m,0},{m,0},{m,0},{m,0}},shade=1,own=true,stairPart='landing'}
  return true
 end
 return M.buildFlight(S,map,cx,cy,s,flight)
end
-- Same three physical treads and two flush landings as the shelf model.
-- Only traversable terrain uses this; native floor-change warps stay at zero.
function M.supportAt(map,x,z)
 if not(map and map.def and map.def.tileset=='CAVERN' and M.material(map))then return end
 local cx,cy=math.floor(x/16),math.floor(z/16)
 local base,h=M.caveStep(map,cx,cy)
 if base~=nil then
  if h==0 then return base end
  local localZ=z-cy*16
  local step=math.max(0,math.min(3,math.ceil((14-localZ)/4)))
  return base+step*h/3
 end
 return M.caveFloorHeight(map,map:cellTile(cx,cy))
end

function M.finish(map,quads,first,s)
 local material=M.material(map)
 if not material then return end
 local last=#quads
 local down=s.class=='stair_down_e' or s.class=='stair_down_w'
 local east=s.class=='stair_e' or s.class=='stair_down_e'
 local axis=s.class=='stair_n' and 3 or 1
 local across=axis==1 and 3 or 1
 for i=first,last do
  local q=quads[i]
  q.uv={{material,0},{material,0},{material,0},{material,0}}
  local tread=q[1][2]==q[2][2] and q[2][2]==q[3][2] and q[3][2]==q[4][2]
  tread=tread and math.abs((q[2][1]-q[1][1])*(q[3][3]-q[1][3])-(q[2][3]-q[1][3])*(q[3][1]-q[1][1]))>1e-6
  if tread then
   q.shade=down and .88 or 1
   -- Split the actual tread, rather than overlaying a coplanar stripe.
   -- Its low edge is bright stone/timber; the darker riser underneath
   -- makes every physical step legible from oblique and overhead views.
   local lo,hi=math.min(q[1][axis],q[2][axis],q[3][axis],q[4][axis]),math.max(q[1][axis],q[2][axis],q[3][axis],q[4][axis])
   local lowEdge=(east and not down) or (not east and down)
   local a,b=lowEdge and lo or hi-.75,lowEdge and lo+.75 or hi
   local z0,z1=math.min(q[1][across],q[2][across],q[3][across],q[4][across]),math.max(q[1][across],q[2][across],q[3][across],q[4][across]);local y=q[1][2]
   for j=1,4 do
    if lowEdge and q[j][axis]==lo then q[j][axis]=b
    elseif not lowEdge and q[j][axis]==hi then q[j][axis]=a end
   end
   local corners=axis==1 and {{a,y,z0},{b,y,z0},{b,y,z1},{a,y,z1}}
    or {{z0,y,a},{z1,y,a},{z1,y,b},{z0,y,b}}
   quads[#quads+1]={corners[1],corners[2],corners[3],corners[4],
    uv={{material,0},{material,0},{material,0},{material,0}},shade=1.15,stairNosing=true}
  else
   q.shade=math.min(q.shade or .75,.68)
  end
 end
end
function M.bind(invalidate)
 for _,name in ipairs({'setIndex','sync'})do
  local previous=M.setting[name]
  M.setting[name]=function(self,...)
   local before=self:get();local value=previous(self,...)
   if before~=self:get()then invalidate()end
   return value
  end
 end
end
return M
