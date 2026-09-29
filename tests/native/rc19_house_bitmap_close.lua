return function(game)
 assert(os.getenv('POKEPORT_IDENTITY')=='vasc-video-polish-qa')
 io.stdout:setvbuf('no');love.audio.setVolume(0);love.window.hasFocus=function()return true end;love.window.isVisible=function()return true end
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


 local WC=V.require('WindowImageCache');local Map=require('src.world.Map')
 W.setting:setValue(true,game);V.require('WorldCurve').setting:setValue(0,game,true)
 local function settled()
  Scene.setPreparationCovered(true)
  for i=1,3000 do
   local status=H.cacheStatus(game.overworld);assert(not status.failed)
   if status.ready and V.require('VoxelState').ready and not Chunk.hasPriorityWork()then break end
   U.wait(1);assert(i<3000,'timeout')
  end
  Scene.setPreparationCovered(false);U.wait(30)
 end
 for _,id in ipairs{'BLUES_HOUSE','VERMILION_TRADE_HOUSE'}do
  U.teleport(game,id,2,4,'up');settled()
  local house=assert(V.require('HouseWindows').describe(game.overworld.map));local pane=house.panes[1]
  print('CLOSE_PANE',id,json.encode(pane))
  local horizontal=pane.edge=='north'or pane.edge=='south'
  local inside=(pane.edge=='north'or pane.edge=='west')and 16 or -16
  for n,fraction in ipairs{.1,.5,.9}do
   local along=pane.from+(pane.upto-pane.from)*fraction
   local px,pz=horizontal and along or pane.at+inside,horizontal and pane.at+inside or along
   local d=game.overworld.map.def;local best,score
   for y=0,d.height*2-1 do for x=0,d.width*2-1 do
    if Map.defIsWalkableCell(d,game.data.tilesets[d.tileset],x,y)then
     local dist=(x*16+8-px)^2+(y*16+8-pz)^2
     if not score or dist<score then score=dist;best={x,y}end
    end
   end end
   assert(best);U.teleport(game,id,best[1],best[2],'up');settled()
   for _,mode in ipairs{6,7}do
    P.setLevel('voxel',mode);U.wait(30)
    fp.yaw=({north=math.pi,south=0,east=math.pi/2,west=-math.pi/2})[pane.edge];fp.pitch=0;U.wait(30)
    print('CLOSE_POSITION',id,n,mode,game.overworld.player.cellX,game.overworld.player.cellY)
    assert(U.shot(game,dir..'/'..id..'-close-'..n..'-'..mode..'.png'))
   end
  end
 end
 local hits=WC.bitmapHits
 V.require('DayNight').setting:setValue('night',game,true);U.wait(180)
 print('NIGHT_TIME',V.require('DayNight').time())
 assert(U.shot(game,dir..'/night-close.png'));assert(WC.bitmapHits==hits)
 W.setting:setValue(false,game);settled()
 for _,p in ipairs(H.meshes(game.overworld))do assert(p.class~='silph_exterior','outside survives windows-off')end
 assert(U.shot(game,dir..'/off-close.png'))
 print('PASS_HOUSE_BITMAP_CLOSE');love.event.quit()
end
