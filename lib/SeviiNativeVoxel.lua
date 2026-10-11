-- Source-art geometry for the ordinary voxel renderer. These are band and
-- silhouette templates, not the optional replacement furniture/buildings.
local V=...
local M={}
local cache=setmetatable({},{__mode='k'})
local function color(r,g,b,a)
 return math.floor(r*255+.5)*16777216+math.floor(g*255+.5)*65536+math.floor(b*255+.5)*256+math.floor(a*255+.5)
end
function M.templates(map,pixels)
 local source=V.require('KascSeviiScenery');local p=source.profile(map)
 if not p or not pixels then return end
 local old=cache[map];if old and old.pixels==pixels then return old.list end
 local background,water,plantFloor={},{},{};local counts,wetCounts,rugCounts={},{},{};local sampled={};local perRow=map.tileset.imageWidth/8
 local function sample(tile,target)
  local values=sampled[tile]
  if not values then
   values={};sampled[tile]=values
   local x,z=tile%perRow*8,math.floor(tile/perRow)*8
   for y=0,7 do for xx=0,7 do local c=color(pixels:getPixel(x+xx,z+y));values[c]=(values[c]or 0)+1 end end
  end
  for c,n in pairs(values)do target[c]=(target[c]or 0)+n end
 end
 for y=0,map.def.height*4-1 do for x=0,map.def.width*4-1 do
  local tag=source.token(map,x,y)
  if (tag=='G'or tag=='D')and map:isWalkableCell(math.floor(x/2),math.floor(y/2))then sample(map:tileAt(x,y),counts)
  elseif p.kind=='room'and tag=='P'and map:isWalkableCell(math.floor(x/2),math.floor(y/2))then sample(map:tileAt(x,y),rugCounts)
  elseif tag=='W'then sample(map:tileAt(x,y),wetCounts)end
 end end
 local function dominant(from,to)
  local ranked={};for c,n in pairs(from)do ranked[#ranked+1]={c,n}end
  table.sort(ranked,function(a,b)return a[2]==b[2]and a[1]<b[1]or a[2]>b[2]end)
  for i=1,math.min(4,#ranked)do to[ranked[i][1]]=true end
 end
 for c in pairs(counts)do plantFloor[c]=true end
 -- A pot may overlap a rug's coloured border. Those floor stripes must
 -- not become tall slabs beside its crown in the original-art renderer.
 for c in pairs(rugCounts)do plantFloor[c]=true end
 dominant(counts,background)
 -- Shore tiles contain both sea and brown cliff paint. Only their blue
 -- palette is water; treating every shore colour as transparent eats banks.
 for c in pairs(wetCounts)do
  local r=math.floor(c/16777216)%256;local g=math.floor(c/65536)%256;local b=math.floor(c/256)%256
  if b>r+10 and b>=g-15 then water[c]=true end
 end
 local function isBackground(r,g,b,a)return a==0 or background[color(r,g,b,a)]or false end
 local function isPlantBackground(r,g,b,a)return a==0 or plantFloor[color(r,g,b,a)]or false end
 local function isCoastalBackground(r,g,b,a)
  -- Bank-bottom tiles carry wave shades that never occur in the open sea
  -- tiles. They belong to the water plane too, not the raised rock face.
  return isBackground(r,g,b,a)or water[color(r,g,b,a)]or b>r+.04 and b>=g-.06
 end
 local function isShipBackground(r,g,b,a)
  return isCoastalBackground(r,g,b,a)or b>r+.04 and b>=g-.06
 end
 local list,bySignature={},{}
 local function add(s)
  local above=s.nativeAbove or (s.tag=='Z'and s.w>=5 and 2)
  if above then s={tag=s.tag,x=s.x,y=s.y-above,w=s.w,h=s.h+above}end
  local x0,y0=math.max(0,s.x),math.max(0,s.y)
  local x1,y1=math.min(map.def.width*2,s.x+s.w),math.min(map.def.height*2,s.y+s.h)
  if x0>=x1 or y0>=y1 then return end
  local W,H=(x1-x0)*16,(y1-y0)*16;local tiles={};local sig={s.tag}
  for y=y0*2,y1*2-1 do local row={}
   for x=x0*2,x1*2-1 do row[#row+1]=map:tileAt(x,y);sig[#sig+1]=row[#row]end
   tiles[#tiles+1]=row
  end
  sig[#sig+1]=W;sig[#sig+1]=H
  for _,v in ipairs{s.w,s.h,x0-s.x,y0-s.y,s.nativeRoofRows or 0,s.nativeRoofStart or 0,s.nativeSourceBase or 0}do sig[#sig+1]=v end
  local key=table.concat(sig,':');local t=bySignature[key]
  if not t then
   t={id='sevii_native_'..#list+1,tiles=tiles,positions={},background=isBackground,
    roofRows=0,roofBack=0,roofFront=0,roofCycle={0,0},slab=0,frontEave=0,panes=false,seal='',silhouette=true}
   if s.tag=='B'then
    -- A neighbouring ground course can share the roof's red/blue paint.
    -- Only green terrain margins cut the reviewed roof bands; the facade
    -- is solid and the leading terrace course has its own source boundary.
    t.background=function(r,g,b,a)return a==0 or isBackground(r,g,b,a)and g>r+.03 and g>b+.015 end
    local fullH=s.h*16;local globalRoof=s.nativeRoofRows or math.max(8,fullH-(fullH<=48 and 16 or 32))
    local sourceY=(y0-s.y)*16;local roof=math.max(0,math.min(H,globalRoof-sourceY))
    t.roofRows=roof;t.roofBack=math.max(1,roof-1);t.roofFront=1;t.roofCycle={math.max(0,roof-8),math.max(0,roof-2)}
    t.slab=3;t.frontEave=2;t.panes=false;t.seal='s';t.solidFacade=true;t.nativeGable=true
    t.heightScale=fullH-globalRoof<=16 and 1.4 or nil
    t.nativeBands={height=fullH,roof=globalRoof,first=s.nativeRoofStart or 0,x=(x0-s.x)*16,y=sourceY,width=s.w*16}
    t.depthPx=fullH;t.offsetZ=-sourceY;t.nativeSourceBase=s.nativeSourceBase
   elseif s.tag=='Z'then
    t.background=isShipBackground;t.groundLine=H;t.roofRows=math.max(1,H-8);t.roofBack=t.roofRows;t.roofCycle={math.max(0,t.roofRows-8),t.roofRows-1}
    t.slab=2;t.useWaterGround=true;t.planCut={};t.keep={}
    local kept={}
    for y=y0*2,y1*2-1 do for x=x0*2,x1*2-1 do
     if map:isWalkableCell(math.floor(x/2),math.floor(y/2))or source.portalAt(map,math.floor(x/2),math.floor(y/2))then
      t.planCut[(y-y0*2)*(W/8)+x-x0*2]=true
      local tile=map:tileAt(x,y);if not kept[tile]then kept[tile]=true;t.keep[#t.keep+1]=tile end
     end
    end end
   elseif s.tag=='t'or s.tag=='b'or s.tag=='r'then
    local roof=math.max(1,H-12);t.roofRows=roof;t.roofBack=roof;t.roofFront=0;t.roofCycle={math.max(0,roof-8),roof-1};t.slab=1
   elseif s.tag=='z'or s.tag=='i'then
    t.roofRows=8;t.roofBack=8;t.roofCycle={0,7};t.slab=1
    t.depthPx=H;t.solidFacade=true
   elseif s.tag=='j'then
    t.roofRows=8;t.roofBack=8;t.roofCycle={0,7};t.slab=1
    t.depthPx=H;t.solidFacade=true;t.seal='s'
    t.planCut={}
    for _,door in ipairs(s.doors or{})do
     for dy=0,1 do for dx=0,1 do
      t.planCut[((door.y-y0)*2+dy)*(W/8)+(door.x-x0)*2+dx]=true
     end end
    end
   elseif s.tag=='k'or s.tag=='c'or s.tag=='q'or s.tag=='l'or s.tag=='n'or s.tag=='h'or s.tag=='u'then
    t.roofRows=math.min(8,H-1);t.roofBack=t.roofRows;t.roofCycle={0,math.max(0,t.roofRows-1)};t.slab=1
    t.depthPx=16;t.offsetZ=H-16;t.solidFacade=true
   elseif s.tag=='m'then
    t.nativeRound=true;t.connectedBackground=true;t.depthPx=math.min(28,W);t.offsetZ=math.max(0,H-t.depthPx)
    t.background=isPlantBackground
   elseif s.tag=='R'then
    t.nativeRound=true;t.connectedBackground=true;t.depthPx=12;t.offsetZ=2
    if p.cave=='seafoam'then
     t.background=function(r,g,b,a)
      return isBackground(r,g,b,a)or r>.89 and g>.92 and b>.95 or r<.7 and g>.72 and b>.82
     end
    end
   elseif s.tag=='o'then
    t.nativeRound=true;t.connectedBackground=true
    -- Ocean rock greys are also blue-tinted. The broad shore-wave mask
    -- removes their lit face and outline, leaving isolated thin ribs.
    t.background=function(r,g,b,a)return a==0 or b-r>.22 and b-g>.13 end
    t.depthPx=math.min(24,H);t.offsetZ=(H-t.depthPx)/2
    t.useWaterGround=true;t.waterUnderlay=true
   elseif s.tag=='T'or s.tag=='p'then
    t.nativeRound=true;t.nativeCrown=s.tag=='T';t.connectedBackground=true;t.depthPx=s.tag=='T'and math.min(32,W)or 12
    t.offsetZ=math.max(0,H-16)+(16-t.depthPx)/2
    t.background=s.tag=='T'and isBackground or isPlantBackground
    if s.tag=='p'then t.rowBackground=true end
   elseif s.tag=='C'then
    t.background=isCoastalBackground;t.roofRows=4;t.roofBack=4;t.roofCycle={0,3};t.slab=1;t.useWaterGround=true
   elseif (s.tag=='s'or s.tag=='e')and W==16 and H==16 then
    local bx=s.tag=='s'and 10 or 2
    t.depthPx=12;t.offsetZ=2
    t.parts={{kind='upright',x={bx,bx+3},top={0,0},facade={0,12},depth=12,rise=6,z=0},
     {kind='flat',x={2,13},rows={5,12},at=6,thick=2,z=2}}
    for _,x in ipairs{3,12}do for _,z in ipairs{1,10}do
     t.parts[#t.parts+1]={kind='box',x={x,x+1},rows={10,15},cycle={14,14},base=0,depth=2,z=z}
    end end
   else
    local depth=s.tag=='S'and 2 or s.tag=='F'and 3 or s.tag=='p'and 8 or 12
    t.parts={{kind='upright',x={0,W-1},top={0,0},facade={0,H-1},depth=depth,z=0}}
    t.depthPx=depth;t.offsetZ=math.max(0,H-16)+(16-depth)/2
    t.silhouette=true
    if s.tag=='p'then t.background=isPlantBackground;t.rowBackground=true end
   end
   bySignature[key]=t;list[#list+1]=t
  end
  t.positions[#t.positions+1]=y0*2*(map.def.width*4)+x0*2
 end
 for _,s in ipairs(p.props)do
  if s.tag:match('^[BptbesahrkuqlcSFmzjio]$')or s.tag=='Z'and s.w>=5 then add(s)end
 end
 for _,s in ipairs(p.nativeTrees or{})do add(s)end
 if p.cave=='seafoam'then for y=0,map.def.height*2-1 do for x=0,map.def.width*2-1 do
  if source.token(map,x*2,y*2)=='R'and not map:isWalkableCell(x,y)
   and not map:isWaterCell(x,y)and not source.portalAt(map,x,y)then
   add{tag='R',x=x,y=y,w=1,h=1}
  end
 end end end
 if p.exterior then for y=0,map.def.height*2-1 do for x=0,map.def.width*2-1 do
  local role=source.token(map,x*2,y*2)
  if(role=='D'or role=='R')and not map:isWalkableCell(x,y)and not map:isWaterCell(x,y)and not source.portalAt(map,x,y)then
   add{tag='R',x=x,y=y,w=1,h=1}
  end
  if source.token(map,x*2,y*2)=='C'and not map:isWalkableCell(x,y)and not map:isWaterCell(x,y)and not source.portalAt(map,x,y)then
   local coastal=false
   for _,d in ipairs{{-1,0},{1,0},{0,-1},{0,1}}do
    if map:isWaterCell(x+d[1],y+d[2])then coastal=true end
   end
   if not coastal then
    for yy=y*2,y*2+1 do for xx=x*2,x*2+1 do
     local tile=map:tileAt(xx,yy);sample(tile,{})
     for c in pairs(sampled[tile])do if water[c]then coastal=true;break end end
    end end
   end
   if coastal then add{tag='C',x=x,y=y,w=1,h=1}end
  end
 end end end
 cache[map]={pixels=pixels,list=list};return list
end
-- The reviewed FRLG grass palette separates yellow-green blade strokes
-- from the blue-green floor painted between them. Luminance masks for the
-- four-shade Kanto atlas treat that opaque floor as a standing solid.
-- Restrict this mask to the exact source contract; other games retain their
-- existing silhouettes. Height, four-tuft spacing and foot occlusion use
-- the common Kanto grass mesher in either presentation mode.
function M.grassMask(map)
 if not V.require('KascSeviiScenery').profile(map)then return nil end
 return function(r,g,b,a)return a>0 and g>=r and r>b+.02 and g>b+.08 end
end
return M
