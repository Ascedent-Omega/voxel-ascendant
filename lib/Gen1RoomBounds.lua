-- Inner faces of the native blocked perimeter. Never infer partitions from
-- arbitrary impassable furniture; only complete outer courses are removed.
local V=...
local M={}
local cache=setmetatable({},{__mode="k"})
function M.refresh(map)cache[map]=nil end
function M.forMap(map)
 if cache[map]then return cache[map]end
 local d=map.def;local b={west=0,north=0,east=d.width*32,south=d.height*32}
 cache[map]=b
 if d.generation==2 or not map.tileset or not map.tileset.blocks or not map.isWalkableCell
  or not(d.tileset=='FACILITY'or d.tileset=='LOBBY'or map.id=='SILPH_CO_11F'or V.require('Gen1Rooftops').gate(map))
  or map.id=='CELADON_MART_ROOF' then return b end
 local w,h=d.width*2,d.height*2;local warps={}
 for _,p in ipairs(d.warps or{})do warps[p.y*w+p.x]=true end
 local function blocked(x,y)
  return warps[y*w+x]or not map:isWalkableCell(x,y)
 end
 local function row(y)for x=0,w-1 do if not blocked(x,y)then return false end end;return true end
 local function col(x)for y=0,h-1 do if not blocked(x,y)then return false end end;return true end
 -- A perimeter course is at most two native cells deep. Fail closed on
 -- tiny elevator cabins and irregular/custom footprints without a room.
 if w<6 or h<6 then return b end
 for y=0,1 do if row(y)then b.north=(y+1)*16 else break end end
 for y=h-1,h-2,-1 do if row(y)then b.south=y*16 else break end end
 for x=0,1 do if col(x)then b.west=(x+1)*16 else break end end
 for x=w-1,w-2,-1 do if col(x)then b.east=x*16 else break end end
 return b
end
-- Floor ownership follows the inset shell, with only actual warp alcoves
-- extending back into the old wall course. Keys match Structures/ChunkMesher.
function M.floorTiles(map)
 local b=M.forMap(map);local d=map.def
 if b.west==0 and b.north==0 and b.east==d.width*32 and b.south==d.height*32 then return end
 local tiles={}
 local function fill(x0,z0,x1,z1)
  for y=z0/8,z1/8-1 do for x=x0/8,x1/8-1 do tiles[(y+64)*4096+x+64]=true end end
 end
 fill(b.west,b.north,b.east,b.south)
 for _,w in ipairs(d.warps or{})do
  local x,z=w.x*16,w.y*16
  if x>=b.west and x+16<=b.east then
   if z<b.north then fill(x,z,x+16,b.north)
   elseif z+16>b.south then fill(x,b.south,x+16,z+16)end
  end
  if z>=b.north and z+16<=b.south then
   if x<b.west then fill(x,z,b.west,z+16)
   elseif x+16>b.east then fill(b.east,z,x+16,z+16)end
  end
 end
 return tiles
end
return M
