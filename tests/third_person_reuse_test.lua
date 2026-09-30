local ground=0
local shapes={[1]={class="ground"}}
local modules={ModSetting={new=function()return{get=function()return false end}end},
 VoxelScene={groundAt=function()return ground end},TileShape={forMap=function()return shapes end}}
local V={require=function(n)return modules[n]or{}end}
local C=assert(loadfile('lib/ThirdPerson.lua'))(V)
local old=assert(loadfile(assert(os.getenv('QA_PERF_REFERENCE'))..'/lib/ThirdPerson.lua'))(V)
local map={widthCells=20,heightCells=20,wall=8}
function map:inBounds(x,y)return x>=0 and y>=0 and x<self.widthCells and y<self.heightCells end
function map:isWalkableCell(x,y)return x~=self.wall end
function map:isWaterCell()return false end
function map:cellTile()return 1 end
local ow={map=map};local pivot={32,12,32}
local function compare()
 local expected=old.reach(ow,pivot,1,0,0,150)
 assert(C.reach(ow,pivot,1,0,0,150)==expected,'camera collision changed')
 assert(C.reach(ow,pivot,1,0,0,150)==expected,'cache changes collision')
end
compare();assert(C.reachCacheHits>0)
for i=1,200 do C.reach(ow,pivot,1,0,0,150)end
local hits=C.reachCacheHits
collectgarbage('collect');collectgarbage('stop');local before=collectgarbage('count')
for i=1,1000 do C.reach(ow,pivot,1,0,0,150)end
local after=collectgarbage('count');collectgarbage('restart')
assert(C.reachCacheHits-hits==1000);assert(after-before<2,'unchanged rays allocate per frame')
map.wall=6;compare();ground=14;compare();ground=0;map.wall=nil;map.widthCells=5;compare()
local neighbor={widthCells=10,heightCells=10,inBounds=map.inBounds,isWalkableCell=map.isWalkableCell,isWaterCell=map.isWaterCell,cellTile=map.cellTile,wall=2}
ow.neighbors={{map=neighbor,ox=80,oy=0}};compare()
ow.neighbors[1].ox=96;compare();neighbor.wall=nil;compare();ow.neighbors={};compare()
pivot[2]=30;compare();C.PAD=7;old.PAD=7;compare()
print('PASS repeated rays: exact collision, live height/wall/neighbor changes; 1000 reuse hits, '..(after-before)..' KiB')
