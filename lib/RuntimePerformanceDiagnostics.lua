-- Bounded, memory-only evidence recorder. No automatic upload or per-frame I/O.
-- Wall time includes waits; these are CPU-side timings, not GPU timer queries.
local mod = ...
local R = {recent={}, worst={}, rows={}, stack={}, frameRows={}, hitches={}, worstHitches={}, epoch=0}
local clock = love and love.timer and love.timer.getTime
if type(clock) ~= "function" then
  R.wrap=function(_,value)return value end
  return R
end
local unpackValues = unpack or table.unpack
local function pack(...) return {n=select('#',...), ...} end
local function safe(v)
  if type(v)~='string' and type(v)~='number' and type(v)~='boolean' then return 'unknown' end
  return tostring(v):gsub('[\r\n%z]', ' '):sub(1,160)
end
local function call(fn, ...)
  if type(fn)~='function' then return 'unavailable','unavailable','unavailable','unavailable' end
  local ok,a,b,c,d=pcall(fn,...)
  if not ok then return 'unavailable','unavailable','unavailable','unavailable' end
  return safe(a),safe(b),safe(c),safe(d)
end
local selected={
  -- build() can yield over many frames. Its wall lifetime is neither CPU
  -- work nor a child of a later pump(); measure each actual pump slice.
  VoxelScene={render=true,prefetch=true,drawWater=true}, ChunkMesher={pump=true},
  TerrainAtlas={forMap=true,forSprite=true,prepare=true}, ShadowMap={begin=true,finish=true},
  HorizonWall={meshes=true}, PanoramaBackdrop={prepare=true,drawAt=true},
  WaterReflection={prepare=true,prepareProgram=true,draw=true},
  Voxel3D={beginScene=true,endScene=true,beginWater=true,endWater=true,newMesh=true,preparePokemonFrame=true},
  Gen1OverworldStadium={prepare=true}, VoxelPropBatch={prewarm=true}, LocalLights={prepare=true}, NativeWindowLights={append=true}, LocalLightGrid={prepare=true}, StaticLightField={prepare=true,beginFrame=true},
  StaticLightDiskCache={beginRead=true,stepRead=true,beginWrite=true,stepWrite=true},
  RegionPreparation={update=true}, WindowImageCache={draw=true},
  OverworldBattle={update=true,draw=true}, BattleScene={render=true},
  TiltShift={apply=true}, AntiAlias={resolve=true}, Diagnostics={writeMobileRecoveryMarker=true},
}
local wrapped=setmetatable({}, {__mode='k'})
local mainContext={stack=R.stack,pool={}}
local contexts=setmetatable({}, {__mode='k'})
local function context()
  local thread,isMain=coroutine.running()
  if not thread or isMain then return mainContext end
  local value=contexts[thread]
  if not value then value={stack={},pool={}};contexts[thread]=value end
  return value
