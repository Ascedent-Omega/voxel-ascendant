return function(game)
 assert(os.getenv('POKEPORT_IDENTITY')=='vasc-video-polish-qa')
 local ex=game.mods.exports.VOXEL_ASCENDANT
 local function find(fn,name,seen)
  if type(fn)~='function'then return end;seen=seen or{};if seen[fn]then return end;seen[fn]=true
  for i=1,100 do local k,v=debug.getupvalue(fn,i);if not k then break end;if k==name then return v end end
  for i=1,100 do local k,v=debug.getupvalue(fn,i);if not k then break end;local x=find(v,name,seen);if x then return x end end
 end
 local V=assert(find(ex.lib.require('VoxelScene').render,'V'))
 if os.getenv('QA_FURNITURE_LIGHT_REFERENCE')=='1'then
  local F=V.require('VoxelFurniture');F.eachWorldLights=function(state,draw)return F.eachWorld(state,draw,true)end
 end
 return assert(loadfile(assert(os.getenv('QA_VASC_ROOT'))..'/tests/native/rc30_neighbor_travel.lua'))()(game)
end
