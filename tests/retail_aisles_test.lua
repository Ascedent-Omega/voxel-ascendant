local enabled,pipeline,engaged=true,'voxel',true
local props={};local P={models={retail_medicine={frameW=32,depth=32,boxes={{7,0,9,19,27,15,2}}}},setting={get=function()return enabled end}}
local modules={VoxelItems=P,VoxelFurniture={find=function()return props end},
 Gen1RoomBounds={forMap=function()return{west=0,north=32,east=320,south=128}end},
 FirstPerson={engaged=function()return engaged end}}
local V={require=function(k)return assert(modules[k],k)end}
package.loaded['src.render.Pipelines']={worldPipeline=function()return pipeline end}
local occupied={}
package.loaded['src.world.Collision']={occupied=function(_,x,y)return occupied[y*20+x]end}
local A=assert(loadfile('lib/RetailAisles.lua'))(V)
local map={id='CELADON_MART_5F',def={tileset='LOBBY',width=10,height=4,warps={},signs={}}}
function map:inBounds(x,y)return x>=0 and x<20 and y>=0 and y<8 end
function map:isWalkableCell(x,y)return self:inBounds(x,y)and y>=2 and not(x>=18 and y>=6)end
function map:warpAtCell(x,y)for _,w in ipairs(self.def.warps)do if w.x==x and w.y==y then return w end end end
local kind=A.variant(P,'retail_medicine',map,36,12)
assert(kind=='retail_medicine_aisle_es')
local model=P.models[kind];assert(model.support==0,'aisle retains native shelf elevation');for _,b in ipairs(model.boxes)do
 assert(b[1]>=0 and b[1]+b[4]<=16 and b[3]>=0 and b[3]+b[6]<=16,'rack covers new window aisle')
 for i=1,6 do assert(b[i]==math.floor(b[i]))end
end
assert(A.variant(P,'retail_medicine',map,20,6)=='retail_medicine','inner bank moved')
assert(A.variant(P,'retail_checkout',map,36,12)=='retail_checkout')
props[1]={kind=kind,tx=36,ty=12,w=4,h=4}
local state={map=map,player={cellX=19,cellY=7,px=19*16,py=7*16},entities={}}
assert(not A.permission(state,19,7),'unclaimed native art released')
props[1].claimed=true
for _,c in ipairs{{19,6},{18,7},{19,7}}do assert(not map:isWalkableCell(unpack(c)));assert(A.permission(state,unpack(c)))end
assert(not A.permission(state,18,6),'solid rack became traversable')
assert(not A.permission(state,20,7),'exterior wall became traversable')
assert(not A.reconcile(state),'active voxel aisle moved player')
map.def.warps={{x=19,y=7}};assert(not A.permission(state,19,7),'warp override');map.def.warps={}
local function reset()state.player={cellX=19,cellY=7,px=19*16,py=7*16}end
pipeline='classic';assert(not A.permission(state,19,7));assert(A.reconcile(state));assert(map:isWalkableCell(state.player.cellX,state.player.cellY))
assert(state.player.px==state.player.cellX*16 and state.player.py==state.player.cellY*16)
pipeline='voxel';enabled=false;reset();assert(A.reconcile(state),'items OFF left player inside native shelf')
enabled=true;engaged=false;reset();assert(A.reconcile(state),'orbit/grid mode left player trapped')
engaged=true;pipeline='classic';occupied[5*20+19]=true;reset();assert(A.reconcile(state));assert(not occupied[state.player.cellY*20+state.player.cellX],'return landed on NPC')
assert(not map:isWalkableCell(19,7),'native collision mutated')
modules.RetailAisles=A
modules.WorldSeats={blocked=function()return false end}
modules.SnowRamps={permission=function()end}
package.loaded['src.core.Game']={data={field={}}}
local Free=assert(loadfile('lib/FreeMove.lua'))(V)
pipeline='voxel';state.player={cellX=5,cellY=5};occupied={}
assert(Free._blockedCell(state,state.player,19,7)==nil,'free movement still uses old rack rectangle')
occupied[7*20+19]=true
assert(Free._blockedCell(state,state.player,19,7)=='entity','aisle bypassed NPC collision')
assert(Free._blockedCell(state,state.player,18,6)=='tile','aisle bypassed actual rack')
assert(Free._blockedCell(state,state.player,20,7)=='bounds','aisle opened exterior wall')
pipeline='classic';occupied={}
assert(Free._blockedCell(state,state.player,19,7)=='tile','native shelf collision changed')
local staff={id='CELADON_MART_3F',def={tileset='LOBBY',width=10,height=4,warps={{x=1,y=1}}}}
staff.inBounds=map.inBounds;staff.warpAtCell=map.warpAtCell
function staff:isWalkableCell(x,y)
 return self:inBounds(x,y)and ((y==1 and x==1)or(y>=2 and y<=3)or(y>=5 and x>=13 and not(x>=18 and y>=6)))
end
pipeline='voxel';state.map=staff
assert(not A.permission(state,19,7),'window aisle bypassed closed service counter')
state.map=map
map.def.generation=2;assert(not A.matches(map))
print('PASS retail window aisles: empty strips only, corner clearance, claims, bounds, warp exclusion, vanilla/items/orbit restoration, NPC-safe return')
