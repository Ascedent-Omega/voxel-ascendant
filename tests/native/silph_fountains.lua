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

 local F=V.require('SilphFountains');local G=V.require('Voxel3D')
 V.require('VoxelItems').setting:setValue(true,game,true)
 local H=V.require('HorizonWall')
 local function ready()
  for i=1,3000 do local status=H.cacheStatus(game.overworld);assert(not status.failed);if status.ready then U.wait(40);return end;U.wait(1)end;error('horizon timeout')
 end
 U.teleport(game,'SILPH_CO_1F',15,12,'up');ready()
 local map=game.overworld.map;assert(F.matches(map))
 local shape=V.require('TileShape');assert(shape.at(map,shape.forMap(map),20,24,12).class=='water')
 assert(V.require('Gen1OutdoorScenery').waterMaterial(map,nil,'water',20)==-174)
 local snapshot={};for y=0,17 do for x=0,29 do snapshot[#snapshot+1]={map:cellTile(x,y),map:isWaterCell(x,y),map:isWalkableCell(x,y)}end end
 local rim=0;for _,p in ipairs(V.require('VoxelFurniture').find(map))do
  if p.kind:match('^silph_coping_')then
   rim=rim+1;assert(V.require('VoxelItems').models[p.kind].support==4)
  end
 end
 assert(rim==36,'expected 36 low coping modules');print('COPING_COUNT',rim)
 local frame=fp.frame
 fp.frame=function(...)local rig,x,z=frame(...);if rig then rig.eye={256,44,265};rig.focus={256,1,110};rig.fov=1.10 end;return rig,x,z end
 P.setLevel('voxel',6);for i=1,1200 do if fp.blend>=1 then break end;U.wait(1)end
 for _,mode in ipairs{'full','sky','off'}do
  V.require('Water').setting:setValue(mode,game,true);assert(V.require('Water').setting:get()==mode);U.wait(45)
  assert(F.lastCount==2);assert(U.shot(game,dir..'/silph-fountains-'..mode..'.png'))
 end
 V.require('Water').setting:setValue('full',game,true)
 V.require('DayNight').setting:setValue('night',game,true);U.wait(40)
 assert(U.shot(game,dir..'/silph-fountains-night.png'))
 V.require('DayNight').setting:setValue('day',game,true)
 fp.frame=function(...)local rig,x,z=frame(...);if rig then rig.eye={256,24,200};rig.focus={256,6,110};rig.fov=1.05 end;return rig,x,z end
 U.wait(40);assert(U.shot(game,dir..'/silph-fountains-eye.png'))
 V.require('VoxelItems').setting:setValue(false,game,true);assert(not V.require('VoxelItems').setting:get());ready()
 for i=1,3000 do if F.lastCount==0 then break end;U.wait(1)end;assert(F.lastCount==0)
 V.require('VoxelItems').setting:setValue(true,game,true);ready()
 for i=1,3000 do if F.lastCount==2 then break end;U.wait(1)end;assert(F.lastCount==2)
 P.setLevel('voxel',0);U.wait(30);assert(U.shot(game,dir..'/silph-fountains-vanilla.png'))
 local index=0;for y=0,17 do for x=0,29 do index=index+1;local old=snapshot[index];assert(map:cellTile(x,y)==old[1]and map:isWaterCell(x,y)==old[2]and map:isWalkableCell(x,y)==old[3],'native cells changed')end end
 fp.frame=frame;P.setLevel('voxel',1);ready()
 for i=1,1200 do if fp.blend<=0 then break end;U.wait(1)end
 assert(U.shot(game,dir..'/silph-fountains-plan.png'))
 for i=1,2 do
  P.setLevel('voxel',1);U.teleport(game,'SILPH_CO_2F',3,5,'up');ready();assert(not F.matches(game.overworld.map)and F.lastCount==0)
  U.teleport(game,'SILPH_CO_1F',15,12,'up');ready();assert(F.lastCount==2)
 end
 print('PASS_NATIVE_SILPH_FOUNTAINS',rim,'2 jets; full/sky/off; night; Vanilla; 540 unchanged cells; repeated room entry')
 love.event.quit(0)
end
