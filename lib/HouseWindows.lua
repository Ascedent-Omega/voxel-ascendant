-- Domestic windows are derived from the actual exterior glass boxes and native
-- entrance warps. Unknown/custom footprints fail closed; no guessed city view.
local V=...
local M={}
local homes={home=true,traditional_home=true,coastal_home=true,daycare=true,center=true,mart=true,hotel=true,diner=true,workshop=true,museum=true,lab=true,casino=true,power_plant=true,ruined_mansion=true}
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
  for id,def in pairs(defs)do if (def.tileset=='OVERWORLD'or def.tileset=='FOREST'or def.tileset=='PLATEAU')and def.generation~=2 then
   for _,warp in ipairs(def.warps or{})do
    local old=links[warp.destMap]
    if not old or id<old.source then links[warp.destMap]={source=id,x=warp.x*16+8,z=warp.y*16+8}end
   end
  end end
 end
 local special,detail,level=V.require('Gen1WindowBindings').specialSource(map)
 if special then return special,detail,level end
 local first=V.require('Gen1WindowBindings').root(map.id)
 -- Upper storeys can also be reached by custom exterior shortcuts. Their
 -- facade still belongs to the building entered on the ground floor.
 local link=links[first]or links[map.id]
 return link and link.source,link,tonumber(map.id:match('_(%d+)F$'))or 1
