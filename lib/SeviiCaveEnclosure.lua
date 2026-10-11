-- Source-shaped cavern walls, using the same wall/ceiling panoramas as
-- Gen-I caves. No guessed rectangular room, collision or map mutation.
local V=...
local M={}
function M.geometry(entry,checkpoint,rects,own,native)
 local map=entry.map;local S=V.require('KascSeviiScenery');local p=S.profile(map)
 if not(p and p.kind=='cave'and p.caveEdges)then return nil end
 local family=V.require('Gen1CavePanoramas').materialFor(map)
 if not family then return nil end
 local w,h=map.def.width*2,map.def.height*2;local H=p.caveCeiling or 96
 local courses=S.elevation(map)
 local wall={family=family,vertices={},indices={},unmaskedRoom=true}
 local atlas=native and V.require('TerrainAtlas').forMap(map,nil)
 if native and not atlas then return nil end
 if native then wall.family='native_sevii_cave';wall.texture=atlas end
 local roof={vertices={},indices={}};local quads,panels=0,0
 local function push(group,c,uv,shade)
  local first=#group.vertices
  for n=1,4 do group.vertices[#group.vertices+1]={c[n][1],c[n][2],c[n][3],uv[n][1],uv[n][2],shade}end
  for _,n in ipairs{1,2,3,1,3,4}do group.indices[#group.indices+1]=first+n end
  quads=quads+1;if checkpoint then checkpoint(1)end
 end
 local directions={{-1,0,'west'},{1,0,'east'},{0,-1,'north'},{0,1,'south'}}
 local function sourceUV(x,y)
  local tile=map:tileAt(x*2,y*2+1)
  local tw,th=map.tileset.imageWidth,map.tileset.imageHeight
  local px,py=tile%(tw/8)*8,math.floor(tile/(tw/8))*8
  local a,b=(px+.05)/tw,(px+15.95)/tw
  local c,d=(py+.05)/th,(py+7.95)/th
  return{{a,d},{b,d},{b,c},{a,c}}
 end
 for y=0,h-1 do for x=0,w-1 do
  local row=p.caveEdges[y+1];local mask=row and (row:byte(x+1)or 33)-33 or 0
  local tag=S.token(map,x*2,y*2)
  local body=p.caveBody and p.caveBody[y+1]
  if tag and tag~='V'and(not body or body:sub(x+1,x+1)=='1')then
   local px,pz=x*16,y*16
   -- A still-cold neighbouring fragment receives a temporary closure.
   -- The ready union removes it atomically when that body is published.
   if rects then for i,step in ipairs(directions)do
    local nx,ny=x+step[1],y+step[2]
    if nx<0 or ny<0 or nx>=w or ny>=h then
     local wx,wz=entry.ox+nx*16+8,entry.oy+ny*16+8;local covered=false
     for j,r in ipairs(rects)do
      if j~=own and wx>=r.x0 and wx<r.x1 and wz>=r.z0 and wz<r.z1 then covered=true;break end
     end
     if not covered and math.floor(mask/2^(i-1))%2==0 then mask=mask+2^(i-1)end
    end
   end end
   -- A constant source-wide ceiling also meets across streamed fragments
   -- with different floor courses, including the two waterfall ponds.
   local u0,u1=(px+entry.ox)/256,(px+16+entry.ox)/256
   local v0,v1=(pz+entry.oy)/256,(pz+16+entry.oy)/256
   push(roof,{{px,H,pz},{px+16,H,pz},{px+16,H,pz+16},{px,H,pz+16}},
    native and sourceUV(x,y)or{{u0,v0},{u1,v0},{u1,v1},{u0,v1}},.55)
   for i,step in ipairs(directions)do
    if math.floor(mask/2^(i-1))%2==1 then
     local base=courses and courses:at(x,y)or 0
     local opening=S.portalAt(map,x,y)or map:isWalkableCell(x,y)or map:isWaterCell(x,y)
     local low=base+(opening and 32 or 0)
     if low<H then
      local c,along
      if i==1 then c={{px,low,pz+16},{px,low,pz},{px,H,pz},{px,H,pz+16}};along=pz+entry.oy
      elseif i==2 then c={{px+16,low,pz},{px+16,low,pz+16},{px+16,H,pz+16},{px+16,H,pz}};along=pz+entry.oy
      elseif i==3 then c={{px,low,pz},{px+16,low,pz},{px+16,H,pz},{px,H,pz}};along=px+entry.ox
      else c={{px+16,low,pz+16},{px,low,pz+16},{px,H,pz+16},{px+16,H,pz+16}};along=px+entry.ox end
      local a,b=along/960,(along+16)/960
      if i==1 or i==4 then a,b=b,a end
      local shade=i==3 and .9 or .78
      if native then
       -- One source pixel stays one world pixel. Stretching an 8px wall
       -- strip over the complete enclosure produces long vertical bars.
       for y0=low,H-1,8 do
        local y1=math.min(H,y0+8);local q={}
        for n=1,4 do q[n]={c[n][1],n<=2 and y0 or y1,c[n][3]}end
        local uv=sourceUV(x,y)
        if y1-y0<8 then
         local v0=uv[3][2];local v1=uv[1][2]
         uv[1][2]=v0+(v1-v0)*(y1-y0)/8;uv[2][2]=uv[1][2]
        end
        push(wall,q,uv,shade)
       end
      else push(wall,c,{{a,1-low/H},{b,1-low/H},{b,0},{a,0}},shade)end
      panels=panels+1
     end
    end
   end
  end
 end end
 return{map=map,ox=entry.ox,oy=entry.oy,class='cave',material=family,
  wallGroups={wall},wallVertices=wall.vertices,wallIndices=wall.indices,
  groundVertices={},groundIndices={},foregroundVertices={},foregroundIndices={},
  ceilingVertices=roof.vertices,ceilingIndices=roof.indices,
  ceilingFamily='interior_ceiling',ceilingTextureFamily=family,
  ceilingTexture=atlas,
  quads=quads,shellHeight=H,caveBoundaryPanels=panels,wallDistance=0}
end
return M
