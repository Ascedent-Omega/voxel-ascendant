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
  local bounds=V.require('Gen1RoomBounds').forMap(game.overworld.map)
  assert(bounds.north==32 and bounds.south==128,'blocked roof rows not trimmed')
  local entry={map=game.overworld.map,w=128,h=128}
  local g=V.require('RooftopPanorama').geometry(entry)
  for _,group in ipairs(g)do for _,v in ipairs(group.vertices)do
   if v[2]>=0 then assert(v[1]>=-1 and v[1]<=129 and v[3]>=31 and v[3]<=129,'rail outside roof bounds')end
  end end
  U.tap(game,'a')
  for i=1,120 do
   if B.current()then break end
   U.wait(4);U.tap(game,'a')
  end
  assert(B.current(),'binoculars failed after native dialogue '..route)
  local s=B.current()
  if route==12 then
   assert(s.subject and s.subject.object.trainerClass=='OPP_FISHER')
   assert(s.subject.object.x==14 and s.subject.object.y==31)
   local q=assert(B.poses(game.overworld,function()end))[1]
   assert(q.mapId=='ROUTE_12'and q.gh<0 and q.py<0,'source subject not in transformed fishing route')
   local eye=s.subject.eye;local aim=B.frame(game.overworld,0,0).focus
   local dx,dz=s.subject.x-eye[1],s.subject.z-eye[3]
   assert(math.abs((aim[1]-eye[1])*dz-(aim[3]-eye[3])*dx)<.001,'subject aim mismatch')
   U.wait(20);assert(U.shot(game,dir..'/route12-angler.png'))
  end
  local x,y=game.overworld.player.cellX,game.overworld.player.cellY
  local rig=B.frame(game.overworld,0,0);local fov=rig.fov
  for i=1,4 do U.tap(game,'up');U.wait(2)end
  local zoom=B.frame(game.overworld,0,0);assert(zoom.fov<fov,'zoom did not change projection')
  local yaw=s.yaw;U.hold(game,'right',10);assert(s.yaw>yaw)
  assert(game.overworld.player.cellX==x and game.overworld.player.cellY==y,'binocular input moved player')
  U.wait(20);assert(U.shot(game,dir..'/binoculars-'..route..'.png'))
  U.tap(game,'b');U.wait(5);assert(not B.current()and not game.overworld.player.inputLocked);assert(not V.require('Voxel3D').camera,'camera not restored')
  print('PASS_NATIVE_BINOCULARS',route)
 end
 print('PASS_NATIVE_RC19_LOOKOUTS');love.event.quit()
end