end
local function perimeter(map,p)
 if p.windowBoundary then return true end
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
 for _,p in ipairs(buildings)do if p~=placement and not(p.kind==placement.kind and p.tx==(placement.hostTx or placement.tx)and p.ty==(placement.hostTy or placement.ty))then
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
 local enabled=V.require('Gen1PalletVillage').buildings:get()
 local tower=V.require('Gen1LavenderTower')
 local setting=tostring(enabled)..':'..tostring(tower.setting:get())
 local old=cache[map];if old and old.setting==setting then return old.value or nil end
 local function done(value)cache[map]={setting=setting,value=value or false};return value end
 if not enabled then return done()end
 local game=require('src.core.Game');local def=game.data.maps[source]
 local city=require('src.world.Map').new(def,game.data.tilesets[def.tileset])
 local P=V.require('VoxelItems');local buildings=V.require('VoxelFurniture').findBuildings(city)
 local placement,model,glazing,floorHeight,floorSpan=V.require('Gen1WindowBindings').facade(map,link,buildings,P)
 if not model or not glazing then return done()end
 local options=V.require('Gen1WindowBindings').options(map)
 local profile=V.require('Gen1InteriorPanoramas').profiles[map.id]
 local H=profile.shellHeight
 local bounds=V.require('Gen1RoomBounds').forMap(map)
 local x0,x1,z0,z1=bounds.west,bounds.east,bounds.north,bounds.south
 local lo,hi=options.crop and options.crop[1]or 0,options.crop and options.crop[2]or 1
 local out={source=source,kind=placement.kind,x=placement.tx*8+lo*model.frameW,z=placement.ty*8,
  hostTx=placement.hostTx or placement.tx,hostTy=placement.hostTy or placement.ty,width=model.frameW*(hi-lo),depth=model.depth,height=floorHeight,panes={},suppressTemplates=model.suppressTemplates}
 local bands={}
 local cabins=V.require('Gen1WindowBindings').cabins(map)
 out.rooms=cabins
 if cabins then
  for _,room in ipairs(cabins)do
   -- Three longitudinal cabin plots per side, within the glazed deckhouse.
   local start,span=48+room.column*72,72
   for _,b in ipairs(glazing.boxes)do
    if b[2]>=floorHeight and b[2]<floorHeight+floorSpan and b[6]<=2 and b[5]>=4
      and b[3]>(model.depth*.65)then
     local a,c=math.max(start,b[1]),math.min(start+span,b[1]+b[4])
     if c>a then bands[#bands+1]={edge=room.edge,at=room[room.edge],room=room,
      from=room.west+(a-start)/span*64,upto=room.west+(c-start)/span*64}end
    end
   end
  end
 end
 for _,b in ipairs(cabins and{}or glazing.boxes)do
  -- Glass doors, roof skylights and signage do not become room windows.
  local edge,from,upto
  if b[6]<=2 and b[5]>=4 then
   if b[3]>model.depth*.65 then edge='south'elseif b[3]<model.depth*(model.windowFaceMid and .5 or .15)then edge='north'end
   local lo,hi=options.crop and options.crop[1]or 0,options.crop and options.crop[2]or 1
   from,upto=x0+(b[1]/model.frameW-lo)/(hi-lo)*(x1-x0),x0+((b[1]+b[4])/model.frameW-lo)/(hi-lo)*(x1-x0)
  elseif b[4]<=2 and b[5]>=4 then
   edge=b[1]<model.frameW/2 and 'west'or'east'
   from,upto=z0+b[3]/model.depth*(z1-z0),z0+(b[3]+b[6])/model.depth*(z1-z0)
  end
  local correctFloor=b[2]>=floorHeight and b[2]<floorHeight+floorSpan
  if edge and (not options.edges or options.edges[edge])and correctFloor and exposed(edge,b,model,placement,buildings,P.models)then
   local door=false
   if edge=='south'and floor==1 and not link.special then
    local localDoor=link.x-placement.tx*8
    if b[1]<=localDoor+6 and b[1]+b[4]>=localDoor-6 then door=true end
   end
   if not door then bands[#bands+1]={edge=edge,from=from,upto=upto}end
  end
 end
 table.sort(bands,function(a,b)if a.edge~=b.edge then return a.edge<b.edge end
  if (a.at or 0)~=(b.at or 0)then return(a.at or 0)<(b.at or 0)end;return a.from<b.from end)
 for _,p in ipairs(bands)do
  local last=out.panes[#out.panes]
  if last and last.edge==p.edge and (last.at or bounds[last.edge])==(p.at or bounds[p.edge])and p.from<=last.upto+4 then last.upto=math.max(last.upto,p.upto)
  else
   local horizontal=p.edge=='north'or p.edge=='south'
   p.at=p.at or bounds[p.edge]
   p.bottom,p.top=12,H-10
   local r=p.room or bounds
   p.from,p.upto=math.max((horizontal and r.west or r.north)+5,p.from),math.min((horizontal and r.east or r.south)-5,p.upto)
   if p.upto-p.from>=3 then out.panes[#out.panes+1]=p end
  end
 end
 if #out.panes==0 or #out.panes>64 then return done()end
 -- Cut apertures at the very same native door intervals as the wall builder.
 local panes={}
 for _,p in ipairs(out.panes)do
  for _,wall in ipairs(V.require('Gen1InteriorLayout').panelsFor(map,profile))do
   if perimeter(map,wall)and wall.edge==p.edge and (not cabins or wall.at==p.at)then
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
function M.activeBounds(map,eye)
 local h=M.describe(map)
 if h and h.rooms and eye then for _,r in ipairs(h.rooms)do
  if eye[1]>=r.west and eye[1]<=r.east and eye[3]>=r.north and eye[3]<=r.south then return r end
 end end
 return V.require('Gen1RoomBounds').forMap(map)
end
function M.anchor(entry)
 local a=M.describe(entry.map);if not a then return end
 return{x=entry.w/2-(a.x+a.width/2),z=entry.h/2-(a.z+a.depth/2),y=-a.height,
  kind=a.kind,suppressTemplates=a.suppressTemplates,tx=a.hostTx or a.x/8,ty=a.hostTy or a.z/8,halfWidth=a.width/2,halfDepth=a.depth/2}
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
 local data=love.image.newImageData(1024,4)
 for _,p in ipairs(house.panes)do
  local row=({north=0,south=1,west=2,east=3})[p.edge]
  for x=math.ceil(p.from),math.floor(p.upto)-1 do data:setPixel(x,row,1,1,1,1)end
 end
 local tex=love.graphics.newImage(data);data:release();tex:setFilter('nearest','nearest');masks[key]=tex
 return tex
end
return M
