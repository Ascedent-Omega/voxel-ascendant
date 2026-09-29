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
 V.require('DayNight').setting:setValue('dusk',game)
 local ids={'POKEMON_TOWER_1F','POKEMON_TOWER_3F','POKEMON_TOWER_5F','POKEMON_TOWER_7F','CELADON_MART_2F','POKEMON_MANSION_1F','SILPH_CO_1F'}
 for _,id in ipairs(ids)do
  U.teleport(game,id,8,8,'up');P.setLevel('voxel',7);U.wait(100)
  fp.lookBy(math.pi-.3-fp.yaw,.2-fp.pitch);U.wait(20)
  local world=game.overworld
  if id:match('^POKEMON_TOWER_')then assert(V.require('Gen1InteriorFloors').profile(world.map)==54)end
  assert(U.shot(game,dir..'/'..id..'.png'))
  print('PASS_INTERIOR',id)
 end
 print('PASS_VIDEO_INTERIORS');love.event.quit(0)
end
