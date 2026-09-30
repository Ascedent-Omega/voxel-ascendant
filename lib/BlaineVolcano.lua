-- VASC presentation of KASC's explicitly authored Blaine route. Native
-- map cells, script triggers, quiz flags, trainer identity and battle stay KASC's.
local V=...
local B={}
local specs={
 KA_BLAINE_GYM_TUNNEL={kind='tunnel',tileset='FACILITY',w=24,h=7},
 KA_BLAINE_VOLCANO_FOOT={kind='foot',tileset='KA_MOLTRES_VOLCANO_67',w=16,h=12},
 KA_BLAINE_VOLCANO_GYM={kind='arena',tileset='KA_BLAINE_VOLCANO_ARENA',w=24,h=18},
}
function B.profile(map)
 local d=map and map.def;local s=d and specs[map.id or d.id]
 if not(s and d.generation~=2 and d.kaOwner=='kasc.blaine-volcano-route/v1'
  and d.tileset==s.tileset and d.width==s.w and d.height==s.h)then return end
 if s.kind=='arena'then
  local a=d.kaArenaGeometry
  if not(a and a.platform and a.bridge and a.kind=='suspended-over-lava')then return end
  local p,r=a.platform,a.bridge
  local legacy=a.version==1 and p.x==8 and p.y==6 and p.width==32 and p.height==24
    and r.x==22 and r.y==30 and r.width==4 and r.height==4
  local compact=a.version==2 and p.x==16 and p.y==10 and p.width==18 and p.height==12
    and r.x==24 and r.y==22 and r.width==2 and r.height==8
  local narrow=a.version==3 and p.x==18 and p.y==10 and p.width==14 and p.height==12
    and r.x==24 and r.y==22 and r.width==2 and r.height==8
  if not(legacy or compact or narrow)then return end
 end
 return s.kind
end
local battleCourt={x=21,y=14,shape='blaine_center',cam='blaine_lava',adaptive=false,surface='land'}
function B.battleCourt(map)
 if B.profile(map)=='arena'and map.def.kaArenaGeometry.version>=2 then return battleCourt end
