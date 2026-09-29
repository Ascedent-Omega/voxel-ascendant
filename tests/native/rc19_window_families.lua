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
 local function clean(v,seen)
  if type(v)=='function'or type(v)=='userdata'or type(v)=='thread'then return nil end
  if type(v)~='table'then return v end
  seen=seen or{};if seen[v]then return nil end;seen[v]=true
  local out={};for k,x in pairs(v)do if type(k)=='string'or type(k)=='number'then out[k]=clean(x,seen)end end;seen[v]=nil;return out
 end
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




 local Map=require('src.world.Map');local Stairs=V.require('Gen1Stairs');local Structures=V.require('Structures')
 Stairs.setting:setValue(true,game);W.setting:setValue(true,game)


 local House=V.require('HouseWindows');local Layout=V.require('Gen1InteriorLayout');local profiles=V.require('Gen1InteriorPanoramas').profiles
 local ids={};for id in pairs(profiles)do if id:find('POKECENTER')or id:match('^CELADON_MART_%d+F$')or id:match('^SILPH_CO_%d+F$')then ids[#ids+1]=id end end;table.sort(ids)
 for _,id in ipairs(ids)do
  local d=game.data.maps[id];local map=Map.new(d,game.data.tilesets[d.tileset])
  local house=House.describe(map);local panels=Layout.panelsFor(map,profiles[id]);local sideDoors=0
  for _,p in ipairs(panels)do if p.nicheReturn then for _,o in ipairs(p.openings or{})do if not o.open then sideDoors=sideDoors+1 end end end end
  assert(sideDoors==0,id..' has side doors')
  emit({map=id,source=House.source(map),windows=house,sideDoors=sideDoors,theme=profiles[id].theme})
 end
 for _,id in ipairs{'CELADON_MART_1F','CELADON_MART_2F','CELADON_MART_3F','CELADON_MART_4F','CELADON_MART_5F','VIRIDIAN_POKECENTER'}do
  local d=game.data.maps[id];local WC=V.require('WindowImageCache');local before=WC.hits
  U.teleport(game,id,5,5,'down');Scene.setPreparationCovered(true);ready()
  for i=1,1200 do local status=H.cacheStatus(game.overworld);assert(not status.failed);if status.ready then break end;U.wait(1)end
  Scene.setPreparationCovered(false);U.wait(30)
  assert(WC.hits>before,'packaged view not used: '..id)
  print('PASS_PACKAGED_VIEW',id,WC.hits,WC.misses)
  for _,yaw in ipairs{0,math.pi/2,math.pi,-math.pi/2}do fp.yaw=yaw;fp.pitch=.1;U.wait(2);U.shot(game,dir..'/'..id..'-'..tostring(yaw)..'.png')end
 end
 print('PASS_WINDOW_DOOR_AUDIT');love.event.quit()
end
