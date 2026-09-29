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
 V.require('CalendarEvents').setting:setValue('off',game);V.require('DayNight').setting:setValue('day',game)
 for _,gate in pairs(require('src.world.FieldDefaults').constant(game.data,'hmBadges')or{})do if gate.badge then game.save.inventory[gate.badge]=1 end end
 U.teleport(game,'PALLET_TOWN',8,12,'left');P.setLevel('voxel',1);U.wait(60)
 local paint=V.require('BicycleColors');local initialBuilds=paint.built
 game.save.onBike=true;paint.setting:setValue('red',game);U.wait(70)
 -- The renderer is lazy: a stationary actor can be culled on the first
 -- frame after a map change. Warm up the actual ride before counting builds.
 U.hold(game,'left',4)
 for i=1,180 do if paint.built>initialBuilds then break end;U.wait(1)end
 assert(paint.built>initialBuilds,'bicycle paint never rendered')
 assert(game.overworld.player.onBike,'bicycle not mounted');print('LIVE_BIKE',game.overworld.player.bikeSprite.def.ascendantRole,game.overworld.player.bikeSprite.def.ascendantCharacterAction,game.overworld.player.bikeSprite.def.voxelSpriteDemo);local before=V.require('BicycleColors').built
 assert(U.shot(game,dir..'/bike-live-red.png'));U.hold(game,'left',20);U.wait(10)
 assert(V.require('BicycleColors').built==before,'bike rebuilt every draw')
 V.require('BicycleColors').setting:setValue('gold',game);U.wait(15);assert(U.shot(game,dir..'/bike-live-gold.png'))
 assert(V.require('BicycleColors').built>before,'live bicycle colour not applied')
 print('PASS_REAL_BICYCLE');love.event.quit(0)
end
