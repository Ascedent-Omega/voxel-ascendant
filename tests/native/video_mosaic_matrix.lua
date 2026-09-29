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
 local ids={'PEWTER_GYM','CERULEAN_GYM','VERMILION_GYM','CELADON_GYM','FUCHSIA_GYM','SAFFRON_GYM','CINNABAR_GYM','VIRIDIAN_GYM','FIGHTING_DOJO'}
 fp.PITCH_UP=-1.5
 for _,id in ipairs(ids)do
  U.teleport(game,id,4,10,'up')
  local world=game.overworld
  -- Inspect the real room renderer without starting trainer scripts.
  while game.stack:top()~=world do game.stack:pop()end
  world.update=function()end
  local plan=assert(V.require('GymSkylights').layout(world.map),id..' layout')
  world.player.px,world.player.py=plan.cx-8,plan.cz+18
  world.player.cellX,world.player.cellY=math.floor(world.player.px/16),math.floor(world.player.py/16)
  P.setLevel('voxel',6);U.wait(120)
  fp.lookBy(math.pi-fp.yaw,-1.40-fp.pitch)
  for _,phase in ipairs{'day','dusk','night'}do
   V.require('DayNight').setting:setValue(phase,game);U.wait(20)
   local light=assert(V.require('GymSkylights').light(world.map,V.require('DayNight'),'clear'))
   assert(light.lampColor[4]+light.color[4]>=.26-1e-9)
   assert(U.shot(game,dir..'/'..id..'-'..phase..'.png'))
  end
  print('PASS_MOSAIC_ROOM',id)
 end
 local L=V.require('LocalLights')
 L.setting:setValue(false,game);U.wait(20)
 assert(U.shot(game,dir..'/DOJO-night-lights-off.png'))
 L.setting:setValue(true,game)
 local oldArg=arg;arg={os.getenv('VASC_REPO')}
 assert(loadfile(os.getenv('VASC_REPO')..'/tests/local_light_grid_test.lua'))();arg=oldArg
 print('PASS_MOSAIC_ALL_NINE_NATIVE');love.event.quit(0)
end
