-- Reuse the real building-transition gates with the lightweight recorder
-- and explicitly enabled maximum tilt-shift, without changing production.
return function(game)
 assert(os.getenv('POKEPORT_IDENTITY')=='vasc-video-polish-qa')
 local root=assert(os.getenv('QA_VASC_ROOT'));local original=loadfile
 loadfile=function(path,...)
  if path==root..'/tests/native/rc50_step_refresh.lua'then
   path=root..'/tests/native/'..(os.getenv('QA_FINAL_CONTINUE')=='1'and 'rc41_continue.lua'or 'rc43_transitions.lua')
  end
  return original(path,...)
 end
 return assert(original(root..'/tests/native/rc53_lightweight_walk.lua'))()(game)
end