end
local function model(P,name,w,d,height)
 local m={terrain=false,boxes={},step=1,directBoxes=true,frameW=w,
  frameH=d+height,depth=d,offsetY=-height,replacesGround=true,groundAt=function()return nil end}
 P.models[name]=m
 local function box(x,y,z,bw,bh,bd,c)
  if bw>0 and bh>0 and bd>0 then m.boxes[#m.boxes+1]={x,y,z,bw,bh,bd,c}end
 end
 return m,box
end
local function rail(box,x,z,length,along,C)
 local function b(a,y,w,h,d,c)
  if along then box(x+a,y,z,w,h,d,c)else box(x,y,z+a,d,h,w,c)end
 end
 b(0,10,length,2,2,C.silver);b(0,4,length,1,1,C.navy)
 for at=0,length-1,32 do b(at,0,2,11,2,C.silver)end
end
local function arena(P,name,map)
 local C=P.decorColors;local m,b=model(P,name,768,576,144)
 -- A room foundation must never be hidden as one oversized foreground prop.
 m.sightFoundation=true
 local a=map.def.kaArenaGeometry;local p,r=a.platform,a.bridge
 local x0,z0,x1,z1=p.x*16,p.y*16,(p.x+p.width)*16,(p.y+p.height)*16
 local bx,bz,bw,bd=r.x*16,r.y*16,r.width*16,r.height*16
 b(0,-44,0,768,4,576,C.oldBeam)
 b(x0,-8,z0,x1-x0,7,z1-z0,C.navy);b(bx,-8,bz,bw,7,bd,C.navy)
 for z=z0,z1-1,32 do for x=x0,x1-1,32 do
  b(x,-1,z,math.min(32,x1-x),1,math.min(32,z1-z),C.slate)
  b(x+1,-.05,z+1,math.min(30,x1-x-1),.1,1,C.navy)
 end end
 for z=bz,bz+bd-1,8 do b(bx,-1,z,bw,1,8,C.stone);b(bx+2,.02,z+1,bw-4,.06,1,C.silver)end
 -- A recognisable 3:2 battle court: perimeter, halves and stepped Pokeball.
 local white=4;local cx,cz=(x0+x1)/2,(z0+z1)/2
 b(x0+16,.12,z0+16,x1-x0-32,.12,2,white);b(x0+16,.12,z1-18,x1-x0-32,.12,2,white)
 b(x0+16,.12,z0+16,2,.12,z1-z0-32,white);b(x1-18,.12,z0+16,2,.12,z1-z0-32,white)
 b(x0+16,.12,cz-1,x1-x0-32,.12,2,white)
 local radius=a.version>=2 and 36 or 24
 for z=-radius,radius-2,2 do for x=-radius,radius-2,2 do
  local d=(x+1)^2+(z+1)^2
  if d>=(radius-4)^2 and d<=radius^2 then b(cx+x,.14,cz+z,2,.12,2,white)
  elseif d<(radius-4)^2 then b(cx+x,.13,cz+z,2,.1,2,z<0 and C.clay or C.stone)end
 end end
 b(cx-6,.26,cz-6,12,.1,12,C.navy);b(cx-3,.38,cz-3,6,.1,6,white)
 rail(b,x0-3,z0-3,x1-x0+6,true,C)
 rail(b,x0-3,z0-2,z1-z0+4,false,C);rail(b,x1+1,z0-2,z1-z0+4,false,C)
 rail(b,x0-3,z1+1,bx-x0+3,true,C);rail(b,bx+bw,z1+1,x1-bx-bw+3,true,C)
 rail(b,bx-3,bz+2,bd-2,false,C);rail(b,bx+bw+1,bz+2,bd-2,false,C)
 for _,q in ipairs{{x0-8,z0-8},{x1+8,z0-8},{x0-8,z1+8},{x1+8,z1+8}}do
  local x,z=q[1],q[2]
  b(x-5,-10,z-5,10,12,10,C.navy);b(x-6,0,z-6,12,3,12,C.silver)
  for y=4,124,8 do
   b(x-3,y,z-1,2,7,2,C.silver);b(x+1,y,z-1,2,7,2,C.silver)
   if y%16==4 then b(x-3,y,z-1,6,2,2,C.stone);b(x-3,y+5,z-1,6,2,2,C.stone)
   else b(x-1,y,z-3,2,2,6,C.stone);b(x-1,y+5,z-3,2,2,6,C.stone)end
  end
  b(x-12,128,z-12,24,10,24,C.oldBeam)
 end
 for z=0,575,32 do for x=0,767,32 do
  if x<32 or x>=736 or z<32 or z>=544 then
   local h=80+(x*3+z*5)%53
   b(x,-40,z,32,h+40,32,C.oldBeam)
   if x==0 then b(28,-30,z+6,12,h+18,18,C.looseRock4)end
   if x==736 then b(726,-30,z+4,12,h+18,20,C.looseRock4)end
   if z==0 then b(x+6,-30,28,18,h+18,12,C.looseRock4)end
   if z==544 and (x<320 or x>=448)then b(x+4,-30,532,20,h+18,16,C.looseRock4)end
  end
 end end
 -- One retained flowing lava surface, below the platform and native actors.
 local lava,lb=model(P,name..'_lava',768,576,1)
 lb(32,-20,32,704,1,512,11);m.blaineLavaKind=name..'_lava'
 -- Four retained low-poly jets; only their transforms change during MAP battles.
 local jet,jb=model(P,name..'_jet',32,32,56)
 for i=0,10 do
  local y=i*4;local w=math.max(2,8-i*.5)
  jb(-w/2,y,-w/2,w,3.5,w,i%3==0 and 1 or 11)
 end
 for side=-1,1,2 do for i=1,8 do
  local x=side*i*2.2;local y=44-i*i*.55
  jb(x-1.3,y,-1.3,2.6,2.6,2.6,i%2==0 and 1 or 11)
 end end
 m.blaineJetKind=name..'_jet'
 m.blaineJets={{x0-32,z0+44},{x1+32,z0+44},{x0-32,z1-44},{x1+32,z1-44}}
 return m
end
local function foot(P,name,map,stairs)
 local C=P.decorColors;local m,b=model(P,name,512,384,112)
 -- Neutral mineral ash and cooled basalt continue the Cinnabar coast. The
 -- actual shared cone is retained by the cancellable panorama build below.
 if stairs then
  b(-128,-7,-128,768,4,448,C.looseRock1)
  b(-128,-7,336,768,4,176,C.looseRock1)
  b(-128,-7,320,368,4,16,C.looseRock1)
  b(256,-7,320,384,4,16,C.looseRock1)
 else b(-128,-7,-128,768,4,640,C.looseRock1)end
 for y=0,23 do for x=0,31 do
  local px,pz=x*16,y*16
  if map:isWalkableCell(x,y)then
   if not(stairs and x==15 and y==20)then b(px,-3,pz,16,3,16,C.looseRock1)end
   if (x*7+y*11)%13==0 then b(px+3,0,pz+5,4,.12,2,3)end
  else
   local hill=x>=8 and x<=21 and y<=11
   local h=hill and 0 or (3+(x*7+y*11)%8)
   local mouth=x>=14 and x<=16 and y>=10 and y<=11
   local bottom=mouth and 49 or -8
   if h>bottom then b(px,bottom,pz,16,h-bottom,16,3)end
   if not mouth and not hill then b(px+3,h-2,pz+3,10,3,10,C.hauntedMortar)end
  end
 end end
 -- The tunnel sits in a low basalt spur of the same mountain, not a facade.
 b(226,0,24,8,44,132,3);b(264,0,24,8,44,132,3)
 b(228,40,20,40,8,136,C.hauntedMortar);b(236,48,18,24,6,130,3)
 b(220,5,142,8,26,14,3);b(272,3,143,8,30,14,3)
 b(234,0,143,30,40,1,3)
 for z=190,205,5 do b(236,.05,z,26,.12,2,C.looseRock1)end
 if not stairs then
  b(236,.02,320,26,.1,16,C.navy)
  for z=322,333,3 do b(238,.15,z,22,.12,1,C.silver)end
 end
 return m
end
-- A close approach to a mountain needs world-sized relief, not a miniature
-- fitted into the room. Keep the shared shape at 16 times the rc.10 scale;
-- its nearest slope stays north of every native walkable approach cell.
B.ENTRANCE_SCALE=8
function B.horizon(map)
 return B.profile(map)=='foot' and V.require('VoxelItems').setting:get()
end
function B.buildHorizon(entry,yieldStep,owned)
 local c,s=math.cos(.18),math.sin(.18)
 return V.require('CinnabarVolcano').meshes(entry.ox or 0,entry.oy or 0,0,yieldStep,owned,{
  transform=function(x,y,z)
   local dx,dz=x+700,z-144;local scale=B.ENTRANCE_SCALE
   return 248+(s*dx-c*dz)*scale,(y-5)*scale,80+(c*dx+s*dz-492)*scale
  end,coneOnly=true})
end
local function tunnel(P,name,map)
 local C=P.decorColors;local m,b=model(P,name,768,224,44)
 -- Existing checkerboard and stair artwork remain native. Add physical
 -- services, rail brackets and lamps above the occupied room boundary.
 for _,z in ipairs{46,176}do
  b(64,29,z,640,4,4,C.navy);b(64,30,z,640,2,2,C.silver)
  b(64,36,z+4,640,2,2,C.walnut)
  for x=64,703,48 do b(x,27,z-1,3,9,7,C.stone)end
 end
 for x=96,672,96 do
  b(x,25,48,12,6,3,C.navy);b(x+2,26,51,8,3,1,11)
 end
 return m
end
function B.find(P,map)
 local kind=B.profile(map);if not kind then return{}end
 local stairs=kind=='foot'and map.def.kaBlaineStairs and V.require('Gen1Stairs').setting:get()and V.require('Gen1Stairs').scripted(map)~=nil
 local name='blaine_'..kind..'_v'..(kind=='arena'and map.def.kaArenaGeometry.version or 1)
 if stairs then name=name..'_stairs'end
 if not P.models[name]then
  local m=({arena=arena,foot=foot,tunnel=tunnel})[kind](P,name,map,stairs)
  -- Keep the native foundation under the enclosing basalt. Besides grounding
  -- the shell this leaves a real terrain mesh for the atomic scene reveal.
  if kind~='tunnel'then m.groundAt=function(x,z)
   if x<16 or z<16 or x>=map.def.width*32-16 or z>=map.def.height*32-16 then
    if kind=='foot'then return map:tileAt(30,36)end
    return map:tileAt(math.floor(x/8),math.floor(z/8))
   end
  end end
 end
 local result={{kind=name,tx=0,ty=0,w=map.def.width*4,h=map.def.height*4,
  keepTerrain=kind=='tunnel',voxelOnly=true,enabled=function()return P.setting:get()end}}
 if kind~='tunnel'then
  local vent=kind=='foot'and 'blaine_foot_ember_vent'or 'blaine_ember_vent'
  if not P.models[vent]then
   local c=P.decorColors;local h=kind=='foot'and 10 or 5
   local vm,vb=model(P,vent,16,16,h+8)
   vb(0,-20,0,16,h+20,16,kind=='foot'and 3 or c.oldBeam);vb(3,h,3,10,1,10,1);vb(5,h+1,5,6,1,6,11)
   vb(6,h-10,15.8,2,10,.2,11)
   vm.lightSource={position={8,h+8,8},normal={0,1,0},radius=128,power=1.6,color={1,.25,.045},kind='ember'}
  end
  local places
  if kind=='arena'then
   local p=map.def.kaArenaGeometry.platform
   places={{p.x*2-5,p.y*2+6},{(p.x+p.width)*2+3,p.y*2+6},
    {p.x*2-5,(p.y+p.height)*2-8},{(p.x+p.width)*2+3,(p.y+p.height)*2-8}}
  else places={{10,28},{44,28}}end
  for _,q in ipairs(places)do
   if kind=='foot'then
    local step=q[1]<map.def.width*2 and -2 or 2
    while q[1]>=2 and q[1]<map.def.width*4-2 and map:isWalkableCell(q[1]/2,q[2]/2)do q[1]=q[1]+step end
   end
   result[#result+1]={kind=vent,tx=q[1],ty=q[2],w=2,h=2,keepTerrain=true,
   voxelOnly=true,enabled=function()return P.setting:get()end}end
 end
 return result
end
function B.prepare(P,model)
 if model and model.blaineJetKind then P.resolveKind(model.blaineJetKind)end
 return not(model and model.blaineLavaKind)or P.resolveKind(model.blaineLavaKind)~=nil
end
function B.draw(state,P,G,Mat)
 if B.profile(state.map)~='arena'or not P.setting:get()then return end
 local name='blaine_arena_v'..state.map.def.kaArenaGeometry.version
 local model=P.models[name]
 if not model then return end
 local claimed=false
 for _,p in ipairs(V.require('VoxelFurniture').find(state.map))do
  if p.kind==name and p.claimed then claimed=true;break end
 end
 if not claimed then return end
 local mesh,texture=P.resolveKind(model.blaineLavaKind)
 if mesh then
  G.magma(true);G.draw(mesh,texture,Mat.translationFor(model,0,0,0),0);G.magma(false)
 end
end
function B.drawBattleFountains(map)
 if B.profile(map)~='arena'then return end
 local P=V.require('VoxelItems');if not P.setting:get()then return end
 local m=P.models['blaine_arena_v'..map.def.kaArenaGeometry.version]
 if not(m and m.blaineJetKind)then return end
 local mesh,texture=P.resolveKind(m.blaineJetKind);if not mesh then return end
 local G,Mat=V.require('Voxel3D'),V.require('Mat4')
 local t=love.timer.getTime()
 G.magma(true)
 local ok,reason=pcall(function()
  for i,p in ipairs(m.blaineJets)do
   local phase=(t*.23+(i-1)*.27)%1
   local height=math.sin(math.pi*phase)^2
   if height>.025 then
    local matrix=Mat.mul(Mat.translate(p[1],-19,p[2]),Mat.scale(.8+height*.2,height,1))
    G.draw(mesh,texture,matrix,0)
   end
  end
 end)
 G.magma(false)
 if not ok then error(reason)end
end
local mist={color={.38,.22,.18},density=.009,height=52}
function B.atmosphere(map)local k=B.profile(map);return k=='foot'or k=='arena'end
function B.mist(map)if B.atmosphere(map)then return mist end end
return B
