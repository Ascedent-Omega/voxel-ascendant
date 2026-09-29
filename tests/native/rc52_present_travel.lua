-- Diagnostic only: time the host loop after draw and before the next update.
-- Late samples belong to the previous trace frame; compare them with next dt.
return function(game)
 assert(os.getenv('POKEPORT_IDENTITY')=='vasc-video-polish-qa')
 local root=assert(os.getenv('QA_VASC_ROOT'));local original=loadfile
 loadfile=function(path,...)
  local chunk=original(path,...)
  if path==root..'/tests/native/rc27_model_trace.lua'then
   return function(...)
    local install=chunk(...)
    return function(V,game)
     local trace,wrap=install(V,game)
     wrap(love.graphics,'present','Loop.present')
     wrap(love.event,'pump','Loop.eventPump')
     wrap(love.timer,'sleep','Loop.sleep')
     local sync=require('src.core.PresentSync')
     for _,name in ipairs{'waitBeforePresent','notePresent','applyFixedStepPeriod','hardwarePacesCap'}do
      wrap(sync,name,'Loop.'..name)
     end
     wrap(require('src.core.RefreshRate'),'sample','Loop.refreshSample')
     return trace,wrap
    end
   end
  end
  return chunk
 end
 local driver=os.getenv('QA_PRESENT_PREPARED')=='1'and 'rc50_step_refresh.lua'or 'rc51_provider_travel.lua'
 return assert(original(root..'/tests/native/'..driver))()(game)
end
