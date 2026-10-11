local recipes=assert(loadfile('data/sevii_voxel_profiles.lua'))()
local function map(id)
  local p=assert(recipes[id])
  local tileset={id='KA_SEVII_TILES_'..id:sub(10),trueColor=true,
    imageWidth=p.atlas[1],imageHeight=p.atlas[2],blocks={},sourceCellCollision={}}
  local collisionCodes={X='WALL',G='FLOOR',W='WATER',g='GRASS'}
  for b=1,#p.blocks do
    local block,collision={},{}
    for y=0,3 do for x=0,3 do
      block[#block+1]=math.floor((b-1)/16)*256+(b-1)%16*4+y*64+x
    end end
    for q=1,4 do collision[q]=collisionCodes[p.collision[b]:sub(q,q)] end
    tileset.blocks[b],tileset.sourceCellCollision[b]=block,collision
  end
  return {id=id,tileset=tileset,def={kaOwner='kasc.sevii-expedition/v1',
    tileset=tileset.id,kaSeviiSource=p.source,
    kaSeviiSourceOrigin={unpack(p.origin)},width=p.size[1],height=p.size[2],
    outdoor=p.outdoor}}
end
local modules={}
local V={data=function(name) assert(name=='sevii_voxel_profiles');return recipes end,
  require=function(name)return assert(modules[name],name)end}
modules.KascSeviiScenery=assert(loadfile('lib/KascSeviiScenery.lua'))(V)
modules.SeviiArenaBindings=assert(loadfile('lib/SeviiArenaBindings.lua'))(V)
local bindings=modules.SeviiArenaBindings
local style=assert(loadfile('lib/BattleArenaStyle.lua'))(V)
local reviewed={VIRIDIAN_FOREST={outdoor=true},ROUTE_19={outdoor=true}}
local cases={
  {id='KA_SEVII_THREE_ISLAND_BERRY_FOREST',family='forest',backdrop='VIRIDIAN_FOREST'},
  {id='KA_SEVII_SIX_ISLAND_PATTERN_BUSH',family='forest',backdrop='VIRIDIAN_FOREST'},
  {id='KA_SEVII_TREASURE',family='coast',backdrop='ROUTE_19'},
}
for _,case in ipairs(cases) do
  local m=map(case.id)
  local got=assert(bindings.forMap(m,reviewed),case.id)
  assert(got.reviewedBackdropId==case.backdrop and got.spec==reviewed[case.backdrop])
  assert(style.resolve(m).id==case.family,case.id..' family')
  m.def.kaOwner='foreign'
  assert(not bindings.forMap(m,reviewed) and not bindings.styleFor(m),'foreign map accepted')
end
assert(not bindings.forMap({id='VIRIDIAN_FOREST',def={}},reviewed))
local unknown=map('KA_SEVII_KINDLE')
assert(not bindings.forMap(unknown,reviewed) and bindings.styleFor(unknown)=='grass')
local forest=map(cases[1].id)
assert(not bindings.forMap(forest,{VIRIDIAN_FOREST={outdoor=false}}),'indoor backdrop accepted')
assert(not bindings.forMap(forest,{}),'missing backdrop accepted')
print('PASS exact Sevii arena bindings, style and fail-closed owner/backdrop checks')

-- Reviewed ARENA paintings must not claim the renderer of another stage.
-- Otherwise the shared scene skips the Terrarium/discs mesh without drawing
-- the ARENA painting, leaving only a flat sky and the Pokemon.
local dataByName={sevii_voxel_profiles=recipes,
  arena_scenery=dofile('data/arena_scenery.lua'),battle_disks={}}
V.data=function(name)return dataByName[name]end
for _,name in ipairs({'Mat4','Voxel3D','DayNight','CompactBackgroundAssets'})do modules[name]={}end
local stage=assert(loadfile('lib/VoxelBattleStage.lua'))(V)
for _,case in ipairs(cases)do
  local m=map(case.id)
  assert(not stage.hasAuthoredBackdrop({map=m,discs=true,portableStage='terarrium',terarrium={}}),
    'ARENA painting suppresses Terrarium on '..case.id)
  assert(not stage.hasAuthoredBackdrop({map=m,discs=true,portableStage='discs'}),
    'ARENA painting suppresses discs on '..case.id)
  local arena={map=m,presentationMode='MAP',player={100,200},enemy={140,250}}
  assert(not stage.hasAuthoredBackdrop(arena),'ARENA painting owns MAP on '..case.id)
  local x,y,z=stage.presentationPosition(arena,'player',16)
  assert(x==100 and y==16 and z==200,'ARENA offsets displaced MAP player on '..case.id)
  assert(stage.presentationScale(arena)==1,'ARENA scale changed MAP actors on '..case.id)
  assert(stage.hasAuthoredBackdrop({map=m,arenaStyle=style.resolve(m),portableStage='arena'}),
    'reviewed ARENA painting missing on '..case.id)
end
for _,id in ipairs({'VIRIDIAN_FOREST','ROUTE_19','PALLET_TOWN'})do
  local m={id=id,def={}}
  assert(not stage.hasAuthoredBackdrop({map=m,discs=true,portableStage='terarrium',terarrium={}}))
  assert(not stage.hasAuthoredBackdrop({map=m,discs=true,portableStage='discs'}))
end
print('PASS ARENA backdrop ownership: Sevii Terrarium/discs and Kanto exclusions')
