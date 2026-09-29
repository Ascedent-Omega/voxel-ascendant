local enabled=true
local root=arg and arg[1] or '.'
local cells=assert(loadfile(root..'/lib/Gen1StairCells.lua'))()
local V={require=function(name)
 if name=='ModSetting'then return {new=function()return{get=function()return enabled end}end}end
 if name=='Gen1StairCells'then return cells end
 if name=='Gen1InteriorFloors'then return {profile=function()end}end
 if name=='Gen1InteriorPanoramas'then return{profiles={}}end
 if name=='HorizonWall'then return{enabled=function()return false end}end
 error(name)
end}
local stairs=assert(loadfile(root..'/lib/Gen1Stairs.lua'))(V)
local function fixture(id,target,down,cx,cy)
 cx,cy=cx or 12,cy or 1
 local map={id=id,def={id=id,tileset='LOBBY',width=10,height=4,blocks={},warps={{x=cx,y=cy,destMap=target}}},tileset={blocks={}}}
 for i=1,40 do
  map.def.blocks[i]=i-1;local b={};for j=1,16 do b[j]=32 end;map.tileset.blocks[i]=b
 end
 local a=down and {10,11,26,27} or {12,13,28,29}
 for dy=0,1 do for dx=0,1 do
  local x,y=cx*2+dx,cy*2+dy
  local b=map.tileset.blocks[math.floor(y/4)*10+math.floor(x/4)+1]
  b[y%4*4+x%4+1]=a[dy*2+dx+1]
 end end
 return map,{class=down and 'stair_down_w'or'stair_e'},cx,cy
end
local function run(map,s,cx,cy)
 local S={objectQuads={}}
 return stairs.buildStore(S,map,cx,cy,s),S.objectQuads
