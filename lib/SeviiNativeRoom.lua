-- Structural enclosure in ordinary voxel mode, sampled from the live
-- imported wall course. Optional Gen1 room art retains its own owner.
local V=...
local M={}
function M.profile(map)
 return V.require('KascSeviiScenery').nativeRoom(map)
end
function M.texture(map)
 return V.require('TerrainAtlas').forMap(map,nil)
end
function M.geometry(entry,profile,checkpoint)
 local map=entry.map;local source=V.require('KascSeviiScenery').profile(map)
 local paint=source and source.nativeWallSource
 if not(paint and profile and profile.nativeSourceWalls)then return end
 local texture=M.texture(map);if not texture then return end
 local H=profile.shellHeight;local tw,th=map.tileset.imageWidth,map.tileset.imageHeight
 local perRow=tw/8;local sourceH=paint.h*16
 local groups,wallVerts,wallIndices,ceilingVerts,ceilingIndices={},{},{},{},{}
 local quads=0
 local function uv(sx,sy,width,height)
  local tile=map:tileAt(paint.x*2+math.floor(sx/8),paint.y*2+math.floor(sy/8))
  local x=tile%perRow*8+sx%8;local y=math.floor(tile/perRow)*8+sy%8
  return (x+.05)/tw,(x+width-.05)/tw,(y+.05)/th,(y+height-.05)/th
 end
 local function push(group,c,u0,u1,v0,v1,shade)
  local v,i=group.vertices,group.indices;local base=#v
  for n=1,4 do v[#v+1]={c[n][1],c[n][2],c[n][3],(n==1 or n==4)and u0 or u1,n<=2 and v1 or v0,shade}end
  for _,n in ipairs{1,2,3,1,3,4}do i[#i+1]=base+n end
  quads=quads+1;if checkpoint then checkpoint()end
 end
 local function face(group,p,a,b,low,high,sy)
  local horizontal=p.edge=='north'or p.edge=='south'
  local at=p.at
  local c=horizontal and {{a,low,at},{b,low,at},{b,high,at},{a,high,at}}
    or {{at,low,a},{at,low,b},{at,high,b},{at,high,a}}
  local sx=a%16;local u0,u1,v0,v1=uv(sx,sy,b-a,1)
  push(group,c,u0,u1,v0,v1,(V.require('Voxel3D').FACE_SHADE[({north=5,south=6,west=1,east=2})[p.edge]]or .8))
 end
 for _,panel in ipairs(V.require('Gen1InteriorLayout').panelsFor(map,profile))do
  local tall={family='native_sevii_wall',vertices={},indices={},interiorPanel=panel,texture=texture}
  local low={family='native_sevii_wall',kind='cutaway_base',vertices={},indices={},interiorPanel=panel,texture=texture}
  groups[#groups+1]=tall;groups[#groups+1]=low
  local cuts={panel.from,panel.upto}
  for a=math.ceil(panel.from/8)*8,panel.upto-1,8 do cuts[#cuts+1]=a end
  for _,door in ipairs(panel.openings)do cuts[#cuts+1]=door.from;cuts[#cuts+1]=door.upto end
  table.sort(cuts)
  for i=1,#cuts-1 do local a,b=cuts[i],cuts[i+1]
   if b>a then
    local bottom=0
    for _,door in ipairs(panel.openings)do if (a+b)/2>=door.from and (a+b)/2<door.upto then bottom=math.max(bottom,door.height or 24)end end
    local y=bottom
    while y<H do
     local nextY,sy
     if y<8 then nextY=y+1;sy=sourceH-1-y
     elseif y>=H-8 then nextY=y+1;sy=H-1-y
     else nextY=H-8;sy=math.min(8,sourceH-9)end
     face(tall,panel,a,b,y,nextY,sy)
     if y<6 then face(low,panel,a,b,y,math.min(6,nextY),sy)end
     y=nextY
    end
   end
  end
 end
 -- Authored picture texels belong on the wall at their source X position.
 local bounds=V.require('Gen1RoomBounds').forMap(map)
 local picturePanel={edge='north',at=bounds.north,from=bounds.west,upto=bounds.east,openings={}}
 for _,art in ipairs(source.nativeWallPictures or{})do
  local group={family='native_sevii_picture',vertices={},indices={},interiorPanel=picturePanel,texture=texture}
  groups[#groups+1]=group
  local first=math.floor((art.cropTop or 0)/8);local last=art.h*2-1-math.floor((art.cropBottom or 0)/8)
  for yy=first,last do for xx=0,art.w*2-1 do
   local tile=map:tileAt(art.x*2+xx,art.y*2+yy)
   local u0,u1=(tile%perRow*8+.05)/tw,(tile%perRow*8+7.95)/tw
   local v0,v1=(math.floor(tile/perRow)*8+.05)/th,(math.floor(tile/perRow)*8+7.95)/th
   local x=art.x*16+xx*8;local y=H-8-(yy-first)*8;local z=bounds.north+.1
   push(group,{{x,y-8,z},{x+8,y-8,z},{x+8,y,z},{x,y,z}},u0,u1,v0,v1,1)
  end end
 end
 local ceiling={vertices=ceilingVerts,indices=ceilingIndices}
 local mask=V.require('Gen1RoomBounds').floorTiles(map)
 local u0,u1,v0,v1=uv(0,math.min(8,sourceH-9),1,1)
 for y=0,map.def.height*4-1 do for x=0,map.def.width*4-1 do
  if mask and mask[(y+64)*4096+x+64]or not mask and x*8>=bounds.west and x*8<bounds.east and y*8>=bounds.north and y*8<bounds.south then
   push(ceiling,{{x*8,H,y*8},{x*8+8,H,y*8},{x*8+8,H,y*8+8},{x*8,H,y*8+8}},u0,u1,v0,v1,.6)
  end
 end end
 return{map=map,ox=entry.ox,oy=entry.oy,class='interior',material='interior_shell',wallGroups=groups,
  wallVertices=wallVerts,wallIndices=wallIndices,groundVertices={},groundIndices={},
  foregroundVertices={},foregroundIndices={},ceilingVertices=ceilingVerts,ceilingIndices=ceilingIndices,
  ceilingTexture=texture,ceilingFamily='interior_ceiling',quads=quads,shellHeight=H,wallDistance=0}
end
return M
