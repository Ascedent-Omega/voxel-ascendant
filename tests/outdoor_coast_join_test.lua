-- A neighbouring sea edge must not erase another map's aligned land strip.
local modules={};local V={require=function(k)return assert(modules[k],k)end}
modules.ModSetting={new=function()return{get=function()return'voxel'end}end}
modules.Voxel3D={};modules.HorizonBuildings={selected=function()return false end}
modules.Gen1ForestLandmarks={gates=function()return{}end}
modules.SeasonalTrees={winter=function()return false end}
modules.SpringBlossom={selected=function()return false end}
local H=assert(loadfile(os.getenv('OUTDOOR_HORIZON_SOURCE')or'lib/OutdoorHorizon.lua'))(V)
local function map(id,x,z,w,h)
 return{map={id=id,def={width=w/32,height=h/32}},x0=x,z0=z,x1=x+w,z1=z+h,w=w,h=h,ox=x,oy=z}
end
local r13=map('ROUTE_13',0,0,960,288)
local r14=map('ROUTE_14',-320,0,320,864)
local policies={ROUTE_13={south='open_water',east='open_water'},ROUTE_14={south='open_water',east='open_water'},LAVENDER_TOWN={},ROUTE_12={east='open_water'}}
local horizon={edgeClass=function(m,edge)return policies[m.id][edge]or'rural'end}
local function boxes(maps,full,dx,dz)
 local out={}
 local emit=function(x,y,z,w,h,d)out[#out+1]={x-(dx or 0),y,z-(dz or 0),w,h,d}end
 if full then H.geometry(maps,horizon,emit)else H.shoulders(maps,horizon,emit,nil,208,{})end
 return out
end
local function groundAt(boxes,x,z)
 for _,b in ipairs(boxes)do if x>=b[1]and x<b[1]+b[4]and z>=b[3]and z<b[3]+b[6]and b[2]<=0 and b[2]+b[5]>=0 then return true end end
 return false
end
local a=boxes({r13,r14})
assert(groundAt(a,80,-80),'Route 14 sea cut Route 13 woodland toward Silph')
assert(not groundAt(a,80,400),'Route 14 sea filled with land')
assert(not groundAt(a,400,320),'Route 13 southern sea filled with land')
assert(not groundAt(a,200,80),'resident map body overwritten')
local isolated=boxes({r14})
assert(not groundAt(isolated,80,-80),'isolated sea corner became land')
local full=boxes({r13,r14},true)
local canopy=false
for _,b in ipairs(full)do if b[1]>=0 and b[1]<160 and b[3]>=-160 and b[3]<0 and b[2]+b[5]>30 then canopy=true end end
assert(canopy,'ground filled but Route 13 canopy still missing')
-- A true connection remains a low continuation, never a raised hedge.
local corridor={}
H.shoulders({r13,r14},horizon,function(...)corridor[#corridor+1]={...}end,nil,208,
 {{x0=64,x1=96,z0=-208,z1=0}})
local low=false
for _,b in ipairs(corridor)do
 if 80>=b[1]and 80<b[1]+b[4]and -80>=b[3]and -80<b[3]+b[6]then
  assert(b[2]+b[5]==0,'connection raised above native ground');low=true
 end
end
assert(low,'connection shoulder missing')
-- Lavender's east land strip meets Route 12's east sea at its southeast corner.
local lavender=map('LAVENDER_TOWN',0,0,320,288)
local r12=map('ROUTE_12',0,288,320,1728)
local l=boxes({lavender,r12})
assert(groundAt(l,352,240),'Route 12 sea cut Lavender east panorama')
assert(not groundAt(l,352,400),'Lavender land filled Route 12 sea')
-- Canonical world offsets and map order cannot change the joins.
local shifted=boxes({map('ROUTE_14',1760,2144,320,864),map('ROUTE_13',2080,2144,960,288)},false,2080,2144)
for z=-208,1072,16 do for x=-528,1168,16 do
 assert(groundAt(a,x+8,z+8)==groundAt(shifted,x+8,z+8),'join depends on world origin/order')
end end
print('PASS coast joins: Route 13/Silph, Lavender/Route 12, canopies, resident bodies, open seas, isolated corners and canonical offsets')
