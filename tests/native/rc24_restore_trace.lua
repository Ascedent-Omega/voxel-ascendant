return function(game)
 assert(os.getenv('POKEPORT_IDENTITY')=='vasc-video-polish-qa')
 local rows={};local frame=0;local stack={};local now=love.timer.getTime
 local update=love.update;love.update=function(...)frame=frame+1;return update(...)end
 local function pack(...)return {n=select('#',...),...}end
 local function wrap(t,k,label,event)
  local fn=t[k];if type(fn)~='function'then return end
  t[k]=function(...)
   local name=label..(event and ':'..tostring(select(1,...))or '')
   local entry={name=name,child=0,start=now(),frame=frame};stack[#stack+1]=entry
   local out=pack(fn(...));local elapsed=(now()-entry.start)*1000
   stack[#stack]=nil
   if stack[#stack]then stack[#stack].child=stack[#stack].child+elapsed end
   if elapsed>1 and #rows<20000 then rows[#rows+1]={name=name,frame=entry.frame,ms=elapsed,selfMs=elapsed-entry.child,parent=stack[#stack]and stack[#stack].name,covered=game.stack:top()~=game.overworld,trace=elapsed>10 and debug.traceback('',2)or nil}end
   return unpack(out,1,out.n)
  end
 end
 for _,n in ipairs{'applyOptions','adoptSave','restoreSave','bootConfig'}do wrap(game,n,'Game.'..n)end
 for _,n in ipairs{'runMigrations','modsDiff','validate','needsPostGameRescue','emptyReport'}do wrap(require('src.core.SaveData'),n,'SaveData.'..n)end
 local startNew=game.startNewGame
 game.startNewGame=function(...)
  local result=startNew(...)
  local methods={};for k,v in pairs(game.overworld)do if type(v)=='function'then methods[k]=true end end
  local mt=getmetatable(game.overworld);if mt and type(mt.__index)=='table'then for k,v in pairs(mt.__index)do if type(v)=='function'then methods[k]=true end end end
  for k in pairs(methods)do wrap(game.overworld,k,'Overworld.'..k)end
  return result
 end
 for _,n in ipairs{'emit','call'}do wrap(require('src.mods.Runtime'),n,'Runtime.'..n,true)end
 for _,n in ipairs{'load','trim','invalidate','releaseAll'}do wrap(require('src.world.MapLoader'),n,'MapLoader.'..n)end
 for _,n in ipairs{'applyOptions','setLevel','activate','deactivate'}do
  for _,module in ipairs{'src.render.Pipelines','src.render.ShaderFX','src.render.Tilt','src.core.Performance'}do wrap(require(module),n,module..'.'..n)end
 end
 local function find(fn,name,seen)
  if type(fn)~='function'then return end;seen=seen or{};if seen[fn]then return end;seen[fn]=true
  for i=1,100 do local k,v=debug.getupvalue(fn,i);if not k then break end;if k==name then return v end end
  for i=1,100 do local k,v=debug.getupvalue(fn,i);if not k then break end;local got=find(v,name,seen);if got then return got end end
 end
 local V=assert(find(game.mods.exports.VOXEL_ASCENDANT.lib.require('VoxelScene').render,'V'))
 for _,name in ipairs{'DeviceProfile','SpritePacks','LocalMusic','LocalSprites','LocalContent','DayNight','SkyEvents','Weather'}do
  wrap(V.require(name),'restore',name..'.restore')
 end
 for _,event in ipairs{'save.loaded','save.loading','map.entered'}do
  for i,entry in ipairs(require('src.mods.Runtime').events.listeners[event]or{})do
   local sources,seen={},{}
   local function origin(fn)
    if seen[fn]then return end;seen[fn]=true
    local info=debug.getinfo(fn,'S');sources[#sources+1]={source=info.source,line=info.linedefined}
    for n=1,50 do local key,value=debug.getupvalue(fn,n);if not key then break end;if type(value)=='function'then origin(value)end end
   end
   origin(entry.callback)
   rows[#rows+1]={name='origin:'..event..':'..tostring(entry.owner)..':'..i,ms=0,selfMs=0,frame=0,sources=sources}
   wrap(entry,'callback','listener:'..event..':'..tostring(entry.owner)..':'..i)
  end
 end
 local rules=game.mods.exports.kanto_ascendant.generationRules
 local sync=rules.syncData
 for i=1,100 do
  local name,value=debug.getupvalue(sync,i);if not name then break end
  if type(value)=='function'then local holder={call=value};wrap(holder,'call','generation.'..name);debug.setupvalue(sync,i,holder.call)end
 end
 wrap(rules,'syncData','generation.syncData')
 wrap(game.mods.exports.kanto_ascendant.generationTypeMatchups67,'apply','generation.matchups')
 local quit=love.event.quit
 love.event.quit=function(...)
  local f=assert(io.open(assert(os.getenv('SHOT_DIR'))..'/restore-trace.json','w'));f:write(assert(require('src.link.Json').encode(rows)));f:close();return quit(...)
 end
 return assert(loadfile(assert(os.getenv('QA_VASC_ROOT'))..'/tests/native/rc22_continue_hitches.lua'))()(game)
end
