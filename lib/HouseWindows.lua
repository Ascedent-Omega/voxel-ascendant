-- Domestic windows are derived from the actual exterior glass boxes and native
-- entrance warps. Unknown/custom footprints fail closed; no guessed city view.
local V=...
local M={}
local homes={home=true,traditional_home=true,coastal_home=true,daycare=true,center=true,mart=true}
local links,linksOwner
local cache=setmetatable({},{__mode='k'})
function M.source(map)
 local profile=map and V.require('Gen1InteriorPanoramas').profiles[map.id]
 local d=map and map.def
 if not(profile and homes[profile.theme]and d and d.generation~=2 and d.tileset==profile.tileset
  and d.width==profile.width and d.height==profile.height)then return end
 local game=require('src.core.Game');local defs=game.data and game.data.maps
 if not defs then return end
 if linksOwner~=defs then
  linksOwner=defs;links={}
  for id,def in pairs(defs)do if def.tileset=='OVERWORLD'and def.generation~=2 then
   for _,warp in ipairs(def.warps or{})do
    local old=links[warp.destMap]
    if not old or id<old.source then links[warp.destMap]={source=id,x=warp.x*16+8,z=warp.y*16+8}end
   end
  end end
 end
 local first=map.id:gsub('_%d+F$','_1F')
 -- Upper storeys can also be reached by custom exterior shortcuts. Their
 -- facade still belongs to the building entered on the ground floor.
 local link=links[first]or links[map.id]
 return link and link.source,link,tonumber(map.id:match('_(%d+)F$'))or 1
end
local function perimeter(map,p)
 local d=map.def
 local b=V.require('Gen1RoomBounds').forMap(map)
 if p.at==b[p.edge]and not p.niche and not p.nicheReturn and not p.column and not p.endcap and not p.wallThickness then return true end
 return not p.wallThickness and not p.endcap and ((p.edge=='north'and(p.at==0 or p.at==16))
  or(p.edge=='south'and p.at==d.height*32)or(p.edge=='west'and p.at==0)or(p.edge=='east'and p.at==d.width*32))
end
M.perimeter=perimeter
-- Reject only panes whose outward strip immediately meets another footprint.
-- Upper floors use the actual neighbour height; a distant street-facing house
-- is a valid view, a shared wall is not. Work runs once per cached room.
local function exposed(edge,b,model,placement,buildings,models)
 local x,z=placement.tx*8,placement.ty*8
 local x0,x1,z0,z1=x+b[1],x+b[1]+b[4],z+b[3],z+b[3]+b[6]
 if edge=='north'then z0,z1=z-8,z
 elseif edge=='south'then z0,z1=z+model.depth,z+model.depth+8
 elseif edge=='west'then x0,x1=x-8,x
 else x0,x1=x+model.frameW,x+model.frameW+8 end
 for _,p in ipairs(buildings)do if p~=placement then
  local a=models[p.kind]
  if a and x0<p.tx*8+a.frameW and x1>p.tx*8 and z0<p.ty*8+a.depth and z1>p.ty*8 then
   for _,box in ipairs(a.boxes or{})do
    if box[2]+box[5]>b[2] and box[2]<b[2]+b[5]then return false end
   end
  end
 end end
 return true
