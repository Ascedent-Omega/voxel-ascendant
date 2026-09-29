-- Silph's two native pool lobes, visual only. No collision, warp or map writes.
local V=...
local M={centers={{208,112},{304,112}},frames=16}
function M.matches(map)
 local d=map and map.def
 if not(d and map.id=='SILPH_CO_1F'and d.generation~=2 and d.tileset=='FACILITY'
  and d.width==15 and d.height==9 and map.tileAt and map.isWaterCell)then return false end
 for _,p in ipairs(M.centers)do
  local x,y=p[1]/16-1,p[2]/16-1
  for dy=0,1 do for dx=0,1 do
   if not map:isWaterCell(x+dx,y+dy)then return false end
  end end
  if map:tileAt(x*2,y*2)~=20 then return false end
 end
 return true
end
local function rim(map,x,y)
 return map:tileAt(x,y)==9 and map:tileAt(x+1,y)==10
  and map:tileAt(x,y+1)==25 and map:tileAt(x+1,y+1)==26
end
function M.rimKind(P,map,x,y)
 if not M.matches(map)then return 'fountain_rim'end
 local n,e,s,w=rim(map,x,y-2),rim(map,x+2,y),rim(map,x,y+2),rim(map,x-2,y)
 local id='silph_coping_'..((n and 1 or 0)+(e and 2 or 0)+(s and 4 or 0)+(w and 8 or 0))
 if P.models[id]then return id end
 local boxes={}
 local function occupied(px,pz,inset)
  if (not w and px<inset)or(not e and px>=16-inset)
   or(not n and pz<inset)or(not s and pz>=16-inset)then return false end
  for _,c in ipairs{{not w and not n,4,4},{not e and not n,12,4},
    {not w and not s,4,12},{not e and not s,12,12}}do
   if c[1]and(px-c[2])*(c[2]==4 and -1 or 1)>0
    and(pz-c[3])*(c[3]==4 and -1 or 1)>0
    and(px-c[2])^2+(pz-c[3])^2>(4-inset)^2 then return false end
  end
  return true
 end
 -- Joined tops have no repeated dark inset squares. Round only exposed corners.
 for layer=0,1 do for z=0,15 do
  local start
  for x=0,16 do
   local filled=x<16 and occupied(x+.5,z+.5,layer*.5)
   if filled and not start then start=x end
   if start and not filled then
    boxes[#boxes+1]={start,layer==0 and 0 or 3,z,x-start,layer==0 and 3 or 1,1,layer==0 and P.decorColors.silver or 2};start=nil
   end
  end
 end end
 P.models[id]={boxes=boxes,frameW=16,frameH=48,depth=16,offsetY=-32,support=4}
 return id
end
function M.spray(phase)
 local boxes={}
 local function drop(x,y,z,size,c)
  boxes[#boxes+1]={x-size/2,y,z-size/2,size,size*1.3,size,c or 14}
 end
 -- Eight thin parabolic streams. Bright moving beads reveal the flow;
 -- separated droplets at the crown avoid a solid white tower.
 for arm=0,7 do
  local a=arm*math.pi/4;local ca,sa=math.cos(a),math.sin(a)
  for j=0,15 do
   local t,u=j/16,(j+1)/16
   local r=1+10*(t+u)/2
   local y0,y1=1+46*t*(1-t)-3*t,1+46*u*(1-u)-3*u
   boxes[#boxes+1]={ca*r-.28,math.min(y0,y1),sa*r-.28,.56,math.abs(y1-y0)+.35,.56,
    (j+math.floor(phase*16))%5<2 and 4 or 14}
  end
 end
 boxes[#boxes+1]={-.35,0,-.35,.7,17,.7,14}
 for j=0,13 do
  local t=(j+phase)/14
  local y=20*(1-(2*t-1)^2)
  drop(math.sin(j*2.4)*(.5+t*1.3),y,math.cos(j*2.4)*(.5+t*1.3),.45,j%3==0 and 7 or 4)
 end
 -- Broken expanding impact rings lie just above the native -2 water surface.
 for ring=0,1 do
  local r=6+((phase+ring*.5)%1)*7
  for j=0,15 do local a=j*math.pi/8
   boxes[#boxes+1]={math.cos(a)*r-.45,-1.4,math.sin(a)*r-.45,.9,.15,.9,14}
  end
 end
 return boxes
end
local registered=false
local function models(P)
 if registered then return end
 P.models.silph_fountain_nozzle={directBoxes=true,boxes={
  {-4,-2,-3,8,1,6,P.decorColors.silver},{-3,-1,-4,6,1,8,P.decorColors.silver},
  {-2,-1,-2,4,1,4,14},{-1,0,-1,2,1,2,7}}}
 for f=0,M.frames-1 do
  P.models['silph_spray_'..f]={directBoxes=true,boxes=M.spray(f/M.frames)}
 end
 registered=true
end
-- All sixteen animation frames share the ordinary prop cache. Decode/upload
-- them in bounded update slices, never when a new animation phase is drawn.
local warm,version,failed,preparedMeshes,preparedTexture
local function active(map)
 return M.matches(map) and V.require('VoxelItems').setting:get()
end
local function refresh()
 local current=V.require('VoxelItems').resourceVersion or 0
 if version~=current then
  warm,failed,preparedMeshes,preparedTexture=nil,nil,nil,nil;version=current
 end
end
function M.prepared(map)
 if not active(map)then return true end
 refresh();return failed==true or preparedMeshes~=nil
end
function M.prepare(map,covered)
 if not active(map)then return true end
 refresh();if failed or preparedMeshes then return true end
 local P=V.require('VoxelItems');models(P)
 if not warm then warm=coroutine.create(function()
  local meshes,texture={}
  for f=-1,M.frames-1 do
   local kind=f==-1 and 'silph_fountain_nozzle' or 'silph_spray_'..f
   local mesh,tex=P.resolveKind(kind)
   assert(mesh,'fountain resource failed: '..kind)
   meshes[kind],texture=mesh,tex
   coroutine.yield()
  end
  preparedMeshes,preparedTexture=meshes,texture
 end)end
 local budget=V.require('BuildBudget')
 budget.begin(warm,covered and .002 or .0005)
 local ok,err=coroutine.resume(warm);budget.finish()
 if not ok then M.lastError=tostring(err);failed=true;warm=nil
 elseif coroutine.status(warm)=='dead'then warm=nil end
 return failed==true or preparedMeshes~=nil
end
function M.draw(state)
 M.lastCount=0
 local map=state and state.map
 if not M.matches(map)then return end
 local P=V.require('VoxelItems');if not P.setting:get()then return end
 refresh();if not preparedMeshes then return end
 local G,Mat=V.require('Voxel3D'),V.require('Mat4')
 local frame=math.floor((V.require('Weather').clock or 0)*12)%M.frames
 for i,p in ipairs(M.centers)do
  local transform=Mat.translate(p[1],0,p[2])
  for _,kind in ipairs{'silph_fountain_nozzle','silph_spray_'..((frame+(i-1)*7)%M.frames)}do
   local mesh=preparedMeshes[kind]
   if mesh then G.draw(mesh,preparedTexture,transform,0)end
  end
  M.lastCount=M.lastCount+1
 end
end
return M
