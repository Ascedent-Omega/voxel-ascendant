return function(game)
 assert(os.getenv('POKEPORT_IDENTITY')=='vasc-video-polish-qa')
 local lib=game.mods.exports.VOXEL_ASCENDANT.lib
 local function find(fn,seen)
  if type(fn)~='function'then return end;seen=seen or{};if seen[fn]then return end;seen[fn]=true
  for i=1,100 do local k,v=debug.getupvalue(fn,i);if not k then break end;if k=='V'then return v end end
  for i=1,100 do local k,v=debug.getupvalue(fn,i);if not k then break end;local x=find(v,seen);if x then return x end end
 end
 local V=assert(find(lib.require('VoxelScene').render))
 local buildings=V.require('Gen1PalletVillage').buildings
 buildings:setValue(true,game,true);assert(buildings:get()==true)
 local quit=love.event.quit
 love.event.quit=function(...)
  assert(buildings:get()==true,'voxel buildings changed')
  assert(lib.require('Voxel3D').worldCardsReady(game.overworld),'Continue left cards pending')
  return quit(...)
 end
 return assert(loadfile(assert(os.getenv('QA_VASC_ROOT'))..'/tests/native/rc22_continue_hitches.lua'))()(game)
end
