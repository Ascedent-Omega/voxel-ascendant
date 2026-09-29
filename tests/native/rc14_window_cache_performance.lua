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


 config.renderer={love.graphics.getRendererInfo()};config.window={love.graphics.getDimensions()};config.pixels={love.graphics.getPixelDimensions()};config.tiltshift=3;config.parallelUserGame=true
 local Cache=V.require('WindowImageCache');local cacheLoad=Cache.load
 local function atWindow()
  local world=game.overworld;local map=world.map
  local profile=H.interiorProfileFor(map);local best
  for _,a in ipairs(W.apertures(map,profile.shellHeight))do
   for y=1,map.def.height*2-2 do for x=1,map.def.width*2-2 do
    local px,pz=x*16+8,y*16+8
    local horizontal=a.edge=='north'or a.edge=='south'
    local along=horizontal and px or pz
    local distance=math.abs((horizontal and pz or px)-a.at)
    if along>a.from+4 and along<a.upto-4 and distance>=16 and distance<=56
     and map:isWalkableCell(x,y)and not world:npcAtCell(x,y)and not map:warpAtCell(x,y)then
     local score=distance+math.abs(along-(a.from+a.upto)/2)*.1
     if not best or score<best.score then best={x=x,y=y,edge=a.edge,score=score}end
    end
   end end
  end
  assert(best,'no window viewpoint '..map.id)
  local player=world.player
  player.cellX,player.cellY,player.px,player.py=best.x,best.y,best.x*16,best.y*16
  player.facing=({north='up',south='down',west='left',east='right'})[best.edge]
  fp.yaw=({north=math.pi,south=0,west=-math.pi/2,east=math.pi/2})[best.edge];fp.pitch=0
  return best
 end
 local function sample(id,x,y,mode)
  H.invalidate()
  Cache.load=mode=='live'and function()return nil end or cacheLoad
  local hits=Cache.hits;local start=love.timer.getTime()
  U.teleport(game,id,x,y,'up');ready()
  while not H.cacheStatus{map=game.overworld.map,neighbors={}}.ready do U.wait(1)end
  local load=love.timer.getTime()-start
  if mode=='cached'then assert(Cache.hits>hits,'cache miss '..id)end
  local point=atWindow();U.wait(90)
  local frameTimes,draws={},0
  for i=1,180 do
   local t=love.timer.getTime();U.wait(1);frameTimes[i]=love.timer.getTime()-t
   draws=draws+(renderedStats and renderedStats.drawcalls or 0)
  end
  table.sort(frameTimes);local total=0;for _,t in ipairs(frameTimes)do total=total+t end
  emit{map=id,mode=mode,view='first-person at window',width=love.graphics.getWidth(),height=love.graphics.getHeight(),edge=point.edge,x=point.x,y=point.y,loadSeconds=load,fps=180/total,medianMs=frameTimes[90]*1000,
   p95Ms=frameTimes[171]*1000,drawCalls=draws/180,textureMiB=renderedStats.texturememory/1048576,luaMiB=collectgarbage('count')/1024}
  assert(U.shot(game,dir..'/'..id..'-'..mode..'.png'))
 end
 P.setLevel('tiltshift',3);P.setLevel('voxel',6)
 for _,id in ipairs{'SILPH_CO_1F','SILPH_CO_5F','SILPH_CO_11F','MR_PSYCHICS_HOUSE','REDS_HOUSE_1F'}do
  local x,y=id:match('^SILPH')and 10 or 3,id:match('^SILPH')and 8 or 4
  if id=='SILPH_CO_11F'then x,y=8,6 end
  for _,mode in ipairs{'live','cached','cached','live'}do sample(id,x,y,mode)end
 end
 love.window.setMode(1920,1080,{resizable=true,vsync=0})
 for _,mode in ipairs{'live','cached','cached','live'}do sample('SILPH_CO_1F',10,8,mode)end
 love.window.setMode(1200,800,{resizable=true,vsync=0})
 Cache.load=cacheLoad
 sample('SILPH_CO_11F',8,6,'cached')
 for _,clock in ipairs{'night','day'}do
  V.require('DayNight').setting:setValue(clock,game,true)
  for _,view in ipairs{6,7,3}do
   P.setLevel('voxel',view);U.wait(60)
   assert(U.shot(game,dir..'/cache-'..clock..'-view'..view..'.png'))
  end
 end
 V.require('Weather').setting:setValue('rain',game,true);U.wait(60)
 assert(U.shot(game,dir..'/cache-rain.png'))
 -- Normal cache eviction (no global invalidation): revisiting more rooms
 -- than the three-entry cap must reach a stable texture residency.
 local residency={}
 for round=1,3 do
  for _,id in ipairs{'SILPH_CO_1F','SILPH_CO_5F','SILPH_CO_11F','MR_PSYCHICS_HOUSE','REDS_HOUSE_1F'}do
   U.teleport(game,id,3,4,'up');ready();U.wait(25)
  end
  collectgarbage('collect');U.wait(3)
  residency[round]=love.graphics.getStats().texturememory
  print('CACHE_RESIDENCY',round,residency[round]/1048576,collectgarbage('count')/1024)
 end
 assert(residency[3]<=residency[2]+8*1048576,'window textures accumulate across revisits')
 print('PASS_WINDOW_CACHE_NATIVE');love.event.quit(0)
end
