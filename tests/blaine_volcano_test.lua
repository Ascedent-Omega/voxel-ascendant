local enabled=true
local colors=setmetatable({},{__index=function()return 4 end})
local P={models={},decorColors=colors,setting={get=function()return enabled end},resolveKind=function(k)return k end}
local B=assert(loadfile('lib/BlaineVolcano.lua')){require=function(name)assert(name=='VoxelItems');return P end}
local function map(id,t,w,h)
 return{id=id,def={tileset=t,width=w,height=h,kaOwner='kasc.blaine-volcano-route/v1'},
 isWalkableCell=function(_,x,y)return x>=6 and x<26 and y>=13 and y<20 end,tileAt=function()return 25 end}
end
local a=map('KA_BLAINE_VOLCANO_GYM','KA_BLAINE_VOLCANO_ARENA',24,18)
assert(not B.profile(a),'missing geometry must fail closed')
a.def.kaArenaGeometry={version=1,kind='suspended-over-lava',platform={x=8,y=6,width=32,height=24},bridge={x=22,y=30,width=4,height=4}}
assert(B.profile(a)=='arena')
local props=B.find(P,a);local m=P.models[props[1].kind]
assert(m and #props==5 and B.prepare(P,m))
local regions={{128,96,640,480},{352,480,416,544}}
for _,b in ipairs(m.boxes)do
 assert(b[4]>0 and b[5]>0 and b[6]>0)
 if b[2]<32 and b[2]+b[5]>.5 then for _,r in ipairs(regions)do
  assert(b[1]+b[4]<=r[1]or b[1]>=r[3]or b[3]+b[6]<=r[2]or b[3]>=r[4], 'decoration blocks native platform/bridge')
 end end
end
assert(m.groundAt(0,0)==25 and m.groundAt(384,400)==nil)
local lava=P.models[m.blaineLavaKind];assert(#lava.boxes==1 and lava.boxes[1][2]+lava.boxes[1][5]<-16)
assert(B.find(P,a)[1].kind==props[1].kind)
enabled=false;assert(not props[1].enabled());enabled=true
for _,field in ipairs{'width','kaOwner','tileset'}do local old=a.def[field];a.def[field]='other';assert(#B.find(P,a)==0);a.def[field]=old end
a.def.kaArenaGeometry.bridge.width=3;assert(not B.profile(a));a.def.kaArenaGeometry.bridge.width=4
a.def.generation=2;assert(not B.profile(a));a.def.generation=nil
local f=map('KA_BLAINE_VOLCANO_FOOT','KA_MOLTRES_VOLCANO_67',16,12)
local fp=B.find(P,f)[1];assert(fp and not fp.keepTerrain)
assert(B.horizon(f)and not B.horizon(a));enabled=false;assert(not B.horizon(f));enabled=true
assert(not B.horizon({id=f.id,def={}}),'unowned map claimed by panorama')
for _,b in ipairs(P.models[fp.kind].boxes)do if b[2]+b[5]>.5 then
 for y=13,19 do for x=6,25 do
  assert(b[1]+b[4]<=x*16 or b[1]>=(x+1)*16 or b[3]+b[6]<=y*16 or b[3]>=(y+1)*16,'blocked foot walkable cell')
 end end
end end
local t=map('KA_BLAINE_GYM_TUNNEL','FACILITY',24,7)
assert(B.find(P,t)[1].keepTerrain,'service corridor must retain native stairs/equipment')
assert(B.install==nil and B.onStep==nil and B.draw2D==nil)
print('PASS Blaine exact map/geometry ownership, unobstructed platform/bridge/foot, native terrain foundation, recessed lava, setting rollback and unchanged gameplay ownership')

local gym=assert(loadfile('lib/Gen1GymInteriors.lua'))()
local cinnabar={id='CINNABAR_GYM',def={tileset='FACILITY',width=10,height=9,warps={{x=16,y=17,destMap='CINNABAR_ISLAND'},{x=17,y=17,destMap='CINNABAR_ISLAND'}}}}
assert(gym.exitDoor(cinnabar))
for _,w in ipairs(cinnabar.def.warps)do w.destMap='LAST_MAP'end;assert(gym.exitDoor(cinnabar))
cinnabar.def.warps[2].destMap='OTHER';assert(not gym.exitDoor(cinnabar))
print('PASS explicit KASC Cinnabar exit, legacy LAST_MAP and malformed-pair guard')

a.def.kaArenaGeometry={version=2,kind='suspended-over-lava',platform={x=16,y=10,width=18,height=12},bridge={x=24,y=22,width=2,height=8}}
assert(B.profile(a)=='arena');local compact=B.find(P,a);assert(compact[1].kind=='blaine_arena_v2')
local fields={{256,160,544,352},{384,352,416,480}}
for _,prop in ipairs(compact)do for _,b in ipairs(P.models[prop.kind].boxes)do
 if b[2]<32 and b[2]+b[5]>.5 then for _,r in ipairs(fields)do
  local x,z=prop.tx*8+b[1],prop.ty*8+b[3]
  assert(x+b[4]<=r[1]or x>=r[3]or z+b[6]<=r[2]or z>=r[4],'compact court or bridge blocked')
 end end
end end
assert(B.atmosphere(a)and B.mist(a));assert(B.atmosphere(f));assert(not B.atmosphere(t))
print('PASS compact 3:2 field, retained legacy contract, clear native lanes and bounded volcanic atmosphere')
