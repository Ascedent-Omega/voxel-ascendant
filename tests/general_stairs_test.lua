local on=true
local V={require=function(n)
 if n=='ModSetting'then return{new=function()return{get=function()return on end}end}end
 if n=='Gen1InteriorFloors'then return{profile=function()end}end
 if n=='Gen1InteriorPanoramas'then return{profiles={}}end
 if n=='HorizonWall'then return{enabled=function()return false end}end
 error(n)
end}
local M=assert(loadfile('lib/Gen1Stairs.lua'))(V)
for _,family in ipairs{'HOUSE','GATE','MANSION','FACILITY','INTERIOR','MUSEUM','CEMETERY','CAVERN'}do
 for _,class in ipairs{'stair_e','stair_w','stair_down_e','stair_down_w'}do
  for _,side in ipairs{'south','west','north','east'}do
   local delta=({south={0,1},west={-1,0},north={0,-1},east={1,0}})[side]
   local map={def={tileset=family,width=5,height=5,warps={{x=3,y=3}}},isWalkableCell=function(_,x,y)return x==3+delta[1]and y==3+delta[2]end}
   local S={objectQuads={}};assert(M.buildGeneral(S,map,3,3,{class=class,art='stair',h=16}))
   local parts={}
   for _,q in ipairs(S.objectQuads)do
    parts[q.stairPart]=(parts[q.stairPart]or 0)+1
    assert(q.stairEntrance==side and not q.storeStair and q.own,'edge cap ownership missing')
    for _,v in ipairs(q)do assert(v[1]>=48 and v[1]<=64 and v[3]>=48 and v[3]<=64)end
    if q.stairPart=='landing'then for _,v in ipairs(q)do assert(v[2]==0,'raised entrance')end end
    local a,b,c=q[1],q[2],q[3];local ux,uy,uz=b[1]-a[1],b[2]-a[2],b[3]-a[3];local vx,vy,vz=c[1]-a[1],c[2]-a[2],c[3]-a[3]
    assert((uy*vz-uz*vy)^2+(uz*vx-ux*vz)^2+(ux*vy-uy*vx)^2>1e-8,'degenerate face')
   end
   assert(parts.tread==4 and parts.nosing==4 and parts.riser==4 and parts.landing==1)
   local flight=M.flight(map,3,3,{class=class,art='stair',h=16})
   local portal=M.portal(map,3,3,flight,{shellHeight=40})
   local floor=flight.down and 0 or flight.count*flight.rise
   assert(portal.height-floor>=20,'insufficient headroom above landing')
   assert(portal.edge==({south='north',north='south',east='west',west='east'})[side],
    'headroom opening did not rotate with native approach')
   assert(#S.objectQuads<125,'geometry budget')
  end
 end
end
local cave={def={tileset='CAVERN'},tileAt=function(_,x,y)return x%2==0 and 21 or 22 end,
 cellTile=function(_,x,y)return y<0 and 5 or y>0 and 20 or 21 end}
local S={objectQuads={}};assert(M.buildGeneral(S,cave,0,0,{art='stair',class='stair_n',h=6}))
for _,q in ipairs(S.objectQuads)do assert(q.stairPart~='rail'and q.stairPart~='post')end
for _,pair in ipairs{{15,0},{13,2},{9,4},{5,6},{1,6}}do assert(M.supportAt(cave,8,pair[1])==pair[2])end
assert(M.supportAt(cave,8,-1)==6)
cave.cellTile=function()return 5 end;S={objectQuads={}}
assert(M.buildGeneral(S,cave,0,0,{art='stair',class='stair_n',h=0}))
assert(#S.objectQuads==1 and S.objectQuads[1][1][2]==6,'level shelf gained fake stairs')
on=false;assert(not M.buildGeneral({objectQuads={}},cave,0,0,{art='stair',class='stair_n'}))
print('PASS 128 family/direction/entrance flights: footprint, flush landing, valid faces, budget; cave tread support and OFF fallback')
