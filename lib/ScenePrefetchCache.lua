-- One retained scene receipt, shared by update and draw. Compare live values
-- (including in-place neighbour edits), never a concatenated key each frame.
local M={}
local directions={'north','south','west','east'}
function M.new()
 local entry
 local C={hits=0,builds=0,warmSkips=0,reuses=0}
 local function mapsMatch(a,map,ox,oy)
  if not a or a.map~=map or a.id~=map.id or a.def~=map.def
   or a.width~=map.def.width or a.height~=map.def.height
   or a.tileset~=map.tileset or a.blocks~=map.def.blocks or a.ox~=ox or a.oy~=oy then return false end
  for i,dir in ipairs(directions)do
   local c=map.def.connections and map.def.connections[dir]
   if a.connections[i*2-1]~=(c and c.map)or a.connections[i*2]~=(c and c.offset)then return false end
  end
  return true
 end
 local function snapshot(map,ox,oy,saved)
  saved=saved or{connections={}}
  for i,dir in ipairs(directions)do local c=map.def.connections and map.def.connections[dir]
   saved.connections[i*2-1]=c and c.map;saved.connections[i*2]=c and c.offset
  end
  saved.map,saved.id,saved.def=map,map.id,map.def
  saved.width,saved.height=map.def.width,map.def.height
  saved.tileset,saved.blocks,saved.ox,saved.oy=map.tileset,map.def.blocks,ox,oy
  return saved
 end
 function C.matches(state,ignoreMotion,...)
  if not entry or entry.state~=state or entry.worldMaps~=state.worldMaps
   or entry.player~=state.player or entry.npcs~=state.npcs or entry.dark~=state.dark
   or entry.optionCount~=select('#',...)then return false end
  for i=1,entry.optionCount do if entry.options[i]~=select(i,...)then return false end end
  if not mapsMatch(entry.maps[1],state.map,0,0)then return false end
  local n=1
  for _,nb in ipairs(state.neighbors or{})do
   n=n+1;if not mapsMatch(entry.maps[n],nb.map,nb.ox,nb.oy)then return false end
  end
  if n~=#entry.maps then return false end
  local p=state.player
  return ignoreMotion or not p or entry.x==p.cellX and entry.y==p.cellY
   and entry.px==p.px and entry.py==p.py and entry.facing==p.facing
 end
 function C.get(state,frame,...)
  if entry and frame~=nil and entry.frame==frame and C.matches(state,false,...)then
   C.hits=C.hits+1;return entry.result
  end
 end
 -- A caller may extend a fully prepared structural union across frames.
 -- Live actors/cameras are read by render, not owned by this geometry receipt.
 function C.reuse(state,frame,...)
  if not C.matches(state,true,...)then return end
  local p=state.player
  entry.frame=frame
  entry.x,entry.y,entry.px,entry.py,entry.facing=p and p.cellX,p and p.cellY,p and p.px,p and p.py,p and p.facing
  C.reuses=C.reuses+1
  return entry.result
 end
 function C.store(state,frame,result,...)
  entry=entry or{maps={},options={}}
  local maps=entry.maps;maps[1]=snapshot(state.map,0,0,maps[1]);local n=1
  for _,nb in ipairs(state.neighbors or{})do n=n+1;maps[n]=snapshot(nb.map,nb.ox,nb.oy,maps[n])end
  for i=#maps,n+1,-1 do maps[i]=nil end
  local p=state.player
  entry.state,entry.frame,entry.result,entry.worldMaps=state,frame,result,state.worldMaps
  entry.player,entry.npcs,entry.dark=p,state.npcs,state.dark
  entry.x,entry.y,entry.px,entry.py,entry.facing=p and p.cellX,p and p.cellY,p and p.px,p and p.py,p and p.facing
  local options=select('#',...)
  for i=1,math.max(options,entry.optionCount or 0)do entry.options[i]=select(i,...)end
  entry.optionCount=options
  C.builds=C.builds+1
 end
 function C.peek()return entry and entry.result end
 function C.clear()entry=nil end
 return C
end
return M
