-- Extend the native Tower's impassable grave border to its panorama enclosure.
-- These are render-only claims: map blocks, collision and events stay native.
local V=...
local M={}
function M.matches(map)
 local d=map and map.def
 return d and d.generation~=2 and d.tileset=='CEMETERY'
  and d.width==10 and d.height==9 and not next(d.connections or{})
  and (map.id or''):match('^POKEMON_TOWER_[1-7]F$')~=nil
end
function M.find(P,map,occupied)
 if not M.matches(map)or not map.isWalkableCell or not map.isWarpTileCell then return {} end
 local d=map.def;local width,height=d.width*2,d.height*2
 local margin=V.require('HorizonWall').BELT/16
 local Budget=V.require('BuildBudget')
 local function key(x,z)return z*(width+margin*2)+x end
 local reserved,mask,used={},{},{}
 for _,list in ipairs{d.warps or{},d.objects or{},d.signs or{}}do
  for _,p in ipairs(list)do if p.x and p.y then reserved[key(p.x,p.y)]=true end end
 end
 local function entrance(x,z)
  for _,w in ipairs(d.warps or{})do
   if (w.y==0 and z<0 or w.y==height-1 and z>=height)and x==w.x
    or (w.x==0 and x<0 or w.x==width-1 and x>=width)and z==w.y then return true end
  end
  return false
 end
 for z=-margin,height+margin-1 do for x=-margin,width+margin-1 do
  Budget.tick()
  local outside=x<0 or z<0 or x>=width or z>=height
  if outside then mask[key(x,z)]=entrance(x,z)and 2 or 1
  elseif not reserved[key(x,z)]and not map:isWalkableCell(x,z)and not map:isWarpTileCell(x,z)then
   local tx,ty=x*2,z*2
   local a,b,c,e=map:tileAt(tx,ty),map:tileAt(tx+1,ty),map:tileAt(tx,ty+1),map:tileAt(tx+1,ty+1)
   local border=a==9 and b==10 and c==25 and e==26
   local void=a==17 and b==17 and c==17 and e==17
   if border or void then
    local free=true
    for dz=0,1 do for dx=0,1 do if occupied(tx+dx,ty+dz)then free=false end end end
    if free then mask[key(x,z)]=1 end
   end
  end
 end end
 local result={}
 local function add(x,z,w,h,mode)
  -- Small rectangular batches avoid hundreds of separate draw calls. Reuse
  -- the existing grave silhouettes without duplicating their candle lights.
  local phase=(x+z)%2
  local kind='tower_grave_field_'..w..'_'..h..'_'..mode..'_'..phase
  if not P.models[kind]then
   local model={boxes={},directBoxes=true,frameW=w*16,depth=h*16,frameH=h*16+32,offsetY=-32}
   P.models[kind]=model
   local C=P.decorColors
   local function box(a,b,c,e,f,g,color)model.boxes[#model.boxes+1]={a,b,c,e,f,g,color}end
   -- A shallow stone bed covers the former flat wall art and the complete
   -- panorama apron. Its top is just above the existing ground, without seams.
   box(0,0,0,w*16,.125,h*16,C.hauntedMortar)
   for dz=0,h-1 do for dx=0,w-1 do
    local variation=(dx+dz+phase)%2
    box(dx*16+.25,.125,dz*16+.25,15.5,.125,15.5,C.hauntedSlate)
    if mode==1 then
     local source=assert(P.models['memorial_stone_'..variation])
     for _,b in ipairs(source.boxes)do
      box(b[1]+dx*16,b[2]+.25,b[3]+dz*16,b[4],b[5],b[6],b[7])
     end
    end
   end end
  end
  result[#result+1]={kind=kind,mapId=map.id,tx=x*2,ty=z*2,w=w*2,h=h*2,
   groundTile=1,voxelOnly=true,towerGraveyard=true,graveCount=mode==1 and w*h or 0}
 end
 for z=-margin,height+margin-1 do for x=-margin,width+margin-1 do
  local k=key(x,z);local mode=mask[k]
  if mode and not used[k]then
   local w,h=1,1
   while w<4 and x+w<width+margin and mask[key(x+w,z)]==mode and not used[key(x+w,z)]do w=w+1 end
   while h<4 and z+h<height+margin do
    local full=true
    for dx=0,w-1 do if mask[key(x+dx,z+h)]~=mode or used[key(x+dx,z+h)]then full=false end end
    if not full then break end;h=h+1
   end
   for dz=0,h-1 do for dx=0,w-1 do used[key(x+dx,z+dz)]=true end end
   add(x,z,w,h,mode)
  end
 end end
 return result
end
return M
