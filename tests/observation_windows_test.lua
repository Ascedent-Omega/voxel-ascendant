local modules={};local V={require=function(n)return assert(modules[n],n)end}
local R=assert(loadfile('lib/Gen1Rooftops.lua'))();modules.Gen1Rooftops=R
modules.ModSetting={new=function()return{get=function()return true end}end}
modules.SilphElevator=assert(loadfile('lib/SilphElevator.lua'))(V)
modules.HouseWindows={describe=function()end,source=function()end,anchor=function()end}
modules.Gen1RoomBounds=assert(loadfile('lib/Gen1RoomBounds.lua'))(V)
modules.Gen1Stairs={perimeterShaft=function()end}
modules.WindowImageCache={load=function()end}
local W=assert(loadfile('lib/SilphWindows.lua'))(V);modules.SilphWindows=W
for floor=1,11 do
 local map={id='SILPH_CO_'..floor..'F',def={width=floor==10 and 8 or floor==11 and 9 or floor>=6 and 13 or 15,height=9,tileset=floor==11 and 'INTERIOR'or 'FACILITY'}}
 assert(W.floor(map)==floor)
 local h=W.height(map);assert(h==(floor==1 and 0 or 32+(floor-2)*24))
 local e={map=map,w=map.def.width*32,h=288}
 local a=W.anchor(e,{{kind='silph',tx=32,ty=20}},{silph={template='silph_co',frameW=128,depth=192}})
 assert(a.y==-h and a.x+256+64==e.w/2 and a.z+160+96==144)
 assert(W.perimeter(map,{edge='north',at=0}));assert(not W.perimeter(map,{edge='south',at=80,wallThickness=16}))
 map.def.generation=2;assert(not W.matches(map))
end
local level=1;local keys={};local calls=0;local OW={interact=function()calls=calls+1 end,handleInput=function()end}
package.loaded['src.world.OverworldController']=OW
package.loaded['src.render.Pipelines']={level=function()return level end}
local game={input={wasPressed=function(_,k)return keys[k]end,isDown=function(_,k)return keys[k]end}}
package.loaded['src.core.Game']=game
modules.FreeMove={drop=function()end};modules.Voxel3D={}
local B=assert(loadfile('lib/ObservationBinoculars.lua'))(V);B.install()
for _,route in ipairs{11,12,15,16,18}do
 local map={id='ROUTE_'..route..'_GATE_2F',def={tileset='GATE',width=4,height=4},signAtCell=function()return{text='TEXT_BINOCULARS'}end}
 local p={cellX=1,cellY=3,facingCell=function()return 1,2 end}
 local world=setmetatable({map=map,player=p,npcAtCell=function()end},{__index=OW})
 game.overworld=world;game.stack={top=function()return world end}
 assert(R.gate(map)and R.source(map)=='ROUTE_'..route)
 world:interact();assert(not B.current());B.update(1/60,game);assert(B.current()and p.inputLocked)
 local rig=B.frame(world,0,0);keys.up=true;world:handleInput();keys={}
 assert(B.frame(world,0,0).fov<rig.fov and p.cellX==1 and p.cellY==3)
 keys.b=true;world:handleInput();keys={};assert(not B.current()and not p.inputLocked and not modules.Voxel3D.camera)
 world:interact();B.update(1/60,game);B.frame(world,0,0);level=0;B.update(1/60,game)
 assert(not B.current()and not p.inputLocked and not modules.Voxel3D.camera)
 world:interact();B.update(1/60,game);assert(not B.current());level=1
end
assert(calls==15,'native interaction hooks bypassed')
print('PASS 11 floor anchors, facade/partition separation, five terraces, native dialogue, FOV zoom, movement lock, exit and Vanilla cleanup')

