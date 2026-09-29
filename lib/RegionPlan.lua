-- Plan logical loading areas from native map data without constructing GPU maps.
-- Ordinary houses belong to the outdoors; gates/caves and large room networks
-- are separate areas. Flooding outdoor cells prevents a gate inside one route
-- from accidentally joining the connections on its opposite side.
local P={}
local Map=require('src.world.Map')
local Warp=require('src.world.Warp')
local directions={{'north',0,-1},{'south',0,1},{'west',-1,0},{'east',1,0}}
local function outside(def)
 return def and (Map.isOutside(def) or def.tileset=='FOREST')
end
local function barrier(id,def)
 return not def or id:find('_GATE',1,true)~=nil or (def.tileset=='CAVERN' or def.tileset=='GATE')
  or id:find('UNDERGROUND_PATH',1,true)~=nil
end
local indexMaps,index,indexEdges
local function roomIndex(data)
 if indexMaps==data.maps then return index end
 local edges={}
 for id,def in pairs(data.maps)do
  if not outside(def) and not barrier(id,def)then edges[id]={}end
 end
 for id in pairs(edges)do
  for _,w in ipairs(data.maps[id].warps or{})do
   if edges[w.destMap]then edges[id][w.destMap]=true;edges[w.destMap][id]=true end
  end
 end
 local out={}
 for id in pairs(edges)do
  if not out[id]then
   local component={id};out[id]=component;local at=1
   while component[at]do
    local links={};for other in pairs(edges[component[at]])do links[#links+1]=other end;table.sort(links)
    for _,other in ipairs(links)do if not out[other]then out[other]=component;component[#component+1]=other end end
    at=at+1
   end
   table.sort(component)
  end
 end
 indexMaps,index,indexEdges=data.maps,out,edges;return out
end
function P.isOutside(data,id)return outside(data.maps[id])==true end
function P.isBoundary(data,id)return barrier(id,data.maps[id])==true end
function P.isLarge(data,id)
 local rooms=roomIndex(data)[id]
 if not rooms then return false end
 if #rooms>=4 then return true end
 local area=0;for _,room in ipairs(rooms)do local d=data.maps[room];area=area+d.width*d.height end
 return area>=256
end
function P.sameBuilding(data,a,b)
 local rooms=roomIndex(data);return rooms[a]~=nil and rooms[a]==rooms[b]
end
function P.new(data,ow)
 local root=ow.map.id
 local result={root=root,ids={},boundaries={},scope='region'}
 local function run()
  local rooms=roomIndex(data)
  local included={}
  local function add(id)
   if not included[id]then included[id]=true;result.ids[#result.ids+1]=id end
  end
  add(root)
  if barrier(root,data.maps[root])then result.scope='boundary';return end
  if P.isLarge(data,root)then
   result.scope='building'
   local queue,head={root},1
   while queue[head]do
    local links={};for id in pairs(indexEdges[queue[head]]or{})do links[#links+1]=id end;table.sort(links)
    for _,id in ipairs(links)do if not included[id]then add(id);queue[#queue+1]=id end end
    head=head+1
   end
   return
  end
  local queue,head,visited,warpCells,tiles={},1,{},{},{}
  local function seed(id,x,y)
   local def=data.maps[id]
   if not outside(def) or barrier(id,def)or type(x)~='number'or type(y)~='number'then return end
   local w,h=def.width*2,def.height*2
   if x<0 or y<0 or x>=w or y>=h then return end
   local key=y*w+x;visited[id]=visited[id]or{}
   if visited[id][key]then return end
   visited[id][key]=true;queue[#queue+1]={id,x,y};add(id)
  end
  local function house(id)
   if barrier(id,data.maps[id])or P.isLarge(data,id)then result.boundaries[id]=true;return end
   for _,room in ipairs(rooms[id]or{id})do add(room)end
  end
  if outside(data.maps[root])then seed(root,ow.player.cellX,ow.player.cellY)
  else
   house(root)
   for _,id in ipairs(rooms[root]or{root})do
    for _,warp in ipairs(data.maps[id].warps or{})do
     local ok,dest,x,y=pcall(Warp.destination,data,warp,ow.lastOutdoor)
     if ok and outside(data.maps[dest])then seed(dest,x,y)end
    end
   end
  end
  local function passable(id,x,y)
   local def=data.maps[id];local ts=data.tilesets[def.tileset]
   if not ts then return false end
   local key=y*def.width*2+x
   tiles[id]=tiles[id]or{}
   if tiles[id][key]==nil then
    tiles[id][key]=Map.defIsWalkableCell(def,ts,x,y)or Map.defIsWaterCell(def,ts,x,y)
   end
   return tiles[id][key]
  end
  while queue[head]do
   local cell=queue[head];queue[head]=false;head=head+1
   local id,x,y=unpack(cell);local def=data.maps[id];local w,h=def.width*2,def.height*2
   if not warpCells[id]then
    local cells={};warpCells[id]=cells
    for _,warp in ipairs(def.warps or{})do cells[warp.y*w+warp.x]=warp end
   end
   local warp=warpCells[id][y*w+x]
   if warp then
    local ok,dest=pcall(Warp.destination,data,warp,{id=id,x=x,y=y})
    if ok and data.maps[dest]and not outside(data.maps[dest])then house(dest)end
   end
   -- An entrance is a dead end in the outdoor walk graph. The initial
   -- landing cell is allowed out, so Continue inside a house finds its town.
   if not warp or head==2 then
    for _,dir in ipairs(directions)do
     local dest,nx,ny=id,x+dir[2],y+dir[3]
     if nx<0 or ny<0 or nx>=w or ny>=h then
      local c=(def.connections or{})[dir[1]];dest=c and c.map
      local dd=dest and data.maps[dest]
      if outside(dd)and not barrier(dest,dd)then
       if dir[1]=='west'then nx,ny=dd.width*2-1,y-(c.offset or 0)*2
       elseif dir[1]=='east'then nx,ny=0,y-(c.offset or 0)*2
       elseif dir[1]=='north'then nx,ny=x-(c.offset or 0)*2,dd.height*2-1
       else nx,ny=x-(c.offset or 0)*2,0 end
      else dest=nil end
     end
     local dd=dest and data.maps[dest]
     if dd and nx>=0 and ny>=0 and nx<dd.width*2 and ny<dd.height*2 and passable(dest,nx,ny)then seed(dest,nx,ny)end
    end
   end
   if head%128==0 then coroutine.yield()end
  end
 end
 result.co=coroutine.create(run)
 return result
end
function P.step(plan)
 if plan.done then return true end
 local ok,err=coroutine.resume(plan.co)
 if not ok then plan.error=tostring(err);plan.done=true
 else plan.done=coroutine.status(plan.co)=='dead'end
 if plan.done then plan.co=nil end
 return plan.done
end
return P
