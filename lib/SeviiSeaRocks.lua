-- Round authored ocean rocks, with live surrounding water beneath them.
local M={}
local function key(x,y)return(y+64)*4096+x+64 end
function M.waterAt(S,tx,ty,w,h)
 for radius=1,6 do
  for y=ty-radius,ty+h-1+radius do for x=tx-radius,tx+w-1+radius do
   local s=S.shapeAt[key(x,y)]
   if s and s.class=='water'then return{tx=x,ty=y,h=s.h or -2,tile=S.tileAt[key(x,y)]}end
  end end
 end
end
function M.kind(P,variant,w,h)
 local name='sevii_sea_rock_'..variant..'_'..w..'_'..h
 if P.models[name]then return name end
 local source=assert(P.models['kanto_plateau_rock_'..variant])
 local model={};for k,v in pairs(source)do model[k]=v end
 model.w=w;model.h=h;model.boxes={};model.waterUnderlay=true
 for i,box in ipairs(source.boxes)do
  local b={unpack(box)};b[1]=b[1]*w/16;b[3]=b[3]*h/16
  b[4]=b[4]*w/16;b[6]=b[6]*h/16;model.boxes[i]=b
 end
 P.models[name]=model;return name
end
return M
