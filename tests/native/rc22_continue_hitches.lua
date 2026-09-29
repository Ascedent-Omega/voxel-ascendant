-- Existing Continue/reveal contract with the production bounded hitch report.
return function(game)
 assert(os.getenv('POKEPORT_IDENTITY')=='vasc-video-polish-qa')
 local original=love.event.quit
 love.event.quit=function(...)
  local r=assert(game.mods.exports.VOXEL_ASCENDANT.runtimePerformanceDiagnostics)
  local f=assert(io.open(assert(os.getenv('SHOT_DIR'))..'/hitches.txt','w'));f:write(r.evidence());f:close()
  local j=assert(io.open(os.getenv('SHOT_DIR')..'/hitches.json','w'))
  j:write(assert(require('src.link.Json').encode({recent=r.hitches,worst=r.worstHitches})));j:close()
  return original(...)
 end
 return assert(loadfile(assert(os.getenv('QA_VASC_ROOT'))..'/tests/native/rc19_cold_continue.lua'))()(game)
end
