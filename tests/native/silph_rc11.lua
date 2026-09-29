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
 for _,n in ipairs(os.getenv('SILPH_QUICK')and{1,11}or{1,2,3,4,5,6,7,8,9,10,11})do
  U.teleport(game,'SILPH_CO_'..n..'F',3,5,'up');ready()
  local m=game.overworld.map;local count,desk=0,0
  for _,p in ipairs(V.require('VoxelFurniture').find(m))do
   if p.kind=='silph_lift_portal'then count=count+1;assert(p.claimed,'portal unclaimed')end
   if p.kind:match('^silph_desk_')then desk=desk+1;assert(p.claimed,'desk unclaimed');assert(V.require('VoxelItems').models[p.kind].support==16)end
  end
  assert(count==1,'lift portal '..n..' count '..count)
  if n==1 then assert(desk==14,'desk modules '..desk)end
  local layout=assert(V.require('InteriorLights').layout(m));local portals=0
  for _,p in ipairs(layout.portals)do if p.facade then portals=portals+1 end end
  assert(portals>0,'no daylight apertures '..n)
  assert(not LL.failure,LL.failure);assert(LL.current().portals and #LL.current().portals<=LL.MAX_PORTALS)
  print('PASS_FLOOR',n,count,desk,portals,#LL.current().portals)
  if n==1 or n==11 then assert(U.shot(game,dir..'/silph-'..n..'-overview.png'))end
 end
 U.teleport(game,'SILPH_CO_1F',5,5,'up');ready()
 local frame=fp.frame
 fp.frame=function(...)local rig,x,z=frame(...);if rig then rig.eye={85,24,120};rig.focus={85,12,48};rig.fov=1.1 end;return rig,x,z end
 P.setLevel('voxel',6);U.wait(140);assert(U.shot(game,dir..'/silph-reception.png'))
 fp.frame=function(...)local rig,x,z=frame(...);if rig then rig.eye={328,23,75};rig.focus={328,16,0};rig.fov=1.0 end;return rig,x,z end
 U.wait(45);assert(U.shot(game,dir..'/silph-lift-door.png'));fp.frame=frame
 W.setting:setValue(false,game,true);ready();assert(not W.enabled(game.overworld.map))
 for _,r in ipairs(H.meshes(game.overworld))do assert(r.class~='silph_exterior'and r.kind~='window_glass','disabled window geometry retained')end
 assert(U.shot(game,dir..'/silph-windows-off.png'))
 W.setting:setValue(true,game,true);ready()
 P.setLevel('voxel',1);U.teleport(game,'SILPH_CO_ELEVATOR',3,1,'up');ready()
 assert(E.matches(game.overworld.map));assert(W.enabled(game.overworld.map))
 local glass=0;for _,r in ipairs(H.meshes(game.overworld))do if r.kind=='window_glass'then glass=glass+1 end end;assert(glass>0,'no cabin glazing')
 fp.frame=function(...)local rig,x,z=frame(...);if rig then rig.eye={32,22,45};rig.focus={-30,24,16};rig.fov=1.1 end;return rig,x,z end
 P.setLevel('voxel',6);U.wait(140);assert(U.shot(game,dir..'/silph-cabin-1f.png'))
 local List=require('src.ui.ListMenu');local menu
 P.setLevel('voxel',1);U.wait(140)
 U.teleport(game,'SILPH_CO_ELEVATOR',3,1,'up');ready()
 local fx,fy=game.overworld.player:facingCell();print('PANEL_FACING',fx,fy,game.overworld.player.facing)
 assert(game.overworld.map:signAtCell(fx,fy),'not facing native panel')
 game.overworld:interact()
 for i=1,500 do
  if getmetatable(game.stack:top())==List then menu=game.stack:top();break end
  U.wait(1)
 end
 assert(menu,'native elevator menu did not open')
 local index;for i,item in ipairs(menu.items)do if item.value and item.value.map=='SILPH_CO_11F'then index=i end end
 assert(index);menu.index=index;U.tap(game,'a')
 P.setLevel('voxel',6)
 assert(E.ride and E.ride.vascTo==11 and E.ride.vascFrom==1,'native selection not tracked')
 U.wait(90);assert(E.offset(game.overworld.map)<0 and E.offset(game.overworld.map)>-248)
 assert(U.shot(game,dir..'/silph-cabin-moving.png'))
 for i=1,1000 do if not E.ride then break end;U.wait(1)end
 assert(not E.ride,'ride did not complete');assert(E.floor(game.overworld.map)==11,'native exit destination lost')
 assert(E.offset(game.overworld.map)==-248);U.wait(30);assert(U.shot(game,dir..'/silph-cabin-11f.png'))
 print('PASS_NATIVE_SILPH_ASCENT','native glass elevator 1F to 11F')
 -- Cancel and return through the same native menu/callbacks.
 P.setLevel('voxel',1);U.wait(140)
 local function openMenu()
  game.overworld.player.facing='up';game.overworld:interact()
  for i=1,500 do local top=game.stack:top();if getmetatable(top)==List then return top end;U.wait(1)end
  error('return floor menu absent')
 end
 menu=openMenu();U.tap(game,'b');U.wait(2);assert(game.stack:top()==game.overworld,'cancel menu left open');assert(not E.ride and E.floor(game.overworld.map)==11,'cancel changed destination')
 menu=openMenu();index=nil;for i,item in ipairs(menu.items)do if item.value and item.value.map=='SILPH_CO_1F'then index=i end end
 assert(index);menu.index=index;U.tap(game,'a')
 assert(E.ride and E.ride.vascFrom==11 and E.ride.vascTo==1)
 U.wait(90);assert(E.offset(game.overworld.map)<0 and E.offset(game.overworld.map)>-248)
 for i=1,1000 do if not E.ride then break end;U.wait(1)end
 assert(not E.ride and E.floor(game.overworld.map)==1 and E.offset(game.overworld.map)==0)
 fp.frame=frame
 print('EXIT_START',game.overworld.player.cellX,game.overworld.player.cellY,P.level('voxel'),fp.blend)
 for i=1,80 do if game.overworld.player.cellX==2 then break end;U.hold(game,'left',1)end
 game.input.state.left=false;U.wait(20)
 print('EXIT_ALIGNED',game.overworld.player.cellX,game.overworld.player.cellY)
 for i=1,160 do if game.overworld.map.id~='SILPH_CO_ELEVATOR'then break end;U.hold(game,'down',1)end
 game.input.state.down=false;U.wait(40)
 print('EXIT_POSITION',game.overworld.map.id,game.overworld.player.cellX,game.overworld.player.cellY,game.overworld.player.inputLocked)
 assert(game.overworld.map.id=='SILPH_CO_1F','walking out did not reach chosen floor');ready()
 print('PASS_NATIVE_SILPH_ELEVATOR_RETURN','cancel; 11F to 1F; walk out')
 -- Show and measure the actual sun-facing floor, not only selected uniforms.
 fp.frame=function(...)local rig,x,z=frame(...);if rig then rig.eye={427,38,200};rig.focus={466,0,233};rig.fov=1.05 end;return rig,x,z end
 P.setLevel('voxel',6);U.wait(140)
 assert(U.shot(game,dir..'/silph-daylight.png'))
 local select=LL.windowPortals;LL.windowPortals=function()return{}end;U.wait(40)
 assert(U.shot(game,dir..'/silph-daylight-control.png'));LL.windowPortals=select
 local function pixels(name)local f=assert(io.open(dir..'/'..name..'.png','rb'));local bytes=f:read('*a');f:close();return love.image.newImageData(love.filesystem.newFileData(bytes,name..'.png'))end
 local lit,dark=pixels('silph-daylight'),pixels('silph-daylight-control');local changed,gain=0,0
 for y=100,700,5 do for x=100,1100,5 do local r,g,b=lit:getPixel(x,y);local a,c,d=dark:getPixel(x,y);local delta=(r+g+b-a-c-d)/3;if delta>.025 then changed=changed+1;gain=gain+delta end end end
 lit:release();dark:release();print('DAYLIGHT_PIXELS',changed,gain);assert(changed>100,'daylight did not visibly illuminate floor')
 fp.frame=frame;print('PASS_NATIVE_SILPH_DAYLIGHT');print('PASS_NATIVE_SILPH_RC11');love.event.quit(0)
end
