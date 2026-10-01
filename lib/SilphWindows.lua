-- A window onto the same Saffron geometry used by the rooftop skyline.
-- Native interiors are wider than their exterior plot: expand that plot only,
-- retaining the distances and sizes of the surrounding streets/buildings.
local V=...
local M={}
M.setting=V.require('ModSetting').new('realWindows','REAL WINDOWS',{true,false},{'ON','OFF'},true)
function M.enabled(map)return M.setting:get()and M.matches(map)end
local paneTextures={};local registered
function M.texture(frame)
 local key=frame and 'frame'or 'glass'
 if not paneTextures[key]then
  local d=love.image.newImageData(1,1);d:setPixel(0,0,frame and .55 or .68,frame and .65 or .85,frame and .68 or .92,1)
  paneTextures[key]=love.graphics.newImage(d);d:release()
  if not registered then require('src.render.Assets').register(function()
   for _,t in pairs(paneTextures)do t:release()end;paneTextures={}
  end);registered=true end
 end
 return paneTextures[key]
end
function M.drawPane(G,rim,matrix)
 local g=love.graphics;local blend,alpha=g.getBlendMode();local mode,write=g.getDepthMode()
 g.setBlendMode('alpha','alphamultiply');g.setDepthMode('lequal',false)
 g.setColor(1,1,1,.075);G.flatten({.68,.85,.92},1)
 G.draw(rim.mesh,rim.texture,matrix)
 G.flatten(nil);g.setColor(1,1,1,1);g.setDepthMode(mode,write);g.setBlendMode(blend,alpha)
end
function M.floor(map)
 local n=map and tonumber((map.id or ''):match('^SILPH_CO_(%d+)F$'))
 if not n or n<1 or n>11 then return end
 local d=map.def or{};local w=n==10 and 8 or n==11 and 9 or n>=6 and 13 or 15
 if d.generation~=2 and d.width==w and d.height==9 and d.tileset==(n==11 and 'INTERIOR'or 'FACILITY')then return n end
