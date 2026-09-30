-- Real imported Gen-I collision/ledge data; no renderer or modified map data.
local host=assert(os.getenv('QA_GAME_HOST'),'QA_GAME_HOST must name an imported Gen-I host')..'/'
local Map=dofile(host..'src/world/Map.lua');package.loaded['src.world.Map']=Map
local data={maps=dofile(host..'red/data/generated/maps.lua'),
 tilesets=dofile(host..'red/data/generated/tilesets.lua'),field=dofile(host..'red/data/generated/field.lua')}
local modules={BuildBudget={check=function()end,tick=function()end},
 ModSetting={new=function()return{get=function()return'world'end}end}}
local V={mod={},data=function()return dofile('data/voxel_heights.lua')end}
V.require=function(n)
 if not modules[n]then modules[n]=assert(loadfile('lib/'..n..'.lua'))(V)end
 return modules[n]
end
local L=assert(loadfile(os.getenv('QA_ELEVATION_SOURCE') or 'lib/LedgeElevation.lua'))(V)
local map=Map.new(data.maps.VIRIDIAN_CITY,data.tilesets.OVERWORLD)
local original={};for i,b in ipairs(map.def.blocks)do original[i]=b end
local e=L.map(map,data)
assert(e:at(23,26)-e:at(23,28)==6,'Center terrace stays level with lower street')
for x=22,25 do for y=22,26 do
 assert(e:at(x,y)==e:at(23,26),'Center foundation split across levels')
end end
for _,x in ipairs{15,19}do
 for y=26,28 do assert(map:isWalkableCell(x,y),'native opening obstructed')end
 local dir,high,low=e:rampAtTile(x*2,54)
 assert(dir=='down' and high-low==6,'walkable opening has no connecting slope')
 assert(high==e:at(x,26) and low==e:at(x,28),'opening misses terrace endpoints')
end
for y=0,map.heightCells-1 do for x=0,map.widthCells-1 do
 for _,d in ipairs{{1,0},{0,1}}do
  local xx,yy=x+d[1],y+d[2]
  if map:inBounds(xx,yy) and map:isWalkableCell(x,y) and map:isWalkableCell(xx,yy)
     and not map:isWaterCell(x,y) and not map:isWaterCell(xx,yy)then
   assert(math.abs(e:at(x,y)-e:at(xx,yy))<=6,'new multi-course walking cliff')
  end
 end
end end
for dir,c in pairs(map.def.connections)do
 local other=Map.new(data.maps[c.map],data.tilesets[data.maps[c.map].tileset])
 local f=L.map(other,data);local checked=0;local offset=(c.offset or 0)*2
 local vertical=dir=='north' or dir=='south'
 for i=0,(vertical and map.widthCells or map.heightCells)-1 do
  local x,y,xx,yy
  if dir=='north'then x,y,xx,yy=i,0,i-offset,other.heightCells-1
  elseif dir=='south'then x,y,xx,yy=i,map.heightCells-1,i-offset,0
  elseif dir=='west'then x,y,xx,yy=0,i,other.widthCells-1,i-offset
  else x,y,xx,yy=map.widthCells-1,i,0,i-offset end
  if other:inBounds(xx,yy) and map:isWalkableCell(x,y) and other:isWalkableCell(xx,yy)then
   local a,b=e:at(x,y),f:at(xx,yy)
   if a~=b then
    local field,cx,cy,edge=e,x,y,dir
    if b<a then
     field,cx,cy=f,xx,yy
     edge=({north='south',south='north',west='east',east='west'})[dir]
    end
    local tx=cx*2+(edge=='east'and 1 or 0)
    local ty=cy*2+(edge=='south'and 1 or 0)
    local slope,high,low=field:rampAtTile(tx,ty)
    assert(slope and high==math.max(a,b) and low==math.min(a,b),
      'connection has neither equal datum nor a joined slope '..dir..' '..i)
   end
   checked=checked+1
  end
 end
 assert(checked>0,'missing native connection coverage '..dir)
 print('PASS aligned native seam',dir,c.map,checked)
end
-- Conservative LOCAL and explicit FLAT remain reversible, separate choices.
for _,mode in ipairs{'local','flat'}do
 L._setModeForTests(mode);local f=L.map(map,data)
 assert(f:at(23,26)==f:at(23,28),'changed '..mode..' layout')
 assert(f:at(23,26)==(mode=='local' and 6 or 0),'changed '..mode..' datum')
end
L._setModeForTests('world')
local celadon=Map.new(data.maps.CELADON_CITY,data.tilesets.OVERWORLD)
local f=L.map(celadon,data)
for y=0,celadon.heightCells-1 do for x=0,celadon.widthCells-1 do
 assert(f:at(x,y)==f:at(0,0),'Celadon level-map guard changed')
end end
for i,b in ipairs(map.def.blocks)do assert(b==original[i],'native map was mutated')end
print('PASS WORLD Center terrace, two walkable slopes, foundations, road grades, LOCAL/FLAT rollback, Celadon and native data retention')
