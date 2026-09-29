local tiles={walkable={0},blocks={}}
package.loaded['src.world.Map']={
 isOutside=function(d)return d.tileset=='OVERWORLD'end,
 defIsWalkableCell=function(d,_,x,y)return not(d.solid and d.solid[y*d.width*2+x])end,
 defIsWaterCell=function()return false end}
package.loaded['src.world.Warp']={destination=function(data,w,last)
 local id=w.destMap=='LAST_MAP'and last.id or w.destMap
 local target=data.maps[id].warps[w.destWarp or 1]or{x=0,y=0}
 return id,target.x,target.y
end}
local function outdoor()return{width=2,height=2,tileset='OVERWORLD',connections={},warps={}}end
local function room(ts)return{width=2,height=2,tileset=ts or'INTERIOR',warps={}}end
local maps={A=outdoor(),WEST=outdoor(),EAST=outdoor(),HOUSE=room(),UPSTAIRS=room(),
 ROUTE_7_GATE=room('GATE'),CAVE=room('CAVERN')}
maps.A.connections={west={map='WEST',offset=0},east={map='EAST',offset=0}}
maps.WEST.connections.east={map='A',offset=0};maps.EAST.connections.west={map='A',offset=0}
maps.A.solid={[2]=true,[10]=true,[14]=true}
maps.A.warps={{x=2,y=1,destMap='ROUTE_7_GATE'}, {x=1,y=0,destMap='HOUSE'},
 {x=0,y=3,destMap='CAVE'}, {x=1,y=2,destMap='BIG_1'}}
maps.HOUSE.warps={{x=0,y=0,destMap='LAST_MAP',destWarp=2},{x=1,y=0,destMap='UPSTAIRS'}}
maps.UPSTAIRS.warps={{x=0,y=0,destMap='HOUSE'}}
for i=1,4 do maps['BIG_'..i]=room();maps['BIG_'..i].warps={{x=0,y=0,destMap='BIG_'..(i%4+1)}}end
local data={maps=maps,tilesets={OVERWORLD=tiles,INTERIOR=tiles}}
local P=assert(loadfile('lib/RegionPlan.lua'))()
local function plan(id,x,y)
 local p=P.new(data,{map={id=id},player={cellX=x or 0,cellY=y or 1},lastOutdoor={id='A'}})
 for i=1,100 do if P.step(p)then break end end
 assert(p.done and not p.error,p.error)
 local set={};for _,v in ipairs(p.ids)do set[v]=true end
 return p,set
end
local p,s=plan('A')
assert(s.A and s.WEST and s.HOUSE and s.UPSTAIRS,'ordinary houses not part of region')
assert(not s.EAST,'gate inside route crossed by coarse map graph')
assert(not s.CAVE and not s.ROUTE_7_GATE and not s.BIG_1,'loading boundary crossed')
assert(p.boundaries.BIG_1 and p.boundaries.CAVE and p.boundaries.ROUTE_7_GATE)
p,s=plan('A',3,1);assert(s.EAST and not s.WEST,'opposite gate side shares region')
p,s=plan('HOUSE');assert(s.A and s.WEST and s.HOUSE and s.UPSTAIRS and not s.EAST,'Continue inside house lost region')
p,s=plan('BIG_3');assert(p.scope=='building'and #p.ids==4 and not s.A,'building not split')
assert(P.sameBuilding(data,'BIG_1','BIG_4')and not P.sameBuilding(data,'HOUSE','BIG_1'))
p,s=plan('CAVE');assert(#p.ids==1 and p.scope=='boundary','cave leaked into outside')
local many=outdoor();many.width,many.height=20,20;maps={OPEN=many};data={maps=maps,tilesets={OVERWORLD=tiles}}
p=P.new(data,{map={id='OPEN'},player={cellX=1,cellY=1}})
assert(not P.step(p),'planning did not yield')
for i=1,100 do if P.step(p)then break end end;assert(p.done and not p.error)
print('PASS region plan: houses included, intra-route gate split, cave boundary, large building, indoor Continue, cycles and cooperative planning')
