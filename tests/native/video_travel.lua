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
 local T=V.require('TravelPokemonModel');local Pokemon=require('src.pokemon.Pokemon')
 local mon=Pokemon.new(game.data,'PIDGEOT',45);mon.moves={{id='FLY',pp=15}};game.save.party={mon}
 U.teleport(game,'PALLET_TOWN',8,8,'down');P.setLevel('voxel',1);U.wait(100)
 local world=game.overworld;world:flyTo('VIRIDIAN_CITY')
 local states=find(ex.speciesCinematics.fly.status,'activeByWorld');local saw,dep,land
 for i=1,1600 do
  local shot=states[world]
  if shot then
   if shot.travelModel and shot.travelModel.actor then saw=true end
   if shot.phase=='departure'and shot.frame>=58 and not dep then
    dep=true;assert(U.shot(game,dir..'/fly-mount.png'))
   elseif shot.phase=='landing'and shot.frame>=42 and not land then
    land=true;assert(U.shot(game,dir..'/fly-landing.png'))
   end
  elseif saw and world.map.id=='VIRIDIAN_CITY' and not world.player.inputLocked then break end
  U.wait(1)
 end
 assert(saw and dep and land,'flight rig/sequence did not render')
 assert(world.map.id=='VIRIDIAN_CITY'and not states[world]and not world.player.inputLocked,'flight did not finish')
 print('PASS_REAL_FLIGHT',T.draws)
 local lapras=Pokemon.new(game.data,'LAPRAS',40);lapras.moves={{id='SURF',pp=15}};lapras.shiny=true;game.save.party={lapras}
 U.teleport(game,'VERMILION_CITY',10,10,'down');world=game.overworld;P.setLevel('voxel',1);U.wait(70)
 local shore
 for y=1,world.map.def.height*2-3 do
  for x=1,world.map.def.width*2-2 do
   if world.map:isWalkableCell(x,y)and world.map:isWaterCell(x,y+1)and world.map:isWaterCell(x,y+2)then shore={x,y};break end
  end
  if shore then break end
 end
 assert(shore,'no surf shore');U.teleport(game,'VERMILION_CITY',shore[1],shore[2],'down');world=game.overworld;U.wait(30)
 print('SURF_USER',world:partyKnows('SURF'),game.save.party[1].species)
 world:trySurf(shore[1],shore[2]+1)
 local surfStates=find(ex.speciesCinematics.surf.status,'activeByWorld');local mounted
 for i=1,1000 do
  if game.stack:top()~=world then if i%8==0 then U.tap(game,'a')end end
  local shot=surfStates[world]
  if i%150==0 then print('SURF_PROGRESS',i,world.player.surfing,game.stack:top().isOverworld,shot and shot.phase,shot and shot.mon.species,shot and shot.travelModel and shot.travelModel.error)end
  if shot and shot.phase=='ride'and shot.travelModel and shot.travelModel.actor then mounted=shot;break end
  U.wait(1)
 end
 assert(mounted,'surf mount not rendered');assert(mounted.travelModel.variant=='shiny','surf lost shiny identity')
 assert(U.shot(game,dir..'/surf-shiny-lapras.png'))
 U.hold(game,'down',20);U.wait(30);assert(world.player.surfing,'surf movement lost mount')
 assert(U.shot(game,dir..'/surf-moving.png'));print('PASS_REAL_SURF',mounted.travelModel.variant,T.draws)
 -- Engine-owned dismount/recall releases only our temporary model resources.
 world.player.surfing=false
 for i=1,350 do if not surfStates[world]then break end;U.wait(1)end
 assert(not surfStates[world]and not world.player.inputLocked,'surf cleanup retained lock')
 assert(mounted.travelModel==nil,'surf rig leaked after dismount')
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
