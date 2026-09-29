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


 local H=V.require('HorizonWall');local W=V.require('SilphWindows');local E=V.require('SilphElevator');local LL=V.require('LocalLights')
 W.setting:setValue(true,game,true)
 local function ready()
  for i=1,3000 do local status=H.cacheStatus(game.overworld);assert(not status.failed);if status.ready then U.wait(40);return end;U.wait(1)end;error('horizon timeout')
 end

 P.setLevel('voxel',6)
 U.teleport(game,'SILPH_CO_ELEVATOR',3,1,'up');ready()
 local sides={};for _,r in ipairs(H.meshes(game.overworld))do if r.kind=='window_glass'then sides[r.interiorPanel.edge]=true end end
 assert(sides.north and sides.east and sides.west and not sides.south,'missing three-sided glass')
 local frame=fp.frame
 fp.frame=function(...)local rig,x,z=frame(...);if rig then rig.eye={32,22,45};rig.focus={24,24,-50};rig.fov=1.1 end;return rig,x,z end
 U.wait(10);U.shot(game,dir..'/cabin-three-sides.png')
 game.overworld:interact()
 local List=require('src.ui.ListMenu');local menu
 for i=1,500 do if getmetatable(game.stack:top())==List then menu=game.stack:top();break end;U.wait(1)end
 assert(menu,'native elevator menu did not open')
 U.wait(5);U.shot(game,dir..'/floor-menu.png')
 local index;for i,item in ipairs(menu.items)do if item.value and item.value.map=='SILPH_CO_7F'then index=i end end
 assert(index);menu.index=index;U.tap(game,'a')
 local r=assert(E.ride,'no ride');assert(r.vascFrom==1 and r.vascTo==7)
 local visited={};local last=0
 for i=1,1200 do
  if not E.ride then break end
  local y=-E.offset(game.overworld.map);assert(y>=last,'ride reversed');last=y
  for floor=1,7 do if y>=E.height(floor)then visited[floor]=true end end
  if i==190 then U.shot(game,dir..'/ride-middle.png')end
  U.wait(1)
 end
 assert(not E.ride and E.floor(game.overworld.map)==7 and E.offset(game.overworld.map)==-E.height(7),'arrival mismatch')
 for floor=1,7 do assert(visited[floor],'skipped floor '..floor)end
 U.wait(5);U.shot(game,dir..'/arrival-7f.png')
 print('PASS_NATIVE_SIX_FLOOR_RIDE',r.vascTicks,last)
 W.setting:setValue(false,game,true);ready()
 for _,r in ipairs(H.meshes(game.overworld))do assert(r.kind~='window_glass'and r.class~='silph_cabin'and r.class~='silph_exterior')end
 U.shot(game,dir..'/cabin-glass-off.png')
 print('PASS_GLASS_OFF_CABIN');love.event.quit()
end
