-- Explicit floor/facade ownership for native rooms that do not have a direct
-- ordinary-house entrance. Gameplay maps and warps remain authoritative.
local V=...
local M={}
local lab={CINNABAR_LAB_TRADE_ROOM={0,1/3,{north=true,west=true}},
 CINNABAR_LAB_METRONOME_ROOM={1/3,2/3,{north=true}},
 CINNABAR_LAB_FOSSIL_ROOM={2/3,1,{north=true,east=true}}}
local ships={SS_ANNE_1F=21,SS_ANNE_1F_ROOMS=21,SS_ANNE_KITCHEN=21,
 SS_ANNE_2F=46,SS_ANNE_2F_ROOMS=46,SS_ANNE_CAPTAINS_ROOM=46,SS_ANNE_3F=46}
function M.root(id)
 if lab[id]then return'CINNABAR_LAB'end
 return id:gsub('_%d+F$','_1F')
end
function M.options(map)
 local id=map.id;local l=lab[id]
 if l then return{crop={l[1],l[2]},edges=l[3]}end
 if id=='SS_ANNE_CAPTAINS_ROOM'then return{crop={76/320,228/320},edges={north=true,south=true}}end
 if id=='OAKS_LAB'then return{edges={west=true,east=true,south=true}}end
 if id=='CINNABAR_LAB'then return{edges={west=true,east=true,south=true}}end
 return{}
end
-- Native cabin maps are six disconnected 2x3-block islands. Never bridge
-- their padding with windows or invent an opening into the corridor side.
function M.cabins(map)
 local id=map.id;local d=map.def
 if id~='SS_ANNE_1F_ROOMS'and id~='SS_ANNE_2F_ROOMS'then return end
 if not d or d.width~=12 or d.height~=8 or d.tileset~='SHIP'or d.generation==2 then return end
 local rectangles={}
 for y=0,7 do for x=0,11 do
  local occupied=(x%5<2 and x<=11 and (y<3 or y>=5))
  if (d.blocks[y*12+x+1]~=d.borderBlock)~=occupied then return end
 end end
 for row=0,1 do for col=0,2 do
  rectangles[#rectangles+1]={west=col*160,east=col*160+64,north=row*160+(id=='SS_ANNE_2F_ROOMS'and 16 or 0),south=row*160+96,
   edge=id=='SS_ANNE_1F_ROOMS'and'south'or'north',column=col}
 end end
 return rectangles
end
function M.specialSource(map)
 if ships[map.id]then
  local defs=require('src.core.Game').data.maps
  local d=defs.VERMILION_DOCK;local city=defs.VERMILION_CITY
  if d and city and d.tileset=='SHIP_PORT'and d.width==14 and d.height==6
    and V.require('Gen1Harbor').kind({id='VERMILION_CITY',def=city})then
   for _,w in ipairs(d.warps or{})do if w.x==14 and w.y==2 and w.destMap=='SS_ANNE_1F'then
    return'VERMILION_CITY',{x=304,z=704,special='ship'},1
   end end
  end
 elseif map.id=='CELADON_MANSION_ROOF_HOUSE'then
  local defs=require('src.core.Game').data.maps;local d=defs.CELADON_MANSION_ROOF
  if d and V.require('Gen1RoofTerrace').matches(require('src.world.Map').new(d,require('src.core.Game').data.tilesets[d.tileset]))then
   for _,w in ipairs(defs.CELADON_CITY.warps or{})do if w.destMap=='CELADON_MANSION_1F'then
    return'CELADON_CITY',{x=w.x*16+8,z=w.y*16+8,special='pavilion'},1
   end end
  end
 end
end
function M.facade(map,link,buildings,P)
 if link.special=='ship'then
  V.require('Gen1Harbor').models(P)
  local a=P.models.ss_anne_liner;local glass={boxes={}}
  for _,b in ipairs(a.boxes)do if b[7]==8 and b[5]>=4 and b[6]==1 then glass.boxes[#glass.boxes+1]=b end end
  return{kind='ss_anne_liner',tx=18,ty=81},{frameW=a.frameW,depth=a.depth,windowFaceMid=true},glass,ships[map.id],25
 end
 local root=M.root(map.id);local chosen
 for _,p in ipairs(buildings)do local a=P.models[p.kind]
  if a then
   local door=false;for _,d in ipairs(a.nativeDoors or{})do if d.dest==root then door=true end end
   if door and link.x>=p.tx*8-16 and link.x<=p.tx*8+a.frameW+16
      and link.z>=p.ty*8-16 and link.z<=p.ty*8+a.depth+16 then chosen=p;break end
   if not chosen and link.x>=p.tx*8 and link.x<p.tx*8+a.frameW
      and link.z>=p.ty*8-8 and link.z<=p.ty*8+a.depth+8 then chosen=p end
  end
 end
 if not chosen then return end
 local a=P.models[chosen.kind];local glass=a.glassKind and P.models[a.glassKind]
 local floor=tonumber(map.id:match('_(%d+)F$'))or 1
 if link.special=='pavilion'then
  local w,d=a.frameW*48/128,a.depth*64/192
  local x,z=chosen.tx*8+a.frameW*16/128,chosen.ty*8+a.depth*64/192
  local g={boxes={{w/48,5,d-1,w*12/48,22,1,7},{w*34/48,5,d-1,w*12/48,22,1,7}}}
  return{kind=chosen.kind,tx=x/8,ty=z/8,hostTx=chosen.tx,hostTy=chosen.ty},{frameW=w,depth=d},g,-(a.offsetY+a.depth),32
 end
 local stride=a.windowLevelHeight
 local height=stride and(floor-1)*stride or floor==2 and 24 or 0
 return chosen,a,glass,height,stride or 24
end
return M