-- Alternating material tags must not fragment the skyline into one mesh per
-- tree/window: independent bounded queues keep draw calls proportional to volume.
local corners={};for i=1,6 do corners[i]={{0,0,0},{1,0,0},{1,1,1},{0,1,1}}end
modules.Voxel3D={FACE_CORNERS=corners,newMesh=function(v,i)return{vertices=v,indices=i}end}
modules.VoxelItems={palette={{1,1,1}}}
modules.CinnabarVolcano={active=function()return false end}
modules.RooftopWorld={texture=function()return{}end,mountains=function()end,geometry=function(e,d,emit)
 for i=1,6000 do emit(i,0,0,1,1,1,1,i%3==0,i%3==1)end
end}
local meshes=W.build({map={id='SILPH_CO_1F',def={width=15,height=9,tileset='FACILITY'}},w=480,h=288},nil,{})
assert(#meshes<=160,'alternating materials fragmented spatial city batches')
for _,m in ipairs(meshes)do assert(m.bounds and #m.mesh.vertices<=12288)end
print('PASS 6000 alternating city boxes use bounded spatial batches',#meshes)
local Portal=assert(loadfile('lib/SilphWindowVisibility.lua'))(V)
local map={id='SILPH_CO_10F',def={width=8,height=9,tileset='FACILITY'}}
local profile={shellHeight=50,ceiling={enabled=true,authored=true}}
local north={edge='north',at=0,from=0,upto=256,openings={}}
local partition={edge='south',at=60,from=0,upto=256,openings={}}
local eye={128,25,100}
assert(#Portal.apertures(map,profile,eye,{north,partition})==0,'sealed room sees exterior')
partition.openings={{from=112,upto=144,height=24,open=true}}
local panes=Portal.apertures(map,profile,eye,{north,partition})
assert(#panes>0,'open doorway hides visible windows')
partition.openings[1].open=false
assert(#Portal.apertures(map,profile,eye,{north,partition})==0,'closed card-key door leaks exterior')
local cone=Portal.cones({128,25,40},{{edge='north',at=0,from=96,upto=160}},50)
assert(Portal.accepts(cone,{100,0,-80,140,50,-30}),'city through window culled')
assert(Portal.accepts(cone,{100,248,-80,140,298,-30},0,0,-248),'moving elevator bounds culled')
assert(not Portal.accepts(cone,{100,0,100,140,50,140}),'city behind observer drawn')
assert(not Portal.accepts(cone,{1000,0,-80,1020,50,-30}),'city outside aperture drawn')
local Ceilings=assert(loadfile('lib/InteriorCeilings.lua'))(V)
assert(Ceilings.visibleFrom(map,profile,eye),'indoor textured ceiling removed')
assert(not Ceilings.visibleFrom(map,profile,{128,80,100}),'orbit roof covers room')
print('PASS closed room / open and closed doorway portals, bounded exterior cone and textured indoor ceiling')

-- Elevated orbit must clip the skyline above the window head, too.
local orbit={128,100,240}
assert(Portal.through(orbit,{128,0,-40},256,288,50),'street visible through far glass hidden')
assert(not Portal.through(orbit,{128,120,-80},256,288,50),'roof above glass leaked')
assert(not Portal.through(orbit,{128,-30,-40},256,288,50),'below-sill geometry leaked')
local close={128,24,2}
assert(Portal.through(close,{128,130,-50},256,288,50),'near-window first person skyline clipped')
assert(not Portal.through(close,{128,1000,-50},256,288,50),'first-person above-frame leak')
assert(not Portal.through({128,100,350},{128,0,400},256,288,50),'outside near wall reveals city')
print('PASS orbit head/sill clipping, near-glass first person and exterior-camera rejection')

-- Ground floor shares the outdoor datum, with natural building heights.
modules.RooftopWorld.geometry=function(e,d,emit)emit(-200,-4,-100,16,4,16,1);emit(-180,0,-100,16,32,16,1)end
local city=W.build({map={id='SILPH_CO_1F',def={width=15,height=9,tileset='FACILITY'}},w=480,h=288},nil,{})
local minY,maxY=math.huge,-math.huge;local ground=false
for _,b in ipairs(city)do for _,v in ipairs(b.mesh.vertices)do minY=math.min(minY,v[2]);maxY=math.max(maxY,v[2]);ground=ground or v[2]==0 end end
assert(minY==-4 and maxY==32 and ground,'street datum or exterior height scaled')
print('PASS lobby outdoor ground at zero and unscaled neighbouring building heights')

local cabin={id='SILPH_CO_ELEVATOR',def={tileset='LOBBY',width=2,height=2}}
assert(W.perimeter(cabin,{edge='north',at=0}))
assert(not W.perimeter(cabin,{edge='south',at=64}))
assert(W.perimeter(cabin,{edge='west',at=0}))
assert(W.perimeter(cabin,{edge='east',at=64}))
assert(Portal.through({32,24,32},{32,24,-32},64,64,40,true))
assert(not Portal.through({32,24,32},{-32,24,32},64,64,40,true))
print('PASS cabin rear and side glazing, shared CPU aperture boundary')
-- A recessed north stair mouth must never count as transparent facade.
local stairMap={id='SILPH_CO_11F',def={width=9,height=9,tileset='INTERIOR',warps={{x=9,y=0,destMap='SILPH_CO_10F'}}},tileset={blocks={}},
 isWalkableCell=function(_,x,y)return x>0 and y>0 and x<17 and y<17 end}
local found=false
for _,p in ipairs(W.apertures(stairMap,50))do if p.edge=='north'then
 found=true;assert(p.upto<=144 or p.from>=160,'stair alcove admitted exterior ground')
end end
assert(found)
print('PASS recessed stair/exit spans excluded from exterior window mask')
