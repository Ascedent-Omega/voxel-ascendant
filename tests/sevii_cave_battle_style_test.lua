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
local V={data=function(name)assert(name=='sevii_voxel_profiles');return recipes end,
 require=function(name)return assert(modules[name],name)end}
modules.KascSeviiScenery=assert(loadfile('lib/KascSeviiScenery.lua'))(V)
modules.SeviiArenaBindings=assert(loadfile('lib/SeviiArenaBindings.lua'))(V)
local style=assert(loadfile('lib/BattleArenaStyle.lua'))(V)
local reviewed=dofile('data/arena_scenery.lua')
local donors={mt_moon='MT_MOON_1F',rock_tunnel='ROCK_TUNNEL_1F',seafoam='SEAFOAM_ISLANDS_1F',
 diglett='DIGLETTS_CAVE',cerulean='CERULEAN_CAVE_1F',victory_road='VICTORY_ROAD_1F'}
local caves=0
for id,p in pairs(recipes)do
 if p.kind=='cave'then
  local m=map(id)
  assert(style.resolve(m).id=='cave','Sevii cave classified by custom tileset/name: '..id)
  local receipt=assert(modules.SeviiArenaBindings.forMap(m,reviewed),'reviewed cave ARENA missing '..id)
  assert(receipt.reviewedBackdropId==donors[p.cave]and receipt.spec.outdoor==false,'native cave family donor '..id)
  assert(modules.SeviiArenaBindings.forMap(m,reviewed)==receipt,'render frames reuse receipt '..id)
  assert(not modules.SeviiArenaBindings.forMap(m,{}),'missing reviewed art cannot bind '..id)
  assert(not modules.SeviiArenaBindings.forMap(m,{[donors[p.cave]]={outdoor=true}}),'outdoor art cannot bind cave '..id)
  m.def.kaOwner='foreign'
  assert(not modules.SeviiArenaBindings.styleFor(m)and not modules.SeviiArenaBindings.forMap(m,reviewed),'foreign cave contract accepted: '..id)
  caves=caves+1
 end
end
assert(caves==47,'complete imported cave family coverage')
for _,id in ipairs({'PALLET_TOWN','VIRIDIAN_FOREST','MT_MOON_1F','SEAFOAM_ISLANDS_1F','REDS_HOUSE_1F'})do
 assert(not modules.SeviiArenaBindings.styleFor({id=id,def={}}),'Sevii family owns Kanto '..id)
end
print('PASS Sevii cave family parity',caves)
