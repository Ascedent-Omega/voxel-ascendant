-- Shared furniture dimensions and source-reviewed occupant bearings.
local V=...
local M={}
local specs={
 arcade_chair={0,5,4.2,-2.15,9.2}, arcade_chair_left={1,5,4.2,-2.15,9.2},arcade_chair_right={3,5,4.2,-2.15,9.2},
 lounge_chair={0,8,6.2,-1.8,14.2},lounge_chair_south={2,8,6.2,-1.8,14.2},
 lounge_chair_left={1,8,6.2,-1.8,14.2},lounge_chair_right={3,8,6.2,-1.8,14.2},
 wood_chair_north={0,8,6.2,-4.8,15.2},wood_chair_south={2,8,6.2,-4.8,15.2},wood_chair_west={3,8,6.2,-4.8,15.2},wood_chair_east={1,8,6.2,-4.8,15.2},
 reds_dining_chair_west={3,8,4.7,-3.55,15.2},reds_dining_chair_east={1,8,4.7,-3.55,15.2},
 wood_stool={0,9,5.2,-100,0},waiting_bench={0,7,7.2,-3.8,14.2},link_club_seat={0,8,6.2,-3.8,14.2},
 captain_chair={0,8,6.2,-4.8,15.2,0,8},club_terminal={2,8,4.2,-100,0,0,16},
 office_station={2,8,6.2,-4.8,15.2,0,16},
}

-- Native cells stay 16px; only the furniture inside them is made human-sized.
-- Keep Red's already compact dining footprint and the RC4 arcade dimensions.
for kind,s in pairs(specs)do
 if not kind:match('^arcade_')then
  local scale=kind:match('^reds_dining_')and 1 or .75
  s[2]=s[2]*.75;s[3]=(s[3]-.2)*scale+.2
  if s[5]>0 then s[4]=(s[4]-.2)*scale+.2;s[5]=(s[5]-.2)*.75+.2 end
 end
end
specs.terrace_stool={0,6.375,3.95,-100,0}
M.specs=specs
local bearings
local function rows()
 if not bearings then
  bearings={}
  local src=assert(V.mod:read('integrated/ascendant_pokemon_overworld/src/human_seat_profiles.lua'))
  local data=assert((loadstring or load)(src))()
  for id,entries in pairs(data.byGeneration[1])do
   local map={};bearings[id]=map
   for _,p in ipairs(entries)do map[p.cellX..':'..p.cellY]=p.row end
  end
 end
 return bearings
end
function M.kind(kind,map,x,y)
 local b=rows()[map.id];local row=b and b[(x/2)..':'..(y/2)]
 if row==nil then return kind end
 if kind=='wood_chair_north'then return ({[0]='wood_chair_north',[1]='wood_chair_east',[2]='wood_chair_south',[3]='wood_chair_west'})[row]end
 if kind=='lounge_chair'then return ({[0]='lounge_chair',[1]='lounge_chair_left',[2]='lounge_chair_south',[3]='lounge_chair_right'})[row]end
 return kind
end
function M.orient(props,map,P)
 local tables={dining_table=true,writing_table=true,round_table=true,terrace_table=true,office_terminal=true}
 for _,p in ipairs(props)do
  if p.kind=='wood_chair_north' or p.kind=='wood_stool' or p.kind=='lounge_chair' then
   local reviewed=rows()[map.id];reviewed=reviewed and reviewed[(p.tx/2)..':'..(p.ty/2)]
   local row=reviewed
   if row==nil then
    local distance=math.huge
    local x,z=p.tx*8+8,p.ty*8+8
    for _,q in ipairs(props)do
     local m=P.models[q.kind]
     if tables[q.kind]and m then
      local dx,dz=q.tx*8+m.frameW/2-x,q.ty*8+m.depth/2-z
      local gap=math.max(0,math.abs(dx)-m.frameW/2)^2+math.max(0,math.abs(dz)-m.depth/2)^2
      if gap<distance and gap<=24*24 then
       distance=gap;row=math.abs(dx)>math.abs(dz)and (dx>0 and 3 or 1)or (dz>0 and 0 or 2)
      end
     end
    end
   end
   if row~=nil then
    p.seatRow=row
    if p.kind=='wood_chair_north'then p.kind=({[0]='wood_chair_north',[1]='wood_chair_east',[2]='wood_chair_south',[3]='wood_chair_west'})[row]
    elseif p.kind=='lounge_chair'then p.kind=({[0]='lounge_chair',[1]='lounge_chair_left',[2]='lounge_chair_south',[3]='lounge_chair_right'})[row]end
   end
  end
 end
end
function M.register(P)
 for kind,s in pairs(specs)do
  local model=P.models[kind]
  if model and not kind:match('^arcade_')then
   model.directBoxes=true;model.support=s[2]
   local scale=kind:match('^reds_dining_')and 1 or .75
   local ox,oz=s[6]or 0,s[7]or 0
   for _,b in ipairs(model.boxes)do
    -- Only the chair half of combined workstations is adjusted.
    if kind~='office_station'and kind~='club_terminal' or b[3]>=oz then
     b[1]=ox+8+(b[1]-ox-8)*scale;b[3]=oz+8+(b[3]-oz-8)*scale
     b[2]=b[2]*.75;b[4]=b[4]*scale;b[5]=b[5]*.75;b[6]=b[6]*scale
    end
   end
  end
 end
 local original=P.models.wood_chair_west
 local east={};for k,v in pairs(original)do east[k]=v end;east.boxes={}
 for _,b in ipairs(original.boxes)do east.boxes[#east.boxes+1]={16-b[1]-b[4],b[2],b[3],b[4],b[5],b[6],b[7]}end
 P.models.wood_chair_east=east
 local s=specs.wood_chair_west;specs.wood_chair_east={1,s[2],s[3],s[4],s[5]}
end
return M
