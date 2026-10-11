-- The independent mesh probe found 24 phantom-support samples in the aisles.
local M=assert(loadfile('lib/KascSeviiScenery.lua')){data=function()return{}end}
local profile={kind='room',theme='game_corner',source='TwoIsland_JoyfulGameCorner',props={}}
M.profile=function()return profile,{[0]='G'}end
M.token=function()return'G'end
local map={id='TEST',def={width=6,height=4},tileAt=function()return 0 end}
local P={models={},decorColors=setmetatable({},{__index=function()return 1 end}),setting={get=function()return true end}}
local props=M.find(P,map);assert(#props==1)
local model=P.models[props[1].kind];assert(type(model.support)=='function'and model.actorSurface)
local points=0
for z=0,47 do for x=0,127 do
 local wx,wz=x+.5,z+.5;local actual=false
 for _,b in ipairs(model.boxes)do
  if b[2]+b[5]==14 and wx>=b[1]and wx<b[1]+b[4]and wz>=b[3]and wz<b[3]+b[6]then actual=true end
 end
 assert((model.support(wx,wz)==14)==actual,'counter support disagrees with physical countertop')
 points=points+1
end end
for _,point in ipairs{{8,24},{40,24},{56,24},{72,8},{72,24},{88,24},{104,24},{8,40}}do
 assert(model.support(unpack(point))==nil,'original aisle raised into the air')
end
assert(model.support(-1,8)==nil and model.support(128,8)==nil and model.support(24,48)==nil)
print('PASS actual U-shaped countertop support: '..points..' points, eight original aisle/rear-gap cells, bounded model')
