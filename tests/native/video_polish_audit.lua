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
 for _,q in ipairs{{'VIRIDIAN_CITY',10,10},{'LAVENDER_TOWN',8,8},{'POKEMON_TOWER_3F',8,8},{'PEWTER_GYM',4,5},{'SILPH_CO_1F',10,8},{'VERMILION_CITY',10,10},{'GAME_CORNER',10,8},{'CELADON_MART_2F',6,4},{'CELADON_MART_ELEVATOR',1,2}}do
  U.teleport(game,q[1],q[2],q[3],'up');P.setLevel('voxel',7);U.wait(120)
  fp.lookBy(math.pi-.3-fp.yaw,-.09-fp.pitch);U.wait(40)
  local world=game.overworld;print('AUDIT_MAP',q[1])
  for _,e in ipairs(world.entities or{})do local d=e.sprite and e.sprite.def
   print('ENTITY',e.def and e.def.name,d and d.ascendantRole,e.cellX,e.cellY,e.sprite and e.sprite.seed)
  end
  local n=0;V.require('Halloween').eachPumpkin(world,function(x,y,z)n=n+1;print('PUMPKIN',x,y,z)end);print('PUMPKIN_COUNT',n)
  assert(U.shot(game,dir..'/'..q[1]..'-night.png'))
  if q[1]=='LAVENDER_TOWN'then assert(n>0,'Lavender needs pumpkins')end
  if q[1]=='POKEMON_TOWER_3F'then
   local H=V.require('Halloween');H.wait=0;U.wait(50)
   assert(H.age,'Tower apparition did not start');assert(U.shot(game,dir..'/tower-eyes.png'))
  elseif q[1]=='PEWTER_GYM'then
   for _,phase in ipairs{'day','dusk'}do
    V.require('DayNight').setting:setValue(phase,game);U.wait(30)
    assert(U.shot(game,dir..'/PEWTER_GYM-'..phase..'.png'))
   end
   V.require('DayNight').setting:setValue('night',game)
   fp.lookBy(0,-1.0-fp.pitch);U.wait(30);assert(U.shot(game,dir..'/PEWTER_GYM-roof-night.png'))
  end
 end
 local oldArg=arg;arg={os.getenv('VASC_REPO')}
 assert(loadfile(os.getenv('VASC_REPO')..'/tests/local_light_grid_test.lua'))();arg=oldArg
 print('PASS_VIDEO_POLISH_NATIVE_CAPTURE');love.event.quit(0)
end
