-- A source-map LOD view from Celadon's real building plot. All positions use
-- WorldPlacement; native map data, collisions and foreground caches stay owned
-- by the engine. No independently authored sky or randomly placed city blocks.
local V=...
local M={}
local tex,registered
function M.texture()
 if not registered then require('src.render.Assets').register(function()if tex then tex:release();tex=nil end end);registered=true end
 if not tex then
  local colors=V.require('VoxelItems').palette;local data=love.image.newImageData(#colors,1)
  for i,c in ipairs(colors)do data:setPixel(i-1,0,c[1]/255,c[2]/255,c[3]/255,1)end
  tex=love.graphics.newImage(data);data:release();tex:setFilter('nearest','nearest')
 end
 return tex
end
function M.anchor(entry,buildings,models)
 local silph=V.require('SilphWindows')
 if silph.matches(entry.map)then return silph.anchor(entry,buildings,models)end
 local roofs=V.require('Gen1Rooftops')
 if roofs.gate(entry.map)then
  local game=require('src.core.Game');local source=game.data.maps[roofs.source(entry.map)]
  local firstFloor=entry.map.id:gsub('_2F$','_1F')
  local best,distance
  for _,warp in ipairs(source and source.warps or{})do if warp.destMap==firstFloor then
   local x,z=warp.x*16+8,warp.y*16+8
   for _,p in ipairs(buildings)do local a=models[p.kind]
    if a then
     local dx=math.max(p.tx*8-x,0,x-p.tx*8-a.frameW)
     local dz=math.max(p.ty*8-z,0,z-p.ty*8-a.depth)
     local d=dx*dx+dz*dz
     if d<=24*24 and(not distance or d<distance)then best,distance=p,d end
    end
   end
  end end
  if best then
   local a=models[best.kind];local b=V.require('Gen1RoomBounds').forMap(entry.map)
   return {x=(b.west+b.east)/2-(best.tx*8+a.frameW/2),
    z=(b.north+b.south)/2-(best.ty*8+a.depth/2),y=a.offsetY or -56,
    kind=best.kind,tx=best.tx,ty=best.ty,
    -- The native Route 12 viewing room faces the southern fishing piers.
    -- Its north-facing optical fixtures therefore reverse the exterior axes.
    -- Rotate the whole source world, not just the telescope subject.
    halfTurn=entry.map.id=='ROUTE_12_GATE_2F',pivotX=(b.west+b.east)/2,pivotZ=(b.north+b.south)/2}
  end
  return nil
 end
 local wanted=entry.map.id=='CELADON_MART_ROOF'and 'celadon_mart'or 'celadon_mansion'
 for _,p in ipairs(buildings)do
  local a=models[p.kind]
  if a and a.template==wanted then
   -- Native interior dimensions differ from the exterior plot. Centre the
   -- terrace on its building without stretching the rest of the world.
   return {x=entry.w/2-(p.tx*8+a.frameW/2),z=entry.h/2-(p.ty*8+a.depth/2),
    y=a.offsetY or -100,kind=p.kind}
  end
 end
end
-- Shared placement for scenery, landmarks and render-only scope subjects.
function M.point(anchor,x,y,z)
 x,y,z=x+anchor.x,y+anchor.y,z+anchor.z
 if anchor.halfTurn then x,z=2*anchor.pivotX-x,2*anchor.pivotZ-z end
 return x,y,z
end
function M.boxOrigin(anchor,x,y,z,w,d)
 x,y,z=M.point(anchor,x,y,z)
 if anchor.halfTurn then x,z=x-w,z-d end
 return x,y,z
end
function M.source(map)
 return V.require('SilphWindows').matches(map)and V.require('SilphWindows').source(map)or V.require('Gen1Rooftops').source(map)
end
function M.radius(entry)
 -- Window images must contain the horizon, not end at the live near-ring.
 -- Only their small decoded images survive into play when a cache is present.
 if V.require('SilphElevator').matches(entry.map)then return 3200 end
 return V.require('SilphWindows').matches(entry.map)and 6144 or 3200
end
function M.maps(entry,defs)
 local Place=V.require('WorldPlacement');local origin=Place.position(M.source(entry.map),defs)
 if not origin then return {} end
 local out={}
 local radius=M.radius(entry)
 for id,d in pairs(defs)do
  if d.generation~=2 and (d.tileset=='OVERWORLD'or d.tileset=='FOREST'or d.tileset=='PLATEAU')then
   local p=Place.position(id,defs)
   if p and p.anchor==origin.anchor then
    local x,z=p.x-origin.x,p.y-origin.y
    local dx=math.max(0,x-entry.w,x*-1-d.width*32)
    local dz=math.max(0,z-entry.h,z*-1-d.height*32)
    if dx*dx+dz*dz<radius*radius then out[#out+1]={id=id,def=d,x=x,z=z}end
   end
  end
 end
 table.sort(out,function(a,b)return a.id<b.id end)
 return out
end
function M.groundColor(material,C)
 if material==-162 or material==-163 or material==-165 or material==-167 or material==-173 then return C.stone end
 if material==-183 then return C.stone end
 if material==-160 then return 25 end
 if material==-130 or material==-171 then return C.oak end
 return C.leaf
end
-- Distant mountains use the same native rock footprint, height field and
-- strata as the walkable maps. Only the sampling density is reduced; no
-- extra peaks are invented north of the routes or scaled above the skyline.
function M.mountains(entry,defs,emit,yieldStep)
 M.lastMountains=nil
 if not M.source(entry.map)then return end
 local game=require('src.core.Game');defs=defs or game.data.maps
 local sourceId=M.source(entry.map)
 local source=defs[sourceId];if not source then return end
 local Map=require('src.world.Map');local F=V.require('VoxelFurniture')
 local P=V.require('VoxelItems');local Mountains=V.require('Gen1MountainExteriors')
 local city=Map.new(source,game.data.tilesets[source.tileset])
 local anchor=M.anchor(entry,F.findBuildings(city),P.models)
 if not anchor then return end
 M.lastMountains={maps={},boxes=0}
 local Volcano=V.require('CinnabarVolcano')
 local vx,vz=Volcano.position(sourceId,defs)
 if Volcano.active()and vx then
  local x,y,z=M.point(anchor,vx,0,vz)
  M.lastMountains.volcano={x=x,z=z,y=y,height=Volcano.HEIGHT}
 end
 for _,place in ipairs(M.maps(entry,defs))do
  if Mountains.supports({id=place.id,def=place.def})then
   local map=Map.new(place.def,game.data.tilesets[place.def.tileset])
   local occupied={}
   for _,p in ipairs(F.findBuildings(map))do
    for y=p.ty,p.ty+p.h-1 do for x=p.tx,p.tx+p.w-1 do occupied[y*4096+x]=true end end
   end
   local scratch={models={},decorColors=P.decorColors}
   local props=Mountains.find(scratch,map,function(x,y)return occupied[y*4096+x]end,
    {coarse=true,yieldStep=yieldStep})
   if #props>0 then M.lastMountains.maps[#M.lastMountains.maps+1]=place.id end
   for _,p in ipairs(props)do
    local model=scratch.models[p.kind]
    for _,box in ipairs(model.boxes)do
     local x,y,z=M.boxOrigin(anchor,place.x+p.tx*8+box[1],box[2],place.z+p.ty*8+box[3],box[4],box[6])
     emit(x,y,z,box[4],box[5],box[6],box[7],false)
     M.lastMountains.boxes=M.lastMountains.boxes+1
    end
    scratch.models[p.kind]=nil
    if yieldStep then yieldStep()end
   end
  end
 end
end

function M.geometry(entry,defs,emit,yieldStep)
 if not M.source(entry.map)then return end
 local game=require('src.core.Game');defs=defs or game.data.maps
 local Map=require('src.world.Map');local P=V.require('VoxelItems');local F=V.require('VoxelFurniture')
 local sourceId=M.source(entry.map)
 local source=defs[sourceId];if not source then return end
 local city=Map.new(source,game.data.tilesets[source.tileset])
 local buildings=F.findBuildings(city);local anchor=M.anchor(entry,buildings,P.models)
 if not anchor then return end
 local C=P.decorColors;local Shapes=V.require('TileShape')
 local detail=V.require('Gen1OutdoorScenery')
 M.last={maps=0,buildings=0,boxes=0,landmarks={}}
 local function box(x,y,z,w,h,d,c,lit,foliage)
  M.last.boxes=M.last.boxes+1
  local px,py,pz=M.boxOrigin(anchor,x,y,z,w,d)
  emit(px,py,pz,w,h,d,c,lit,foliage==true)
 end
 local maps=M.maps(entry,defs)
 -- Source maps describe playable corridors, not the land between them.
 -- Fill only unmapped space with a distant forest shoulder; source roads,
 -- shores and building plots always win. A deep base closes downward views.
 local radius=M.radius(entry)-192
 box(-radius-192,-1400,-radius-192,radius*2+1024,1392,radius*2+1024,C.leaf or 12)
 local Volcano=V.require('CinnabarVolcano')
 local vx,vz=Volcano.position(sourceId,defs)
 local coast=Volcano.active()and vx and {vx-1440,vz-400,vx,vz+700}
 -- The added island sits west of the native Cinnabar map. Extend its sea
 -- apron too, otherwise the generic unmapped-land filler grows below it.
 if coast then box(coast[1],-4,coast[2],coast[3]-coast[1],4,coast[4]-coast[2],8)end
 local forestStep=V.require('SilphWindows').matches(entry.map)and 128 or 64
 for z=-radius,radius,forestStep do for x=-radius,radius,forestStep do
  if x*x+z*z<radius*radius then
   local occupied=coast and x<coast[3]and x+forestStep>coast[1]and z<coast[4]and z+forestStep>coast[2]
   for _,m in ipairs(maps)do
    if x<m.x+m.def.width*32 and x+forestStep>m.x and z<m.z+m.def.height*32 and z+forestStep>m.z then occupied=true;break end
   end
   if not occupied then
    local height=24+((x/64*13+z/64*7)%4)*5
    box(x,0,z,forestStep,8,forestStep,C.leafDark)
    if forestStep==128 then
     -- Distant canopy clusters retain the forest silhouette without building
     -- thousands of individual trees for a small indoor window.
     box(x+2,7,z+2,124,height-7,124,C.leafDark,false,true)
     box(x+7,height,z+7,114,6,114,C.leaf,false,true)
    else
    for n=0,3 do
     local tx=x+(n%2)*32;local tz=z+math.floor(n/2)*32
     local top=height+(n*7+x/64)%11
     box(tx+5,7,tz+5,22,top-7,22,C.leafDark,false,true)
     box(tx+2,top-15,tz+3,28,12,26,C.leaf,false,true)
     box(tx+8,top-3,tz+8,16,7,16,C.leafLight,false,true)
    end
    end
   end
  end
 end;if yieldStep then yieldStep()end end
 for _,e in ipairs(maps)do
  local map=e.id==sourceId and city or Map.new(e.def,game.data.tilesets[e.def.tileset])
  local props=e.id==sourceId and buildings or F.findBuildings(map)
  local occupied={};local shapes=Shapes.forMap(map)
  for _,p in ipairs(props)do local a=P.models[p.kind]
   if a then
    for y=p.ty,p.ty+p.h-1 do for x=p.tx,p.tx+p.w-1 do occupied[y*4096+x]=true end end
    if not(anchor.suppressTemplates and anchor.suppressTemplates[a.template])and(e.id~=sourceId or p.kind~=anchor.kind or (anchor.tx and (p.tx~=anchor.tx or p.ty~=anchor.ty)))then
     M.last.buildings=M.last.buildings+1
     if a.template=='silph_co'or a.template=='pokemon_tower'or a.template=='pokemon_tower_top'then
      local x,_,z=M.point(anchor,e.x+p.tx*8,0,e.z+p.ty*8)
      M.last.landmarks[#M.last.landmarks+1]={map=e.id,template=a.template,x=x,z=z}
     end
     -- Use the actual facade/roof boxes and original colours. Their texture
     -- atlas is tiny; no foreground voxel meshes or sprite caches are loaded.
     local kinds={p.kind,a.glassKind}
     for _,door in ipairs(a.slidingDoors or{})do kinds[#kinds+1]=door.kind end
     for _,kind in ipairs(kinds)do
      local m=P.models[kind]
      if m then for _,b in ipairs(m.boxes)do
       box(e.x+p.tx*8+b[1],b[2],e.z+p.ty*8+b[3],b[4],b[5],b[6],b[7],kind==a.glassKind)
      end end
     end
    end
   end
  end
  -- The quay and truck are native harbor props outside ordinary facades.
  if e.id=='VERMILION_CITY'and V.require('Gen1Harbor').kind(map)then
   V.require('Gen1Harbor').models(P)
   for _,p in ipairs{{'ss_anne_pier',384,0,584},{'ss_anne_truck',408,3,598}}do
    for _,b in ipairs(P.models[p[1]].boxes)do box(e.x+p[2]+b[1],p[3]+b[2],e.z+p[4]+b[3],b[4],b[5],b[6],b[7],b[7]==8)end
   end
  end
  -- Coarse terrain follows actual native cells. Merge identical horizontal
  -- runs; a road/shore/forest keeps its position across every map boundary.
  local distance=math.max(math.abs(e.x),math.abs(e.z))
  local step=e.id==sourceId and 2 or distance>1600 and 8 or 4
  for ty=0,e.def.height*4-1,step do
   local run
   local function flush()
    if not run then return end
    local x,z=e.x+run.x*8,e.z+ty*8;local w=run.w*8;local d=step*8
    box(x,-4,z,w,4,d,run.color)
    if run.tree then
     box(x+2,0,z+2,math.max(2,w-4),run.tree,d-4,C.leafDark,false,true)
     box(x+4,run.tree,z+4,math.max(2,w-8),5,d-8,C.leafLight,false,true)
    end
   end
   for tx=0,e.def.width*4-1,step do
    local t=map:tileAt(tx,ty);local s=Shapes.at(map,shapes,t,tx,ty)
    local cls=s and s.class;local tree=not occupied[ty*4096+tx] and (cls=='canopy'or cls=='tree'or cls=='cylinder')and 22 or nil
    local color=C.leaf or 12
    if map:isWaterCell(math.floor(tx/2),math.floor(ty/2))then color=8
    elseif occupied[ty*4096+tx]then color=C.stone or 14
    elseif tree or cls=='grass'or cls=='flower'then color=C.leaf or 12
    elseif map:isWalkableCell(math.floor(tx/2),math.floor(ty/2))then
     local material=detail.material(map,true,t,tx,ty)
     color=M.groundColor(material,C)
    end
    if run and run.color==color and run.tree==tree then run.w=run.w+step
    else flush();run={x=tx,w=step,color=color,tree=tree}end
   end
   flush()
   if yieldStep and ty%16==0 then yieldStep()end
  end
  M.last.maps=M.last.maps+1
  if yieldStep then yieldStep()end
 end
end
return M
