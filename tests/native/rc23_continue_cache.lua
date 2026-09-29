return function(game)
 assert(os.getenv('POKEPORT_IDENTITY')=='vasc-video-polish-qa')
 local root=assert(os.getenv('QA_VASC_ROOT'));local dir=assert(os.getenv('SHOT_DIR'))
 local function find(fn,name,seen)
  if type(fn)~='function'then return end;seen=seen or{};if seen[fn]then return end;seen[fn]=true
  for i=1,100 do local k,v=debug.getupvalue(fn,i);if not k then break end;if k==name then return v end end
  for i=1,100 do local k,v=debug.getupvalue(fn,i);if not k then break end;local got=find(v,name,seen);if got then return got end end
 end
 local V=assert(find(game.mods.exports.VOXEL_ASCENDANT.lib.require('VoxelScene').render,'V'))
 local C=V.require('StaticLightDiskCache')
 local oldKey=C.key;local salt=tostring(love.timer.getTime())
 C.key=function(signature)return oldKey(signature..salt)end -- fresh run, no destructive cache deletion
 if os.getenv('QA_REFERENCE_CACHE')then
  local V=assert(find(oldKey,'V'))
  local old=assert(loadfile(assert(os.getenv('QA_CACHE_BASELINE'))))(V)
  C.beginWrite=function(k,c)old.write(k,c);C.writes=old.writes;C.errors=old.errors end
  C.beginRead=function(k,w,h)return {key=k,width=w,height=h}end
  C.stepRead=function(t)local image=old.read(t.key,t.width,t.height);C.hits=old.hits;C.errors=old.errors;return true,image end
 end
 local timings={}
 for _,name in ipairs{'beginWrite','stepWrite','beginRead','stepRead'}do
  local raw=C[name];timings[name]={max=0,total=0,count=0}
  C[name]=function(...)
   local start=love.timer.getTime();local a,b=raw(...);local row=timings[name]
   local ms=(love.timer.getTime()-start)*1000;row.max=math.max(row.max,ms);row.total=row.total+ms;row.count=row.count+1
   return a,b
  end
 end
 local quit=love.event.quit
 love.event.quit=function(...)
  local f=assert(io.open(dir..'/cache-timings.json','w'))
  f:write(assert(require('src.link.Json').encode({timings=timings,stages=C.stageMaxMs,errors=C.errors,lastError=C.lastError,hits=C.hits,writes=C.writes})));f:close()
  return quit(...)
 end
 return assert(loadfile(root..'/tests/native/rc22_continue_hitches.lua'))()(game)
end
