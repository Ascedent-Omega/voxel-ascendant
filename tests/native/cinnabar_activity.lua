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
 V.require('DayNight').setting:setValue('night',game)
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
 V.require('DayNight').setting:setValue('day',game)

 P.setLevel('tiltshift',0)
 local activity=V.require('CinnabarActivity');local volcano=V.require('CinnabarVolcano')
 volcano.setting:setValue('connected',game)
 local update=activity.update;local clock=48
 activity.update=function(...)update(...);activity.clock=clock end
 P.setLevel('voxel',1);U.teleport(game,'CINNABAR_ISLAND',9,9,'down');U.wait(160)
 assert(activity.ashAmount(game.overworld.map)==1)
 assert(U.shot(game,dir..'/zinnober-ascheregen.png'))
 for _,id in ipairs{'CINNABAR_LAB_TRADE_ROOM','CINNABAR_POKECENTER','CINNABAR_MART','CINNABAR_GYM','POKEMON_MANSION_1F'}do
  assert(game.data.maps[id],'missing native map '..id)
  U.teleport(game,id,3,3,'down');clock=69;U.wait(100)
  assert(activity.playable,'indoor quake disabled '..id)
  assert(activity.ashAmount(game.overworld.map)==0,'indoor ash '..id)
  local x,y=activity.camera(game.overworld.map,100,100)
  assert(x~=100 and y~=100,'indoor quake absent '..id)
  if id=='CINNABAR_LAB_TRADE_ROOM'then
   assert(U.shot(game,dir..'/zinnober-beben-labor.png'))
   P.setLevel('voxel',6)
   for i=1,1200 do if fp.blend>=1 then break end;U.wait(1)end
   U.wait(20);assert(U.shot(game,dir..'/zinnober-beben-ego.png'))
   P.setLevel('voxel',1)
  end
  print('PASS_NATIVE_TREMOR',id)
 end
 volcano.setting:setValue('classic',game);U.wait(15);assert(not activity.playable)
 volcano.setting:setValue('connected',game);P.setLevel('voxel',0);U.wait(15);assert(not activity.playable)
 activity.update=update
 print('PASS_NATIVE_CINNABAR_ACTIVITY');love.event.quit(0)
end
