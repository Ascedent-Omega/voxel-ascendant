-- One stable door colour per destination, shared by both sides of its warp.
local M={}
M.colors={walnut={99,70,54},oak={177,137,88},clay={171,85,62},
 roofGreen={69,105,86},navy={40,62,85},slate={80,102,118}}
local variants={'walnut','oak','clay','roofGreen','navy','slate'}
local authored={REDS_HOUSE_1F='walnut',BLUES_HOUSE='slate',OAKS_LAB='oak',
 VIRIDIAN_NICKNAME_HOUSE='clay',VIRIDIAN_SCHOOL_HOUSE='roofGreen'}
function M.variant(id)
 if authored[id]then return authored[id]end
 local hash=0;for i=1,#tostring(id or'')do hash=(hash*31+tostring(id):byte(i))%997 end
 return variants[hash%#variants+1]
end
function M.material(id)return 'room_wood_door:'..M.variant(id)end
function M.exterior(P,box,id,width,height)
 local C=P.decorColors;local color=C[M.variant(id)]or C.walnut or 3
 local half=width/2;local dark=C.oldBeam or C.walnut or 3
 -- A single continuous slab, two recessed panels, one off-centre handle.
 box(-half,2,2,width,height,1,color)
 for _,p in ipairs{{4,6},{12,7}}do
  box(2-half,p[1],3,width-4,p[2],1,dark)
  box(3-half,p[1]+1,4,width-6,p[2]-2,1,color)
 end
 box(half-3,10,4,1,2,1,dark)
 box(half-4,11,5,3,1,1,11)
end
return M