end
function M.matches(map)return M.floor(map)~=nil or V.require('SilphElevator').matches(map)or V.require('HouseWindows').describe(map)~=nil end
function M.source(map)return V.require('HouseWindows').source(map)or 'SAFFRON_CITY'end
function M.apertures(map,H)
 local house=V.require('HouseWindows').describe(map)
 if house then return house.panes end
 local b=V.require('Gen1RoomBounds').forMap(map);local out={}
 for _,p in ipairs{{'north',b.west,b.east,b.north},{'south',b.west,b.east,b.south},{'west',b.north,b.south,b.west},{'east',b.north,b.south,b.east}}do
  if not V.require('SilphElevator').matches(map)or p[1]~='south'then
   local inset=M.floor(map) and 8 or 0
   out[#out+1]={edge=p[1],from=p[2]+inset,upto=p[3]-inset,at=p[4],bottom=10,top=H-5}
  end
 end
 -- Native exit/stair alcoves continue behind the inset facade. They are
 -- opaque architecture, not windows: exterior ground must not fill a sunken
 -- stairwell merely because it lies behind the nominal glass plane.
 for _,warp in ipairs(map.def.warps or{})do
  local x,z=warp.x*16,warp.y*16
  local edge=z<b.north and 'north'or z+16>b.south and 'south'
   or x<b.west and 'west'or x+16>b.east and 'east'
  if edge then
   local shaft=V.require('Gen1Stairs').perimeterShaft(map,warp)
   local from=shaft and shaft.from or (edge=='north'or edge=='south')and x or z
   local upto=shaft and shaft.upto or from+16
   local nextOut={}
   for _,p in ipairs(out)do
    if p.edge~=edge or from>=p.upto or upto<=p.from then nextOut[#nextOut+1]=p
    else
     for _,range in ipairs{{p.from,math.min(p.upto,from)},{math.max(p.from,upto),p.upto}}do
      if range[2]>range[1]then local q={};for k,v in pairs(p)do q[k]=v end;q.from,q.upto=range[1],range[2];nextOut[#nextOut+1]=q end
     end
    end
   end
   out=nextOut
  end
 end
 return out
end
local masks=setmetatable({},{__mode='k'});local masksRegistered
function M.mask(map,H)
 local b=V.require('Gen1RoomBounds').forMap(map)
 local old=masks[map]
 local stamp={b.west,b.north,b.east,b.south}
 for _,w in ipairs(map.def.warps or{})do stamp[#stamp+1]=w.x;stamp[#stamp+1]=w.y end
 local key=table.concat(stamp,':')
 if old and old.key==key then return old.texture end
 if old then old.texture:release()end
 local data=love.image.newImageData(1024,4)
 local row={north=0,south=1,west=2,east=3}
 for _,p in ipairs(M.apertures(map,H))do
  for x=math.max(0,math.ceil(p.from)),math.min(1023,math.ceil(p.upto)-1)do data:setPixel(x,row[p.edge],1,1,1,1)end
 end
 local texture=love.graphics.newImage(data);data:release();texture:setFilter('nearest','nearest')
 masks[map]={key=key,texture=texture}
 if not masksRegistered then
  require('src.render.Assets').register(function()
   for _,entry in pairs(masks)do entry.texture:release()end;masks=setmetatable({},{__mode='k'})
  end);masksRegistered=true
 end
 return texture
end
function M.panelApertures(map,p,H)
 local out={}
 for _,a in ipairs(M.apertures(map,H))do if a.edge==p.edge and a.at==p.at and a.from<p.upto and a.upto>p.from then out[#out+1]=a end end
 return out
end
function M.height(map)
 if V.require('SilphElevator').matches(map)then return 0 end
 local n=M.floor(map);return n and (n==1 and 0 or 32+(n-2)*24)
end
function M.anchor(entry,buildings,models)
 local house=V.require("HouseWindows").anchor(entry);if house then return house end
 for _,p in ipairs(buildings)do local a=models[p.kind]
  if a and a.template=='silph_co'then
   return {x=entry.w/2-(p.tx*8+a.frameW/2),z=entry.h/2-(p.ty*8+a.depth/2),y=-M.height(entry.map),kind=p.kind}
  end
 end
end
function M.perimeter(map,p)
 if not M.enabled(map)then return false end
 local d=map.def
 if V.require("HouseWindows").describe(map)then return V.require("HouseWindows").perimeter(map,p)end
 if V.require('SilphElevator').matches(map)and p.edge=='south'then return false end
 local b=V.require('Gen1RoomBounds').forMap(map)
 return not p.wallThickness and not p.endcap and not p.niche and not p.column and p.at==b[p.edge]
end
-- Keep the glass clear: structural mullions and sparse glints establish its
-- surface, without a flat opaque blue layer concealing the real city.
function M.panel(quad,group,glass,frame,p,a,b,bottom,H,inset,map)
 local house=V.require("HouseWindows").describe(map)
 local pane
 for _,v in ipairs(M.panelApertures(map,p,H))do if (a+b)/2>=v.from and (a+b)/2<v.upto then pane=v;break end end
 if not pane or bottom>=pane.top then quad(group,a,b,bottom,H,a/128,b/128,1-bottom/H,0,inset);return end
 local sill,head=math.max(bottom,pane.bottom),pane.top
 if bottom<sill then quad(group,a,b,bottom,sill,a/128,b/128,1-bottom/H,1-sill/H,inset)end
 quad(glass,a,b,sill,head,0,1,1,0,inset*.7)
 if house then
  quad(frame,a,b,sill,sill+.7,0,1,.15,.15,inset)
  quad(frame,a,b,head-.7,head,0,1,.15,.15,inset)
 end
 quad(group,a,b,head,H,a/128,b/128,1-head/H,0,inset)
 if math.abs(a-pane.from)<.01 then quad(frame,a,math.min(a+1,b),sill,head,0,0,.15,.15,inset)end
 if math.abs(b-pane.upto)<.01 then quad(frame,math.max(a,b-1),b,sill,head,0,0,.15,.15,inset)end
end

-- The baker and live fallback share exactly the same floor/plot transform.
function M.geometry(entry,defs,emit,yieldStep)
 local world=V.require('RooftopWorld')
 local house=V.require('HouseWindows').describe(entry.map)
 local halfW,halfD=house and house.width/2 or 64,house and house.depth/2 or 96
 local function axis(v,centre,half,target)
  local t=v-centre
  if t < -half then return t+half end
  if t > half then return target+t-half end
  return (t+half)*target/(half*2)
 end
 local function transformed(x,y,z,w,h,d,c,lit,foliage)
  local x0,x1=axis(x,entry.w/2,halfW,entry.w),axis(x+w,entry.w/2,halfW,entry.w)
  local z0,z1=axis(z,entry.h/2,halfD,entry.h),axis(z+d,entry.h/2,halfD,entry.h)
  emit(x0,y,z0,x1-x0,h,z1-z0,c,lit,foliage)
 end
 world.geometry(entry,defs,transformed,yieldStep);world.mountains(entry,defs,transformed,yieldStep)
end
-- Landmarks are independent of the compact house neighborhood and the image
-- cache. Resolve the same source plot even when geometry() was skipped on a hit.
function M.volcanoPosition(entry,defs)
 local Volcano=V.require('CinnabarVolcano')
 if not Volcano.active()then return end
 local game=require('src.core.Game');defs=defs or game.data.maps
 local sourceId=M.source(entry.map);local source=defs[sourceId]
 local x,z=Volcano.position(sourceId,defs)
 if not x or not source then return end
 local city=require('src.world.Map').new(source,game.data.tilesets[source.tileset])
 local a=M.anchor(entry,V.require('VoxelFurniture').findBuildings(city),V.require('VoxelItems').models)
 if not a then return end
 local house=V.require('HouseWindows').describe(entry.map)
 local function axis(v,c,h,target)
  local t=v-c
  if t< -h then return t+h elseif t>h then return target+t-h end
  return(t+h)*target/(h*2)
 end
 return axis(x+a.x,entry.w/2,house and house.width/2 or 64,entry.w),
  a.y,axis(z+a.z,entry.h/2,house and house.depth/2 or 96,entry.h)
end
function M.build(entry,yieldStep,defs,ownedMeshes)
 local world=V.require('RooftopWorld');local G=V.require('Voxel3D');local P=V.require('VoxelItems')
 local out,batches=ownedMeshes or {},{}
 local clock=love and love.timer and love.timer.getTime
 local started=clock and clock()or 0
 local work=0
 local function checkpoint()
  work=work+1
  if yieldStep and work%8==0 and (work>=64 or clock and clock()-started>=.00075)then
   yieldStep();work=0;started=clock and clock()or 0
  end
 end
 local house=V.require("HouseWindows").describe(entry.map)
 if house then V.require("HouseWindows").mask(entry.map)end
 local function flush(batch)
  local vertices,indices=batch.vertices,batch.indices
  if #vertices==0 then return end
  local bounds={math.huge,math.huge,math.huge,-math.huge,-math.huge,-math.huge}
  for i,v in ipairs(vertices)do
   for axis=1,3 do bounds[axis]=math.min(bounds[axis],v[axis]);bounds[axis+3]=math.max(bounds[axis+3],v[axis])end
   if i%64==0 then checkpoint()end
  end
  local mesh=assert(V.require('SceneryMeshUpload').newMesh(vertices,indices,yieldStep),'Silph city mesh')
  out[#out+1]={mesh=mesh,texture=world.texture(),kind='wall',class='silph_exterior',windowLight=batch.lit,seasonalFoliage=batch.foliage,bounds=bounds,ox=entry.ox or 0,oy=entry.oy or 0,castsShadow=false}
  batch.vertices,batch.indices={},{};if yieldStep then yieldStep()end
 end
 local function emit(x0,y,z0,w,h,d,c,lit,foliage)
  checkpoint()
  local x1,z1=x0+w,z0+d
  -- Keep nearby boxes together so the window cone can reject entire city
  -- blocks before issuing draw calls, rather than retaining long map rows.
  local key=(lit and 'windows'or foliage and 'foliage'or 'world')..':'
   ..math.floor(x0/512)..':'..math.floor(z0/512)
  local batch=batches[key]
  if not batch then batch={vertices={},indices={},lit=lit==true,foliage=foliage==true};batches[key]=batch end
  local vertices,indices=batch.vertices,batch.indices
  -- Lobby floor belongs to the room; exterior terrain underneath it is safe.
  local u=(c-.5)/#P.palette
  for face,corners in ipairs(G.FACE_CORNERS)do
   local base=#vertices
   for _,v in ipairs(corners)do vertices[#vertices+1]={x0+v[1]*(x1-x0),y+v[2]*h,z0+v[3]*(z1-z0),u,.5,({.82,.82,1,.65,.85,.85})[face]}end
   for _,i in ipairs{1,2,3,1,3,4}do indices[#indices+1]=base+i end
  end
  if #vertices>=12288 then flush(batch)end
 end
 local near,baked=V.require('WindowImageCache').load(entry,defs,yieldStep)
 if near then
  for _,b in ipairs(near)do emit(unpack(b))end
 else M.geometry(entry,defs,emit,yieldStep)end
 local vx,vy,vz=M.volcanoPosition(entry,defs)
 if vx then
  local first=#out+1
  V.require('CinnabarVolcano').meshes(vx,vz,vy,yieldStep,out)
  for i=first,#out do local rim=out[i]
   rim.class='silph_exterior';rim.windowLandmark='cinnabar_volcano'
   rim.ox,rim.oy=entry.ox or 0,entry.oy or 0
  end
 end
 local keys={};for key in pairs(batches)do keys[#keys+1]=key end;table.sort(keys)
 for _,key in ipairs(keys)do flush(batches[key])end
 for _,rim in ipairs(baked or{})do out[#out+1]=rim end
 if V.require('SilphElevator').matches(entry.map)then
  local vertices,indices=P.geometry('silph_glass_cabin')
  out[#out+1]={mesh=assert(G.newMesh(vertices,indices)),texture=world.texture(),kind='wall',class='silph_cabin',
   interiorPanel={edge='north',at=0,from=0,upto=64},ox=entry.ox or 0,oy=entry.oy or 0,castsShadow=false}
 end
 return out
end
return M