end
local function id(n)return n==6 and 'CELADON_MART_ROOF'or('CELADON_MART_'..n..'F')end
local counts={}
for from=1,6 do for _,to in ipairs({from-1,from+1})do if to>=1 and to<=6 then
 local m,s,cx,cy=fixture(id(from),id(to),to<from,from==6 and 15 or 12,from==6 and 2 or 1)
 local old=m.def.warps[1].destMap;local ok,q=run(m,s,cx,cy);assert(ok)
 local parts={};local minY,maxY=0,0
 for _,v in ipairs(q)do
  parts[v.storeStair]=(parts[v.storeStair]or 0)+1
  for i=1,4 do local p=v[i]
   assert(p[1]>=cx*16 and p[1]<=(cx+1)*16 and p[3]>=cy*16 and p[3]<=(cy+1)*16,'footprint escaped')
   minY,maxY=math.min(minY,p[2]),math.max(maxY,p[2]);assert(v.uv[i][1]<-128)
  end
  local a,b,c=v[1],v[2],v[3];local ux,uy,uz=b[1]-a[1],b[2]-a[2],b[3]-a[3];local vx,vy,vz=c[1]-a[1],c[2]-a[2],c[3]-a[3]
  assert((uy*vz-uz*vy)^2+(uz*vx-ux*vz)^2+(ux*vy-uy*vx)^2>1e-8,'degenerate quad')
 end
 assert(parts.tread==5 and parts.nosing==5 and parts.riser==5)
 assert(parts.rail==12 and #q<125,'mesh budget')
 if to<from then assert(minY==-8 and maxY<6 and parts['well-end']==1)
 else assert(minY==0 and maxY<18 and parts.back==1)end
 assert(m.def.warps[1].destMap==old and cells.classForWarp(m,m.def.warps[1])==s.class,'native map mutated')
 counts[#counts+1]=#q
end end end
assert(#counts==10)
local function declines(m,s,x,y)local ok,q=run(m,s,x,y);assert(not ok and #q==0,'unsafe model substitution')end
for _,name in ipairs({'GAME_CORNER','CELADON_MANSION_1F','SILPH_CO_ELEVATOR','CELADON_MART_ELEVATOR'})do declines(fixture(name,id(2),false))end
local m,s,x,y=fixture(id(1),id(2),false);m.def.generation=2;declines(m,s,x,y)
m,s,x,y=fixture(id(1),id(2),false);m.def.width=9;declines(m,s,x,y)
m,s,x,y=fixture(id(1),id(2),false);m.def.warps[1].destMap='SILPH_CO_2F';declines(m,s,x,y)
m,s,x,y=fixture(id(1),id(3),false);declines(m,s,x,y)
m,s,x,y=fixture(id(2),id(1),false);declines(m,s,x,y)
m,s,x,y=fixture(id(1),id(2),false);m.tileset.blocks[7][9]=99;declines(m,s,x,y)
-- A blocked south approach must rotate the whole flight, including rails.
for _,side in ipairs{'south','west','north','east'}do
 local m,s,x,y=fixture(id(1),id(2),false)
 local delta=({south={0,1},west={-1,0},north={0,-1},east={1,0}})[side]
 m.isWalkableCell=function(_,a,b)return a==x+delta[1]and b==y+delta[2]end
 local ok,q=run(m,s,x,y);assert(ok)
 for _,v in ipairs(q)do
  assert(v.stairEntrance==side)
  if v.storeStair=='landing'then for j=1,4 do
   local p=v[j];local a,b=p[1]-x*16,p[3]-y*16
   assert((side=='south'and b>=14)or(side=='north'and b<=2)
    or(side=='west'and a<=2)or(side=='east'and a>=14),'landing faces blocked cell')
  end end
 end
 -- A second native approach cannot receive a side railing.
 m.isWalkableCell=function(_,a,b)return b==y+1 or a==x-1 end
 ok,q=run(m,s,x,y)
 local rails=0;for _,v in ipairs(q)do if v.storeStair=='rail'then rails=rails+1 end end
 assert(rails==6,'rail blocks a native side approach')
end
print('PASS stair orientation: four native entrances, landing rotation, open-side railing exclusion')
-- Native enclosed store floors share a full-width shaft with their opening
-- and room mask; the terrace keeps its independent bounded roof stair model.
for from=1,5 do for _,to in ipairs{from-1,from+1}do if to>=1 then
 local m,s,x,y=fixture(id(from),id(to),to<from)
 m.isWalkableCell=function(_,a,b)return a==x and b==y+1 end
 local shaft=assert(stairs.perimeterShaft(m,m.def.warps[1]))
 assert(shaft.width==32 and shaft.length==80 and shaft.at==16 and shaft.back==-48)
 local ok,q=run(m,s,x,y);assert(ok)
 local treads,roof,lo,hi=0,0,0,0
 for _,v in ipairs(q)do
  if v.stairPart=='tread'then treads=treads+1 end
  if v.stairPart=='shaft-roof'then roof=roof+1 end
  for _,p in ipairs(v)do
   assert(p[1]>=shaft.from and p[1]<=shaft.upto and p[3]>=shaft.back and p[3]<=shaft.mouth)
   lo,hi=math.min(lo,p[2]),math.max(hi,p[2])
  end
 end
 assert(treads==16 and roof==1)
 assert(to<from and lo==-52 or to>from and hi==80)
 local portal=stairs.portal(m,x,y,stairs.storeFlight(m,x,y,s),{shellHeight=50})
 assert(portal.height==50 and portal.upto-portal.from==32)
end end end
local roof,rs,rx,ry=fixture(id(6),id(5),true,15,2)
roof.isWalkableCell=function(_,a,b)return a==rx and b==ry+1 end
assert(not stairs.perimeterShaft(roof,roof.def.warps[1]))
assert(not stairs.storeFlight(roof,rx,ry,rs).shaft)
print('PASS native retail shafts: nine full-storey flights and independent roof fallback')
enabled=false;declines(fixture(id(1),id(2),false))
print('PASS department store stairs: 10 directions, bounded nondegenerate geometry, native data and fallback guards')
