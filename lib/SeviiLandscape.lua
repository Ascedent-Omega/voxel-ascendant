-- Regional presentation of verified Sevii source maps. Coordinates, heights,
-- water, encounters and collision remain owned by the imported map.
local M={}
function M.region(p)
 if not(p and p.exterior)then return nil end
 if p.kind=='canopy'then return 'forest'end
 if p.kind=='mountain'then return 'volcano'end
 if p.source=='TrainerTower_Roof'then return 'tower_roof'end
 if p.source:match('Island_Harbor$')then return 'ferry_quay'end
 if p.source=='OneIsland_KindleRoad'then return 'volcanic_coast'end
 if p.source:find('Tanoby',1,true)or p.source:find('RuinValley',1,true)then return 'ruins'end
 if p.source:find('SevaultCanyon',1,true)or p.source:find('CanyonEntrance',1,true)then return 'canyon'end
 return 'island'
end
function M.seed(p,x,y)
 x,y=x+p.origin[1],y+p.origin[2]
 return (x*37+y*71+x*y*3)%997
end
function M.nearWater(map,x,y,radius)
 if not map.isWaterCell then return false end
 local w,h=map.def.width*2,map.def.height*2
 for dy=-radius,radius do for dx=-radius,radius do
  local xx,yy=x+dx,y+dy
  if dx*dx+dy*dy<=radius*radius and xx>=0 and yy>=0 and xx<w and yy<h
   and map:isWaterCell(xx,yy)then return true end
 end end
 return false
end
function M.treeKind(p,map,x,y,token,portal)
 local region=M.region(p);local seed=M.seed(p,x,y)
 -- Sparse coastal accents on the existing blocked tree plots. Keep clear
 -- of buildings and entrances; no palm is placed on a new walking plot.
 if region=='island'and seed%13==0 and not map:isWalkableCell(x,y)
  and M.nearWater(map,x,y,3)then
  local clear=true
  for dy=-3,3 do for dx=-3,3 do
   if token(map,(x+dx)*2,(y+dy)*2)=='B'or portal(map,x+dx,y+dy)then clear=false end
  end end
  if clear then return 'cinnabar_palm_'..(1+seed%3)end
 end
 local variants={1,2,4,5}
 local gx,gy=x+p.origin[1],y+p.origin[2]
 local grove=math.floor(gx/5)*19+math.floor(gy/4)*31
 local tone=1+(grove+math.floor(seed/37))%3
 return 'sevii_tree_'..tone..'_'..variants[1+seed%#variants]
end
function M.rockKind(p,x,y)
 local region=M.region(p);local variant=1+M.seed(p,x,y)%4
 return (region=='forest'and'kanto_safari_rock_'
  or(region=='volcanic_coast'or region=='volcano')and'sevii_basalt_rock_'or'kanto_plateau_rock_')..variant
end
function M.register(P)
 local C=P.decorColors
 local tones={{C.leafDark,C.leaf,C.leafLight},
  {C.forestDeepDark,C.forestDeep,C.forestDeepLight},
  {C.forestSunDark,C.forestSun,C.forestSunLight}}
 for tone,colors in ipairs(tones)do for _,variant in ipairs{1,2,4,5}do
  local source=P.models['kanto_tree_1_'..variant]
  local name='sevii_tree_'..tone..'_'..variant
  if source and not P.models[name]and colors[1]then
   local model={};for k,v in pairs(source)do model[k]=v end
   model.boxes={};model.leafColors={[1]=true}
   local replace={[C.leafDark]=colors[1],[C.leaf]=colors[2],[C.leafLight]=colors[3]}
   for _,color in ipairs(colors)do model.leafColors[color]=true end
   for i,b in ipairs(source.boxes)do
    local copy={unpack(b)};copy[7]=replace[b[7]]or b[7];model.boxes[i]=copy
   end
   P.models[name]=model
  end
 end end
 for variant=1,4 do
  local name='sevii_basalt_rock_'..variant
  if not P.models[name]then
   local source=P.models['kanto_plateau_rock_'..variant]
   if source then
    local model={};for k,v in pairs(source)do model[k]=v end;model.boxes={}
    local c=P.decorColors
    for i,b in ipairs(source.boxes)do
     local copy={unpack(b)}
     copy[7]=b[7]==c.silver and c.looseRock4 or b[7]==(c.leafDark or 10)and c.oldBeam or c.looseRock1
     model.boxes[i]=copy
    end
    P.models[name]=model
   end
  end
 end
end
function M.groundMaterial(p,tag)
 local region=M.region(p)
 if region=='canyon'and tag~='g'then return -171 end
 if region=='tower_roof'then return -162 end
 if region=='ferry_quay'then return -162 end
 return region=='forest'and -161 or -159
end
function M.stoneMaterial(p)
 local region=M.region(p)
 return(region=='volcanic_coast'or region=='volcano')and -180 or -175
end
local groundCache=setmetatable({},{__mode='k'})
function M.groundTiles(map,token,portal)
 if groundCache[map]then return groundCache[map]end
 local w,h=map.def.width*2,map.def.height*2;local tiles={};local queue={}
 -- Continue the actual nearby lawn, earth or sand underneath a replacement.
 -- The imported collision still owns these blocked object plots.
 for y=0,h-1 do for x=0,w-1 do
  local tag=token(map,x*2,y*2)
  if tag and tag:match('^[GgDC]$')and map:isWalkableCell(x,y)
   and not map:isWaterCell(x,y)and not portal(map,x,y)then
   local key=y*w+x;tiles[key]=map:tileAt(x*2,y*2);queue[#queue+1]=key
  end
 end end
 local cursor=1
 while cursor<=#queue do
  local key=queue[cursor];cursor=cursor+1;local x,y=key%w,math.floor(key/w)
  for _,d in ipairs{{-1,0},{1,0},{0,-1},{0,1}}do
   local xx,yy=x+d[1],y+d[2];local nextKey=yy*w+xx
   if xx>=0 and yy>=0 and xx<w and yy<h and tiles[nextKey]==nil and not map:isWaterCell(xx,yy)then
    tiles[nextKey]=tiles[key];queue[#queue+1]=nextKey
   end
  end
 end
 groundCache[map]=tiles;return tiles
end
function M.grassGroups(p,map,groups,tuft)
 local result={};local meshes={}
 local function mesh(coastal)
  local key=coastal and 2 or 1
  if meshes[key]then return meshes[key]end
  local quads={};meshes[key]=quads
  for _,q in ipairs(tuft)do
   local copy={};for k,v in pairs(q)do copy[k]=v end
   if coastal then for n=1,4 do
    local v=q[n];copy[n]={4+(v[1]-4)*.94,v[2]*.92,v[3]}
   end end
   copy.uv={{-166,0},{-166,0},{-166,0},{-166,0}};quads[#quads+1]=copy
  end
  return quads
 end
 local coast=M.region(p)=='island'or M.region(p)=='ruins'
 for _,group in ipairs(groups)do
  local bins={{},{}}
  for n=1,#group.placements,2 do
   local x,z=group.placements[n],group.placements[n+1]
   local coastal=coast and M.nearWater(map,math.floor(x/16),math.floor(z/16),4)
   local bin=bins[coastal and 2 or 1];bin[#bin+1]=x;bin[#bin+1]=z
  end
  for key,placements in ipairs(bins)do if #placements>0 then
   result[#result+1]={placements=placements,quads=mesh(key==2)}
  end end
 end
 return result
end
return M
