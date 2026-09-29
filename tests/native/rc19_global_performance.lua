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
 if os.getenv('QA_STALL_TRACE')then require('tests.native.rc21_stall_trace')(V,game)end
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




 local field=V.require('StaticLightField');field.enabled=os.getenv('QA_STATIC_FIELD')~='off'
 local H=V.require('HorizonWall');local W=V.require('SilphWindows');local LL=V.require('LocalLights');local Scene=V.require('VoxelScene')
 local Chunk=V.require('ChunkMesher');local Neighborhood=V.require('VisibleNeighborhood')
 local json=require('src.link.Json')
 local renderedStats;local rawDraw=love.draw
 love.draw=function(...)rawDraw(...);renderedStats=love.graphics.getStats()end
 local rows={};local config={resolution=os.getenv('QA_RESOLUTION')or'balanced',
  tiltShift=tonumber(os.getenv('QA_TILT_SHIFT'))or 3,lighting=os.getenv('QA_LIGHTING')~='off',
  water=os.getenv('QA_WATER')or'saved',detailedHorizonProfile=os.getenv('QA_HORIZON_PROFILE')~=nil};local started=love.timer.getTime()
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



 local timings={};local peaks={};local calls={};local measured=false
 local function pack(...)return{n=select('#',...),...}end
 if os.getenv('QA_HORIZON_PROFILE')then
  local visited={};local count=0
  local names={addressOf=true,advanceJob=true,touch=true,trimReady=true,newBuildJob=true}
  local function instrument(root)
   if visited[root]then return end;visited[root]=true
   for i=1,100 do
    local name,fn=debug.getupvalue(root,i);if not name then break end
    if type(fn)=='function'then
     if names[name]then
      local label=name
      debug.setupvalue(root,i,function(...)
       local t=love.timer.getTime();local out=pack(fn(...));local elapsed=love.timer.getTime()-t
       if measured then
        local key='Horizon.'..label;timings[key]=(timings[key]or 0)+elapsed
        if label=='advanceJob'and elapsed>.0001 then
         local job=(...);local info=job.co and(debug.getinfo(job.co,2,'Sl')or debug.getinfo(job.co,1,'Sl'))
         local loc=info and(info.short_src..':'..info.currentline)or'dead'
         local k='Slice.'..loc;timings[k]=(timings[k]or 0)+elapsed;peaks[k]=math.max(peaks[k]or 0,elapsed*1000);calls[k]=(calls[k]or 0)+1
         if elapsed>.008 then print('SLOW_HORIZON_SLICE',loc,elapsed*1000,job.key)end
        end
       end
       return unpack(out,1,out.n)
      end);count=count+1
     else instrument(fn)end
    end
   end
  end
  instrument(H.meshes);print('PROFILE_HORIZON_FUNCTIONS',count);assert(count>0)
  local mesh=love.graphics.newMesh
  love.graphics.newMesh=function(...)
   local t=love.timer.getTime();local result=mesh(...)
   if measured then local elapsed=love.timer.getTime()-t;timings['GPU.newMesh']=(timings['GPU.newMesh']or 0)+elapsed;peaks['GPU.newMesh']=math.max(peaks['GPU.newMesh']or 0,elapsed*1000)end
   return result
  end
  local probe=mesh(3,'triangles','static')
  local methods=getmetatable(probe).__index;probe:release()
  for _,name in ipairs{'setVertices','setVertexMap'}do
   local raw=methods[name]
   methods[name]=function(...)
    local t=love.timer.getTime();local result=raw(...)
    if measured then local k='GPU.'..name;local elapsed=love.timer.getTime()-t;timings[k]=(timings[k]or 0)+elapsed;peaks[k]=math.max(peaks[k]or 0,elapsed*1000)end
    return result
   end
  end

 end
 if os.getenv('QA_FRAME_PROFILE')then
  for _,name in ipairs{'newCanvas','newImage','newShader'}do
   local raw=love.graphics[name]
   love.graphics[name]=function(...)
    local t=love.timer.getTime();local out=pack(raw(...))
    if measured then local k='Native.'..name;local dt=love.timer.getTime()-t;timings[k]=(timings[k]or 0)+dt;peaks[k]=math.max(peaks[k]or 0,dt*1000)end
    return unpack(out,1,out.n)
   end
  end
 end
 for _,spec in ipairs{{'LocalLights','prepare'},{'LocalLightGrid','prepare'},{'LocalLightGrid','sources'},{'LightVisibility','prepare'},
  {'VoxelFurniture','eachWorld'},{'ShadowMap','begin'},{'VoxelScene','render'},
  {'VoxelScene','prefetch'},{'ChunkMesher','pump'},{'HorizonWall','meshes'},
  {'VisibleNeighborhood','apply'},{'InteriorLights','prepare'},{'WindowImageCache','draw'},
  {'VoxelPropBatch','draw'},{'TerrainAtlas','prepare'},{'TerrainAtlas','forMap'},{'Voxel3D','newMesh'},
  {'Voxel3D','beginScene'},{'Voxel3D','endScene'},{'Voxel3D','worldCardsReady'},
  {'Voxel3D','preparePokemonFrame'},{'VoxelScene','drawWater'},{'CurrentRoom','prepare'},
  {'WaterActors','prepare'},{'WorldPokemonAnimation','prepare'},{'LightAtmosphere','draw'},
  {'WallDecals','drawState'},{'Voxel3D','shader'}}do
  local m=V.require(spec[1]);local fn=m[spec[2]]
  if type(fn)=='function'then m[spec[2]]=function(...)
   local t=love.timer.getTime();local out=pack(fn(...))
   if measured then local k=table.concat(spec,'.');local ms=love.timer.getTime()-t;timings[k]=(timings[k]or 0)+ms;peaks[k]=math.max(peaks[k]or 0,ms*1000);calls[k]=(calls[k]or 0)+1 end
   return unpack(out,1,out.n)
  end end
 end
 V.require('AntiAlias').resolution:setValue(os.getenv('QA_RESOLUTION')or'balanced',game,true)
 love.window.setMode(1710,958,{resizable=true,vsync=0})
 P.setLevel('voxel',6);P.setLevel('tiltshift',tonumber(os.getenv('QA_TILT_SHIFT'))or 3)
 if os.getenv('QA_WATER')then V.require('Water').setting:setValue(os.getenv('QA_WATER'),game,true)end
 V.require('WorldResidency').setting:setValue(tonumber(os.getenv('QA_CACHE_MB'))or 512,game,true)
 if os.getenv('QA_FLAT')then V.require('WorldCurve').setting:setValue(0,game,true)end
 local count=tonumber(os.getenv('QA_FRAMES'))or 600
 local up=game.update;game.update=function(...)local t=love.timer.getTime();local out=pack(up(...));if measured then timings.update=(timings.update or 0)+love.timer.getTime()-t end;return unpack(out,1,out.n)end
 local draw=love.draw;love.draw=function(...)local t=love.timer.getTime();draw(...);if measured then timings.draw=(timings.draw or 0)+love.timer.getTime()-t end end
 local diagnosticVariant
 local function sample(id,clock,light)
  measured=false;LL.setting:setValue(light,game,true);V.require('DayNight').setting:setValue(clock,game,true)
  local start=love.timer.getTime();U.teleport(game,id,18,18,'down');ready();U.wait(180)
  local map=game.overworld.map;local best
  for y=3,map.def.height*2-4 do
   local first
   for x=2,map.def.width*2-3 do
    local open=map:isWalkableCell(x,y) and not map:warpAtCell(x,y) and not game.overworld:npcAtCell(x,y)
    if open then first=first or x end
    if (not open or x==map.def.width*2-3)and first then
     local length=x-first;local score=length-math.abs(y-map.def.height)*.1
     if length>=12 and(not best or score>best.score)then best={x=math.floor((x+first)/2),y=y,score=score}end
     first=nil
    end
   end
  end
  assert(best,'no walkable test street');U.teleport(game,id,best.x,best.y,'right');ready();U.wait(180)
  if os.getenv('QA_LIGHT_PROFILE')then
   local visibility=find(V.require('LocalLightGrid').prepare,'visibility')
   if visibility and not visibility._qaProfiled then
    visibility._qaProfiled=true;local raw=visibility.prepare
    visibility.prepare=function(...)
     local t=love.timer.getTime();local out=raw(...);local elapsed=love.timer.getTime()-t
     if measured then local k='GridVisibility.prepare';timings[k]=(timings[k]or 0)+elapsed;peaks[k]=math.max(peaks[k]or 0,elapsed*1000);calls[k]=(calls[k]or 0)+1 end
     return out
    end
   end
  end
  local drive=0;local originalMove=fp.moveVector
  fp.moveVector=function()return -math.cos(fp.yaw)*drive,math.sin(fp.yaw)*drive end
  local load=love.timer.getTime()-start
  while game.stack:top()~=game.overworld do game.stack:pop()end
  local peakHidden,peakLOD=0,0;local times,positions={},{};local lo,hi=math.huge,-math.huge;timings={};peaks={};calls={};measured=true
  for i=1,count do
   fp.yaw=i/count*math.pi*4;fp.pitch=-.08
   drive=math.floor((i-1)/60)%2==0 and 1 or -1
   local prior={};if os.getenv('QA_FRAME_PROFILE')then for k,v in pairs(timings)do prior[k]=v end end
   local t=love.timer.getTime();U.wait(1);times[#times+1]=(love.timer.getTime()-t)*1000
   if os.getenv('QA_FRAME_PROFILE')and times[#times]>28 then
    local delta={};for k,v in pairs(timings)do local ms=(v-(prior[k]or 0))*1000;if ms>.15 then delta[k]=ms end end
    print('SLOW_FRAME '..assert(json.encode{frame=i,ms=times[#times],scale=V.require('FrameBudget').scale,parts=delta}))
   end
   lo=math.min(lo,game.overworld.player.px);hi=math.max(hi,game.overworld.player.px)
   local occ=V.require('PropOcclusion').last;peakHidden=math.max(peakHidden,occ.hidden or 0);peakLOD=math.max(peakLOD,occ.lods or 0)
   drive=0
   if i%150==0 then positions[#positions+1]={game.overworld.player.px,game.overworld.player.py}end
  end
  fp.moveVector=originalMove;assert(hi-lo>8,'benchmark did not walk');measured=false;table.sort(times);local total,over,over33=0,0,0
  for _,t in ipairs(times)do total=total+t;if t>16.7 then over=over+1 end;if t>33.4 then over33=over33+1 end end
  for k,v in pairs(timings)do timings[k]=v*1000/count end
  emit{distantTemplates=V.require('VoxelItems').distantCount,distantSavedVertices=V.require('VoxelItems').distantSavedVertices,peakHidden=peakHidden,peakLOD=peakLOD,curve=V.require('Voxel3D').curveK,occlusion=V.require('PropOcclusion').last,shadowBuilds=V.require('ShadowMap').staticBuilds,shadowReuses=V.require('ShadowMap').staticReuses,backgroundSkipped=V.require('BackgroundBudget').skipped,gridDynamics=LL.current().allLights and V.require('LocalLightGrid').prepare(LL.current(),LL,nil).dynamicCount,staticField=field.last,staticFieldError=field.lastError,map=id,clock=clock,lighting=light,diagnosticVariant=diagnosticVariant,tiltShift=V.require('TiltShift').level,horizon=H.buildStatus(),weather=os.getenv('QA_WEATHER')or'rain',frames=count,fps=count*1000/total,medianMs=times[math.ceil(count*.5)],p95Ms=times[math.ceil(count*.95)],p99Ms=times[math.ceil(count*.99)],maxMs=times[count],over16=over,over33=over33,timings=timings,peaks=peaks,calls=calls,positions=positions,loadSeconds=load,width=love.graphics.getWidth(),height=love.graphics.getHeight(),drawCalls=renderedStats.drawcalls,textureBytes=renderedStats.texturememory,luaKB=collectgarbage("count"),cache=V.require("WorldResidency").last,grid=V.require('LocalLightGrid').last,scale=V.require('FrameBudget').scale,renderSize={V.require('Voxel3D').size()}}
  fp.yaw=math.pi/2;fp.pitch=0;U.wait(3);assert(U.shot(game,dir..'/'..id..'-'..clock..'-'..tostring(light)..(diagnosticVariant and '-'..diagnosticVariant or '')..'.png'))
 end
 local maps={};for id in (os.getenv('QA_MAPS')or'SAFFRON_CITY,CELADON_CITY,VIRIDIAN_CITY,FUCHSIA_CITY'):gmatch('[^,]+')do maps[#maps+1]=id end
 for _,id in ipairs(maps)do
  if os.getenv('QA_ROUND2')then
   local variants={{'warmup',false,false,false,false},{'reference',false,false,false,false},
    {'visibility',true,false,false,false},{'blur',false,true,false,false},
    {'shadows',false,false,true,false},{'all',true,true,true,true},{'reference-repeat',false,false,false,false}}
   if os.getenv('QA_ROUND2_SHORT')then variants={{'warmup',false,false,false,false},{'reference',false,false,false,false},{'all',true,true,true,true},{'reference-repeat',false,false,false,false}}end
   for _,variant in ipairs(variants)do
    diagnosticVariant=variant[1]
    V.require('PropOcclusion').enabled=variant[2];V.require('DistantProps').enabled=variant[2]
    V.require('TiltShift').optimized=variant[3];V.require('ShadowMap').stableFootprint=variant[4]
    V.require('BackgroundBudget').enabled=variant[5]
    if os.getenv('QA_RETAINED')and variant[1]=='all'then
     diagnosticVariant='retained';V.require('PropOcclusion').enabled=false;V.require('TiltShift').optimized=false
    end
    sample(id,os.getenv('QA_CLOCK')or'night',true)
   end
  elseif os.getenv('QA_FIELD_PROBE')then
   local variants={{'cache',true},{'reference',false},{'cache-repeat',true}}
   if os.getenv('QA_FIELD_RECHECK')then variants[#variants+1]={'reference-repeat',false};variants[#variants+1]={'cache-final',true}end
   for _,variant in ipairs(variants)do
    diagnosticVariant=variant[1];field.enabled=variant[2];sample(id,'night',true)
   end
  elseif os.getenv('QA_EFFECT_PROBE')then
   for _,variant in ipairs{{'full',true,3},{'no-local-light',false,3},{'no-blur',true,0}}do
    diagnosticVariant=variant[1];P.setLevel('tiltshift',variant[3]);sample(id,'night',variant[2])
   end
  else sample(id,'night',os.getenv('QA_LIGHTING')~='off')end
 end
 print('PASS_MOVING_PERFORMANCE');love.event.quit(0)
end
