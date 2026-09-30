local Q=assert(loadfile('lib/ArenaQueryCache.lua'))()
local authored={}
local eyeX,eyeZ,eyeH=0,0,96
local rayBlocked=false;local compactRig=false
local mode='raised';local failCamera=false;local failTerrain=false;local moduleFault={}
local revisions={cacheRevision=0}
local modules={ArenaQueryCache=Q,ChunkMesher=revisions,HorizonWall={cacheRevision=0},
 LedgeElevation={mode=function()if failTerrain then error(moduleFault)end;return mode end},
 VoxelScene={groundAt=function(map,x,y)return map.heights[x+y*map.widthCells]or 0 end},
 TileShape={forMap=function()return{[1]={art='ground'},[2]={art='grass'}}end},
 Gen1InteriorPanoramas={profileFor=function(map)return map.room and{}or nil end},
 VoxelFurniture={supportAt=function(map,x,y)return map.seats[math.floor(x/16)+math.floor(y/16)*map.widthCells]end},
 BattleCam={rig=function(arena,ground)
  return {eye={arena.mid[1]+(compactRig and arena.cam=='compact'and 0 or eyeX),ground+eyeH,arena.mid[2]+eyeZ}}
 end},
 BattleHeroesBridge={geometryForMap=function(map)return function(x,z)return map.geometry or 0 end end,
 geometryClear=function(geometry,eye,point)return not rayBlocked and geometry(point[1],point[3])<point[2] end}}
local V={data=function(name)return name=='battle_arenas'and authored or{}end,
 require=function(name)if name=='BattleCam'and failCamera then error(moduleFault)end;return modules[name]or{}end}
local old=assert(loadfile(assert(os.getenv('QA_ARENA_REFERENCE'))))(V)
local B=assert(loadfile('lib/BattleArena.lua'))(V)
local function map(id,w,h)
 local m={id=id,widthCells=w,heightCells=h,def={tileset='OVERWORLD'},tileset={id='OVERWORLD'},blocked={},heights={},seats={},grass={},warps={},warpTiles={},water={}}
 function m:inBounds(x,y)return x>=0 and y>=0 and x<self.widthCells and y<self.heightCells end
 function m:warpAtCell(x,y)return self.warps[x+y*self.widthCells]end
 function m:isWarpTileCell(x,y)return self.warpTiles[x+y*self.widthCells]end
 function m:isGrassCell(x,y)return self.grass[x+y*self.widthCells]end
 function m:isWalkableCell(x,y)return not self.blocked[x+y*self.widthCells]end
 function m:isWaterCell(x,y)return self.water[x+y*self.widthCells]end
 function m:cellTile(x,y)return self.grass[x+y*self.widthCells]and 2 or 1 end
 return m
end
local function equal(a,b,seen,key)
 if key=='map'or key=='pick' then assert(a==b,'external identity changed');return end
 assert(type(a)==type(b),'different result type '..tostring(key))
 if type(a)~='table'then assert(a==b,'different result value '..tostring(key));return end
 seen=seen or{};if seen[a]==b then return end;seen[a]=b
 for k,v in pairs(a)do equal(v,b[k],seen,k)end
 for k in pairs(b)do assert(a[k]~=nil,'missing result key '..tostring(k))end
end
local function pack(...)return {n=select('#',...),...}end
local checks=0
local function check(m,x,y,surf)
 local expected=pack(old.find(m,x,y,surf))
 local got=pack(B.find(m,x,y,surf));equal(got,expected)
 local again=pack(B.find(m,x,y,surf));equal(again,expected)
 if got[1]then assert(got[1]~=again[1],'cache exposed its private arena')end
 checks=checks+1;return got[1],got[2]
