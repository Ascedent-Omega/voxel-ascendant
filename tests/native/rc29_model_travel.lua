return function(game)
 assert(os.getenv('POKEPORT_IDENTITY')=='vasc-video-polish-qa')
 local root=assert(os.getenv('QA_VASC_ROOT'))
 local ex=assert(game.mods.exports.VOXEL_ASCENDANT)
 local function find(fn,name,seen)
  if type(fn)~='function'then return end;seen=seen or{};if seen[fn]then return end;seen[fn]=true
  for i=1,100 do local k,v=debug.getupvalue(fn,i);if not k then break end;if k==name then return v end end
  for i=1,100 do local k,v=debug.getupvalue(fn,i);if not k then break end;local x=find(v,name,seen);if x then return x end end
 end
 local V=assert(find(ex.lib.require('VoxelScene').render,'V'))
 local Pack=V.require('CobblemonPack')
 local reference=os.getenv('QA_PACK_REFERENCE')
 if reference then
  local old=assert(loadfile(reference))(V)
  for name,value in pairs(old)do Pack[name]=value end
 end
 local content=V.require('CobblemonContent');local record=content.record;local loads={}
 content.record=function(dex,variant,...)
  local t=love.timer.getTime();local value=record(dex,variant,...)
  loads[#loads+1]={dex=dex,variant=variant,ms=(love.timer.getTime()-t)*1000,
   map=game.overworld and game.overworld.map.id}
  return value
 end
 local quit=love.event.quit;love.event.quit=function(...)
  local f=assert(io.open(assert(os.getenv('SHOT_DIR'))..'/model-loads.json','w'))
  f:write(assert(require('src.link.Json').encode({loads=loads,reference=reference~=nil,
   residency=not reference and Pack.residency()or nil})));f:close();return quit(...)
 end
 -- Seed both standard sources. The live walk is still time-dependent; use
 -- the controlled model lifecycle test for numerical A/B claims.
 math.randomseed(290928);love.math.setRandomSeed(290928)
 return assert(loadfile(root..'/tests/native/rc27_model_travel.lua'))()(game)
end
