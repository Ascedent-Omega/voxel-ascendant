return function(game)
 assert(os.getenv('POKEPORT_IDENTITY')=='vasc-video-polish-qa')
 love.audio.setVolume(0)
 io.stdout:setvbuf('no');love.window.hasFocus=function()return true end;love.window.isVisible=function()return true end
 local U=require('tests.drivers.util');game:startNewGame{intro=false}
 local ex=game.mods.exports.VOXEL_ASCENDANT;assert(not os.getenv('EXPECTED_VASC_VERSION')or ex.packageVersion==os.getenv('EXPECTED_VASC_VERSION'),'wrong packed version');ex.setupCard.suspended=true
 ex.ascendantContent.promptDisabled=true;ex.ascendantContent.onboardingShown=true
 local function find(fn,name,seen)
  if type(fn)~='function'then return end;seen=seen or{};if seen[fn]then return end;seen[fn]=true
  for i=1,100 do local k,v=debug.getupvalue(fn,i);if not k then break end;if k==name then return v end end
  for i=1,100 do local k,v=debug.getupvalue(fn,i);if not k then break end;local got=find(v,name,seen);if got then return got end end
 end
 local rawUpdate=game.update;game.update=function(self,dt)return require('src.mods.Runtime').call('core.update',rawUpdate,self,dt)end
 local V=assert(find(ex.lib.require('VoxelScene').render,'V'));local P=require('src.render.Pipelines')
 V.require('PokemonModelProvider').setting:setValue('cobblemon',game)
 local dir=assert(os.getenv('SHOT_DIR'));local fp=V.require('FirstPerson')
 local coverCache=V.require('ContinuePreparation');local cached=coverCache.cachedScene
 local reuseCount=0
 coverCache.cachedScene=function(...)
  if os.getenv('QA_DISABLE_SCENE_HOLD')then return end
  local canvas=cached(...);if canvas then reuseCount=reuseCount+1 end;return canvas
 end
 V.require('Gen1PalletVillage').buildings:setValue(true,game,true)
 V.require('SilphWindows').setting:setValue(true,game,true)
 if os.getenv('QA_STALL_TRACE')then assert(loadfile(assert(os.getenv('QA_VASC_ROOT'))..'/tests/native/rc27_model_trace.lua'))()(V,game)end
 game.save.flags.EVENT_FOLLOWED_OAK_INTO_LAB=true;game.save.flags.EVENT_GOT_STARTER=true
 game.save.flags.EVENT_BEAT_BROCK=true;game.save.flags.EVENT_BEAT_PEWTER_GYM_TRAINER_0=true
 V.require('CalendarEvents').setting:setValue('halloween',game)
 V.require('Weather').setting:setValue(os.getenv('QA_WEATHER')or'rain',game)
 V.require('VoxelGrid').setting:setValue(false,game,true)
 V.require('DayNight').setting:setValue('night',game,true)
 love.window.setMode(1200,800,{resizable=true,vsync=0})
 local Screens=require('src.ui.Screens')
 local menu=Screens.push(game,'VascSettings',{section='pokemon'})
 for _,r in ipairs(menu.items)do
  if r.settingKey=='apo_pokemon_model_source'or r.settingKey=='apo_follower_sprite_source'or r.settingKey=='modernDexSpriteSource'then
   local owner=find(r.descriptor.step,'self_');if owner then owner:setValue('cobblemon',game,true);print('SET',r.settingKey,owner:get())end
  end
 end
 game.stack:pop()

 ex.voxelCharacterCard.setting:setValue(true,game);assert(ex.voxelCharacterCard.select('voxel',game))
 V.require('CalendarEvents').setting:setValue('off',game)
 V.require('DayNight').setting:setValue('day',game,true)


 P.setLevel('tiltshift',0);P.setLevel('voxel',1)




 local H=V.require('HorizonWall');local W=V.require('SilphWindows');local LL=V.require('LocalLights');local Scene=V.require('VoxelScene')
 local Chunk=V.require('ChunkMesher');local Neighborhood=V.require('VisibleNeighborhood')
 local json=require('src.link.Json')
 local renderedStats;local rawDraw=love.draw
 love.draw=function(...)rawDraw(...);renderedStats=love.graphics.getStats()end
 local rows={};local config={};local started=love.timer.getTime()
 local function emit(row)
  rows[#rows+1]=row
  print('RESULT_JSON '..assert(json.encode(row)))
  local f=assert(io.open(dir..'/results.json','w'));f:write(assert(json.encode({config=config,rows=rows},{indent=true})));f:close()
 end
 local function ready()
  for i=1,1000 do
   local plan=Scene.planStatus();local active=plan and plan.active
   if V.require('VoxelState').ready and active and active.rootId==game.overworld.map.id and not Chunk.hasPriorityWork()then return end
   U.wait(1)
  end
  error('readiness timeout '..game.overworld.map.id)
 end
 P.setLevel('voxel',7);LL.setting:setValue(true,game,true)
 V.require('PerformanceOverlay').enabled:setValue(false,game,true)



 V.require('AntiAlias').resolution:setValue('balanced',game,true)
 love.window.setMode(1710,958,{resizable=true,vsync=0})
 P.setLevel('voxel',6);P.setLevel('tiltshift',3)
 V.require('DayNight').setting:setValue('night',game,true)
 V.require('WorldResidency').setting:setValue(tonumber(os.getenv('QA_CACHE_MB'))or 512,game,true)
 for _,id in ipairs(os.getenv('QA_CONTINUE_MAP')and {os.getenv('QA_CONTINUE_MAP')}or{'SAFFRON_CITY','CELADON_CITY','SILPH_CO_6F'})do
  if os.getenv('QA_LAST_OUTDOOR')then game.save.lastOutdoor={id=os.getenv('QA_LAST_OUTDOOR'),x=5,y=5}end
  U.teleport(game,id,tonumber(os.getenv('QA_START_X'))or(id=='SILPH_CO_6F'and 17 or 18),tonumber(os.getenv('QA_START_Y'))or(id=='SILPH_CO_6F'and 5 or 18),'down');ready();U.wait(3)
  local player=game.overworld.player
  game.save.player.map=id;game.save.player.x=player.cellX;game.save.player.y=player.cellY
  assert(require('src.core.SaveData').save(game.save,game.modStatus.loaded))
  game:returnToTitle();U.wait(3)
  H.invalidate();Chunk.invalidate();V.require('WorldSceneHold').clear()
  local title=game.stack:top();assert(type(title.onContinue)=='function')
  local start=love.timer.getTime();title.onContinue()
  local cover=game.stack:top();assert(cover.vascContinue and not cover.drawn)
  local frames,largest=0,0;local firstDraw,sceneReady,presented
  local originalSerial=V.require('WorldSceneHold').serial()
  while game.stack:top()~=game.overworld and frames<30000 and love.timer.getTime()-start<180 do
   local tick=love.timer.getTime();U.wait(1);frames=frames+1
   largest=math.max(largest,(love.timer.getTime()-tick)*1000)
   local elapsed=love.timer.getTime()-start
   if cover.drawn and not firstDraw then firstDraw=elapsed end
   if Scene.readyForReveal(game.overworld)and not sceneReady then sceneReady=elapsed end
   if V.require('WorldSceneHold').serial()>originalSerial and not presented then presented=elapsed end
   if frames%300==0 then print('REGION_PROGRESS',assert(json.encode(V.require('RegionPreparation').status(cover.region)or{})))end
   if frames==2 then assert(U.shot(game,dir..'/'..id..'-loading.png'))end
  end
  assert(game.stack:top()==game.overworld,'Continue preparation stuck '..id)
  assert(game.overworld.map.id==id and Scene.readyForReveal(game.overworld),'Continue revealed incomplete destination')
  assert(Scene.resumeNeighborhoodReady(game.overworld),'Continue skipped direct neighbour preparation')
  assert(not V.require('LoadingCompanion').status().visible)
  local region=assert(V.require('RegionPreparation').status(cover.region),'region not started')
  assert(not region.error,region.error)
  assert(region.phase=='done','region unfinished')
  local cached={}
  for _,mid in ipairs(region.ids)do
   cached[mid]=true
   if not region.skipped[mid]then
    local m=assert(require('src.world.MapLoader').cached(mid))
    assert(Chunk.ready(m,H.preferBody(m))and Chunk.auxReady(m)and V.require('TerrainAtlas').prepared(m),'incomplete prepared map '..mid)
   end
  end
  if os.getenv('QA_LAST_OUTDOOR')then assert(cached[os.getenv('QA_LAST_OUTDOOR')],'indoor Continue lost outdoor area')end
  if os.getenv('QA_EXPECT_REGION_MIN')then assert(region.prepared>=tonumber(os.getenv('QA_EXPECT_REGION_MIN')),'too few prepared maps')end
  local seconds=love.timer.getTime()-start
  assert(U.shot(game,dir..'/'..id..'-ready.png'))
  if os.getenv('QA_GC_PROBE')then
   local before=collectgarbage('count');local tick=love.timer.getTime();collectgarbage('collect')
   print('GC_PROBE',id,before,collectgarbage('count'),(love.timer.getTime()-tick)*1000)
   local blocked={[game]=true,[game.mods]=true,[game.mods.exports]=true}
   for _,m in pairs(game.mods.mods or{})do blocked[m]=true end
   for _,m in pairs(game.mods.exports or{})do if type(m)=='table'then blocked[m]=true end end
   local function size(root)
    local seen,queue={},{};if type(root)=='table'then queue[1]=root end
    local tables,entries,strings=0,0,0
    while #queue>0 do
     local t=table.remove(queue)
     if not seen[t]and(t==root or not blocked[t])then
      seen[t]=true;tables=tables+1
      for k,v in pairs(t)do
       entries=entries+1
       if type(k)=='table'and not seen[k]then queue[#queue+1]=k end
       if type(v)=='table'and not seen[v]then queue[#queue+1]=v elseif type(v)=='string'then strings=strings+#v end
      end
     end
    end
    return tables,entries,strings
   end
   for _,spec in ipairs{{'Structures','forMap','cache'},{'HorizonWall','meshes','readyCaches'},{'VoxelFurniture','find','cache'},{'VoxelItems','resolveKind','cache'}}do
    local m=V.require(spec[1]);local c=find(m[spec[2]],spec[3]);print('HEAP_OWNER',spec[1],size(c))
    if spec[1]=='Structures'and c then for key,v in pairs(c)do print('HEAP_MAP',key,size(v))end end
   end
   local jobs=find(H.meshes,'pendingJobs')or{}
   for key,job in pairs(jobs)do
    for level=1,16 do for index=1,40 do
     local ok,name,value=pcall(debug.getlocal,job.co,level,index)
     if not ok or not name then break end
     if type(value)=='table'then local n,e,b=size(value);if n>20000 then print('HEAP_JOB',level,name,n,e,b)end end
    end end
   end
   local seenFn,seenTable={},{}
   local function inspect(label,fn)
    if seenFn[fn]then return end;seenFn[fn]=true
    for i=1,100 do
     local name,value=debug.getupvalue(fn,i);if not name then break end
     if type(value)=='function'then inspect(label,value)
     elseif type(value)=='table'and name~='V'and name~='mod'and name~='_ENV'and not seenTable[value]then
      seenTable[value]=true;local n,e,b=size(value)
      if n>100000 or e>500000 or b>10000000 then print('HEAP_CAPTURE',label,name,n,e,b)end
     end
    end
   end
   local all=os.getenv('QA_HEAP_CAPTURES')and find(V.require,'modules')or{}
   for name,m in pairs(all)do if type(m)=='table'then for _,fn in pairs(m)do if type(fn)=='function'then inspect(name,fn)end end end end
   print('HEAP_MODELS',size(V.require('VoxelItems').models))
   print('HEAP_GAME_DATA',size(game.data))
   for key,t in pairs(game.mods.content)do local n,e,b=size(t);if n>20000 then print('HEAP_REGISTRY',key,n,e,b)end end
   for key,t in pairs(game.mods.exports)do local n,e,b=size(t);if n>20000 then print('HEAP_EXPORT',key,n,e,b)end end
   for key,t in pairs(game.mods.exports.kanto_ascendant or{})do local n,e,b=size(t);if n>50000 then print('HEAP_KASC_FIELD',key,n,e,b)end end

   if os.getenv('QA_HEAP_ARRAYS')then
    local seen={};local rows={}
    local function scan(t,path)
     if type(t)~='table'or seen[t]then return end;seen[t]=true
     if #t>1000 then rows[#rows+1]={path=path,n=#t};return end
     for k,v in pairs(t)do if type(v)=='table'then scan(v,path..'.'..tostring(k))end end
    end
    scan(game,'game');table.sort(rows,function(a,b)return a.n>b.n end)
    for i=1,math.min(50,#rows)do print('HEAP_ARRAY',rows[i].path,rows[i].n)end
   end


  end
  local playback
  if os.getenv('QA_POST_FRAMES')then
   local times={};local count=tonumber(os.getenv('QA_POST_FRAMES'))
   for i=1,count do
    fp.yaw=i/count*math.pi*4;fp.pitch=-.08
    local tick=love.timer.getTime();U.wait(1);times[i]=(love.timer.getTime()-tick)*1000
   end
   table.sort(times);local total=0;for _,ms in ipairs(times)do total=total+ms end
   playback={frames=count,fps=count*1000/total,p95Ms=times[math.ceil(count*.95)],maxMs=times[count],luaKB=collectgarbage('count'),textureBytes=renderedStats.texturememory}
  end
  emit{hiddenSceneReuses=reuseCount,staticField=V.require('StaticLightField').last,fieldError=V.require('StaticLightField').lastError,fieldDisk={hits=V.require('StaticLightDiskCache').hits,writes=V.require('StaticLightDiskCache').writes,errors=V.require('StaticLightDiskCache').errors},batchPrepared=V.require('VoxelPropBatch').preparedTemplates,playback=playback,region=region,map=id,loadSeconds=seconds,coverFrames=frames,firstCoverSeconds=firstDraw,
   sceneReadySeconds=sceneReady,presentedSeconds=presented,maxCoveredFrameMs=largest,
   horizon=H.buildStatus(),plan=Scene.planStatus()}
 end
 print('PASS_COLD_CONTINUE');love.event.quit(0)
end
