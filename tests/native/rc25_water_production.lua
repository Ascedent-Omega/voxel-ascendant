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
 if os.getenv('QA_CURVE')then V.require('WorldCurve').setting:setValue(tonumber(os.getenv('QA_CURVE')),game,true)end
 V.require('DayNight').setting:setValue(os.getenv('QA_CLOCK')or'night',game,true)
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




 local json=require('src.link.Json')
 local Scene=V.require('VoxelScene');local Chunk=V.require('ChunkMesher');local LL=V.require('LocalLights')
 local water=V.require('Water');local weather=V.require('Weather')
 local diagnostics=assert(ex.runtimePerformanceDiagnostics)
 local results={};local count=tonumber(os.getenv('QA_FRAMES'))or 360
 love.window.setMode(1710,958,{resizable=true,vsync=0})
 V.require('AntiAlias').resolution:setValue('balanced',game,true)
 V.require('WorldResidency').setting:setValue(128,game,true)
 V.require('PerformanceOverlay').enabled:setValue(false,game,true)
 V.require('DayNight').setting:setValue(os.getenv('QA_CLOCK')or'night',game,true)
 P.setLevel('voxel',6);P.setLevel('tiltshift',3)
 local chosenShader,qualityArgs
 local measured=false;local waterDraws=0;local timings={};local calls={}
 local renderedStats;local rawLoveDraw=love.draw
 love.draw=function(...)rawLoveDraw(...);renderedStats=love.graphics.getStats()end
 local function pack(...)return {n=select('#',...),...}end
 local function wrap(owner,key,label)
  local fn=owner[key];if type(fn)~='function'then return end
  owner[key]=function(...)
   local t=love.timer.getTime();if label=='VoxelScene.render'then qualityArgs=pack(...)end;local out=pack(fn(...))
   if measured then timings[label]=(timings[label]or 0)+(love.timer.getTime()-t)*1000;calls[label]=(calls[label]or 0)+1 end
   return unpack(out,1,out.n)
  end
 end
 for _,spec in ipairs{{'VoxelScene','render'},{'VoxelScene','drawWater'},{'TiltShift','apply'},{'LocalLights','prepare'},{'LocalLightGrid','prepare'},{'Voxel3D','endScene'}}do wrap(V.require(spec[1]),spec[2],table.concat(spec,'.'))end
 wrap(water,'draw','Water.draw')


 local R=V.require('WaterReflection');local rawReflection=R.draw
 R.draw=function(...)if not chosenShader then return end;return rawReflection(...)end
 local originalMove=fp.moveVector;fp.moveVector=function()return 0,0 end
 local function ready()
  for i=1,1200 do
   local plan=Scene.planStatus();local a=plan and plan.active
   if V.require('VoxelState').ready and a and a.rootId==game.overworld.map.id and not Chunk.hasPriorityWork()then return end
   U.wait(1)
  end
  error('readiness timeout')
 end
 local maps={};for id in(os.getenv('QA_MAPS')or'CELADON_CITY,SAFFRON_CITY'):gmatch('[^,]+')do maps[#maps+1]=id end
 local variants={{'full-a','full',true,3},{'water-off','off',true,3},{'full-b','full',true,3},
  {'lights-off','full',false,3},{'full-c','full',true,3},{'blur-off','full',true,0},{'full-d','full',true,3},
  {'water-sky','sky',true,3},{'full-e','full',true,3}}
 if os.getenv('QA_LIGHT_ONLY')then variants={{'full-a','full',true,3},{'lights-off','full',false,3},{'full-b','full',true,3},{'lights-off-repeat','full',false,3},{'full-c','full',true,3}}end
 if os.getenv('QA_PAIRED')then
  variants={}
  for view=1,4 do
   for _,effect in ipairs{{'water','off',true,3},{'lights','full',false,3},{'blur','full',true,0}}do
    local key='view'..view..'-'..effect[1];local yaw=(view-1)*math.pi*.5
    variants[#variants+1]={key..'-before','full',true,3,yaw}
    variants[#variants+1]={key..'-off',effect[2],effect[3],effect[4],yaw}
    variants[#variants+1]={key..'-after','full',true,3,yaw}
   end
  end
 end
 if os.getenv('QA_UNIFIED')then
  variants={}
  for view=1,4 do
   for round=1,2 do
    local key='view'..view..'-round'..round;local yaw=(view-1)*math.pi*.5
    variants[#variants+1]={key..'-before','full',true,3,yaw,false}
    variants[#variants+1]={key..'-unified','full',true,3,yaw,true}
    variants[#variants+1]={key..'-after','full',true,3,yaw,false}
   end
  end
 end
 if os.getenv('QA_UNIFIED_MOVING')then variants={{'reference-before','full',true,3,nil,false},{'shared','full',true,3,nil,true},{'reference-after','full',true,3,nil,false}}end

 if os.getenv('QA_DEPTH_FIXED') then
  variants={}
  for view=3,4 do for round=1,2 do for _,candidate in ipairs{false,true,false}do
   variants[#variants+1]={'view'..view..'-round'..round..'-'..#variants,'full',true,3,(view-1)*math.pi*.5,candidate}
  end end end
 end
 for _,id in ipairs(maps)do
  U.teleport(game,id,18,18,'down');ready();U.wait(120)
  local map=game.overworld.map;local best
  for y=3,map.def.height*2-4 do
   local first
   for x=2,map.def.width*2-3 do
    local open=map:isWalkableCell(x,y)and not map:warpAtCell(x,y)and not game.overworld:npcAtCell(x,y)
    if open then first=first or x end
    if(not open or x==map.def.width*2-3)and first then
     local length=x-first;local score=length-math.abs(y-map.def.height)*.1
     if length>=12 and(not best or score>best.score)then best={x=math.floor((x+first)/2),y=y,score=score}end
     first=nil
    end
   end
  end
  if os.getenv('QA_DEPTH_FIXED') and id=='CELADON_CITY' then best={x=24,y=23} end
  assert(best);U.teleport(game,id,best.x,best.y,'down');ready()
  while game.stack:top()~=game.overworld do game.stack:pop()end
  local px,py=game.overworld.player.px,game.overworld.player.py
  for i=1,720 do fp.yaw=i/720*math.pi*4;fp.pitch=-.08;U.wait(1)end
  if os.getenv('QA_UNIFIED')then
   for view=1,8 do
    fp.yaw=(view-1)*math.pi*.25;U.wait(2);assert(qualityArgs)
    chosenShader=false;local a=assert(Scene.render(unpack(qualityArgs,1,qualityArgs.n))):newImageData()
    chosenShader=true;local b=assert(Scene.render(unpack(qualityArgs,1,qualityArgs.n))):newImageData()
    local difference,worst,sum=0,0,0
    for y=0,a:getHeight()-1 do for x=0,a:getWidth()-1 do
     local r,g,bb=a:getPixel(x,y);local rr,gg,bv=b:getPixel(x,y)
     local delta=math.max(math.abs(r-rr),math.abs(g-gg),math.abs(bb-bv));worst=math.max(worst,delta);sum=sum+delta
     if delta>1/255+.00001 then difference=difference+1 end
    end end
    print('WATER_PRODUCTION_PIXEL_COMPARE',id,view,difference,worst,sum/(a:getWidth()*a:getHeight()))
    for name,data in pairs{reference=a,candidate=b}do
     local f=assert(io.open(dir..'/'..id..'-view'..view..'-'..name..'.png','wb'));f:write(data:encode('png'):getString());f:close();data:release()
    end
   end
  end
  for _,variant in ipairs(variants)do
   if variant[6]~=nil then chosenShader=variant[6] end
   water.setting:setValue(variant[2],game,true);LL.setting:setValue(variant[3],game,true);P.setLevel('tiltshift',variant[4])
   -- Warm every camera direction for each shader combination before timing.
   for i=1,(variant[5] and 24 or count) do fp.yaw=variant[5] or i/count*math.pi*2;fp.pitch=-.08;U.wait(1)end
   assert(LL.enabled()==variant[3],'lighting mismatch: '..tostring(LL.failure))
   assert(V.require('TiltShift').level==variant[4],'blur mismatch')
   timings={};calls={};measured=true;local frames={};weather.clock=120
   for i=1,count do
    fp.yaw=variant[5] or i/count*math.pi*2;fp.pitch=-.08
    assert(game.overworld.player.px==px and game.overworld.player.py==py,'camera origin moved')
    local t=love.timer.getTime();U.wait(1);frames[i]=(love.timer.getTime()-t)*1000
   end
   assert(not R.lastError and not R.lastPaintError,R.lastError or R.lastPaintError)
   measured=false;local sorted={};local total=0
   for i,ms in ipairs(frames)do sorted[i]=ms;total=total+ms end;table.sort(sorted)
   for k,ms in pairs(timings)do timings[k]=ms/count end
   local row={map=id,variant=variant[1],water=water.level(),lights=LL.enabled(),blur=V.require('TiltShift').level,
    optimizedReflection=chosenShader,frames=frames,meanMs=total/count,fps=count*1000/total,p95=sorted[math.ceil(count*.95)],p99=sorted[math.ceil(count*.99)],maxMs=sorted[count],
    timings=timings,calls=calls,origin={px,py},renderSize={V.require('Voxel3D').size()},stats=renderedStats,grid=V.require('LocalLightGrid').last,field=V.require('StaticLightField').last,fieldError=V.require('StaticLightField').lastError,horizon=V.require('HorizonWall').buildStatus()}
   results[#results+1]=row
   print('ABLATION '..assert(json.encode(row)))
   local file=assert(io.open(dir..'/results.json','w'));file:write(assert(json.encode(results)));file:close()
   local evidence=assert(io.open(dir..'/hitches.txt','w'));evidence:write(diagnostics.evidence());evidence:close()
   if not variant[5] or variant[1]:find('view1-',1,true)then assert(U.shot(game,dir..'/'..id..'-'..variant[1]..'.png'))end
  end
 end
 fp.moveVector=originalMove
 print('PASS_CONTROLLED_ABLATION');love.event.quit(0)
end
