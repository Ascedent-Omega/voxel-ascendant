return function(game)
 assert(os.getenv('POKEPORT_IDENTITY')=='vasc-video-polish-qa')
 io.stdout:setvbuf('no');love.window.hasFocus=function()return true end;love.window.isVisible=function()return true end
 local U=require('tests.drivers.util');game:startNewGame{intro=false}
 local ex=game.mods.exports.VOXEL_ASCENDANT;ex.setupCard.suspended=true
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
 V.require('CalendarEvents').setting:setValue('halloween',game)
 V.require('Weather').setting:setValue('clear',game)
 V.require('DayNight').setting:setValue('night',game)
 love.window.setMode(1200,800,{resizable=true,vsync=0})
 V.require('DayNight').setting:setValue('day',game)
 U.teleport(game,'LAVENDER_TOWN',1,8,'left');P.setLevel('voxel',1);U.wait(80)
 local world=game.overworld;local Map=require('src.world.Map');local found
 for y=0,world.map.def.height*2-1 do
  if world.map:isWalkableCell(0,y)then
   world.player.cellX,world.player.cellY=0,y
   local d,t,x,z=world:connectionLanding('left')
   if d and Map.defPassable(d,t,x,z,false)then found=y;break end
  end
 end
 assert(found,'no walkable Lavender west crossing')
 world.player.cellX,world.player.cellY=0,found;world.player.px,world.player.py=0,found*16
 world.player.facing='left';world.player.turnTimer=0;U.wait(15)
 assert(U.shot(game,dir..'/lavender-before-west.png'))
 U.hold(game,'left',24);U.wait(30)
 assert(world.map.id=='ROUTE_8','west connection did not cross: '..world.map.id)
 assert(U.shot(game,dir..'/lavender-outbound.png'))
 U.hold(game,'right',60);U.wait(30)
 assert(world.map.id=='LAVENDER_TOWN','return connection did not cross: '..world.map.id)
 assert(U.shot(game,dir..'/lavender-inbound.png'))
 print('PASS_LAVENDER_BIDIRECTIONAL_NATIVE')
 U.teleport(game,'PALLET_TOWN',8,8,'down');P.setLevel('voxel',1);U.wait(70)
 local O=V.require('OverworldBattle');O.setting:setValue(true,game)
 game.save.party={require('src.pokemon.Pokemon').new(game.data,'PIDGEOT',40)}
 local B=require('src.battle.BattleState');local screen=B.newWild(game,'RATTATA',4)
 game.overworld:pushBattle(screen)
 for i=1,2000 do if screen.phase=='menu'then break end;if i%10==0 then U.tap(game,'a')end;U.wait(1)end
 assert(screen.phase=='menu','battle did not reach menu');U.wait(80)
 assert(O.shot(),'no VASC battle');local Cam=V.require('BattleCam')
 print('CAMERA_STEERABLE',Cam.steerable)
 for _,mode in ipairs{'clear','rain','storm'}do
  V.require('Weather').setting:setValue(mode,game);U.wait(90)
  assert(U.shot(game,dir..'/battle-'..mode..'.png'))
 end
 local changed=Cam.dragOrbit(.04)
 print('MANUAL_CHANGE',changed,Cam.directorManualUntil)
 if changed and Cam.directorManualUntil==math.huge then
  U.wait(300);assert(Cam.directorManualUntil==math.huge,'safe MAP manual view expired')
  print('PASS_MAP_MANUAL_HOLD_NATIVE')
 end
 assert(U.shot(game,dir..'/battle-manual.png'))
 local oldArg=arg;arg={os.getenv('VASC_REPO')}
 for _,test in ipairs{'indoor_mist_composite_test','mobile_mist_gpu_test','local_light_grid_test'}do
  assert(loadfile(os.getenv('VASC_REPO')..'/tests/'..test..'.lua'))()
 end
 arg=oldArg
 print('PASS_VIDEO_SEAM_AND_WEATHER');love.event.quit(0)
end
