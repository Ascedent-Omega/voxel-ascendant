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



 local old=arg;arg={assert(os.getenv('VASC_REPO'))}
 for _,name in ipairs{'curved_mist_gpu_test','indoor_mist_composite_test','mobile_mist_gpu_test'}do assert(loadfile(arg[1]..'/tests/'..name..'.lua'))()end
 arg=old
 local H=V.require('HorizonWall');local G=V.require('Voxel3D')
 local function ready()
  for i=1,3000 do local status=H.cacheStatus(V.require('VisibleNeighborhood').apply(game.overworld));assert(not status.failed);if status.ready then U.wait(40);return end;U.wait(1)end;error('horizon timeout')
 end
 V.require('DayNight').setting:setValue('night',game,true)
 V.require('WorldCurve').setting:setValue(2,game,true)
 U.teleport(game,'ROUTE_12',10,18,'up');P.setLevel('voxel',7);ready();U.wait(180)
 local frame=fp.frame
 fp.frame=function(...)local rig,x,z=frame(...);if rig then rig.eye={168,30,650};rig.focus={168,22,-180};rig.fov=1.05 end;return rig,x,z end
 U.wait(50);assert(U.shot(game,dir..'/lavender-fog-distant.png'))
 print('CURVE',G.curveK,G.curveX,G.curveZ,'MIST',V.require('IndoorMist').last.mode)
 fp.frame=frame;U.teleport(game,'LAVENDER_TOWN',8,14,'up');ready();U.wait(90);assert(U.shot(game,dir..'/lavender-fog-near.png'))
 print('PASS_NATIVE_CURVED_MIST');love.event.quit(0)
end