end
local m=map('TEST_ROUTE',24,24)
local first=assert(check(m,10,10,false));assert(B.resultCacheStatus().hits>0,'cache never used')
local expectedX=first.enemy[1];first.enemy[1]=-10000;first.cam='broken';first.extra='caller state'
assert(check(m,10,10,false).enemy[1]==expectedX,'caller edited a retained cached result')
local cell=first.x+first.y*m.widthCells
m.blocked[cell]=true;check(m,10,10,false);m.blocked[cell]=nil;check(m,10,10,false)
m.warps[cell]={};check(m,10,10,false);m.warps[cell]=nil
m.warpTiles[cell]=true;check(m,10,10,false);m.warpTiles[cell]=nil
m.grass[cell]=true;check(m,10,10,false);m.grass[cell]=nil
m.heights[10+10*m.widthCells]=16;check(m,10,10,false);m.heights[10+10*m.widthCells]=nil
for _,shift in ipairs{8,-12,0}do eyeX=shift;check(m,10,10,false)end
eyeH=128;check(m,10,10,false);eyeH=96
check(m,10.1,10.4,false);check(m,10.9,10.4,false);check(m,10,10,true)
revisions.cacheRevision=1;check(m,10,10,false)
-- Same object, same function identity, completely changed collision answers.
for y=0,23 do for x=0,23 do m.blocked[x+y*24]=true end end
assert(check(m,10,10,false)==nil)
for y=0,23 do for x=0,23 do m.water[x+y*24]=true end end
check(m,10,10,true)
m.blocked={};m.water={};check(m,10,10,false)
-- The compact fallback depends on live seat/support occupancy as well.
local aisle=map('TEST_AISLE',10,24);aisle.def.tileset='CAVERN'
for y=0,23 do for x=0,9 do aisle.blocked[x+y*10]=x~=5 end end
compactRig=true;eyeX=300
local narrow=assert(check(aisle,5,10,false));assert(narrow.cam=='compact')
aisle.seats[narrow.x+narrow.y*10]={};check(aisle,5,10,false)
aisle.seats={};check(aisle,5,10,false)
compactRig=false;eyeX=0
-- Errors during proof validation must not return an old arena or strand the
-- recorder/sampling scopes. The next successful request can populate again.
local walk=m.isWalkableCell;local fault={}
m.isWalkableCell=function()error(fault)end
local ok,err=pcall(B.find,m,10,10,false);assert(not ok and err==fault)
m.isWalkableCell=walk;check(m,10,10,false)
B.setOverride(m.id,false);old.setOverride(m.id,false);check(m,10,10,false)
B.setOverride(m.id,nil);old.setOverride(m.id,nil);check(m,10,10,false)
-- Authored courts exercise trainer geometry and live ray-provider state.
local room=map('TEST_ROOM',48,48)
authored.TEST_ROOM={fixed=true,x=20,y=20,shape='court_east',cam='court'}
local found,review=check(room,24,24,false);assert(found and review)
local candidate=review.candidates[1]
assert(found==candidate,'find/review aliasing changed')
room.geometry=100;check(room,24,24,false);room.geometry=nil;check(room,24,24,false)
rayBlocked=true;check(room,24,24,false);rayBlocked=false;check(room,24,24,false)
authored.TEST_ROOM.x=21;check(room,24,24,false)
authored.TEST_ROOM={fixed=true,x=21,y=20,shape='court_east',cam='court'};check(room,24,24,false)
B.SHAPES[6].trainerOffsets.player[1]=-17;old.SHAPES[6].trainerOffsets.player[1]=-17;check(room,24,24,false)
B.SAMPLE_STEP=3;old.SAMPLE_STEP=3;check(room,24,24,false)
local sameId=map('TEST_ROOM',48,48);check(sameId,24,24,false)
-- A formerly absent optional rig and a nil terrain mode differ from failed
-- required module reads; cache validation must preserve those failures.
local rig=modules.BattleCam.rig;modules.BattleCam.rig=nil
assert(check(room,24,24,false));failCamera=true
ok,err=pcall(B.find,room,24,24,false);assert(not ok and err==moduleFault)
failCamera=false;modules.BattleCam.rig=rig;check(room,24,24,false)
authored.TEST_ROOM.terrain='flat';mode=nil;check(room,24,24,false)
failTerrain=true;ok,err=pcall(B.find,room,24,24,false);assert(not ok and err==moduleFault)
failTerrain=false;mode='raised';authored.TEST_ROOM.terrain=nil;check(room,24,24,false)
-- Bounds used only by route feet/camera admission must also invalidate a
-- negative or positive cache entry, even when all integer floor cells agree.
local route=map('ROUTE_999',48,48)
authored.ROUTE_999={fixed=true,x=20,y=20,shape='diagonal_east'}
local bounds=route.inBounds;local fractionalBlocked=false;local cameraBlocked=false
function route:inBounds(x,y)
 if fractionalBlocked and (x~=math.floor(x)or y~=math.floor(y))then return false end
 if cameraBlocked and x==29 and y==22 then return false end
 return bounds(self,x,y)
end
assert(check(route,24,24,false));fractionalBlocked=true;assert(check(route,24,24,false)==nil)
fractionalBlocked=false;eyeX=104;cameraBlocked=true
assert(check(route,24,24,false)==nil);cameraBlocked=false;assert(check(route,24,24,false))
eyeX=0
-- Foreign loader residency and identity are live dependencies as well.
local previousGame,previousLoader=package.loaded['src.core.Game'],package.loaded['src.world.MapLoader']
local foreign=map('OTHER_FLOOR',48,48)
package.loaded['src.core.Game']={data={}}
package.loaded['src.world.MapLoader']={load=function(_,id)assert(id=='OTHER_FLOOR');return foreign end}
authored.TEST_ROOM.map='OTHER_FLOOR';check(room,24,24,false)
foreign=map('OTHER_FLOOR',48,48);check(room,24,24,false)
foreign=nil;check(room,24,24,false)
package.loaded['src.core.Game'],package.loaded['src.world.MapLoader']=previousGame,previousLoader
-- Live camera clearance outside find must acquire geometry only once per
-- call, then drop it. A failed factory cannot leak a scope into later frames.
local factory=modules.BattleHeroesBridge.geometryForMap;local factories=0
modules.BattleHeroesBridge.geometryForMap=function(map)factories=factories+1;return factory(map)end
local court=B.at(21,20,'court_east');court.map=room
assert(B.clearance(room,court));assert(factories==1)
assert(B.clearance(room,court));assert(factories==2,'geometry retained across live clearance calls')
local goodFactory=modules.BattleHeroesBridge.geometryForMap
modules.BattleHeroesBridge.geometryForMap=function()error(fault)end
ok,err=pcall(B.clearance,room,court);assert(not ok and err==fault)
modules.BattleHeroesBridge.geometryForMap=goodFactory
assert(B.clearance(room,court));assert(factories==3,'failed clearance stranded its geometry scope')
modules.BattleHeroesBridge.geometryForMap=factory
-- Unknown replacements of selection helpers bypass proofs that cannot cover
-- arbitrary side effects/private state. Their ordinary behavior stays live.
local prior=B.keepAnchorSafe
local allowed=false
B.keepAnchorSafe=function()return allowed end
B.setOverride(m.id,nil);old.setOverride(m.id,nil)
assert(B.find(m,10,10,false)==nil);allowed=true;assert(B.find(m,10,10,false))
B.keepAnchorSafe=prior
local stats=B.resultCacheStatus();assert(stats.hits>=20 and stats.rejected>=10)
print('PASS',checks,'differential find scenarios; live collision/heights/camera/geometry/config/foreign maps, fresh outputs and aliasing',stats.hits,stats.rejected)
