-- Settled snow bridges small native outdoor ledges. The map and its collision
-- tables stay immutable. Only the resident map is retained; no travel history.
local V=...
local R={BUILD=.65,THAW=.45}
local current, coat, retained = nil, false, nil
local dirs={up={0,-1},down={0,1},left={-1,0},right={1,0}}
local function key(x,y,w)return y*w+x end
local function release(s)
 if not s then return end
 if s.mesh and s.mesh.release then s.mesh:release()end
 if s.retainedMesh and s.retainedMesh.release then s.retainedMesh:release()end
end
local function eligible(map)
 return map and map.def and V.require('Weather').isOutdoor(map) and map.widthCells and map.heightCells
   and map.widthCells*map.heightCells<=65536
end
local function elevationFor(map)
 return {at=function(_,x,z)return V.require('VoxelScene').groundAt(map,x,z)end}
end
function R.build(map,data,elevation)
 local s={map=map,elevation=elevation,list={},cells={}}
 if not eligible(map)then return s end
 local P=require('src.world.gen2.Permissions');local w,h=map.widthCells,map.heightCells
 local blocked={}
 for _,group in ipairs{map.def.warps or {},map.def.bgEvents or {},map.def.objects or {},map.def.coordEvents or {}}do
  for _,o in ipairs(group)do if o.x and o.y then blocked[key(o.x,o.y,w)]=true end end
 end
 local function safe(x,y)
  return x>0 and y>0 and x<w-1 and y<h-1 and not blocked[key(x,y,w)]
   and not map:isWaterCell(x,y) and not(map.isWarpTileCell and map:isWarpTileCell(x,y))
 end
 local function walk(x,y)return safe(x,y)and map:isWalkableCell(x,y)end
 local components={};local component=0
 local opposites={up='down',down='up',left='right',right='left'}
 local function coll(x,y)return map:cellCollision(x,y)end
 for y=1,h-2 do for x=1,w-2 do local k=key(x,y,w)
  if walk(x,y)and not components[k]then
   component=component+1;local queue={{x,y}};local at=1;components[k]=component
   while at<=#queue do local q=queue[at];at=at+1
    for dir,d in pairs(dirs)do local nx,ny=q[1]+d[1],q[2]+d[2];local nk=key(nx,ny,w)
     if not components[nk]and walk(nx,ny)and P.stepPermitted(coll,q[1],q[2],dir)and P.stepPermitted(coll,nx,ny,opposites[dir])then
      components[nk]=component;queue[#queue+1]={nx,ny}
     end
    end
   end
  end
 end end
 for y=1,h-2 do for x=1,w-2 do
  local facings=P.ledgeFacings(coll(x,y))
  if walk(x,y)and facings then for dir in pairs(facings)do
   local d=dirs[dir];local lx,ly=x+d[1],y+d[2];local tx,ty=x+2*d[1],y+2*d[2];local k=key(lx,ly,w)
   if safe(lx,ly)and walk(tx,ty)and not s.cells[k]and components[key(x,y,w)]==components[key(tx,ty,w)]then
    local high,low=elevation:at(x,y),elevation:at(tx,ty)
    if high>=low and high-low<=6.01 then
     local r={sx=x,sy=y,lx=lx,ly=ly,tx=tx,ty=ty,dx=d[1],dy=d[2],high=high,low=low}
     s.list[#s.list+1]=r;s.cells[k]=r
    end
   end
  end end
 end end
 return s
end
local function within(r,x,z)
 local dx,dz=x-(r.lx*16+8),z-(r.ly*16+8)
 return math.abs(dx*r.dy-dz*r.dx)<=8.01 and math.abs(dx*r.dx+dz*r.dy)<=24.01
end
local function active(r)return coat or r==retained end
local function slope(r,t)
 local peak=math.max(r.high,r.low+1)+.35
 if t< -8 then return r.high+.1+(peak-r.high-.1)*(t+24)/16 end
 if t<8 then return peak end
 return peak+(r.low+.1-peak)*(t-8)/16
end
function R.height(map,x,z)
 if not current or current.map.def~=map.def or (not coat and not retained)then return end
 local w=map.widthCells;local cx,cy=math.floor(x/16),math.floor(z/16)
 local k=key(cx,cy,w);local answer
 -- Only the cell and its four neighbours can support this foot; this stays
 -- constant-time even on a long route with hundreds of authored ledges.
 for i=1,5 do
  local at=i==1 and k or i==2 and k-1 or i==3 and k+1 or i==4 and k-w or k+w
  local r=current.cells[at]
  if r and active(r)and within(r,x,z)then
   local y=slope(r,(x-(r.lx*16+8))*r.dx+(z-(r.ly*16+8))*r.dy)
   answer=answer and math.max(answer,y)or y
  end
 end
 return answer
end
function R.observe(state,amount)
 local map=state.map
 if current and current.map.def~=map.def then release(current);current=nil;coat=false;retained=nil end
 if not eligible(map)then return end
 if not current and amount>=R.BUILD then
  current=R.build(map,{},elevationFor(map))
 end
 if not current then return end
 if amount>=R.BUILD then coat=true elseif amount<R.THAW then coat=false end
 -- Hold the whole bank until the player's body clears it, even if the
 -- weather changes or the coat melts in the middle of a crossing.
 local p=state.player
 if coat then retained=nil
 elseif p then
  local x,z=p.px+8,p.py+8
  if retained and not within(retained,x,z)then retained=nil end
  if not retained then
   local r=current.cells[key(p.cellX,p.cellY,map.widthCells)]
   if r then retained=r end
  end
 end
end
-- nil leaves native collision untouched. Explicit false closes the sides of
-- a snow crossing; true permits only the two safe ends and the lip between.
function R.permission(state,p,x,y)
 if not current or current.map.def~=state.map.def or p~=state.player or p.surfing then return end
 local map=state.map;local w=map.widthCells
 local from=current.cells[key(p.cellX,p.cellY,w)]
 local to=current.cells[key(x,y,w)]
 local r=from or to
 if not r or not active(r)then return end
 if (V.require('VoxelState').level or 0)<=0 and not from then return end
 local function endCell(cx,cy)return (cx==r.sx and cy==r.sy)or(cx==r.tx and cy==r.ty)end
 if (from and not endCell(x,y))or(to and not endCell(p.cellX,p.cellY))then return false end
 for _,e in ipairs(state.entities or {})do if e~=p and not e.passable and ((e.cellX==x and e.cellY==y)or(e.moving and e.targetX==x and e.targetY==y))then return false end end
 if state.npcAt then local npc=state:npcAt(x,y);if npc and not npc.passable then return false end end
 return true
end
local function meshFor(list)
 local verts={}
 local function vertex(r,t,u)
  return {r.lx*16+8+r.dx*t+r.dy*u,slope(r,t),r.ly*16+8+r.dy*t-r.dx*u,0,0,3}
 end
 for _,r in ipairs(list)do
  local stops={-24,-8,8,24}
  for i=1,3 do
   local a,b,c,d=vertex(r,stops[i],-8),vertex(r,stops[i],8),vertex(r,stops[i+1],8),vertex(r,stops[i+1],-8)
   -- two-sided banks survive either camera bearing, including free look.
   for _,v in ipairs{a,b,c,a,c,d,c,b,a,d,c,a}do verts[#verts+1]=v end
  end
 end
 if #verts>0 then return V.require('Voxel3D').newMesh(verts)end
end
local texture
function R.draw(state)
 if not current or current.map.def~=state.map.def or(not coat and not retained)then return end
 local G=V.require('Voxel3D');local mesh
 if coat then current.mesh=current.mesh or meshFor(current.list);mesh=current.mesh
 elseif retained then
  if current.drawRetained~=retained then
   if current.retainedMesh then current.retainedMesh:release()end
   current.retainedMesh=meshFor{retained};current.drawRetained=retained
  end
  mesh=current.retainedMesh
 end
 if not mesh then return end
 if not texture then
  local img=love.image.newImageData(1,1);img:setPixel(0,0,.88,.94,1,1)
  texture=love.graphics.newImage(img);img:release()
 end
 G.draw(mesh,texture)
end
function R.install()
 if R.installed then return end
 V.mod.hooks:wrap('movement.collision',function(next,allowed,ctx)
  local result=next(allowed,ctx)
  local state=require('src.core.Game').world
  if state and ctx and ctx.mover==state.player and (ctx.reason==nil or ctx.reason=='tile')then
   local answer=R.permission(state,ctx.mover,ctx.toX,ctx.toY)
   if answer~=nil then ctx.reason=answer and nil or 'tile';return answer end
  end
  return result
 end)
 local O=require('src.world.gen2.World');local hop=O.tryLedgeJump
 function O:tryLedgeJump(dir)
  local d=dirs[dir]
  if d and R.permission(self,self.player,self.player.cellX+d[1],self.player.cellY+d[2])~=nil then return false end
  return hop(self,dir)
 end
 R.installed=true
end
function R.status()return {count=current and #current.list or 0,active=coat,retained=retained~=nil}end
return R
