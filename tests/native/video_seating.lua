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
 local Seats=V.require('WorldSeats')
 P.setLevel('voxel',1);U.teleport(game,'GAME_CORNER',4,10,'left');P.setLevel('voxel',6)
 for i=1,1200 do if fp.blend>=1 then break end;U.wait(1)end
 assert(fp.blend>=1,'camera transition not finished');U.wait(10)
 fp.lookBy(-math.pi/2-fp.yaw,.25-fp.pitch);U.wait(25)
 assert(Seats.viewRow(1,40,168)==2,'rear view must show the NPC back')
 assert(U.shot(game,dir..'/npc-facing-machine.png'))
 -- The purple backrest must occlude the green coat in this fixed rear view.
 -- This catches a camera-depth pull even when the logical seat pose passes.
 do
  local f=assert(io.open(dir..'/npc-facing-machine.png','rb'));local bytes=f:read('*a');f:close()
  local file=love.filesystem.newFileData(bytes,'seat.png');local pixels=love.image.newImageData(file)
  local purple=0
  for y=345,384 do for x=580,619 do
   local r,g,b=pixels:getPixel(x,y);if r>g*1.3 and b>g*1.3 then purple=purple+1 end
  end end
  pixels:release();file:release();assert(purple>1400,'occupant paints over the solid backrest')
  print('PASS_BACKREST_DEPTH',purple)
 end
 local seat=assert(find(V.require('Voxel3D').draw,'humanJohtoSeat'))
 assert(seat.meshes>=8,'stationary casino profiles missing')
 -- Check both banks from behind, the side and an oblique angle in each style.
 local observerFrame=fp.frame
 for _,style in ipairs{'voxel','hd'}do
  assert(ex.voxelCharacterCard.select(style,game));U.wait(30)
  for _,bank in ipairs{{'left',2,10,1},{'right',5,11,-1}}do
   for _,angle in ipairs{{'rear',32,0},{'side',0,24},{'oblique',24,24}}do
    local x,z=bank[2]*16+8,bank[3]*16+8
    fp.frame=function(...)local rig,cx,cz=observerFrame(...);if rig then
     rig.eye={x+angle[2]*bank[4],17,z+angle[3]};rig.focus={x,8,z};rig.fov=.85
    end;return rig,cx,cz end
    U.wait(15);assert(U.shot(game,dir..'/backrest-'..style..'-'..bank[1]..'-'..angle[1]..'.png'))
   end
  end
 end
 fp.frame=observerFrame;assert(ex.voxelCharacterCard.select('voxel',game));U.wait(15)
 -- Exercise a free chair through the normal controller/touch A button.
 U.teleport(game,'GAME_CORNER',3,11,'left');P.setLevel('voxel',1);U.wait(80)
 local world=game.overworld
 assert(Seats.chairAt(world,2,11),'reviewed free chair missing')
 assert(not Seats.sit(world,2,10),'occupied NPC seat admitted')
 U.tap(game,'a');U.wait(35)
 assert(Seats.current(world),'A did not sit down')
 assert(world.player.cellX==2 and world.player.cellY==11 and world.player.facing=='left','seat anchor/bearing')
 local profile=seat:pose(game,{sprite=world.player.sprite},nil,love.timer.getTime())
 assert(profile and profile.index==0,'player seat pose not admitted')
 assert(U.shot(game,dir..'/player-seated.png'))
 -- Fixed QA observer: inspect the actual occupied chair from its side.
 local frame,hide=fp.frame,fp.hidePlayer
 fp.hidePlayer=function()return false end
 fp.frame=function(...)local rig,x,z=frame(...);if rig then
  rig.eye={world.player.px+16,18,world.player.py+32};rig.focus={world.player.px+8,8,world.player.py+8};rig.fov=.9
 end;return rig,x,z end
 P.setLevel('voxel',6);U.wait(50);assert(U.shot(game,dir..'/player-seated-close.png'))
 assert(ex.voxelCharacterCard.select('hd',game));U.wait(45)
 assert(U.shot(game,dir..'/player-seated-hd.png'));fp.frame,fp.hidePlayer=frame,hide
 assert(ex.voxelCharacterCard.select('voxel',game));U.wait(25)
 P.setLevel('voxel',6);U.wait(45);fp.lookBy(-math.pi/2-fp.yaw,-.55-fp.pitch);U.wait(25)
 assert(Seats.current(world)and world.player.facing=='left','first-person camera changed seated body')
 assert(U.shot(game,dir..'/player-seated-first-person.png'))
 fp.lookBy(math.pi/2,0);U.wait(10)
 assert(world.player.facing=='left','looking around rotated seated body')
 P.setLevel('voxel',1);U.wait(30)
 -- Machine interaction is still native; without coins it opens its normal text.
 U.tap(game,'a');U.wait(12)
 assert(game.stack:top()~=world,'seated A did not reach the slot machine')
 for i=1,160 do if game.stack:top()==world then break end;U.tap(game,'b');U.wait(2)end
 assert(game.stack:top()==world,'machine dialogue failed to close')
 U.tap(game,'b');U.wait(5);assert(not Seats.current(world),'B did not stand')
 assert(world.player.cellX==3 and world.player.cellY==11,'stand did not return to free entry cell')
 world.player.facing='left';U.tap(game,'a');U.wait(8);assert(Seats.current(world))
 U.hold(game,'down',1);U.wait(5);assert(not Seats.current(world),'movement retained seating')
 -- First-person A uses the same seat and aims at its machine screen.
 P.setLevel('voxel',6);U.wait(45);fp.lookBy(-math.pi/2-fp.yaw,-.1-fp.pitch);U.wait(5)
 U.tap(game,'a');U.wait(10)
 assert(Seats.current(world)and math.abs(fp.pitch+.55)<.001,'first-person sit did not aim at machine')
 U.tap(game,'b');U.wait(5);assert(not Seats.current(world))
 -- Opposite-facing bank; menu must restore ordinary movement before opening.
 P.setLevel('voxel',1);U.wait(25)
 U.teleport(game,'GAME_CORNER',4,12,'right');U.wait(45);world=game.overworld
 assert(Seats.chairAt(world,5,12),'right-facing free chair missing')
 U.tap(game,'a');U.wait(20);assert(Seats.current(world)and world.player.facing=='right')
 assert(U.shot(game,dir..'/player-seated-right.png'))
 U.tap(game,'start');U.wait(10);assert(not Seats.current(world)and game.stack:top()~=world,'menu kept seating')
 while game.stack:top()~=world do game.stack:pop()end
 -- Mode changes and map changes cannot leave input locks or a saved seat.
 world.player.facing='right';U.tap(game,'a');U.wait(10);assert(Seats.current(world))
 P.setLevel('voxel',0);U.wait(5);assert(not Seats.current(world)and not world.player.inputLocked)
 P.setLevel('voxel',1);world.player.facing='right';U.tap(game,'a');U.wait(10);assert(Seats.current(world))
 U.teleport(game,'PALLET_TOWN',8,8,'down');U.wait(10)
 assert(not Seats.current(game.overworld)and not game.overworld.player.inputLocked,'map change retained seat')
 print('PASS_NATIVE_SEATING_DIRECTION_INTERACTION');love.event.quit(0)
end
