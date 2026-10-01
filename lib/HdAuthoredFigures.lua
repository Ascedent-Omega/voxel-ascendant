-- Tile-authored people keep their furniture/collision and fixed couch anchor.
-- Each presentation uses its own artwork; Cobble is baked from the roster rig.
local V = ...
local M = {}
local cache = {}
local specs = {
  hd = {path='assets/characters/pokecenter-seated-man-hd-v1.png',
    bounds={376,92,990,1164},size={1254,1254},filter='linear'},
  voxel = {path='assets/characters/pokecenter-seated-man-voxel-v1.png',
    bounds={350,48,1020,1228},size={1254,1254},filter='linear'},
  cobble = {path='assets/characters/center-seated/cobble/sitting-4x4.png',
    bounds={93,88,188,303},size={1024,1280},filter='nearest',frames=4,
    row=320,stride=256},
}
function M.style()
  local exports=V.mod and V.mod.exports
  local dlc=exports and exports.humanDlc
  local options=V.mod and V.mod.options
  local walkers=exports and exports.overworldPokemon
  walkers=walkers and walkers.walkingSprites
  if not (dlc and options and walkers and type(walkers.enabled)=='function') then return 'native' end
  local ok,on=pcall(walkers.enabled)
  if not ok or on~=true then return 'native' end
  local style=dlc.style(options:get('apo_human_art_style'))
  return specs[style] and style or 'native'
end
function M.enabled() return M.style()~='native' end
local function prepare(style)
  local entry=cache[style]
  if entry then return not entry.failed and entry or nil end
  entry={meshes={}};cache[style]=entry
  local spec=specs[style]
  local ok,result=pcall(function()
    entry.texture=require('src.render.Assets').image(V.mod.path..'/'..spec.path)
    if not entry.texture then return false end
    entry.texture:setFilter(spec.filter,spec.filter)
    local renderer=V.require('Voxel3D')
    local bounds=spec.bounds
    entry.w=20*(bounds[3]-bounds[1])/(bounds[4]-bounds[2])
    for frame=0,(spec.frames or 1)-1 do
      local x,y=frame*(spec.stride or 0),spec.row or 0
      local u0,v0=(bounds[1]+x)/spec.size[1],(bounds[2]+y)/spec.size[2]
      local u1,v1=(bounds[3]+x)/spec.size[1],(bounds[4]+y)/spec.size[2]
      local rows={{0,0,0,u0,v1,1},{entry.w,0,0,u1,v1,1},
        {entry.w,20,0,u1,v0,1},{0,20,0,u0,v0,1}}
      local indices={};renderer.pushQuad(indices,0)
      entry.meshes[frame+1]=assert(renderer.newMesh(rows,indices))
    end
    return true
  end)
  if not ok or not result then entry.failed=true;return nil end
  return entry
end
local function frame(style)
  if style~='cobble' then return 1 end
  local time=love and love.timer and love.timer.getTime and love.timer.getTime() or 0
  local phase=time%4
  if phase<2.65 or phase>=3.02 then return 1 end
  if phase<2.76 then return 2 end
  if phase<2.86 then return 3 end
  return 4
end
function M.resolve(figure)
  if figure.hdActor~='pokecenter_seated_man' then return figure,nil end
  local style=M.style()
  if style=='native' then return figure,nil end
  local entry=prepare(style)
  if not entry then return figure,nil end
  return {mesh=entry.meshes[frame(style)],wx=figure.wx+(figure.w or 0)/2-entry.w/2,
    wz=figure.wz,y=figure.y-4.5,w=entry.w,hdActor=figure.hdActor},entry.texture
end
function M.invalidate()
  for _,entry in pairs(cache) do
    for _,mesh in pairs(entry.meshes) do
      if mesh.release then pcall(mesh.release,mesh) end
    end
  end
  -- Assets owns the shared textures; only our meshes are released here.
  cache={}
end
return M
