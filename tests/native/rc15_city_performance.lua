return function(game)
 assert(os.getenv('POKEPORT_IDENTITY')=='vasc-video-polish-qa')
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
 game.save.flags.EVENT_FOLLOWED_OAK_INTO_LAB=true;game.save.flags.EVENT_GOT_STARTER=true
 game.save.flags.EVENT_BEAT_BROCK=true;game.save.flags.EVENT_BEAT_PEWTER_GYM_TRAINER_0=true
 V.require('CalendarEvents').setting:setValue('halloween',game)
 V.require('Weather').setting:setValue('clear',game)
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



 local timings={};local measured=false
 for _,spec in ipairs{{'LocalLights','prepare'},{'LocalLightGrid','prepare'},{'LightVisibility','prepare'},
  {'VoxelFurniture','eachWorld'},{'ShadowMap','render'},{'VoxelScene','render'}}do
  local m=V.require(spec[1]);local fn=m[spec[2]]
  if type(fn)=='function'then m[spec[2]]=function(...)
   local t=love.timer.getTime();local out={fn(...)}
   if measured then local k=table.concat(spec,'.');timings[k]=(timings[k]or 0)+love.timer.getTime()-t end
   return unpack(out)
  end end
 end
 V.require('AntiAlias').resolution:setValue(os.getenv('QA_RESOLUTION')or'balanced',game,true)
 love.window.setMode(1710,958,{resizable=true,vsync=0})
 P.setLevel('voxel',6);P.setLevel('tiltshift',3)
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
  local drive=0;local originalMove=fp.moveVector
  fp.moveVector=function()return -math.cos(fp.yaw)*drive,math.sin(fp.yaw)*drive end
  local load=love.timer.getTime()-start
  local times,positions={},{};timings={};measured=true
  for i=1,600 do
   fp.yaw=i/600*math.pi*4;fp.pitch=-.08
   drive=math.floor((i-1)/60)%2==0 and 1 or -1
   local t=love.timer.getTime();U.wait(1);times[#times+1]=(love.timer.getTime()-t)*1000
   drive=0
   if i%150==0 then positions[#positions+1]={game.overworld.player.px,game.overworld.player.py}end
  end
  fp.moveVector=originalMove;assert(math.abs(positions[1][1]-positions[2][1])>8,'benchmark did not walk');measured=false;table.sort(times);local total,over,over33=0,0,0
  for _,t in ipairs(times)do total=total+t;if t>16.7 then over=over+1 end;if t>33.4 then over33=over33+1 end end
  for k,v in pairs(timings)do timings[k]=v*1000/600 end
  emit{map=id,clock=clock,lighting=light,fps=600000/total,medianMs=times[300],p95Ms=times[570],p99Ms=times[594],maxMs=times[600],over16=over,over33=over33,timings=timings,positions=positions,loadSeconds=load,width=love.graphics.getWidth(),height=love.graphics.getHeight(),drawCalls=renderedStats.drawcalls,grid=V.require('LocalLightGrid').last,scale=V.require('FrameBudget').scale,renderSize={V.require('Voxel3D').size()}}
  fp.yaw=math.pi/2;fp.pitch=0;U.wait(3);assert(U.shot(game,dir..'/'..id..'-'..clock..'-'..tostring(light)..'.png'))
 end
 for _,id in ipairs{'SAFFRON_CITY','CELADON_CITY'}do
  sample(id,'night',true)
 end
 print('PASS_MOVING_PERFORMANCE');love.event.quit(0)
end
