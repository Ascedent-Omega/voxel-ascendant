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
     local grid=V.require('LocalLightGrid')
     local function localValue(fn,name,seen)
      if type(fn)~='function'then return end
      seen=seen or{};if seen[fn]then return end;seen[fn]=true
      for i=1,100 do local k,v=debug.getupvalue(fn,i);if not k then break end
       if k==name then return v,fn,i end
      end
      for i=1,100 do local k,v=debug.getupvalue(fn,i);if not k then break end
       local found,owner,index=localValue(v,name,seen);if found then return found,owner,index end
      end
     end
     for _,name in ipairs{'sources','layout'}do wrap(grid,name,'grid.'..name)end
     local prepare=grid.prepare;local installed
     grid.prepare=function(...)
      local visibility=localValue(prepare,'visibility')
      if visibility and not installed then
       installed=true
       for _,name in ipairs{'signature','emitterPlan'}do
        local fn,owner,index=localValue(visibility.prepare,name)
        assert(fn,'missing '..name);local box={call=fn};wrap(box,'call','grid.visibility.'..name);debug.setupvalue(owner,index,box.call)
       end
       wrap(visibility,'prepare','grid.visibility.prepare')
      end
      return prepare(...)
     end
     return trace,wrap
    end
   end
  end
  return chunk
 end
 return assert(original(root..'/tests/native/rc34_light_travel.lua'))()(game)
end
