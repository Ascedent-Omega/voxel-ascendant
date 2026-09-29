-- Calendar props share the reviewed non-walkable placements with October.
local V=...
local C=V.require('CalendarEvents')
local M={}
local registered
local function register()
 if registered then return end;registered=true
 local P=V.require('VoxelItems')
 local function add(id,boxes)
  P.models['festival_'..id]={boxes=boxes,directBoxes=true,frameW=16,frameH=24,depth=16,offsetY=-8}
 end
 add('spring',{{-4,0,-3,8,3,6,P.decorColors.clay},{-3,3,-2,6,1,4,12},
  {-2,4,0,1,6,1,12},{2,4,-1,1,4,1,12},
  {-4,9,-1,5,2,3,15},{-3,8,-1,3,4,3,15},{-2,9,2,1,1,.2,11},
  {0,7,-2,5,2,3,7},{1,6,-2,3,4,3,7},{2,7,1,1,1,.2,11}})
 add('summer',{{-3,0,-3,6,1,6,3},{-.6,1,-.6,1.2,17,1.2,3},
  {-4,17,-1,8,1,2,3},{-3,11,-2.5,6,5,5,15},{-2,10,-2,4,1,4,11},
  {-2,16,-2,4,1,4,11},{-.25,8,0,.5,2,.5,5}})
 add('winter',{{-3,0,-3,6,4,6,2},{-4,4,-4,8,5,8,2},{-3,9,-3,6,5,6,4},
  {-2,12,3,1,1,.3,3},{1,12,3,1,1,.3,3},{-.5,10.5,3,1,1,2,15},
  {-3,9,-3.1,6,1,6.2,5},{-4,14,-4,8,1,8,3},{-2,15,-2,4,3,4,3},
  {-7,0,-2,4,4,5,5},{-5.5,0,-2.1,1,4.2,5.2,11},{-7,4,-.2,4,.3,1,11}})
 add('summer_glow',{{-2.8,11.2,2.55,5.6,4.6,.1,11},{-2.8,11.2,-2.65,5.6,4.6,.1,11}})
end
function M.event()
 for _,id in ipairs{'spring','summer','winter'}do if C.active(id)then return id end end
end
function M.each(state,visit)
 local id=M.event();if not id then return end
 V.require('Halloween').eachPumpkin(state,function(x,y,z,p,map)visit(id,x,y,z,p,map)end,id)
end
function M.draw(state)
 if not M.event()then return end
 register();local P=V.require('VoxelItems');local G=V.require('Voxel3D');local Mat=V.require('Mat4')
 M.each(state,function(id,x,y,z)
  local mesh,tex=P.resolveKind('festival_'..id);local mat=Mat.translate(x,y,z)
  if mesh then G.draw(mesh,tex,mat,0)end
  if id=='summer'then
   local glow,t=P.resolveKind('festival_summer_glow')
   if glow then G.flatten({1,.64,.24},.7);local ok,err=pcall(G.draw,glow,t,mat,0);G.flatten(nil);if not ok then error(err)end end
  end
 end)
end
function M.lights(state,sources)
 if not C.active('summer')then return end
 M.each(state,function(id,x,y,z,p)
  sources[#sources+1]={x=x,y=y+13,z=z+3,normal={0,0,1},radius=40,
   power=.15+.65*V.require('DayNight').windowLight(),color={1,.56,.16},owner=p,kind='festival-lantern'}
 end)
end
return M
