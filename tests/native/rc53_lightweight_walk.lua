-- Final full-visual walk with only callback/presentation timing. Avoid the
-- diagnostic wrappers on every model, light, texture and event callback.
return function(game)
 assert(os.getenv('POKEPORT_IDENTITY')=='vasc-video-polish-qa')
 local root=assert(os.getenv('QA_VASC_ROOT'));local original=loadfile
 local pipelines=require('src.render.Pipelines')
 local tilt=tonumber(os.getenv('QA_TILT_LEVEL'))
 if tilt then
  local set=pipelines.setLevel
  pipelines.setLevel=function(id,value)
   return set(id,id=='tiltshift'and tilt or value)
  end
 end
 loadfile=function(path,...)
  if path==root..'/tests/native/rc27_model_trace.lua'then
   return function()return function(V,game)
    local trace={frame=0,frames={},slowCalls={}}
    local now=love.timer.getTime
    local update,draw,present,quit=love.update,love.draw,love.graphics.present,love.event.quit
    local start,parts=now(),{}
    love.update=function(...)
     trace.frame=trace.frame+1;parts={};start=now()
     update(...);parts.update=(now()-start)*1000
    end
    love.draw=function(...)
     local t=now();draw(...);parts.draw=(now()-t)*1000
     trace.frames[#trace.frames+1]={frame=trace.frame,dt=love.timer.getDelta()*1000,
      cpuMs=(now()-start)*1000,parts=parts,map=game.overworld and game.overworld.map and game.overworld.map.id,
      covered=game.stack:top()~=game.overworld}
    end
    love.graphics.present=function(...)
     local t=now();present(...);parts['Loop.present']=(now()-t)*1000
    end
    love.event.quit=function(...)
     trace.tiltShift=pipelines.level('tiltshift')
     if tilt then assert(trace.tiltShift==tilt,'requested blur level not active')end
     local f=assert(io.open(assert(os.getenv('QA_STALL_TRACE')),'w'))
     f:write(assert(require('src.link.Json').encode(trace)));f:close();return quit(...)
    end
    local function wrap(owner,name,label)
     if label~='QA.pathToExit'then return end
     local fn=owner[name]
     owner[name]=function(...)
      local t=now();local result=fn(...)
      trace.slowCalls[#trace.slowCalls+1]={frame=trace.frame,label=label,ms=(now()-t)*1000}
      return result
     end
    end
    return trace,wrap
   end end
  end
  return original(path,...)
 end
 return assert(original(root..'/tests/native/rc50_step_refresh.lua'))()(game)
end
