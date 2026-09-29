return function(game)
 assert(os.getenv('POKEPORT_IDENTITY')=='vasc-video-polish-qa');love.audio.setVolume(0)
 local root=assert(os.getenv('QA_VASC_ROOT'));local dir=assert(os.getenv('SHOT_DIR'))
 local function find(fn,name,seen)
  if type(fn)~='function'then return end;seen=seen or{};if seen[fn]then return end;seen[fn]=true
  for i=1,100 do local k,v=debug.getupvalue(fn,i);if not k then break end;if k==name then return v end end
  for i=1,100 do local k,v=debug.getupvalue(fn,i);if not k then break end;local got=find(v,name,seen);if got then return got end end
 end
 local V=assert(find(game.mods.exports.VOXEL_ASCENDANT.lib.require('VoxelScene').render,'V'))
 local R=V.require('WaterReflection');local raw=R.prepare;local allocations={};local continuing=false
 local title=game.returnToTitle
 game.returnToTitle=function(self,...)
  local result=title(self,...);local screen=self.stack:top();local proceed=screen.onContinue
  screen.onContinue=function(...)
   local slot=find(V.require('Voxel3D').beginWater,'held');if slot then R.release(slot)end
   R.invalidate();allocations={};continuing=true;return proceed(...)
  end
  return result
 end
 R.prepare=function(slot)
  local cold=slot and slot.waterReflection==nil;local t=love.timer.getTime();local result=raw(slot)
  if cold and result then
   local top=game.stack:top();local loading=V.require('LoadingCompanion').status()
   allocations[#allocations+1]={continuing=continuing,continueCover=top and top.vascContinue==true,loading=loading.visible==true,
    inWorld=top==game.overworld,w=result.w,h=result.h,ms=(love.timer.getTime()-t)*1000}
  end
  return result
 end
 local quit=love.event.quit
 love.event.quit=function(...)
  assert(not R.lastError and not R.lastPaintError,R.lastError or R.lastPaintError)
  assert(#allocations>0,'cold target was not exercised')
  for _,a in ipairs(allocations)do assert(not(a.continuing and a.inWorld and not a.loading),'late reflection target allocation')end
  local f=assert(io.open(dir..'/reflection-preparation.json','w'));f:write(assert(require('src.link.Json').encode(allocations)));f:close()
  print('PASS_WATER_CONTINUE_PREPARATION',#allocations)
  return quit(...)
 end
 return assert(loadfile(root..'/tests/native/rc22_continue_hitches.lua'))()(game)
end
