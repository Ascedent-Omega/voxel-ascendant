-- Desktop residency ring: whole current map plus all direct connections.
-- Keep the engine's complete state and two-hop discovery data untouched.
local V=...
local N={}
N.setting=V.require('ModSetting').new('desktopNeighborRing','PC MAP RING',{true,false},{'ON','OFF'})
function N.requiredIds(state)
 local map=state and state.map;local d=map and map.def;local ids={}
 if not d then return ids end
 for _,c in pairs(d.connections or{})do if type(c)=='table'and c.map then ids[c.map]=true end end
 -- Sevii source maps are partitioned into small runtime rectangles. Their
 -- diagonal bodies belong to the same visible source, not another route.
 -- Omitting them leaves sky-sized square holes beside cardinal neighbours.
 if d.kaOwner=='kasc.sevii-expedition/v1'and d.outdoor and d.kaSeviiSource then
  local w,h=d.width*32,d.height*32
  for _,nb in ipairs(state.neighbors or{})do
   local n=nb.map and nb.map.def
   if n and n.kaOwner==d.kaOwner and n.kaSeviiSource==d.kaSeviiSource
    and(nb.ox+n.width*32==0 or nb.ox==w)and(nb.oy+n.height*32==0 or nb.oy==h)then ids[nb.map.id]=true end
  end
 end
 return ids
end
function N.apply(state)
 if not N.setting:get()or not(state and state.map and state.map.def)then return state end
 local keep=N.requiredIds(state);keep[state.map.id]=true;local con=state.map.def.connections
 if type(con)~='table'then return state end -- unknown custom-map topology
 local neighbors,seen={},{}
 for _,nb in ipairs(state.neighbors or{})do
  local id=nb.map and nb.map.id
  if keep[id]and id~=state.map.id and not seen[id]then neighbors[#neighbors+1]=nb;seen[id]=true end
 end
 if #neighbors==#(state.neighbors or{})then return state end
 local out={};for k,v in pairs(state)do out[k]=v end;out.neighbors=neighbors
 return out
end
return N