end
local function measure(label, fn)
  if wrapped[fn] then return fn end
  local function completed(ctx,entry,start,ok,...)
    local elapsed=math.max(0,(clock()-start)*1000)
    local stack=ctx.stack
    stack[#stack]=nil
    -- A suspended coroutine's lifetime is not CPU work in its resume frame.
    if entry.epoch~=R.epoch then
      if not ok then error((...),0) end
      return ...
    end
    if #stack>0 and stack[#stack].epoch==R.epoch then stack[#stack].child=stack[#stack].child+elapsed end
    local fr=R.frameRows[label]
    if not fr then fr={calls=0,total=0,self=0,max=0};R.frameRows[label]=fr end
    fr.calls=fr.calls+1;fr.total=fr.total+elapsed
    fr.self=fr.self+math.max(0,elapsed-entry.child);fr.max=math.max(fr.max,elapsed)
    local row=R.rows[label]
    if not row then row={calls=0,total=0,self=0,max=0,errors=0};R.rows[label]=row end
    row.calls=row.calls+1;row.total=row.total+elapsed
    row.self=row.self+math.max(0,elapsed-entry.child);row.max=math.max(row.max,elapsed)
    if not ok then row.errors=row.errors+1;error((...),0) end
    return ...
  end
  local function wrappedFn(...)
    local ctx=context()
    local depth=#ctx.stack+1
    local entry=ctx.pool[depth]
    if not entry then entry={};ctx.pool[depth]=entry end
    entry.child=0;entry.epoch=R.epoch;ctx.stack[depth]=entry
    return completed(ctx,entry,clock(),pcall(fn,...))
  end
  wrapped[wrappedFn]=true
  return wrappedFn
end
function R.wrap(name,value)
  if name=='Diagnostics' then R.logger=value end
  if name=='VoxelScene' and type(value)=='table' and type(value.setPreparationCovered)=='function'
      and not wrapped[value.setPreparationCovered] then
    local fn=value.setPreparationCovered
    value.setPreparationCovered=function(covered,...)
      R.preparingCovered=covered==true
      return fn(covered,...)
    end
    wrapped[value.setPreparationCovered]=true
  end
  if type(value)=='table' and selected[name] then
    for key in pairs(selected[name]) do
      if type(value[key])=='function' then value[key]=measure(name..'.'..key,value[key]) end
    end
  end
  return value
end
local function scene(game)
  local top=game.stack and game.stack.top and game.stack:top()
  return safe(game.overworld and game.overworld.map and game.overworld.map.id),
    safe(top and ((top.screenId and (top.screenId..':'..tostring(top.phase or ''))) or top.phase or top.name or top.id or top.title) or 'world-or-menu')
end
-- One interval is previous draw start -> this draw start: previous draw,
-- following update, plus presentation/scheduling outside the game callbacks.
-- Do not label the latter GPU time: LÖVE exposes no GPU timer here.
local function frameBoundary(now,map,phase)
  local last=R.frameStart
  if last and (now-last)*1000>50 then
    local rows={}
    for name,row in pairs(R.frameRows) do
      if row.calls>0 then rows[#rows+1]={name=name,calls=row.calls,total=row.total,self=row.self,max=row.max} end
    end
    table.sort(rows,function(a,b)return a.self>b.self end)
    local update=R.frameRows['game.update'];local draw=R.frameRows['game.draw']
    local callbacks=(update and update.total or 0)+(draw and draw.total or 0)
    local ms=(now-last)*1000
    local record={frame=R.epoch,start=last,ms=ms,fromMap=R.frameMap,map=map,
      fromPhase=R.framePhase,phase=phase,covered=R.preparingCovered==true,fromCovered=R.frameCovered==true,
      callbackMs=callbacks,unattributedMs=math.max(0,ms-callbacks),rows=rows}
    -- Snapshot only on a hitch. No disk writes, stack traces or graphics sync.
    local ok,mem=pcall(collectgarbage,'count');if ok then record.luaKiB=mem end
    local stats=R.graphicsStats
    if stats then
      record.graphics={drawcalls=stats.drawcalls,texturememory=stats.texturememory,canvasswitches=stats.canvasswitches}
      record.graphicsAgeMs=R.lastGraphicsAt and (now-R.lastGraphicsAt)*1000
    end
    R.hitches[#R.hitches+1]=record;if #R.hitches>24 then table.remove(R.hitches,1) end
    R.worstHitches[#R.worstHitches+1]=record
    table.sort(R.worstHitches,function(a,b)return a.ms>b.ms end)
    if #R.worstHitches>8 then table.remove(R.worstHitches) end
  end
  for _,row in pairs(R.frameRows) do row.calls=0;row.total=0;row.self=0;row.max=0 end
  R.epoch=R.epoch+1;R.frameStart=now;R.frameMap=map;R.framePhase=phase;R.frameCovered=R.preparingCovered
end
local function closeWindow()
  local w=R.window
  if not w or w.frames==0 then return end
  w.mean=w.total/w.frames;w.fps=1000/math.max(.001,w.mean)
  local sorted={}
  for name,row in pairs(R.rows) do sorted[#sorted+1]={name=name,row=row} end
  table.sort(sorted,function(a,b)return a.row.self>b.row.self end)
  local lines={string.format('scene map=%s phase=%s frames=%d fps=%.2f meanMs=%.3f maxMs=%.3f over33=%d over100=%d',
    w.map,w.phase,w.frames,w.fps,w.mean,w.max,w.over33,w.over100)}
  for i=1,math.min(10,#sorted) do
    local e=sorted[i];local r=e.row
    lines[#lines+1]=string.format('timing %s calls=%d totalMs=%.3f selfMs=%.3f maxMs=%.3f errors=%d',e.name,r.calls,r.total,r.self,r.max,r.errors)
  end
  lines[#lines+1]=string.format('window startSeconds=%.3f endSeconds=%.3f',w.start,clock())
  local stats=R.graphicsStats or {}
  lines[#lines+1]='render-sample drawcalls='..safe(stats.drawcalls)..' textureBytes='..safe(stats.texturememory)..' canvasSwitches='..safe(stats.canvasswitches)
  local memOk,mem=pcall(collectgarbage,'count')
  if memOk then lines[#lines+1]='lua-memory-KiB='..safe(mem) end
  local record={mean=w.mean,peak=w.max,key=w.map..':'..w.phase,text=table.concat(lines,'\n')}
  R.recent[#R.recent+1]=record;if #R.recent>3 then table.remove(R.recent,1) end
  if w.mean>33.34 or w.max>100 then
    local found
    for i,old in ipairs(R.worst) do
      if old.key==record.key then
        found=true
        if record.peak>old.peak or (record.peak==old.peak and record.mean>old.mean) then R.worst[i]=record end
        break
      end
    end
    if not found then R.worst[#R.worst+1]=record end
    table.sort(R.worst,function(a,b)
      if a.peak~=b.peak then return a.peak>b.peak end
      return a.mean>b.mean
    end)
    if #R.worst>3 then table.remove(R.worst) end
  end
  R.window=nil;R.rows={}
end
function R.install(game)
  if not game or R.game==game then return end
  R.game=game; R.recent={};R.worst={};R.rows={};R.window=nil
  R.frameRows={};R.hitches={};R.worstHitches={};R.frameStart=nil;R.epoch=R.epoch+1
  R.lastGraphicsAt=nil;R.graphicsStats=nil
  local last,previousMap,previousPhase
  if type(game.update)=='function' then game.update=measure('game.update',game.update) end
  if type(game.draw)=='function' then
    local draw=measure('game.draw',game.draw)
    function game:draw(...)
      local now=clock();local map,phase=scene(self)
      frameBoundary(now,map,phase)
      if R.window and (map~=previousMap or phase~=previousPhase or now-R.window.start>=3) then closeWindow() end
      if not R.window then R.window={start=now,map=map,phase=phase,frames=0,total=0,max=0,over33=0,over100=0} end
      if last and map==previousMap and phase==previousPhase then
        local ms=math.max(0,(now-last)*1000);local w=R.window
        w.frames=w.frames+1;w.total=w.total+ms;w.max=math.max(w.max,ms)
        if ms>33.34 then w.over33=w.over33+1 end
        if ms>100 then w.over100=w.over100+1 end
      end
      last=now;previousMap=map;previousPhase=phase
      local result=pack(draw(self,...))
      if not R.lastGraphicsAt or now-R.lastGraphicsAt>=1 then
        R.lastGraphicsAt=now
        local ok,stats=pcall(function()return love.graphics.getStats()end)
        if ok and type(stats)=='table' then R.graphicsStats=stats end
      end
      return unpackValues(result,1,result.n)
    end
  end
end
function R.evidence()
  if not R.game then return 'runtime-evidence=waiting-for-game' end
  closeWindow()
  local g=R.game
  local renderer,version,vendor,device=call(love.graphics and love.graphics.getRendererInfo)
  local ok,engine=pcall(require,'src.core.Version')
  local major,minor,revision=call(love.getVersion)
  local lines={'runtime-evidence=3', 'engine='..safe(ok and type(engine)=='table' and engine.engine),
    'love='..major..'.'..minor..'.'..revision, 'renderer='..renderer,'renderer-version='..version,
    'gpu-vendor='..vendor,'gpu-device='..device,
    'processors='..call(love.system and love.system.getProcessorCount),
    'timing-kind=CPU wall time; inclusive and nested self time; GPU execution not measured',
    'capture=3-second windows; latest 3 and worst 3 retained; no automatic upload'}
  if love.graphics then
    local w,h=call(love.graphics.getDimensions);lines[#lines+1]='resolution='..w..'x'..h
    local pw,ph=call(love.graphics.getPixelDimensions);lines[#lines+1]='framebuffer='..pw..'x'..ph
    local stats=R.graphicsStats
    lines[#lines+1]='graphics-sampling=after-draw; at most once per second'
    if type(stats)=='table' then
      for _,k in ipairs({'drawcalls','canvasswitches','texturememory','images','canvases','shaders'}) do lines[#lines+1]='graphics.'..k..'='..safe(stats[k]) end
    end
  end
  local mods=g.mods and g.mods.mods
  if type(mods)=='table' then
    local ids={};for id in pairs(mods) do ids[#ids+1]=id end
    table.sort(ids,function(a,b)return tostring(a)<tostring(b)end)
    for i=1,math.min(40,#ids) do
      local id=ids[i];local m=mods[id];local manifest=m.manifest or {}
      lines[#lines+1]='mod='..safe(id)..' version='..safe(manifest.version)..' enabled='..safe(m.enabled)..' state='..safe(m.state)..' failed='..safe(m.failed or false)
    end
  else lines[#lines+1]='mod-inventory=unavailable' end
  local options=g.options or (g.save and g.save.options) or {}
  for _,key in ipairs({'vsync','fullscreen','resolution','renderer','shadows','aa','deviceProfile','preload'}) do
    if options[key]~=nil then lines[#lines+1]='option.'..key..'='..safe(options[key]) end
  end
  local own=options.modOptions and options.modOptions.VOXEL_ASCENDANT or {}
  for _,key in ipairs({'aa','sceneResolution','battles','battleHudStyle','deviceProfile','shadows','preload','scenery','sky','skyEvents','water','weather','daytime','pokemonModelSkin'}) do
    if own[key]~=nil then lines[#lines+1]='vasc-option.'..key..'='..safe(own[key]) end
  end
  for _,key in ipairs({'voxel','tiltshift','curve','zoom'}) do
    if options.pipelines and options.pipelines[key]~=nil then lines[#lines+1]='pipeline.'..key..'='..safe(options.pipelines[key]) end
  end
  lines[#lines+1]='hitch-capture=draw-start intervals >50ms; latest 24 and worst 8; graphics sample may be stale; unattributed includes presentation/scheduling'
  local seenHitches={}
  for _,kind in ipairs({'worstHitches','hitches'}) do
    for _,r in ipairs(R[kind]) do
      if not seenHitches[r] then
        seenHitches[r]=true
        lines[#lines+1]=string.format('hitch frame=%d ms=%.3f callbackMs=%.3f unattributedMs=%.3f fromMap=%s map=%s fromPhase=%s phase=%s covered=%s fromCovered=%s luaKiB=%s graphicsAgeMs=%s',
          r.frame,r.ms,r.callbackMs,r.unattributedMs,r.fromMap,r.map,r.fromPhase,r.phase,tostring(r.covered),tostring(r.fromCovered),safe(r.luaKiB),safe(r.graphicsAgeMs))
        if r.graphics then
          lines[#lines+1]='hitch-graphics drawcalls='..safe(r.graphics.drawcalls)..' textureBytes='..safe(r.graphics.texturememory)..' canvasSwitches='..safe(r.graphics.canvasswitches)
        end
        for i=1,math.min(10,#r.rows) do
          local row=r.rows[i]
          lines[#lines+1]=string.format('hitch-part %s calls=%d totalMs=%.3f selfMs=%.3f maxMs=%.3f',row.name,row.calls,row.total,row.self,row.max)
        end
      end
    end
  end
  local seen={}
  for _,kind in ipairs({'worst','recent'}) do
    for _,r in ipairs(R[kind]) do
      if not seen[r] then lines[#lines+1]='--- '..kind..' ---\n'..r.text;seen[r]=true end
    end
  end
  return table.concat(lines,'\n')
end
if mod.exports then mod.exports.runtimePerformanceDiagnostics=R end
if mod.events and type(mod.events.on)=='function' then
  mod.events:on('game.ready',function(payload) if payload then R.install(payload.game) end end)
end
return R
