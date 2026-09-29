-- Voxel-only clearance behind exact department-store rack replacements.
-- Native maps stay immutable; NPCs, scripts and vanilla keep their grid owner.
local V=...
local M={}
local cache=setmetatable({},{__mode='k'})
function M.matches(map)
 local d=map and map.def
 return d and d.generation~=2 and d.tileset=='LOBBY'and d.width==10 and d.height==4
  and tostring(map.id):match('^CELADON_MART_[2345]F$')~=nil
end
function M.variant(P,kind,map,x,z)
 if not M.matches(map)or not kind:match('^retail_')or kind=='retail_checkout' or kind:find('_half')then return kind end
 local source=P.models[kind];if not source then return kind end
 local b=V.require('Gen1RoomBounds').forMap(map)
 local west,east=x*8==b.west,x*8+32==b.east
 local north,south=z*8==b.north,z*8+32==b.south
 if not(west or east or north or south)then return kind end
 local suffix=(west and 'w'or east and 'e'or'')..(north and 'n'or south and 's'or'')
 local name=kind..'_aisle_'..suffix
 if not P.models[name]then
  local model={};for k,v in pairs(source)do model[k]=v end;model.boxes={}
  model.retailAisle={west=west,east=east,north=north,south=south}
  -- The newly walkable strip replaces raised native rack art with floor.
  model.support=0
  for _,box in ipairs(source.boxes)do
   local q={unpack(box)}
   if west or east then
    local function project(v)return math.floor((v-16)*.75+16+.5)+(west and 8 or -8)end
    q[1]=project(box[1]);q[4]=math.max(1,project(box[1]+box[4])-q[1])
   end
   if north or south then q[3]=q[3]+(north and 8 or -8)end
   model.boxes[#model.boxes+1]=q
  end
  P.models[name]=model
 end
 return name
end
local function cells(map)
 local props=V.require('VoxelFurniture').find(map)
 local old=cache[map];if old and old.props==props then return old.cells end
 local P=V.require('VoxelItems');local out={};local b=V.require('Gen1RoomBounds').forMap(map)
 for _,p in ipairs(props)do
  local m=P.models[p.kind]
  if m and m.retailAisle then
   local cx,cy=p.tx/2,p.ty/2
   for y=cy,cy+1 do for x=cx,cx+1 do
    local x0,z0=x*16,y*16;local clear=x0>=b.west and z0>=b.north and x0+16<=b.east and z0+16<=b.south
    for _,box in ipairs(m.boxes)do
     local bx,bz=p.tx*8+box[1],p.ty*8+box[3]
     if bx<x0+16 and bx+box[4]>x0 and bz<z0+16 and bz+box[6]>z0 then clear=false;break end
    end
    for _,list in ipairs{map.def.warps or{},map.def.signs or{}}do
     for _,event in ipairs(list)do if event.x==x and event.y==y then clear=false end end
    end
    if clear then out[y*20+x]=p end
   end end
  end
 end
 -- Shelves behind a closed service counter are staff storage, not a new
 -- public passage. Only release cells connected to the authored entrances.
 local queue,seen={},{}
 local function visit(x,y)
  local k=y*20+x
  if map:inBounds(x,y)and not seen[k]and (out[k]or map:isWalkableCell(x,y))then
   seen[k]=true;queue[#queue+1]=k
  end
 end
 for _,w in ipairs(map.def.warps or{})do visit(w.x,w.y)end
 -- Layout fixtures without warps still have a native floor component.
 if #queue==0 then
  for y=0,7 do for x=0,19 do
   if #queue==0 and map:isWalkableCell(x,y)then visit(x,y)end
  end end
 end
 local head=1
 while head<=#queue do
  local k=queue[head];head=head+1;local x,y=k%20,math.floor(k/20)
  visit(x-1,y);visit(x+1,y);visit(x,y-1);visit(x,y+1)
 end
 for k in pairs(out)do if not seen[k]then out[k]=nil end end
 cache[map]={props=props,cells=out};return out
end
function M.permission(state,x,y)
 if not M.matches(state.map)or not V.require('VoxelItems').setting:get()
  or require('src.render.Pipelines').worldPipeline()~='voxel'
  or not state.map:inBounds(x,y)or state.map:warpAtCell(x,y)then return false end
 local p=cells(state.map)[y*20+x]
 return p~=nil and p.claimed==true
end
-- A save or mode switch can put the player in the released strip. Walk its
-- small connected cell graph back to native floor, without crossing a shelf,
-- wall, warp or occupied cell. Never rewrite collision data or a save directly.
function M.reconcile(state)
 local map,p=state.map,state.player
 if not p or not M.matches(map)or p.moving or p.inputLocked or map:isWalkableCell(p.cellX,p.cellY)
  or (M.permission(state,p.cellX,p.cellY)and V.require('FirstPerson').engaged())then return false end
 local free=cells(map);local first=p.cellY*20+p.cellX
 if not free[first]then return false end
 local occupied=require('src.world.Collision').occupied
 local queue,seen={first},{[first]=true};local head=1
 while head<=#queue do
  local k=queue[head];head=head+1;local x,y=k%20,math.floor(k/20)
  if map:isWalkableCell(x,y)and not map:warpAtCell(x,y)and not occupied(state.entities,x,y,p)then
   p.cellX,p.cellY=x,y;p.px,p.py=x*16,y*16
   return true
  end
  for _,d in ipairs{{0,-1},{-1,0},{1,0},{0,1}}do
   local nx,ny=x+d[1],y+d[2];local nk=ny*20+nx
   if map:inBounds(nx,ny)and not seen[nk]and not map:warpAtCell(nx,ny)
    and not occupied(state.entities,nx,ny,p)
    and (free[nk]or map:isWalkableCell(nx,ny))then seen[nk]=true;queue[#queue+1]=nk end
  end
 end
 return false
end
return M
