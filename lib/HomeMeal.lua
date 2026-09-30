-- Decoration follows the native scripted heal; it never heals, teleports or
-- changes the dialogue. A new save/map clears the short-lived dinner scene.
local V=...
local M={}
function M.afterHeal(ctx)
 local ow=ctx and ctx.overworld
 if ow and ow.map and ow.map.id=='REDS_HOUSE_1F'and ctx.save then
  M.save=ctx.save;M.map=ow.map;M.remaining=180
 end
end
function M.update(dt,game)
 if not M.save then return end
 local ow=game and game.overworld
 if not ow or game.save~=M.save or ow.map~=M.map then
  M.save,M.map,M.remaining=nil,nil,nil;return
 end
 if game.stack:top()==ow then M.remaining=math.max(0,M.remaining-math.max(0,math.min(.1,dt or 0)))end
 if M.remaining==0 then M.save,M.map=nil,nil end
end
function M.install()
 local C=require('src.script.Commands')
 if C._vascHomeMeal then return end
 C._vascHomeMeal=true
 local heal=C.heal_party
 function C.heal_party(ctx,...)
  local value=heal(ctx,...);M.afterHeal(ctx);return value
 end
end
local registered
function M.drawProps(state)
 if not(M.map and state and state.map==M.map)then return end
 local P=V.require('VoxelItems')
 if not registered then
  local boxes={}
  local function b(x,y,z,w,h,d,c)boxes[#boxes+1]={x,y,z,w,h,d,c}end
  for _,x in ipairs{7,24}do
   -- Round plates, warm soup, cutlery and a small drinking cup. The original
   -- central flower vase remains unobstructed.
   for dx=-3,3 do for dz=-3,3 do if dx*dx+dz*dz<=10 then
    b(x+dx,10.15,16+dz,1,.45,1,4)
    if dx*dx+dz*dz<=4 then b(x+dx,10.6,16+dz,1,.45,1,11)end
   end end end
   b(x-5,10.2,13,.45,.25,6,14);b(x+5,10.2,13,.45,.25,6,14)
   b(x-1.5,10.1,22,3,3,3,7);b(x-.8,13.1,22.7,1.6,.2,1.6,3)
  end
  P.models.home_meal={boxes=boxes,directBoxes=true,frameW=32,frameH=64,depth=32,offsetY=-32}
  registered=true
 end
 local F=V.require('VoxelFurniture')
 for _,p in ipairs(F.find(M.map))do if p.kind=='dining_table'and p.claimed and F.enabled(p)then
  local mesh,texture=P.resolveKind('home_meal')
  if mesh then F.drawProp(mesh,texture,V.require('Mat4').translate(p.tx*8,0,p.ty*8),1)end
  return
 end end
end
return M
