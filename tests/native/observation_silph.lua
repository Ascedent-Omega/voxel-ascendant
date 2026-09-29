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
 V.require('CalendarEvents').setting:setValue('off',game)
 V.require('DayNight').setting:setValue('day',game)


 P.setLevel('tiltshift',0);P.setLevel('voxel',1)
 local H=V.require('HorizonWall');local Roof=V.require('Gen1Rooftops');local B=V.require('ObservationBinoculars')
 local function ready()
  for i=1,3000 do local status=H.cacheStatus(game.overworld);assert(not status.failed,'horizon build failed');if status.ready then U.wait(40);return end;U.wait(1)end
  error('horizon timeout')
 end
 for _,route in ipairs(os.getenv('SILPH_ONLY')and {}or(os.getenv('GATE_ROUTE')and{tonumber(os.getenv('GATE_ROUTE'))}or{11,12,15,16,18}))do
  U.teleport(game,'ROUTE_'..route..'_GATE_2F',route==15 and 6 or 1,3,'up');ready()
  assert(Roof.gate(game.overworld.map));assert(not H.interiorProfileFor(game.overworld.map))
  local exterior=false;for _,rim in ipairs(H.meshes(game.overworld))do if rim.class=='voxel_horizon'then exterior=true end;assert(rim.class~='interior_ceiling')end;assert(exterior,'missing route exterior')
  assert(U.shot(game,dir..'/gate-'..route..'.png'))
  U.tap(game,'a')
  for i=1,120 do
   if B.current()then break end
   U.wait(4);U.tap(game,'a')
  end
  assert(B.current(),'binoculars failed after native dialogue '..route)
  local s=B.current();local x,y=game.overworld.player.cellX,game.overworld.player.cellY
  local rig=B.frame(game.overworld,0,0);local fov=rig.fov
  for i=1,4 do U.tap(game,'up');U.wait(2)end
  local zoom=B.frame(game.overworld,0,0);assert(zoom.fov<fov,'zoom did not change projection')
  U.hold(game,'right',10);assert(s.yaw>0)
  assert(game.overworld.player.cellX==x and game.overworld.player.cellY==y,'binocular input moved player')
  U.wait(20);assert(U.shot(game,dir..'/binoculars-'..route..'.png'))
  U.tap(game,'b');U.wait(5);assert(not B.current()and not game.overworld.player.inputLocked);assert(not V.require('Voxel3D').camera,'camera not restored')
  print('PASS_NATIVE_BINOCULARS',route)
 end
 local W=V.require('SilphWindows');local frame=fp.frame
 for floor=tonumber(os.getenv('SILPH_FLOOR'))or 1,tonumber(os.getenv('SILPH_FLOOR'))or 11 do
  P.setLevel('voxel',1);U.teleport(game,'SILPH_CO_'..floor..'F',3,5,'up');ready()
  local map=game.overworld.map;assert(W.floor(map)==floor)
  local profile=H.interiorProfileFor(map);assert(profile.ceiling.enabled and profile.ceiling.authored,'Silph ceiling lost')
  local panels=V.require('Gen1InteriorLayout').panelsFor(map,H.interiorProfileFor(map))
  local glazed=0;for _,p in ipairs(panels)do if W.perimeter(map,p)then glazed=glazed+1 end end
  assert(glazed==4,'missing perimeter glazing')
  local exterior,panes,count,ceiling=false,0,0,false;for _,rim in ipairs(H.meshes(game.overworld))do if rim.class=='silph_exterior'then exterior=true;count=count+1 end;if rim.kind=='window_glass'then panes=panes+1 end;if rim.class=='interior_ceiling'then ceiling=true end end
  assert(exterior and panes==4 and ceiling,'missing real city, transparent glass or retained ceiling')
  assert(count<1600,'unbounded city draw batches');print('SILPH_BATCHES',floor,count)
  assert(U.shot(game,dir..'/silph-'..floor..'-plan.png'))
  if floor==1 or floor==6 or floor==11 then
   fp.frame=function(...)local rig,x,z=frame(...);if rig then
    local x=floor==11 and 88 or map.def.width*16
    rig.eye={x,25,44};rig.focus={x,22,-200};rig.fov=.9
   end;return rig,x,z end
   P.setLevel('voxel',6);for i=1,1200 do if fp.blend>=1 then break end;U.wait(1)end
   U.wait(30);assert(U.shot(game,dir..'/silph-'..floor..'-window.png'))
   local visible=V.require('SilphWindowVisibility').last;assert(visible and visible.rejected>0,'window culling inactive')
   print('SILPH_PORTALS',floor,visible.portals,visible.accepted,visible.rejected)
   if floor==6 then
    local windowFrame=fp.frame
    fp.frame=function(...)local rig,x,z=windowFrame(...);if rig then rig.focus={rig.eye[1],55,rig.eye[3]+50}end;return rig,x,z end
    U.wait(20);assert(U.shot(game,dir..'/silph-6-ceiling.png'));fp.frame=windowFrame
    V.require('DayNight').setting:setValue('night',game);V.require('Weather').setting:setValue('storm',game);U.wait(40)
    assert(U.shot(game,dir..'/silph-6-night-storm.png'))
    V.require('DayNight').setting:setValue('day',game);V.require('Weather').setting:setValue('clear',game)
   end
   fp.frame=frame
  end
  print('PASS_NATIVE_SILPH_WINDOWS',floor,W.height(map))
 end
 print('PASS_NATIVE_OBSERVATION_SILPH');love.event.quit(0)
end
