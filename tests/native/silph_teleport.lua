return function(game)
 assert(os.getenv('POKEPORT_IDENTITY')=='vasc-silph-teleport-qa')
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

 local T=V.require('SilphTeleport')
 local chars=assert(game.mods.exports.kanto_ascendant.extendedCharacters)
 local H=V.require('HorizonWall')
 local function ready()
  for i=1,4000 do
   local status=H.cacheStatus(game.overworld)
   assert(not status.failed,'scene failed')
   if status.ready then U.wait(45);return end
   U.wait(1)
  end
  error('scene timeout')
 end
 -- Find a real source pad and use the native warp resolver, not a guessed destination.
 U.teleport(game,'SILPH_CO_3F',3,3,'down');ready()
 local source,sourceIndex,crossFloor
 for i,w in ipairs(game.overworld.map.def.warps) do
  if game.overworld.map:warpPadOrHoleAt(w.x,w.y)=='pad' then
   if not source then source=w;sourceIndex=i end
   if w.destMap~='SILPH_CO_3F' and not crossFloor then crossFloor=w end
  end
 end
 assert(source,'no real pad')
 print('PAD',sourceIndex,source.x,source.y,source.destMap,source.destWarp)
 P.setLevel('voxel',3)
 for _,hero in ipairs{'RED','BLUE','GREEN'} do
  if hero~='RED' then source=assert(crossFloor,'no cross-floor pad') end
  chars.select(hero);assert(chars.getPlayerCharacter()==hero)
  U.teleport(game,'SILPH_CO_3F',source.x,source.y,'down');ready()
  local ow=game.overworld
  assert(U.shot(game,dir..'/'..hero..'-before.png'))
  local expected,x,y=require('src.world.Warp').destination(game.data,source,ow.lastOutdoor)
  ow:takeWarp(source)
  local fx=assert(T.current(ow),'teleport was not armed');local tr=fx.transition
  local stages={}
  local lastPhase,lastTick,clipIndex=nil,-99,0
  for i=1,2500 do
   local key=tr.phase..'-'..(tr.t<18 and 'start' or tr.t<42 and 'middle' or 'end')
   if (tr.phase=='out' and (tr.t>=28 and tr.t<=42 or tr.t>=55 and tr.t<=64))
    or (tr.phase=='in' and tr.t>=34 and tr.t<=47) then
    if not stages[key]then
     stages[key]=true;assert(fx.mesh and not fx.failed,'final actor mesh missing')
     print('FX',hero,tr.phase,tr.t,#fx.pieces,#fx.vertices,fx.texture:getDimensions())
     assert(U.shot(game,dir..'/'..hero..'-'..key..'.png'))
    end
   end
   if hero=='RED' and (lastPhase~=tr.phase or tr.t-lastTick>=3) then
    clipIndex=clipIndex+1;lastPhase,lastTick=tr.phase,tr.t
    assert(U.shot(game,dir..('/clip-%03d.png'):format(clipIndex)))
   end
   if not ow.transitioning then break end
   U.wait(1)
  end
  assert(not ow.transitioning and not T.current(ow),'warp stuck')
  assert(ow.map.id==expected and ow.player.cellX==x and ow.player.cellY==y,'wrong native destination')
  assert(not ow.player.spinning and not ow.player.spinFrames,'native spin leaked')
  assert(stages['out-middle'] and stages['out-end'] and stages['in-middle'],'missed animation stages')
  U.wait(10);assert(not ow.player.inputLocked,'input lock leaked');assert(U.shot(game,dir..'/'..hero..'-after.png'))
  print('HERO_PASS',hero,expected,x,y)
 end
 -- Native mode retains the ordinary timing and arrival spin.
 P.setLevel('voxel',0);U.wait(60)
 U.teleport(game,'SILPH_CO_3F',source.x,source.y,'down');U.wait(20)
 game.overworld:takeWarp(source)
 assert(not T.current(game.overworld),'2D teleport claimed')
 assert(game.overworld.teleportOut or game.stack:top().frames~=T.FRAMES,'2D timing changed')
 U.wait(100)
 print('PASS_NATIVE_SILPH_TELEPORT');love.event.quit(0)
end
