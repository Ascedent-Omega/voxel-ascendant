-- Decorative walls follow native room boundaries; positions are pixels.
-- This module only reads layouts. Collision, doors and actors keep their owner.
local V = ...
local M = {}
local function add(out, edge, from, upto, at)
  if upto > from then
    local p={edge=edge,from=from,upto=upto,at=at,openings={}}
    out[#out+1]=p;return p
  end
end
local function perimeter(map,out)
  local b=V.require('Gen1RoomBounds').forMap(map)
  for _,v in ipairs{{'north',b.west,b.east,b.north},{'south',b.west,b.east,b.south},
    {'west',b.north,b.south,b.west},{'east',b.north,b.south,b.east}}do
    local edge,from,upto,at=unpack(v)
    local horizontal=edge=='north'or edge=='south'
    local near=edge=='north'or edge=='west'
    local niches={}
    for _,w in ipairs(map.def.warps or{})do
      local a=(horizontal and w.x or w.y)*16
      local c=(horizontal and w.y or w.x)*16
      local back=near and c or c+16
      if (near and back<at or not near and back>at)and a>=from and a+16<=upto then
        local shaft=V.require('Gen1Stairs').perimeterShaft(map,w)
        niches[#niches+1]={from=shaft and shaft.from or a,upto=shaft and shaft.upto or a+16,back=back}
      end
    end
    table.sort(niches,function(a,b)return a.from<b.from end)
    local merged={}
    for _,n in ipairs(niches)do
      local last=merged[#merged]
      if last and last.upto==n.from and last.back==n.back then last.upto=n.upto else merged[#merged+1]=n end
    end
    local cursor=from
    for _,n in ipairs(merged)do
      if n.from>=cursor then
        local p=add(out,edge,cursor,n.from,at);if p then p.boundary=true end
        p=add(out,edge,n.from,n.upto,n.back);p.boundary=true;p.niche=true
        local lo,hi=math.min(at,n.back),math.max(at,n.back)
        p=add(out,horizontal and 'west'or'north',lo,hi,n.from);p.niche=true;p.nicheReturn=true
        p=add(out,horizontal and 'east'or'south',lo,hi,n.upto);p.niche=true;p.nicheReturn=true
        cursor=n.upto
      end
    end
    local p=add(out,edge,cursor,upto,at);if p then p.boundary=true end
  end
end
local function blockFootprint(map, out)
  local d=map.def
  local function occupied(x,y)
    return x>=0 and y>=0 and x<d.width and y<d.height
      and d.blocks[y*d.width+x+1]~=d.borderBlock
  end
  for _,edge in ipairs({'north','south','west','east'})do
    local horizontal=edge=='north' or edge=='south'
    local across,along=horizontal and d.height or d.width,horizontal and d.width or d.height
    for at=0,across do
      local start
      for n=0,along do
        local x,y=horizontal and n or at,horizontal and at or n
        local inside,outside
        if edge=='north' then inside,outside=occupied(x,y),occupied(x,y-1)
        elseif edge=='south' then inside,outside=occupied(x,y-1),occupied(x,y)
        elseif edge=='west' then inside,outside=occupied(x,y),occupied(x-1,y)
        else inside,outside=occupied(x-1,y),occupied(x,y)end
        local exposed=n<along and inside and not outside
        if exposed and not start then start=n end
        if not exposed and start then add(out,edge,start*32,n*32,at*32).boundary=true;start=nil end
      end
    end
  end
end
local function tile(map,x,y)
  local d,t=map.def,map.tileset
  local b=d.blocks[math.floor(y/4)*d.width+math.floor(x/4)+1]
  local a=t.blocks[b+1]
  return a[y%4*4+x%4+1]
end
-- Reuse the authored stair/ladder pins instead of treating every warp as
-- a doorway. Inspect the complete cell; some stairs share door collision IDs.
local function verticalWarp(map,warp)
 if V and V.require and V.require('Gen1StairCells').classForWarp(map,warp) then return true end
 if not (V and V.data and map.tileset and map.def.blocks) then return false end
 local spec=V.data("voxel_heights");local groups=spec and spec.tilesets and spec.tilesets[map.def.tileset]
 if not groups then return false end
 for class,ids in pairs(groups)do
  if type(class)=="string" and (class:match("^stair") or class:find("ladder",1,true)) and type(ids)=="table" then
   for _,id in ipairs(ids)do for dy=0,1 do for dx=0,1 do
    if tile(map,warp.x*2+dx,warp.y*2+dy)==id then return true end
   end end end
  end
 end
 return false
end
M.verticalWarp=verticalWarp
local function opposing(out,panels,edge,offset)
  for _,p in ipairs(panels)do
    out[#out+1]=p
    local q=add(out,edge,p.from,p.upto,p.at+(p.thickness or offset))
    for _,door in ipairs(p.openings)do
      q.openings[#q.openings+1]={from=door.from,upto=door.upto,height=door.height,open=door.open,material=door.material}
    end
    -- Close the ends of the wall's thickness, not the adjacent passage.
    -- The two long faces alone leave a black slit when viewed obliquely.
    local lo,hi=math.min(p.at,q.at),math.max(p.at,q.at)
    local horizontal=p.edge=='north'or p.edge=='south'
    p.wallThickness=hi-lo
    local first=add(out,horizontal and'east'or'south',lo,hi,p.from)
    local last=add(out,horizontal and'west'or'north',lo,hi,p.upto)
    -- End caps belong to this partition, not to an independent wall. If
    -- both long faces are cut away, their narrow ends must disappear too.
    if first then first.endcap=true;first.cutawayFaces={p,q} end
    if last then last.endcap=true;last.cutawayFaces={p,q} end
  end
end
local function joinRun(out,edge,from,upto,at)
  local last=out[#out];local gap=last and from-last.upto
  -- A one/two-cell passage has a lintel. Wider gaps separate rooms.
  if last and last.at==at and gap>0 and gap<=32 then
    last.openings[#last.openings+1]={from=last.upto,upto=from,open=true}
    last.upto=upto
  else add(out,edge,from,upto,at) end
end
local function facility(map,out)
  local d=map.def
  perimeter(map,out)
  -- FACILITY's horizontal wall courses ($2a/$57) and their caps.
  -- Equipment, shelving, rubble and balustrades are separate native objects.
  local horizontal={}
  for y=1,d.height*4-3 do
    local start,core=nil,false
    for x=0,d.width*4 do
      local t=x<d.width*4 and tile(map,x,y)
      local band=t==0x2a or t==0x57;local cap=t==0x2d or t==0x2e
      if band or cap then start=start or x;core=core or band
      elseif start then
        if core and y>=2 then joinRun(horizontal,'south',start*8,x*8,y*8)end
        start=nil;core=false
      end
    end
  end
  opposing(out,horizontal,'north',16)
  -- The paired $2b/$2c vertical wall faces are 16px wide. Both sides
  -- receive a complete wall; camera cutaway chooses the visible room side.
  local vertical={}
  for x=2,d.width*4-3 do
    local start
    for y=0,d.height*4 do
      local band=y<d.height*4 and tile(map,x,y)==0x2b and tile(map,x+1,y)==0x2c
      if band then start=start or y
      elseif start then
        if y-start>=2 then joinRun(vertical,'east',start*8,y*8,x*8)end
        start=nil
      end
    end
  end
  opposing(out,vertical,'west',16)
end
local function silphOffice(map,out)
  local d=map.def
  perimeter(map,out)
  -- The top office uses INTERIOR instead of FACILITY. Exact wall courses
  -- keep its presidential desk, monitors, chairs and stair art separate.
  local horizontal={}
  for y=2,d.height*4-3 do
    local start,core=nil,false
    for x=0,d.width*4 do
      local t=x<d.width*4 and tile(map,x,y)
      local band=t==87 and tile(map,x,y-1)~=87;local cap=t==45 or t==46
      if band or cap then start=start or x;core=core or band
      elseif start then
        if core then
          joinRun(horizontal,'south',start*8,x*8,y*8)
          -- The president's north partition has two plan-view rows and
          -- two face rows. Put its room-facing panel at the actual front,
          -- rather than leaving the old white course in front of it.
          if y+3<d.height*4 then for at=start,x-1 do
            if tile(map,at,y+2)==52 and tile(map,at,y+3)==68 then
              horizontal[#horizontal].thickness=32;break
            end
          end end
        end
        start=nil;core=false
      end
    end
  end
  opposing(out,horizontal,'north',16)
  local vertical={}
  for x=2,d.width*4-3 do
    local start
    for y=0,d.height*4 do
      local band=y<d.height*4 and tile(map,x,y)==89 and tile(map,x+1,y)==90
      if band then start=start or y
      elseif start then
        if y-start>=2 then joinRun(vertical,'east',start*8,y*8,x*8)end
        start=nil
      end
    end
  end
  opposing(out,vertical,'west',16)
end
local function mansion(map,out)
  blockFootprint(map,out)
  local d=map.def
  -- Only the audited Mansion side-wall pairs, including their junctions.
  -- Stairs, desk tops and display cabinets use other tiles and stay separate.
  local pairsByLeft={[74]=75,[72]=73,[88]=89,[90]=91,[92]=93}
  local vertical={}
  for x=0,d.width*4-2 do
    local start
    for y=0,d.height*4 do
      local left=y<d.height*4 and tile(map,x,y)
      local wall=left and pairsByLeft[left] and tile(map,x+1,y)==pairsByLeft[left]
      if wall then start=start or y
      elseif start then
        if y-start>=2 then joinRun(vertical,'east',start*8,y*8,x*8)end
        start=nil
      end
    end
  end
  opposing(out,vertical,'west',16)
  local horizontal={}
  local baseCourse={[30]=true,[22]=true,[23]=true,[92]=true,[93]=true}
  for y=0,d.height*4-2 do
    local start
    for x=0,d.width*4 do
      local top=x<d.width*4 and tile(map,x,y)
      local wall=(top==76 or top==77) and baseCourse[tile(map,x,y+1)]
      if wall then start=start or x
      elseif start then
        if x-start>=2 then
          -- $16/$17 is a blocked decorative wall panel, not a doorway.
          add(horizontal,'south',start*8,x*8,y*8)
        end
        start=nil
      end
    end
  end
  opposing(out,horizontal,'north',16)
  -- All three native floors enter the room around the eastern end of the
  -- front wall: the one-cell gap between the vertical partition and that
  -- front wall. Fit a lintel to that verified floor cell, never to $16/$17.
  for _,side in ipairs(vertical)do
    for _,front in ipairs(horizontal)do
      if front.at==side.upto+16 and front.upto==side.at+16 then
        local x,y=side.at/8,side.upto/8
        local walkable={};for _,id in ipairs(map.tileset.walkable or{})do walkable[id]=true end
        if walkable[tile(map,x,y+1)] and walkable[tile(map,x+1,y+1)] then
          local portal={};local p=add(portal,'east',side.upto,front.at,side.at)
          p.openings={{from=side.upto,upto=front.at,open=true}}
          opposing(out,portal,'west',16)
        end
      end
    end
  end
end
local function underground(map,out)
  -- These maps contain wide black padding outside the corridor. The actual
  -- wall is the $06/$09 north band, $02 south edge and $16/$17 side rims.
  -- Fit to their inner faces rather than the padded map rectangle.
  local d=map.def;local west,east,north,south
  for y=0,d.height*4-1 do for x=0,d.width*4-1 do
    local t=tile(map,x,y)
    if t==0x16 then west=(x+1)*8
    elseif t==0x17 then east=x*8
    elseif t==0x09 then north=(y+1)*8
    elseif t==0x02 then south=y*8 end
  end end
  if not (west and east and north and south and west<east and north<south)then
    return perimeter(map,out)
  end
  add(out,'north',west,east,north);add(out,'south',west,east,south)
  add(out,'west',north,south,west);add(out,'east',north,south,east)
end
-- Perimeter faces, native partition backs and T-junction caps can share
-- one plane. Emit each interval once; overlapping opaque panoramas otherwise
-- fight for depth and show doubled rails/frames in eye-level cameras.
function M.uniquePlanes(panels)
 local planes,out={},{}
 for _,p in ipairs(panels)do
  local axis=(p.edge=='north'or p.edge=='south')and 'z'or 'x'
  local k=axis..':'..p.at;local covered=planes[k]or{};planes[k]=covered
  local spans={{p.from,p.upto}}
  for _,c in ipairs(covered)do
   local nextSpans={}
   for _,a in ipairs(spans)do
    if a[1]<c[1]then nextSpans[#nextSpans+1]={a[1],math.min(a[2],c[1])}end
    if a[2]>c[2]then nextSpans[#nextSpans+1]={math.max(a[1],c[2]),a[2]}end
   end
   spans=nextSpans
  end
  for _,span in ipairs(spans)do if span[2]>span[1]then
   local q={};for key,value in pairs(p)do q[key]=value end
   q.from,q.upto=span[1],span[2];q.openings={}
   for _,o in ipairs(p.openings or{})do
    if o.from<q.upto and o.upto>q.from then
     local copy={};for key,value in pairs(o)do copy[key]=value end
     copy.from=math.max(q.from,o.from);copy.upto=math.min(q.upto,o.upto)
     q.openings[#q.openings+1]=copy
    end
   end
   out[#out+1]=q;covered[#covered+1]=span
  end end
 end
 return out
end
-- The glass facade has four full-height load-bearing corner piers. The
-- outer faces are the opaque ends of the facade; these are their room faces.
local function cornerPiers(map,out)
 if not tostring(map.id):match('^SILPH_CO_%d+F$')then return end
 local b=V.require('Gen1RoomBounds').forMap(map)
 local w,d=b.east,b.south
 for _,c in ipairs{{b.west,b.north},{w-8,b.north},{b.west,d-8},{w-8,d-8}}do
  local x,z=c[1],c[2]
  local a=add(out,z==b.north and 'north'or'south',x,x+8,z==b.north and b.north+8 or z)
  local face=add(out,x==b.west and 'west'or'east',z,z+8,x==b.west and b.west+8 or x)
  a.column=true;face.column=true
 end
end
function M.panelsFor(map, profile)
  V.require('Gen1RoomBounds').refresh(map)
  local d=map.def;local out={};local domesticInset=false
  local cabins=(map.id=='SS_ANNE_1F_ROOMS'or map.id=='SS_ANNE_2F_ROOMS')and V.require('Gen1WindowBindings').cabins(map)
  if cabins then
   blockFootprint(map,out)
   for _,p in ipairs(out)do p.windowBoundary=true end
  elseif map.id=='LANCES_ROOM' or map.id=='CINNABAR_LAB' then blockFootprint(map,out)
  elseif tostring(map.id):match('^CELADON_MANSION_[123]F$') and map.tileset and map.tileset.blocks then mansion(map,out)
  elseif map.id=='SILPH_CO_11F' and d.tileset=='INTERIOR' and map.tileset and map.tileset.blocks then silphOffice(map,out)
  elseif d.tileset=='UNDERGROUND' and map.tileset and map.tileset.blocks then underground(map,out)
  elseif d.tileset=='FACILITY' and map.tileset and map.tileset.blocks then facility(map,out)
  else perimeter(map,out) end
  local b=V.require('Gen1RoomBounds').forMap(map)
  local clipped={}
  for _,p in ipairs(out)do
    local horizontal=p.edge=='north'or p.edge=='south'
    if not p.niche then
      p.from=math.max(p.from,horizontal and b.west or b.north)
      p.upto=math.min(p.upto,horizontal and b.east or b.south)
    end
    if p.upto>p.from and (p.niche or p.at>=(horizontal and b.north or b.west)
      and p.at<=(horizontal and b.south or b.east))then clipped[#clipped+1]=p end
  end
  out=clipped
  V.require('Gen1SecurityDoors').addPanels(map,out)
  cornerPiers(map,out)
  local stairPortals={}
  local stairs=V.require('Gen1Stairs')
  for _,warp in ipairs(d.warps or{})do
    local class=stairs.classForWarp(map,warp)
    if class then
      local s={class=class,art='stair',h=16}
      local flight=stairs.storeFlight(map,warp.x,warp.y,s)or stairs.flight(map,warp.x,warp.y,s)
      local portal=flight and stairs.portal(map,warp.x,warp.y,flight,profile)
      if portal then stairPortals[#stairPortals+1]=portal end
    end
  end
  for _,p in ipairs(out)do
    local horizontal=p.edge=='north' or p.edge=='south'
    for _,portal in ipairs(stairPortals)do
      if p.edge==portal.edge and p.at==portal.at and not p.column and not p.endcap
        and p.from<portal.upto and p.upto>portal.from then
        p.openings[#p.openings+1]={from=math.max(p.from,portal.from),upto=math.min(p.upto,portal.upto),
          height=portal.height,open=true,stair=true}
      end
    end
    for _,warp in ipairs(d.warps or{})do
      local along=(horizontal and warp.x or warp.y)*16
      local across=(horizontal and warp.y or warp.x)*16
      local row=p.at-((p.edge=='south' or p.edge=='east')and 16 or 0)
      -- Silph's teleporter pads are floor events, never doors into a wall.
      local floorPad=tostring(map.id):match('^SILPH_CO_%d+F$') and tostring(warp.destMap):match('^SILPH_CO_%d+F$')
      if (not cabins or p.edge==(map.id=='SS_ANNE_1F_ROOMS'and'north'or'south'))and not floorPad and not p.nicheReturn and not p.column and not p.endcap and (not tostring(map.id):match('^CELADON_MANSION_[123]F$') or p.boundary) and across==row and along>=p.from and along<p.upto and not verticalWarp(map,warp) then
        local breach=p.edge=='north' and V.require('Gen1BreachExterior').opening(map,warp)
        p.openings[#p.openings+1]={from=along,upto=math.min(along+16,p.upto),
          height=warp.destMap=='SILPH_CO_ELEVATOR' and 36 or breach and 28 or nil,
          open=warp.destMap=='SILPH_CO_ELEVATOR' or breach or nil,breach=breach or nil,
          material=V.require('Gen1GlassDoors').interior(map,warp.destMap)and 'room_glass_door'
            or V.require('Gen1DoorStyles').material(map.id),
          singleLeaf=V.require('Gen1GlassDoors').wooden(map,warp.destMap)or nil,
          doorView=V.require('Gen1GlassDoors').interior(map,warp.destMap)and V.require('Gen1GlassDoors').outViewKey(map,warp)or nil}
      end
    end
    -- These wall tiles contain a readable native sign, not just a blank
    -- decorative panel. Mount it on the corridor-facing side only. Native
    -- sign events still own the text and A-button interaction; PC events
    -- elsewhere on 3F must not turn into wall plaques.
    if tostring(map.id):match('^CELADON_MANSION_[123]F$') and p.edge=='north' and not p.endcap then
      for _,sign in ipairs(d.signs or{})do
        local x,y=sign.x*2,sign.y*2
        if p.at==(sign.y+1)*16 and sign.x*16>=p.from and (sign.x+1)*16<=p.upto
          and tile(map,x,y+1)==22 and tile(map,x+1,y+1)==23 then
          p.signs=p.signs or{}
          p.signs[#p.signs+1]={from=sign.x*16+1,upto=(sign.x+1)*16-1,
            bottom=17,top=24,text=sign.text}
        end
      end
    end
    for _,door in ipairs(p.openings)do door.height=door.height or math.min(24,profile.shellHeight-16) end
    table.sort(p.openings,function(a,b)return a.from<b.from end)
    local merged={}
    for _,door in ipairs(p.openings)do
      local last=merged[#merged]
      if last and last.height==door.height and last.open==door.open and last.material==door.material and door.from<=last.upto then
        last.upto=math.max(last.upto,door.upto)
      else merged[#merged+1]=door end
    end
    -- Adjacent native exit tiles form one warp aperture, not an extra-wide
    -- wooden slab. This is presentation geometry only; native warps and
    -- collision remain untouched. Keep the leaf at exterior door proportions.
    for _,door in ipairs(merged)do
      if door.singleLeaf and not door.open and not door.breach then
        local center=(door.from+door.upto)/2
        local width=math.min(door.upto-door.from,door.height*2/3)
        door.from,door.upto=center-width/2,center+width/2
      end
    end
    p.openings=merged
    if (profile.theme=="home" or profile.theme=="coastal_home" or profile.theme=="traditional_home")
        and p.edge=="north" and (p.at==0 or cabins)and #p.openings==0 then
      p.at=p.at+16;domesticInset=true
    end
  end
  if domesticInset then
    for _,p in ipairs(out)do
      if (p.edge=="west" or p.edge=="east") and p.from==0 then p.from=16 end
    end
  end
  return M.uniquePlanes(out)
end
return M
