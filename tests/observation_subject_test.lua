local modules={};local V={require=function(n)return assert(modules[n],n)end,mod={exports={}}}
modules.Gen1Rooftops=assert(loadfile('lib/Gen1Rooftops.lua'))()
modules.SilphWindows={matches=function()return false end}
local World=assert(loadfile('lib/RooftopWorld.lua'))(V);modules.RooftopWorld=World
local source={tileset='OVERWORLD',warps={{x=10,y=15,destMap='ROUTE_12_GATE_1F'}},objects={
 {index=2,x=14,y=31,sprite='FISHER',range='LEFT',trainerClass='OPP_FISHER',movement='STAY'},
 {index=3,x=5,y=39,sprite='FISHER',range='UP',trainerClass='OPP_FISHER',movement='STAY'},
 {index=4,x=11,y=23,sprite='OTHER',trainerClass='OPP_FISHER',movement='WALK'}}}
local game={data={maps={ROUTE_12=source},tilesets={OVERWORLD={}},sprites={FISHER={},OTHER={}}}}
package.loaded['src.core.Game']=game
package.loaded['src.world.Map']={new=function(d,t)return {id='ROUTE_12',def=d,tileset=t}end}
package.loaded['src.render.SpriteRenderer']={new=function(d,id)return{def=d,id=id}end}
modules.Gen1RoomBounds={forMap=function()return{west=0,east=128,north=32,south=128}end}
modules.VoxelItems={models={gate={frameW=96,depth=96,offsetY=-74}}}
modules.VoxelFurniture={findBuildings=function()return{{tx=16,ty=32,kind='gate'}}end}
local map={id='ROUTE_12_GATE_2F',def={tileset='GATE',width=4,height=4}}
local entry={map=map,w=128,h=128}
local a=World.anchor(entry,modules.VoxelFurniture.findBuildings(),modules.VoxelItems.models)
assert(a.halfTurn and a.y==-74)
local x,y,z=World.point(a,176,0,304)
assert(x==64 and z==80 and y==-74,'building plot not centred on trimmed roof')
-- Rotated minimum corners must match all four actual corners, not rotate
-- the origin alone and move a positive-width box to the wrong side.
local bx,by,bz=World.boxOrigin(a,224,4,496,16,32)
for _,p in ipairs{{224,496},{240,496},{224,528},{240,528}}do
 local px,py,pz=World.point(a,p[1],4,p[2]);assert(px>=bx and px<=bx+16 and pz>=bz and pz<=bz+32 and py==by)
end
local plain={x=13,y=-7,z=29}
x,y,z=World.point(plain,2,3,5);assert(x==15 and y==-4 and z==34)
local bound=0
V.mod.exports.overworldPokemon={walkingSprites={scenerySprite=function(id,obj,native)
 assert(id=='ROUTE_12'and obj==source.objects[1]);bound=bound+1;return{def={trueColor=true},id=native.id}
end}}
local level=1;local OW={interact=function()end,handleInput=function()end}
package.loaded['src.world.OverworldController']=OW;package.loaded['src.render.Pipelines']={level=function()return level end}
modules.FreeMove={drop=function()end};modules.Voxel3D={}
local B=assert(loadfile('lib/ObservationBinoculars.lua'))(V);B.install()
local sign={text='TEXT_ROUTE12GATE2F_LEFT_BINOCULARS'}
local s=assert(B.subject(map,sign,1,2));assert(s.object==source.objects[1]and s.x==8 and s.z==-120 and s.y==-74)
assert(s.facing=='right'and s.sprite.def.trueColor and s.yaw<0 and s.slope<0 and bound==1)
assert(not B.subject(map,{text='TEXT_ROUTE12GATE2F_RIGHT_BINOCULARS'},6,2))
map.def.generation=2;assert(not B.subject(map,sign,1,2));map.def.generation=nil
map.signAtCell=function()return sign end
local player={cellX=1,cellY=3,facingCell=function()return 1,2 end}
local world=setmetatable({map=map,player=player,npcAtCell=function()end},{__index=OW})
game.overworld=world;game.stack={top=function()return world end}
assert(not B.poses(world,function()end));world:interact();B.update(1/60,game)
assert(player.inputLocked)
local pose=assert(B.poses(world,function()return'palette'end));assert(#pose==1 and not pose[1].entity)
assert(pose[1].gh==-74 and pose[1].mapId=='ROUTE_12'and pose[1].colors=='palette')
local frame=B.frame(world);assert(frame.eye[1]==24 and frame.eye[3]==44,'optical viewpoint moved off pedestal')
local target=B.current().subject;local dx,dz=target.x-frame.eye[1],target.z-frame.eye[3]
assert(math.abs((frame.focus[1]-frame.eye[1])*dz-(frame.focus[3]-frame.eye[3])*dx)<1e-8)
-- Centre of the fishers' body clears the north parapet instead of looking
-- through the terrace floor or painting the subject over it.
local yAtRail=frame.eye[2]+(target.y+9-frame.eye[2])*(32-frame.eye[3])/(target.z-frame.eye[3])
assert(yAtRail>25.2)
B.close();assert(not player.inputLocked and not B.poses(world,function()end))
assert(source.objects[1].range=='LEFT'and source.objects[1].x==14 and #source.objects==3)
print('PASS lookout subject: shared world/box rotation, source identity/style, optical aim/clearance, no NPC simulation, cleanup')