end
M.exposed=exposed
function M.describe(map)
 local source,link,floor=M.source(map);if not source then return end
 local setting=V.require('Gen1PalletVillage').buildings:get()
 local old=cache[map];if old and old.setting==setting then return old.value or nil end
 local function done(value)cache[map]={setting=setting,value=value or false};return value end
 if not setting then return done()end
 local game=require('src.core.Game');local def=game.data.maps[source]
 local city=require('src.world.Map').new(def,game.data.tilesets[def.tileset])
 local P=V.require('VoxelItems');local buildings=V.require('VoxelFurniture').findBuildings(city)
 local model,placement
 for _,p in ipairs(buildings)do local a=P.models[p.kind]
  if a and link.x>=p.tx*8 and link.x<p.tx*8+a.frameW and link.z>=p.ty*8-8 and link.z<=p.ty*8+a.depth+8 then
   model,placement=a,p;break
  end
 end
 if not model or not P.models[model.glassKind]then return done()end
 local profile=V.require('Gen1InteriorPanoramas').profiles[map.id]
 local w,d,H=map.def.width*32,map.def.height*32,profile.shellHeight
 local bounds=V.require('Gen1RoomBounds').forMap(map)
 local x0,x1,z0,z1=bounds.west,bounds.east,bounds.north,bounds.south
 local department=map.id:match('^CELADON_MART_%d+F$')~=nil
 local floorHeight=department and (floor-1)*17.5 or floor==2 and 24 or 0
 local out={source=source,kind=placement.kind,x=placement.tx*8,z=placement.ty*8,
  width=model.frameW,depth=model.depth,height=floorHeight,panes={}}
 local bands={}
 for _,b in ipairs(P.models[model.glassKind].boxes)do
  -- Glass doors, roof skylights and signage do not become room windows.
  local edge,from,upto
  if b[6]<=2 and b[5]>=4 then
   if b[3]>model.depth*.65 then edge='south'elseif b[3]<model.depth*.15 then edge='north'end
   from,upto=x0+b[1]/model.frameW*(x1-x0),x0+(b[1]+b[4])/model.frameW*(x1-x0)
  elseif b[4]<=2 and b[5]>=4 then
   edge=b[1]<model.frameW/2 and 'west'or'east'
   from,upto=z0+b[3]/model.depth*(z1-z0),z0+(b[3]+b[6])/model.depth*(z1-z0)
  end
  local correctFloor=department and b[2]>=floorHeight and b[2]<floorHeight+17.5
   or not department and (floor==2 and b[2]>=24 or floor==1 and b[2]<24)
  if edge and correctFloor and exposed(edge,b,model,placement,buildings,P.models)then
   local door=false
   if edge=='south'and floor==1 then
    local localDoor=link.x-placement.tx*8
    if b[1]<=localDoor+6 and b[1]+b[4]>=localDoor-6 then door=true end
   end
   if not door then bands[#bands+1]={edge=edge,from=from,upto=upto}end
  end
 end
 table.sort(bands,function(a,b)return a.edge==b.edge and a.from<b.from or a.edge<b.edge end)
 for _,p in ipairs(bands)do
  local last=out.panes[#out.panes]
  if last and last.edge==p.edge and p.from<=last.upto+4 then last.upto=math.max(last.upto,p.upto)
  else
   local horizontal=p.edge=='north'or p.edge=='south'
   p.at=bounds[p.edge]
   p.bottom,p.top=12,H-10
   p.from,p.upto=math.max((horizontal and x0 or z0)+5,p.from),math.min((horizontal and x1 or z1)-5,p.upto)
   if p.upto-p.from>=3 then out.panes[#out.panes+1]=p end
  end
 end
 if #out.panes==0 or #out.panes>64 then return done()end
 -- Cut apertures at the very same native door intervals as the wall builder.
 local panes={}
 for _,p in ipairs(out.panes)do
  for _,wall in ipairs(V.require('Gen1InteriorLayout').panelsFor(map,profile))do
   if perimeter(map,wall)and wall.edge==p.edge then
    local runs={{math.max(p.from,wall.from),math.min(p.upto,wall.upto)}}
    for _,door in ipairs(wall.openings or{})do
     local nextRuns={}
     for _,run in ipairs(runs)do
      if door.upto<=run[1]or door.from>=run[2]then nextRuns[#nextRuns+1]=run
      else
       if door.from-1>run[1]then nextRuns[#nextRuns+1]={run[1],door.from-1}end
       if door.upto+1<run[2]then nextRuns[#nextRuns+1]={door.upto+1,run[2]}end
      end
     end
     runs=nextRuns
    end
    for _,run in ipairs(runs)do if run[2]-run[1]>=3 then
     panes[#panes+1]={edge=p.edge,at=wall.at,from=run[1],upto=run[2],bottom=p.bottom,top=p.top}
    end end
   end
  end
 end
 out.panes=panes;if #panes==0 or #panes>64 then return done()end
 return done(out)
end
function M.anchor(entry)
 local a=M.describe(entry.map);if not a then return end
 return{x=entry.w/2-(a.x+a.width/2),z=entry.h/2-(a.z+a.depth/2),y=-a.height,
  kind=a.kind,tx=a.x/8,ty=a.z/8,halfWidth=a.width/2,halfDepth=a.depth/2}
end
-- Only a compact surrounding neighborhood is needed at domestic eye height.
M.radius=640
local masks={};local registered
function M.mask(map)
 local house=M.describe(map);if not house then return end
 local key=map.id..':'..house.kind;local found=masks[key];if found then return found end
 if not registered then
  require('src.render.Assets').register(function()
   for _,t in pairs(masks)do t:release()end;masks={}
  end);registered=true
 end
 local data=love.image.newImageData(512,4)
 for _,p in ipairs(house.panes)do
  local row=({north=0,south=1,west=2,east=3})[p.edge]
  for x=math.ceil(p.from),math.floor(p.upto)-1 do data:setPixel(x,row,1,1,1,1)end
 end
 local tex=love.graphics.newImage(data);data:release();tex:setFilter('nearest','nearest');masks[key]=tex
 return tex
end
return M
