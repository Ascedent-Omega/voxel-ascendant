-- Presentation for KASC's locally imported Sevii world. The source recipes
-- contain no artwork and are admitted only by their exact atlas contract.
-- Never register maps, change collision/warps or write a player's save.
local V=...
local M={}
local recipes
local atlasCache=setmetatable({},{__mode='k'})
local function data()if not recipes then recipes=V.data('sevii_voxel_profiles')or{}end;return recipes end
local code={WALL='X',FLOOR='G',WATER='W',GRASS='g'}
function M.profile(map)
 local d=map and map.def;local ts=map and map.tileset
 if not(d and ts and d.kaOwner=='kasc.sevii-expedition/v1'and d.generation~=2)then return nil end
 local id=map.id or d.id;local p=data()[id]
 if not(p and d.tileset=='KA_SEVII_TILES_'..id:sub(10)and ts.id==d.tileset
  and d.kaSeviiSource==p.source and d.width==p.size[1]and d.height==p.size[2]
  and d.outdoor==p.outdoor and ts.trueColor==true
  and ts.imageWidth==p.atlas[1]and ts.imageHeight==p.atlas[2]
  and type(d.kaSeviiSourceOrigin)=='table'and d.kaSeviiSourceOrigin[1]==p.origin[1]
  and d.kaSeviiSourceOrigin[2]==p.origin[2]
  and type(ts.blocks)=='table'and #ts.blocks==#p.blocks
  and type(ts.sourceCellCollision)=='table'and #ts.sourceCellCollision==#p.blocks)then return nil end
 local checked=atlasCache[ts]
 if checked==false then return nil end
 if not checked then
  local tags={}
  for b,row in ipairs(ts.blocks)do
   local collisions=ts.sourceCellCollision[b];local label=p.blocks[b]
   if type(collisions)~='table'or #collisions~=4 or #row~=16 then atlasCache[ts]=false;return nil end
   local signature=''
   for q=1,4 do signature=signature..(code[collisions[q]]or'?')end
   if signature~=p.collision[b]then atlasCache[ts]=false;return nil end
   for y=0,3 do for x=0,3 do
    local expected=math.floor((b-1)/16)*256+(b-1)%16*4+y*64+x
    if row[y*4+x+1]~=expected then atlasCache[ts]=false;return nil end
    tags[expected]=label:sub(math.floor(y/2)*2+math.floor(x/2)+1,math.floor(y/2)*2+math.floor(x/2)+1)
   end end
  end
  checked={profile=p,tags=tags};atlasCache[ts]=checked
 end
 if checked.profile~=p then return nil end
 return p,checked.tags
end
function M.warps(map)
 local p=M.profile(map)
 return p and map.def.kaSeviiWarps or map.def.warps or{}
end
function M.portalAt(map,x,y)
 if map.warpAtCell then local warp=map:warpAtCell(x,y);if warp then return warp end end
 for _,warp in ipairs(M.warps(map))do if warp.x==x and warp.y==y then return warp end end
end
function M.token(map,tx,ty,tile)
 local p,tags=M.profile(map);if not p then return nil end
 if tile~=nil then return tags[tile]end
 if not(tx and ty)or tx<0 or ty<0 or tx>=map.def.width*4 or ty>=map.def.height*4 then return nil end
 return tags[map:tileAt(tx,ty)]
end
local cellRoles=setmetatable({},{__mode='k'})
local function objectRole(p,tx,ty)
 if not(tx and ty)then return nil end
 local cells=cellRoles[p]
 if not cells then cells={};cellRoles[p]=cells
  for _,o in ipairs(p.props)do if o.tag=='Z'or o.tag=='d'then
   for y=math.max(0,o.y),math.min(p.size[2]*2,o.y+o.h)-1 do
    for x=math.max(0,o.x),math.min(p.size[1]*2,o.x+o.w)-1 do cells[y*p.size[1]*2+x]=o.tag end
   end
  end end
 end
 return cells[math.floor(ty/2)*p.size[1]*2+math.floor(tx/2)]
end
local shapes={
 G={class='ground',h=0,art='flat',flat=true,authored=true},
 Z={class='water',h=-2,art='flat',flat=true,authored=true},
 W={class='water',h=-2,art='flat',flat=true,authored=true},
 g={class='grass',h=0,art='grass',flat=true,authored=true},
 C={class='wall',h=16,art='upright',flat=false,authored=true},
 X={class='wall',h=16,art='upright',flat=false,authored=true},
 B={class='roof',h=28,art='top',flat=false,authored=true},
 L={class='ledge',h=6,art='top',flat=false,authored=true},
 F={class='post',h=10,art='post',flat=false,authored=true},
 S={class='signpost',h=16,art='billboard',flat=false,authored=true},
 V={class='void',h=0,art='flat',flat=true,authored=true},
}
function M.shape(map,tile,tx,ty)
 local p=M.profile(map);if not p then return nil end
 if tx<0 or ty<0 or tx>=map.def.width*4 or ty>=map.def.height*4 then return shapes.V end
 local cx,cy=math.floor(tx/2),math.floor(ty/2)
 local token=objectRole(p,tx,ty)or M.token(map,tx,ty,tile)
 if map:isWaterCell(cx,cy)then return shapes.W end
 if M.portalAt(map,cx,cy)then return shapes.G end
 if p.source=='OneIsland_KindleRoad_EmberSpa'then
  if token=='w'then return shapes.W end
  if token=='v'then return shapes.G end
 end
 if token=='g'then return shapes.g end
 if token=='L'then return shapes.L end
 if map:isWalkableCell(cx,cy)or token=='d'then return shapes.G end
 return shapes[token]or shapes.C
end
function M.material(map,tile,tx,ty)
 local p=M.profile(map);if not p then return nil end
 -- Interior palettes and floor patterns are part of each imported FireRed
 -- room. A generic Kanto floor finish erases those authored distinctions.
 -- The reviewed One Island apartment keeps its established voxel finish.
 if p.kind=='room'and p.source~='OneIsland_House1'then return nil end
 local role=objectRole(p,tx,ty);local tag=role=='d'and'K'or role or M.token(map,tx,ty,tile)
 -- Puzzle markings, ice cracks, arrows, sealed exits and door thresholds
 -- retain their source artwork. Only known ordinary flooring is repainted.
 if tag=='G' or tag=='g' or tag=='T' or tag=='B' or tag=='f' then
  if p.exterior then return V.require('SeviiLandscape').groundMaterial(p,tag)end
  if p.kind=='cave'then return p.cave=='seafoam'and -227 or p.cave=='diglett'and -223 or p.cave=='mt_moon'and -226 or -224 end
  return -128-({center=4,mart=5,coastal_home=3,home=2,traditional_home=2,hotel=2,daycare=2,rocket=6,corporate=6,gate=7,casino=8})[p.theme]
 elseif tag=='D'then
  local region=p.exterior and V.require('SeviiLandscape').region(p)
  return region=='volcano'and -177 or region=='canyon'and -171 or -160
 elseif tag=='Z'then return -174
 elseif tag=='L'or tag=='C'then
  if p.exterior then
   local landscape=V.require('SeviiLandscape')
   if landscape.region(p)=='tower_roof'then return nil end
   if tag=='C'and landscape.region(p)=='canyon'then return -171 end
   return landscape.stoneMaterial(p)
  end
 elseif tag=='K'then return -130 end
end
function M.caveMaterial(map,class,tile,face)
 local p=M.profile(map);if not(p and p.kind=='cave')then return nil end
 local n=({seafoam=7,rock_tunnel=2,diglett=3,victory_road=4,cerulean=5,mt_moon=6})[p.cave]
 local token=M.token(map,nil,nil,tile)
 if class=='water'and(token=='W'or token=='w')then return -174 end
 if class=='wall'and token=='C'then return -(face=='side'and 200 or 210)-n end
 if face=='side'and token and token:match('^[GgCD]$')then return -200-n end
 if face~='side'then return M.material(map,tile)end
end
local courseFields=setmetatable({},{__mode='k'})
function M.elevation(map)
 local p=M.profile(map);if not(p and p.courses)or not(p.waterfallRelief or V.require('Gen1Stairs').setting:get())then return end
 local old=courseFields[map];if old then return old end
 local w,h=p.size[1]*2,p.size[2]*2
 local field={width=w,height=h,tileWidth=w*2,tileHeight=h*2,step=6,ledgeCount=0,terrainMode='flat',seviiSource=true}
 function field:at(x,y)
  x,y=math.floor(x),math.floor(y)
  if x<0 or y<0 or x>=w or y>=h then return 0 end
  if objectRole(p,x*2,y*2)=='Z'then return 0 end
  return (p.courses[y+1]:byte(x+1)-33)*6
 end
 function field:atTile(x,y)return self:at(math.floor(x/2),math.floor(y/2))end
 function field:atWorld(x,z)return self:at(math.floor(x/16),math.floor(z/16))end
 function field:rampAtTile()end
 courseFields[map]=field;return field
end
local roomBounds=setmetatable({},{__mode='k'})
function M.bounds(map)
 local p=M.profile(map);if not(p and p.kind=='room')or not map.isWalkableCell then return end
 if roomBounds[map]then return roomBounds[map]end
 local x0,y0,x1,y1=math.huge,math.huge,-1,-1
 for y=0,map.def.height*2-1 do for x=0,map.def.width*2-1 do
  local tag=M.token(map,x*2,y*2)
  if tag~='V'and (map:isWalkableCell(x,y)or M.portalAt(map,x,y))then
   x0,y0,x1,y1=math.min(x0,x),math.min(y0,y),math.max(x1,x+1),math.max(y1,y+1)
  end
 end end
 -- Blocked furniture at the north edge still belongs inside the room. A
 -- walkable-only enclosure otherwise hides its bookcases behind the wall.
 for _,prop in ipairs(p.props or{})do
  local wallMounted=prop.tag:match('^[knqclp]$')
  local left,top=math.max(0,prop.x),math.max(0,prop.y+(wallMounted and math.max(0,prop.h-1)or 0))
  local right,bottom=math.min(map.def.width*2,prop.x+prop.w),math.min(map.def.height*2,prop.y+prop.h)
  if right>left and bottom>top then
   x0,y0,x1,y1=math.min(x0,left),math.min(y0,top),math.max(x1,right),math.max(y1,bottom)
  end
 end
 if x1<0 then return end
 local b={west=x0*16,north=y0*16,east=x1*16,south=y1*16};roomBounds[map]=b;return b
end
function M.partitions(map,out)
 local p=M.profile(map);if not(p and p.kind=='room')then return end
 local bounds=M.bounds(map);if not bounds then return end
 local w,h=map.def.width*2,map.def.height*2
 local function wall(x,y)return x>=0 and y>=0 and x<w and y<h and M.token(map,x*2,y*2)=='X'
  and not map:isWalkableCell(x,y)and not M.portalAt(map,x,y)end
 for _,edge in ipairs{'north','south','west','east'}do
  local horizontal=edge=='north'or edge=='south'
  local across,along=horizontal and h or w,horizontal and w or h
  for at=0,across-1 do
   local start
   for n=0,along do
    local x,y=horizontal and n or at,horizontal and at or n
    local dx,dy=edge=='west'and -1 or edge=='east'and 1 or 0,edge=='north'and -1 or edge=='south'and 1 or 0
    local xx,yy=x+dx,y+dy
    local face=n<along and wall(x,y)and xx*16>=bounds.west and(xx+1)*16<=bounds.east
     and yy*16>=bounds.north and(yy+1)*16<=bounds.south and not wall(xx,yy)and M.token(map,xx*2,yy*2)~='V'
    if face then start=start or n end
    if not face and start then
     local plane=(at+((edge=='south'or edge=='east')and 1 or 0))*16
     if plane~=bounds[edge]then out[#out+1]={edge=edge,from=start*16,upto=n*16,at=plane,openings={}}end
     start=nil
    end
   end
  end
 end
end
local roomProfiles={}
local nativeRoomProfiles={}
function M.room(map)
 local p=M.profile(map);if not(p and p.kind=='room')or next(map.def.connections or{})then return nil end
 local id=map.id or map.def.id;local shell=roomProfiles[id]
 if not shell then
  shell={theme=p.theme,enabled=true,shellHeight=40,wallDistance=0,
   wallAsset='kanto_'..p.theme,nativeRoomPanels=true,cutawayPlan=true,
   wallEdges={north=true,south=true,west=true,east=true},
   ceiling={enabled=true,authored=true},doors={},wallPanorama={edge='north',width=40}}
  roomProfiles[id]=shell
 end
 return shell
end
function M.nativeRoom(map)
 local p=M.profile(map);local room=M.room(map)
 if not(room and p.nativeWallSource)then return end
 local id=map.id or map.def.id;local result=nativeRoomProfiles[id]
 if not result then
  result={};for k,v in pairs(room)do result[k]=v end
  result.nativeSourceWalls=true;result.shellHeight=48
  result.wallAsset=nil;result.wallPanorama=nil
  result.ceiling={enabled=true,native=true}
  nativeRoomProfiles[id]=result
 end
 return result
end
-- Retain this presentation accessor for callers, but keep atmosphere policy
-- beside Kanto's shared definitions instead of duplicating their values.
function M.mist(map)
 if M.profile(map)then return V.require('IndoorMist').profile(map,false)end
end
local function boxes(P,kind,w,h)
 local a={boxes={},directBoxes=true,terrain=true,step=1,frameW=w,frameH=h+48,depth=h,offsetY=-48}
 P.models[kind]=a
 return a,function(x,y,z,bw,bh,bd,c)
  if bw>0 and bh>0 and bd>0 then a.boxes[#a.boxes+1]={x,y,z,bw,bh,bd,c}end
 end
end
local function furniture(P,tag,w,h,rise)
 local kind='sevii_'..tag..'_'..w..'_'..h..(tag=='A'and'_rise_'..(rise or 0)or'')
 if P.models[kind]then return kind end
 local c=P.decorColors;local a,b=boxes(P,kind,w,h)
 if tag=='q'or tag=='l'or tag=='Lf'or tag=='n'or tag=='k'
     or tag=='c'or tag=='Ct'then
  local raw=b;local back=math.max(0,h-16);h=math.min(h,16)
  b=function(x,y,z,bw,bh,bd,color)raw(x,y,z+back,bw,bh,bd,color)end
 end
 if tag=='Z'then
  -- Compact ferries share the Anne's navy hull, white cabins and red funnel.
  for x=0,w-1,4 do local edge=math.min(x+2,w-x-2);local breadth=math.max(4,h*math.min(1,(edge+4)/12));local z=(h-breadth)/2
   b(x,-3,z,math.min(4,w-x),7,breadth,c.navy);b(x,4,z,math.min(4,w-x),2,breadth,14)
  end
  b(6,6,4,math.max(2,w-12),2,math.max(2,h-8),c.oak)
  b(w*.25,8,h*.25,w*.5,14,h*.5,14);b(w*.22,22,h*.22,w*.56,2,h*.56,14)
  for x=w*.28,w*.7,10 do b(x,12,h*.25,5,6,1,8)end
  b(w*.45,24,h*.4,8,12,8,1);b(w*.43,35,h*.38,10,3,10,c.navy)
 elseif tag=='d'then
  b(0,0,0,w,2,h,c.oak);for x=3,w-3,8 do b(x,2,0,.6,.3,h,c.walnut)end
  a.support=2;a.actorSurface=true
 elseif tag=='y'then
  -- The Tanoby drawing is a squat weathered stone gate into a rocky mound.
  -- Keep a full source-cell doorway, with piers and a stepped masonry cap.
  local door=w/2;local front=h-12;local rear=math.max(0,h-28);local tones={c.warmBrick,c.paperWindow,c.looseRock6}
  for z=0,rear-2,4 do for x=0,w-4,4 do
   local edge=math.min(x+2,w-x-2,z+2,rear-z)
   local height=6+math.min(12,math.floor(edge/2)*2)
   b(x,0,z,4,height,4,tones[1+(x/4+z/4)%3])
  end end
  for y=0,24,4 do
   for x=0,w-1,8 do
    local width=math.min(8,w-x);local color=tones[1+(math.floor(x/8)+y/4)%3]
    b(x,y,rear+2,width,4,6,color)
    if x+width<=door-8 or x>=door+8 then b(x,y,front,width,4,10,color)end
   end
   b(0,y,rear+8,5,4,math.max(2,front-rear-8),tones[1+y/4%3])
   b(w-5,y,rear+8,5,4,math.max(2,front-rear-8),tones[1+(y/4+1)%3])
  end
  for _,x in ipairs{door-12,door+8}do
   b(x-1,0,front-1,6,3,12,c.looseRock5)
   b(x,3,front,4,24,10,c.paperWindow)
   b(x-1,27,front-1,6,3,12,c.looseRock6)
  end
  b(0,28,rear,w,4,h-rear,c.looseRock5)
  b(2,32,rear+2,w-4,3,h-rear-4,c.warmBrick)
  b(6,35,rear+6,w-12,3,h-rear-12,c.paperWindow)
  for x=4,w-6,8 do b(x,30,h-2,2,2,1,c.looseRock4)end
 elseif tag=='m'then
  -- Memorial Pillar: stepped stone cairn, never a windowed house fragment.
  local cx,cz=w/2,h*.68
  for tier=0,6 do
   local radius=math.max(3,math.min(w*.45,18)-tier*2)
   for z=-radius,radius-2,2 do for x=-radius,radius-2,2 do
    if math.abs(x+1)+math.abs(z+1)<=radius*1.5 then
     b(cx+x,tier*5,cz+z,2,5,2,(x+z+tier)%3==0 and c.silver or c.stone)
    end
   end end
  end
  b(cx-3,35,cz-3,6,5,6,c.silver)
  b(cx-5,7,cz+math.min(w*.45,18)-1,10,7,1,c.slate)
  b(cx-3,9,cz+math.min(w*.45,18),6,1,1,14)
 elseif tag=='i'then
  -- Low yellow cargo blocks in the original warehouse movement puzzle.
  -- They are obstacles on individual source cells, never full-height walls.
  b(0,0,0,w,2,h,c.oak)
  for z=1,h-7,8 do for x=1,w-7,8 do
   b(x,2,z,6,9,6,c.paperWindow);b(x,11,z,6,1,6,11)
   b(x+2,2,z+6,2,9,.5,c.oak)
  end end
 elseif tag=='z'then
  -- Individual shipping crates, with open slat joints and timber braces.
  b(1,0,1,w-2,20,h-2,c.walnut)
  for z=2,h-4,4 do b(2,20,z,w-4,2,3,c.oak)end
  for y=2,17,4 do
   b(1,y,0,w-2,3,1,c.oak);b(1,y,h-1,w-2,3,1,c.oak)
   b(0,y,1,1,3,h-2,c.oak);b(w-1,y,1,1,3,h-2,c.oak)
  end
  for _,x in ipairs{2,w-4}do
   b(x,0,0,2,22,2,c.oldTimber);b(x,0,h-2,2,22,2,c.oldTimber)
   b(x,22,1,2,1,h-2,c.oldTimber)
  end
  for x=4,w-6,2 do b(x,2+math.floor((x-4)*16/math.max(1,w-10)),h-1,2,3,1,c.oldTimber)end
 elseif tag=='v'then
  b(0,0,2,w,24,math.max(2,h-4),c.stone);b(0,24,0,w,3,h,c.slate)
  for x=3,w-6,12 do b(x,9,h-1,6,9,1,8);b(x-1,18,h-1,8,1,1,c.oak)end
 elseif tag=='F'then
  local along=w>=h
  if along then
   for x=1,w-3,12 do b(x,0,h/2-1,3,16,3,c.walnut);b(x-1,16,h/2-2,5,2,5,c.oak)end
   b(0,5,h/2,w,2,2,c.oak);b(0,11,h/2,w,2,2,c.oak)
  else
   for z=1,h-3,12 do b(w/2-1,0,z,3,16,3,c.walnut);b(w/2-2,16,z-1,5,2,5,c.oak)end
   b(w/2,5,0,2,2,h,c.oak);b(w/2,11,0,2,2,h,c.oak)
  end
 elseif tag=='S'then
  b(w/2-2,0,h/2-2,4,17,4,c.walnut);b(1,15,h/2-3,w-2,10,3,c.oak)
  b(3,17,h/2,math.max(1,w-6),6,1,4)
  for x=4,w-5,3 do b(x,19,h/2+1,1,1,1,3)end
 elseif tag=='f'then
  for x=3,w-3,6 do for z=3,h-3,6 do b(x,0,z,1,4,1,c.leafDark);b(x-1,4,z-1,3,2,3,(x+z)%2==0 and 1 or 11)end end
 elseif tag=='H'then
  b(2,0,1,2,30,2,c.oak);b(w-4,0,1,2,30,2,c.oak)
  for y=2,26,4 do b(4,y,1,w-8,1.5,2,c.oak)end
 elseif tag=='A'then
  rise=rise or 0
  local function top(z)
   local fraction=math.max(0,math.ceil((h-z-4)/4))/math.max(1,math.ceil(h/4)-1)
   return math.abs(rise)*(rise<0 and 1-fraction or fraction)
  end
  for z=0,h-1,4 do local height=top(z)
   b(0,-.5,z,w,height+.5,math.min(4,h-z),c.slate)
   b(0,height-.2,z,w,.2,math.min(.8,h-z),c.stone)
  end
  a.support=function(_,z)return top(z)end;a.actorSurface=true;a.supportRelative=true
  a.replacesGround=true;a.groundAt=function()return false end
 elseif tag=='J'or tag=='N'or tag=='O'or tag=='Q'then
  local down=tag=='O'or tag=='Q'
  for z=0,h-1,4 do
   local height=2+math.floor((h-z-1)/4)*2
   b(0,down and -height or 0,z,w,height,math.min(4,h-z),c.slate)
   b(0,down and -height or height,z,w,.5,.8,c.stone)
  end
  a.support=function(_,z)local height=2+math.floor(math.max(0,h-z-1)/4)*2;return down and -height or height end
  a.actorSurface=true
 elseif tag=='p'then
  local source=assert(P.models.indoor_plant_0)
  for _,box in ipairs(source.boxes)do b(box[1]*w/16,box[2],box[3]*h/32,box[4]*w/16,box[5],box[6]*h/32,box[7])end
 elseif tag=='s'or tag=='e'then
  -- Same open chair geometry as Gen1FurnitureCompletion, facing the table.
  local source=P.models['reds_dining_chair_'..(tag=='s'and'east'or'west')]
  assert(source,'missing Gen1 dining chair')
  for _,box in ipairs(source.boxes)do a.boxes[#a.boxes+1]=box end
  a.support=source.support;a.actorSurface=true
 elseif tag=='sR'or tag=='eR'then
  -- The island homes use the orange dining chairs from the source rooms.
  -- Keep the same compact, sit-able footprint as Kanto furniture.
  for _,x in ipairs{2,w-4}do for _,z in ipairs{2,h-4}do
   b(x,0,z,2,9,2,c.walnut)
  end end
  b(1,9,1,w-2,2,h-2,c.oak)
  b(2,11,2,w-4,1,h-4,1)
  local back=tag=='sR'and w-4 or 1
  b(back,10,1,3,13,h-2,c.walnut)
  b(back+1,13,2,1,8,h-4,1)
  a.support=12;a.actorSurface=true
 elseif tag=='a'then
  local source=assert(P.models.waiting_bench)
  for _,box in ipairs(source.boxes)do a.boxes[#a.boxes+1]=box end
  a.support=source.support;a.actorSurface=true
 elseif tag=='c'then
  -- Shallow cream display cabinet with glass doors and low drawers.
  local back=math.max(0,h-16);local depth=math.min(16,h)
  b(1,0,back+1,w-2,8,depth-2,c.oak)
  b(2,2,back+depth-1,w-4,5,1,c.walnut)
  b(w/2-.5,2,back+depth,1,5,.5,c.silver)
  b(1,8,back+1,w-2,14,depth-2,14)
  b(2,10,back+depth-1,w-4,10,1,8)
  b(w/2-.5,9,back+depth,1,12,.5,c.silver)
  b(1,22,back,w-2,7,depth,11)
 elseif tag=='Ct'then
  local back=math.max(0,h-16);local depth=math.min(16,h)
  b(1,0,back+1,w-2,29,depth-2,c.oak)
  b(2,2,back+depth-1,w-4,24,1,8)
  b(w/2-.5,2,back+depth,w>2 and 1 or .5,24,.5,c.walnut)
  b(1,27,back,w-2,3,depth,c.oak)
  b(w/2-2,13,back+depth,1,3,.5,11);b(w/2+1,13,back+depth,1,3,.5,11)
 elseif tag=='Lf'then
  b(2,0,2,w-4,29,h-4,1)
  b(2,15,h-2,w-4,2,1,c.silver)
  b(3,2,h-1,w-6,12,1,c.warmBrick)
  b(3,17,h-1,w-6,10,1,c.warmBrick)
  b(w-5,19,h,1,5,.5,c.silver)
  b(w-5,8,h,1,4,.5,c.silver)
 elseif tag=='q'then
  b(1,0,1,w-2,12,h-2,14);b(0,12,0,w,2,h,c.stone)
  b(3,14,3,math.max(2,w*.46),1,h-6,c.slate)
  b(5,15,5,math.max(2,w*.46-4),.5,h-10,8)
  b(w*.26,15,2,2,5,2,c.silver);b(w*.26,19,2,5,1,2,c.silver)
  for x=math.ceil(w*.65),w-4,6 do for z=4,h-4,7 do b(x,14,z,3,1,3,3)end end
 elseif tag=='l'then
  b(2,0,2,w-4,26,h-4,14);b(3,2,h-2,w-6,22,1,4)
  b(w-6,6,h-1,1,6,1,c.silver);b(3,17,h-1,w-6,.5,1,c.slate)
 elseif tag=='t'or tag=='b'or tag=='r'then
  local height=tag=='t'and 11 or 7
  for _,x in ipairs{2,w-5}do for _,z in ipairs{2,h-5}do b(x,0,z,3,height,3,c.oak)end end
  b(0,height,0,w,2,h,tag=='b'and c.navy or c.oak)
  if tag=='t'then b(3,height+2,3,w-6,.5,h-6,8)end
  if tag=='b'then b(1,height+2,1,w-2,2,math.min(8,h-2),4);b(1,height+2,9,w-2,1,math.max(1,h-10),8)end
  if tag=='r'then b(0,9,0,w,9,3,1)end
  a.support=height+2;a.actorSurface=true
 elseif tag=='h'then
  local source=assert(P.models.healing_station)
  for _,box in ipairs(source.boxes)do b(box[1]*w/32,box[2],box[3]*h/32,box[4]*w/32,box[5],box[6]*h/32,box[7])end
  a.lightSource={position={w/2,8,h+2},normal={0,0,1},radius=60,power=.5,color={.55,.85,1},kind='sevii-healer'}
 elseif tag=='R'then
  -- Only the long front run is a counter. Adjacent back-wall runs are
  -- separate cabinets, or their full-depth tops merge into a giant slab.
  b(0,0,1,w,8,h-2,14);b(0,8,0,w,1,h,1)
  b(0,2,h-1,w,2,1,c.slate)
 elseif tag=='Y'then
  b(0,0,0,w,11,4,c.silver);b(0,11,0,w,2,4,14)
  b(0,0,h-2,w,4,2,c.slate)
  if w>=32 then b(3,4,4,w-6,3,1,8)end
 elseif tag=='C'then
  -- A short service desk sits in front of the nurse while leaving the rear
  -- half of her cell free for the actor and the next cell free for dialogue.
  b(0,0,10,w,7,6,14);b(0,7,9,w,2,7,1)
  b(2,2,9,w-4,3,1,c.slate)
 elseif tag=='U'or tag=='V'then
  -- The network machinery is a restricted service bay. Show its boundary
  -- and a small console instead of a solid block across six floor cells.
  b(0,0,0,w,.25,h,14)
  b(0,0,0,2,6,h,c.silver);b(0,6,0,2,1,h,1)
  if tag=='V'and w>=48 then
   b(w-30,0,2,26,12,h-4,c.slate)
   b(w-27,8,h-2,20,3,1,8)
   b(w-23,5,h-1,12,1,.5,c.silver)
  end
 elseif tag=='M'then
  -- One Island's network room has a six-cell machine bay. Its source
  -- silhouette is useful in 2D, but full-height extrusion hides the entire
  -- right wall. Keep the footprint, then expose the servers and controls.
  b(0,0,0,w,3,h,c.slate)
  b(0,3,0,3,20,h,c.silver);b(w-3,3,0,3,20,h,c.silver)
  b(3,3,0,w-6,20,3,c.silver)
  b(3,3,h-5,w-6,11,5,c.slate)
  for x=8,w-25,24 do
   b(x,3,8,17,25,19,8);b(x+1,4,27,15,23,2,c.slate)
   b(x+3,13,29,11,8,1,3);b(x+4,14,30,9,6,.5,c.silver)
   for y=6,10,2 do b(x+3,y,29,2,1,1,7)end
  end
  b(12,3,38,w-24,8,25,c.silver)
  b(16,11,42,w-32,2,18,14)
  for x=20,w-24,16 do
   b(x,13,44,10,8,2,c.slate);b(x+1,14,46,8,6,.5,8)
   b(x+2,13,52,6,1,3,7)
  end
  for x=13,w-23,22 do
   b(x,6,h-4,17,6,1,3);b(x+2,7,h-3,13,4,.5,8)
  end
 elseif tag=='I'then
  -- The compact red/blue link cabinet at the left side of every Center.
  b(1,0,2,w-2,3,h-4,c.slate)
  b(1,3,2,w-2,12,h-4,c.navy)
  b(2,15,2,w-4,2,h-4,c.silver)
  for x=4,w-7,8 do
   b(x,4,h-1,5,8,1,8)
   b(x+1,5,h,3,3,.5,3)
  end
  b(0,0,0,2,17,h,c.silver);b(w-2,0,0,2,17,h,c.silver)
 elseif tag=='T'then
  -- The glass-topped link terminal is a console, not a wooden table.
  b(1,0,1,w-2,11,h-2,c.slate)
  b(0,11,0,w,2,h,c.silver)
  b(2,13,2,w-4,2,h-4,14)
  b(4,15,3,w-8,.5,h-6,8)
  for _,x in ipairs{2,w-5}do for _,z in ipairs{2,h-5}do
   b(x,0,z,3,11,3,c.slate)
  end end
  a.support=15;a.actorSurface=true
 elseif tag=='G'then
  -- The source classifier also groups trim and wall fragments as props.
  -- Claim their former upright art, but leave the reviewed floor visible.
  b(1,-3,1,w-2,.1,h-2,c.silver)
 elseif tag=='N'then
  -- Upper-wall status display; the public PC uses the normal center_pc.
  b(1,12,2,w-2,2,h-4,c.slate)
  b(2,14,h-3,w-4,10,1,c.navy)
  b(3,16,h-2,w-6,6,.5,8)
 elseif tag=='E'then
  -- The upper-floor transfer desks are red like the FireRed source, with
  -- individual grey workstations separating the counter runs.
  b(1,0,2,w-2,9,h-4,c.silver)
  b(0,9,0,w,2,h,1)
  b(2,11,2,w-4,1,h-4,c.navy)
  for x=4,w-8,12 do
   b(x,2,h-1,8,5,1,c.navy)
   b(x+1,3,h,6,2,.5,8)
  end
 elseif tag=='Jp'then
  -- White partition at the right end of the upper transfer room. The final
  -- cell is the counter, so the pillar must stop before it.
  b(0,0,0,w,32,h-16,c.silver)
  b(0,17,0,w,3,h-16,1)
  b(1,3,1,w-2,24,h-18,14)
 elseif tag=='Dc'then
  -- The Day Care's L-shaped reception counter is part of its source map,
  -- although the generic source classifier labels it as wall artwork.
  b(0,0,0,w,10,h,c.silver)
  b(0,10,0,w,2,h,14)
  b(1,2,h-1,w-2,5,1,c.slate)
 elseif tag=='W'then
  -- Joyful Game Corner's yellow U-shaped service counter is one fixture.
  -- Its source pixels were split into bookshelves and wooden tables.
  local yellow=11
  -- Its blocked source cells form two rear runs, side arms and one front.
  -- Keep the centre and the west aisle open exactly as the ROM does.
  for _,x in ipairs{16,80}do
   b(x,0,0,48,12,16,yellow)
   b(x,12,0,48,2,16,c.paperWindow)
  end
  for _,x in ipairs{16,w-16}do
   b(x,0,0,16,12,h,yellow)
   b(x,12,0,16,2,h,c.paperWindow)
  end
  b(16,0,h-16,w-16,12,16,yellow)
  b(16,12,h-16,w-16,2,16,c.paperWindow)
  for _,x in ipairs{20,w-31}do
   b(x,13,2,16,2,10,c.silver)
   b(x+2,15,4,12,1,6,8)
  end
  -- Only the actual U-shaped countertop supports actors. Its footprint
  -- also contains the original open west aisle, rear gap and centre floor.
  a.support=function(x,z)
   if x<0 or z<0 or x>=w or z>=h then return end
   if z<16 and ((x>=16 and x<64)or(x>=80 and x<128))
      or (x>=16 and x<32 or x>=w-16)and z<h
      or x>=16 and z>=h-16 then return 14 end
  end
  a.actorSurface=true
 elseif tag=='P'then
  -- The checkout is the narrow vertical fixture beside the clerk. The
  -- separate white shelves in front of it must remain separate models.
  b(0,0,0,w,9,h,c.silver)
  b(0,9,0,w,2,h,14)
  b(1,3,h-2,w-2,4,1,c.martBlue)
  b(2,11,2,w-4,8,8,c.slate)
  b(3,19,3,w-6,1,6,8)
  a.support=11;a.actorSurface=true
 elseif tag=='MS'then
  -- Freestanding Sevii Mart product racks are white metal and glass, not
  -- the brown bookcases used in homes.
  b(0,0,0,w,3,h,c.silver)
  for _,x in ipairs{1,w-3}do b(x,0,1,2,27,h-2,14)end
  for z=2,h-3,15 do
   local depth=math.min(13,h-z-1)
   b(1,10,z,w-2,2,depth,14)
   b(2,12,z+1,w-4,1,math.max(1,depth-2),c.paperWindow)
   for x=4,w-6,7 do
    b(x,13,z+3,4,5,math.min(5,depth-4),((x+z)%3==0)and 3 or((x+z)%3==1)and 8 or 12)
   end
  end
  -- Narrow rails keep the merchandise visible from the usual overhead
  -- camera; a solid top would read as a featureless white slab.
  for z=0,h-1,16 do
   b(0,27,z,w,2,2,c.silver)
   b(0,27,math.min(h-2,z+14),w,2,2,c.silver)
  end
 elseif tag=='MW'then
  b(1,6,h-5,w-2,20,4,c.silver)
  b(2,9,h-1,w-4,12,1,c.navy)
  b(3,12,h,w-6,4,.5,8)
 elseif tag=='TP'then
  -- Eighteen small white trainer-lane markers are baked into each tower
  -- floor. They are blocked cells in the source, not empty yellow tiles.
  b(1,0,1,w-2,3,h-2,c.slate)
  b(3,3,3,w-6,15,h-6,14)
  b(2,18,2,w-4,3,h-4,c.silver)
  b(5,8,h-2,w-10,6,1,c.navy)
 elseif tag=='D'then
  b(0,0,0,w,.25,h,14)
 elseif tag=='u'then
  b(0,0,0,w,22,h,c.slate);b(1,22,1,w-2,2,h-2,8)
  b(2,7,h-1,w-4,12,1,3);b(3,9,h-.5,w-6,8,.5,8)
 elseif tag=='n'then
  local source=assert(P.models.center_pc)
  for _,box in ipairs(source.boxes)do
   b(box[1]*w/16,box[2],(box[3]-6)*16/18,box[4]*w/16,box[5],box[6]*16/18,box[7])
  end
 else
  b(1,0,1,w-2,2,h-2,c.oak);b(1,2,1,2,24,h-2,c.walnut);b(w-3,2,1,2,24,h-2,c.walnut)
  for y=3,23,7 do b(3,y,1,w-6,1,h-2,c.oak)
   for x=4,w-5,5 do b(x,y+1,h-6,3,5,4,(x+y)%2==0 and 8 or 12)end end
 end
 return kind
end
local function clipped(P,kind,x0,z0,x1,z1)
 local source=P.models[kind];local name=kind..'_clip_'..x0..'_'..z0..'_'..x1..'_'..z1
 if P.models[name]then return name end
 local a={};for key,value in pairs(source)do a[key]=value end;a.boxes={};P.models[name]=a
 for _,b in ipairs(source.boxes)do
  local x,z=math.max(x0,b[1]),math.max(z0,b[3]);local xx,zz=math.min(x1,b[1]+b[4]),math.min(z1,b[3]+b[6])
  if xx>x and zz>z then a.boxes[#a.boxes+1]={x,b[2],z,xx-x,b[5],zz-z,b[7]}end
 end
 if a.glassKind then a.glassKind=clipped(P,a.glassKind,x0,z0,x1,z1)end
 -- Seasonal ornaments use the whole roof and would cross a fragment seam.
 a.winterKind=nil
 return name
end
function M.find(P,map,buildingsOnly)
 local p=M.profile(map);if not p then return {}end
 local centerGround=p.theme=='center'and p.source:match('PokemonCenter_1F$')~=nil
 local centerUpper=p.theme=='center'and p.source:match('PokemonCenter_2F$')~=nil
 local gameCorner=p.source=='TwoIsland_JoyfulGameCorner'
 local seviiMart=p.theme=='mart'
 local dayCare=p.source=='FourIsland_PokemonDayCare'
 local towerFloor=p.source:match('^TrainerTower_[1-8]F$')~=nil
 -- The source profile records exact furniture footprints in imported rooms.
 -- Use models for those objects in all Voxel modes, while retaining source
 -- walls, floor artwork, portals and collision as their own separate layers.
 local result={};local d=map.def;local used={};local c=P.decorColors
 local _,tags=M.profile(map);local groundTile
 for tile,tag in pairs(tags)do if (tag=='G'or tag=='D')and(not groundTile or tile<groundTile)then groundTile=tile end end
 if not groundTile then for tile,tag in pairs(tags)do if (tag=='T'or tag=='B')and(not groundTile or tile<groundTile)then groundTile=tile end end end
 groundTile=groundTile or map:tileAt(0,0)
 local function add(kind,x,y,w,h,enabled,claim,floorTile)
  local fillTile=not centerGround and(floorTile or groundTile)or nil
  result[#result+1]={kind=kind,mapId=map.id,tx=x*2,ty=y*2,w=w*2,h=h*2,voxelOnly=true,enabled=enabled,
   claimTx=claim and claim[1]*2,claimTy=claim and claim[2]*2,groundTile=fillTile,keepTerrain=kind:match('^sevii_Z_')~=nil}
 end
 for _,s in ipairs(p.props)do
  local networkBay=centerGround and p.source=='OneIsland_PokemonCenter_1F'
    and s.tag=='u'and s.x==12 and s.y>=1 and s.y<=5
  local gameCounter=gameCorner and s.x<9 and s.x+s.w>1 and s.y<4 and s.y+s.h>1
  local martCounter=seviiMart and s.tag=='k'and
    ((s.x==3 and s.y==2)or(s.x==2 and s.y==3)or(s.x==1 and s.y==4))
  local upperCounter=centerUpper and s.tag=='r'and s.y==3
  if not networkBay and not gameCounter and not martCounter and not upperCounter
      and not(s.tag=='f'and V.require('SeviiMapAnimations').active(map,'flower'))
      and(not buildingsOnly or s.tag=='B')then
   local kind
   if s.tag=='B'then
    local dest=s.doors[1]and s.doors[1].destMap or''
    local template=dest:find('CENTER')and'pokecenter'or dest:find('MART')and'pokemart'or dest:find('TOWER')and'silph_co'or'gabled_house'
    local fake={id=map.id,def={warps=s.doors}}
    if p.source=='SevenIsland_TanobyRuins'or dest:find('DOTTED_HOLE')then kind=furniture(P,'y',s.w*16,s.h*16)
    else kind=V.require('Gen1KantoBuildings').create('sevii_building_'..p.source..'_'..(s.x+p.origin[1])..'_'..(s.y+p.origin[2]),fake,s.x*2,s.y*2,s.w*2,s.h*2,template)end
   elseif s.tag=='j'then kind=V.require('SeviiHarbor').facade(P,p,s)
   elseif s.tag=='o'then kind=V.require('SeviiSeaRocks').kind(P,1+V.require('SeviiLandscape').seed(p,s.x,s.y)%4,s.w*16,s.h*16)
   else
    local tag=s.tag
    if centerGround then
     local first=p.source=='OneIsland_PokemonCenter_1F'
     local bench=tag=='a'and(first and s.y==9 and s.x>=15 and s.x<=17
      or not first and s.x==14 and(s.y==6 or s.y==7))
     local leftLink=tag=='r'and(first and s.x==0 and s.y==6 or
      not first and s.x==0 and s.y==7)
     if tag=='r'then
      tag=s.y==3 and s.w==6 and'R' or leftLink and'I'
       or s.y==2 and s.w==3 and'Y' or'G'
     elseif tag=='h'then tag=s.w==2 and'h'or'Y'
     elseif tag=='n'then tag=s.y==6 and'n'or'N'
     elseif tag=='t'then tag='T'
     elseif tag=='p'then tag='p'
     elseif bench then tag='a'
     else tag='G'end
    elseif centerUpper then
     if tag=='r'then
      tag=s.x==0 and s.y==7 and'O'
       or s.x==13 and s.y==0 and'Jp'
       or s.y==1 and s.w==4 and'Y' or'G'
     elseif tag=='a'then
      tag=s.y==7 and s.x>=5 and s.x<=11 and'a'or'G'
     elseif tag=='k'or tag=='p'or tag=='s'then
      -- Original plants, chairs and the two wall cabinets are distinct.
     else tag='G'end
    elseif gameCorner then
     if tag=='t'and s.x==8 and s.y==5 then tag='T'
     elseif tag=='k'then tag='G'end
    elseif seviiMart and tag=='k'then
     tag=s.x==0 and s.y==1 and'MW' or'MS'
    elseif p.theme=='coastal_home'or p.theme=='home'
        or p.theme=='traditional_home'then
     if tag=='c'and p.theme=='traditional_home'then tag='Ct'
     elseif p.theme~='traditional_home'and tag=='l'then tag='Lf'
     elseif p.theme~='traditional_home'and tag=='s'then tag='sR'
     elseif p.theme~='traditional_home'and tag=='e'then tag='eR'end
    end
    kind=centerUpper and s.tag=='u'and'trade_transfer_station'
      or furniture(P,tag,s.w*16,s.h*16,s.rise)
   end
   if s.tag=='F'and p.source:match('Island_Harbor$')then kind=V.require('SeviiHarbor').rail(P,kind)end
   local x0,y0=math.max(0,s.x),math.max(0,s.y)
   local x1,y1=math.min(d.width*2,s.x+s.w),math.min(d.height*2,s.y+s.h)
   if x0>s.x or y0>s.y or x1<s.x+s.w or y1<s.y+s.h then kind=clipped(P,kind,(x0-s.x)*16,(y0-s.y)*16,(x1-s.x)*16,(y1-s.y)*16)end
   local tag=s.tag
   add(kind,s.x,s.y,x1-x0,y1-y0,function()
    return P.setting:get()and(tag~='B'or V.require('Gen1PalletVillage').buildings:get())
     and(not tag:match('^[AHJNOQ]$')or V.require('Gen1Stairs').setting:get())
   end,{x0,y0})
   for y=y0,y1-1 do for x=x0,x1-1 do used[y*d.width*2+x]=true end end
  end
 end
 if centerGround and p.source=='OneIsland_PokemonCenter_1F'and not buildingsOnly then
  add(furniture(P,'M',96,80),12,1,6,5,function()return P.setting:get()end,{12,1})
 end
 if centerUpper and not buildingsOnly then
  for _,segment in ipairs{{0,3,'E'},{3,1,'n'},{4,4,'E'},
    {8,1,'n'},{9,3,'E'},{12,2,'E'}}do
   local x,w,tag=unpack(segment)
   add(furniture(P,tag,w*16,16),x,3,w,1,function()return P.setting:get()end,{x,3})
   for xx=x,x+w-1 do used[3*d.width*2+xx]=true end
  end
 end
 if dayCare and not buildingsOnly then
  for _,segment in ipairs{{0,3,5,1},{4,2,1,1}}do
   local x,y,w,h=unpack(segment)
   add(furniture(P,'Dc',w*16,h*16),x,y,w,h,function()return P.setting:get()end,{x,y})
   for yy=y,y+h-1 do for xx=x,x+w-1 do used[yy*d.width*2+xx]=true end end
  end
 end
 if towerFloor and not buildingsOnly then
  for _,x in ipairs{3,9,15}do for _,y in ipairs{10,11,12,14,15,16}do
   add(furniture(P,'TP',16,16),x,y,1,1,function()return P.setting:get()end,{x,y})
   used[y*d.width*2+x]=true
  end end
 end
 if gameCorner and not buildingsOnly then
  add(furniture(P,'W',128,48),1,1,8,3,function()return P.setting:get()end,{1,1})
  for y=1,3 do for x=1,8 do used[y*d.width*2+x]=true end end
 end
 if seviiMart and not buildingsOnly then
  add(furniture(P,'P',16,48),3,2,1,3,function()return P.setting:get()end,{3,2})
  for y=2,4 do used[y*d.width*2+3]=true end
  add(furniture(P,'G',16,16),2,3,1,1,function()return P.setting:get()end,{2,3})
  used[3*d.width*2+2]=true
  for _,shelf in ipairs{{0,4,3},{1,6,2}}do
   local x,y,w=unpack(shelf)
   add(furniture(P,'MS',w*16,16),x,y,w,1,function()return P.setting:get()end,{x,y})
   for xx=x,x+w-1 do used[y*d.width*2+xx]=true end
  end
 end
 if buildingsOnly then return result end
 if p.cave=='seafoam'then
  local ice=V.require('SeviiIce');ice.register(P)
  for y=0,d.height*2-1 do for x=0,d.width*2-1 do
   local tag=M.token(map,x*2,y*2)
   if(tag=='R'or tag=='C')and not used[y*d.width*2+x]and not map:isWalkableCell(x,y)
    and not map:isWaterCell(x,y)and not M.portalAt(map,x,y)then
    local variant=1+((x+p.origin[1])*37+(y+p.origin[2])*71)%4
    local kind=tag=='R'and'sevii_iceberg_'..variant or V.require('SeviiLandforms').kind(P,p,map,x,y,M.token,M.portalAt,'ice')
    local role=tag
    add(kind,x,y,1,1,function()return P.setting:get()and(role=='R'or V.require('HorizonWall').enabled(map))end)
    used[y*d.width*2+x]=true
   end
  end end
 end
 for y=0,d.height*2-1 do for x=0,d.width*2-1 do
  local key=y*d.width*2+x;local tag=M.token(map,x*2,y*2)
  if not centerGround and not used[key]and(tag=='k'or tag=='B')and not map:isWaterCell(x,y)and not M.portalAt(map,x,y)then
   add(furniture(P,tag=='B'and'v'or'k',16,16),x,y,1,1,function()return P.setting:get()end);used[key]=true
  end
 end end
 if p.exterior and p.source~='TrainerTower_Roof'then
  local landscape=V.require('SeviiLandscape');landscape.register(P)
  local ground=landscape.groundTiles(map,M.token,M.portalAt)
  for y=0,d.height*2-1 do for x=0,d.width*2-1 do
   local key=y*d.width*2+x;local tag=M.token(map,x*2,y*2)
   if not used[key]and(tag=='T'or tag=='C'or tag=='D'or tag=='R')and(tag=='T'or not map:isWalkableCell(x,y))and not map:isWaterCell(x,y)and not M.portalAt(map,x,y)then
    local kind
    if tag=='T'then kind=landscape.treeKind(p,map,x,y,M.token,M.portalAt)
    elseif tag=='C'then
     local region=landscape.region(p)
     local family=(region=='volcano'or region=='volcanic_coast')and'basalt'
      or region=='canyon'and'canyon'or region=='forest'and'forest'or'coastal'
     kind=V.require('SeviiLandforms').kind(P,p,map,x,y,M.token,M.portalAt,family)
    else kind=landscape.rockKind(p,x,y)end
    local token=tag
    add(kind,x,y,1,1,function()local scenery=V.require('Gen1OutdoorScenery');return P.setting:get()and(token=='T'and scenery.trees:get()or token~='T'and scenery.stone:get())end,nil,ground[key])
   end
  end end
 end
 return result
end
local objects=setmetatable({},{__mode='k'})
function M.objectStyle(name,sprite)
 if sprite=='SPRITE_POKE_BALL'then
  if name:find('BUOY',1,true)then return 'buoy'end
  for _,word in ipairs{'PEARL','MUSHROOM','STARDUST','BELL','COIN','EVERSTONE','ASH'}do
   if name:find(word,1,true)then return word:lower()end
  end
  return 'item_capsule'
 end
 if sprite=='SPRITE_PAPER'or sprite=='SPRITE_CLIPBOARD'then
  if name:find('BED',1,true)then return 'garden' end
  if name:find('FEATHER',1,true)then return 'feather' end
  if name:find('PLANK',1,true)then return 'plank' end
  return 'journal'
 end
 if sprite=='SPRITE_POKEDEX'then
  if name:find('LIFE_PC_',1,true)or name:find('CONSOLE',1,true)then return 'terminal'end
  if name:find('LANTERN',1,true)then return 'lantern'end
  if name:find('CLOCK',1,true)or name:find('PULSE',1,true)or name:find('TIME_',1,true)then return 'clock'end
  if name:find('RADIO',1,true)then return 'radio'end
  if name:find('VENT',1,true)then return 'vent'end
  if name:find('GATE',1,true)then return 'gate'end
  if name:find('TIDE_',1,true)or name:find('BALANCE',1,true)then return 'gauge'end
  return 'seal'
 end
 if sprite=='SPRITE_BOULDER'then
  if name:find('SILT',1,true)then return 'silt'end
  if name:find('MIRROR',1,true)then return 'mirror'end
  if name:find('STONE_',1,true)or name:find('ANCHOR',1,true)then return 'rune'end
  if name:find('SHAYMIN',1,true)then return 'altar_garden'end
  if name:find('ICE',1,true)then return 'altar_ice'end
  if name:find('STEEL',1,true)or name:find('REGIGIGAS',1,true)then return 'altar_steel'end
  if name:find('PHIONE',1,true)or name:find('MANAPHY',1,true)then return 'altar_tide'end
  return 'altar'
 end
end
local function liveModel(P,style)
 if style=='item_capsule'then return style end
 local name='sevii_live_'..style;if P.models[name]then return name end
 local c=P.decorColors;local a,b=boxes(P,name,16,16);a.terrain=nil
 if style=='mushroom'then
  b(6,0,6,4,7,4,4);b(3,6,3,10,3,10,1);b(5,9,5,6,2,6,1);b(4,7,4,2,1,2,4);b(10,7,9,2,1,2,4)
 elseif style=='pearl'then
  for z=3,11,2 do for y=0,8,2 do local r=25-(z-8)^2-(y-5)^2;if r>0 then local w=math.floor(math.sqrt(r));b(8-w,y,z,w*2,2,2,4)end end end
 elseif style=='bell'then b(4,0,4,8,2,8,11);b(5,2,5,6,6,6,11);b(7,8,7,2,2,2,c.silver);b(7,0,7,2,1,2,3)
 elseif style=='coin'then b(3,0,3,10,1,10,11);b(4,1,4,8,1,8,11);b(7,2,5,2,1,6,c.oak)
 elseif style=='stardust'or style=='ash'then
  b(4,0,4,8,9,8,style=='stardust'and 11 or c.slate);b(3,9,3,10,2,10,c.oak);b(6,11,6,4,2,4,c.oak)
 elseif style=='everstone'then b(3,0,3,10,5,10,c.slate);b(5,5,5,6,3,6,c.stone)
 elseif style=='vent'then
  b(1,0,1,14,4,14,c.slate);for x=3,12,3 do b(x,4,2,1,1,12,c.silver)end
 elseif style=='buoy'then
  b(3,0,3,10,3,10,4);b(5,3,5,6,8,6,1);b(7,11,7,2,5,2,c.silver);b(6,15,6,4,2,4,11)
 elseif style=='garden'or style=='silt'then
  b(1,0,1,14,2,14,c.oak);b(2,2,2,12,1,12,c.walnut)
  if style=='garden'then for x=3,12,4 do b(x,3,5,2,4,2,c.leaf);b(x-1,7,4,4,2,4,11)end end
 elseif style=='plank'then b(1,0,2,14,2,12,c.oak);for x=3,12,4 do b(x,2,3,1,.5,10,c.walnut)end
 elseif style=='journal'then
  b(2,0,3,12,2,10,c.navy);b(3,2,3,10,1.5,9,4);b(8,3.5,3,.5,.5,9,c.oak)
  for z=5,10,2 do b(4,3.5,z,3,.5,.5,3);b(9,3.5,z,3,.5,.5,3)end
 elseif style=='feather'then
  b(7,1,2,1,1,13,c.oak);for z=3,12,2 do b(4,1,z,7,1,1,4)end
 elseif style=='terminal'then furniture(P,'n',16,16);a.boxes=P.models.sevii_n_16_16.boxes
 elseif style=='gate'then
  b(1,0,2,3,22,3,c.walnut);b(12,0,2,3,22,3,c.walnut);b(4,18,2,8,3,3,c.oak)
  b(5,2,2,2,16,2,c.oak);b(9,2,2,2,16,2,c.oak)
 elseif style=='lantern'then
  b(3,0,3,10,2,10,c.slate);b(4,2,4,8,10,8,11);b(3,12,3,10,2,10,c.slate)
  for _,x in ipairs{3,11}do b(x,2,3,2,10,2,c.slate);b(x,2,11,2,10,2,c.slate)end
  a.lightSource={position={8,7,8},radius=48,power=.4,color={1,.77,.42},kind='sevii-lantern'}
 elseif style=='clock'or style=='radio'or style=='gauge'then
  b(2,0,3,12,3,10,c.oak);b(3,3,4,10,13,8,c.slate);b(4,5,12,8,9,1,4)
  if style=='radio'then b(5,6,13,5,5,1,3);b(11,13,5,1,7,1,c.silver)
  else b(7,7,13,1,5,1,3);b(7,10,13,3,1,1,3)end
 else
  local tone=style=='altar_ice'and 7 or style=='altar_tide'and 8 or style=='altar_garden'and c.leaf or style=='altar_steel'and c.silver or c.stone
  b(1,0,1,14,3,14,c.stone);b(3,3,3,10,5,10,c.slate);b(5,8,5,6,12,6,tone)
  if style=='mirror'then b(3,8,6,10,14,2,c.silver);b(4,9,8,8,12,1,8)
  elseif style=='seal'then b(3,8,3,10,2,10,c.oak);b(6,10,6,4,2,4,11)
  else b(7,10,11,2,6,1,11);b(6,12,11,4,1,1,11)end
 end
 -- Native item actors provide the cell origin, like the existing item models.
 return name
end
function M.objectKind(P,def,seed)
 if type(seed)~='string'then return nil end
 local id,index=seed:match('^(KA_SEVII_.-)_obj_(%d+)$');if not id then return nil end
 local D=require('src.core.Data');local d=D.maps[id]
 if not(d and d.kaOwner=='kasc.sevii-expedition/v1')then return nil end
 local map=require('src.world.MapLoader').load(D,id);if not M.profile(map)then return nil end
 local byIndex=objects[d]
 if not byIndex then byIndex={};for _,o in ipairs(d.objects or{})do byIndex[o.index]=o end;objects[d]=byIndex end
 local o=byIndex[tonumber(index)];if not(o and o.sprite==def.id)then return nil end
 if o.item and P.itemKinds and P.itemKinds[o.item]then return P.itemKinds[o.item]end
 local style=M.objectStyle(o.name or'',o.sprite)
 return style and liveModel(P,style)or nil
end

return M
