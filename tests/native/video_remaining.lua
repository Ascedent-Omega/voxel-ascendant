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
 U.teleport(game,'GAME_CORNER',7,12,'left');P.setLevel('voxel',1);U.wait(180)
 for _,npc in pairs(game.overworld.npcs)do print('CASINO_ACTOR',npc.def.index,npc.cellX,npc.cellY,npc.sprite.def.ascendantRole,npc.sprite.def.voxelSpriteDemo)end
 assert(U.shot(game,dir..'/casino-full.png'))
 P.setLevel('voxel',7);U.wait(20);assert(U.shot(game,dir..'/casino-close.png'))
 local sprites=ex.overworldPokemon.voxelCharacters
 print('SEAT_ERROR',sprites.humanJohtoSeatError)
 local seat=assert(find(V.require('Voxel3D').draw,'humanJohtoSeat'));assert(seat.meshes>=8,'casino seats not active')
 local updates=seat.updates
 U.teleport(game,'GAME_CORNER',4,10,'left');P.setLevel('voxel',6);U.wait(60)
 fp.lookBy(-math.pi/2-fp.yaw,.25-fp.pitch);U.wait(25)
 assert(U.shot(game,dir..'/casino-seated.png'));U.wait(90)
 assert(seat.updates>updates,'casino operation animation stopped');print('SEATED',seat.meshes,seat.updates)
 assert(ex.voxelCharacterCard.select('hd',game));U.wait(60)
 assert(U.shot(game,dir..'/casino-seated-hd.png'))
 assert(ex.voxelCharacterCard.select('voxel',game));U.wait(30)

 U.teleport(game,'PALLET_TOWN',8,8,'down');P.setLevel('voxel',1);U.wait(80)
 for _,id in ipairs{'spring','summer','winter'}do
  V.require('CalendarEvents').setting:setValue(id,game)
  if id=='summer'then V.require('DayNight').setting:setValue('night',game)else V.require('DayNight').setting:setValue('day',game)end
  U.wait(50);local n=0;V.require('CalendarDecor').each(game.overworld,function()n=n+1 end);assert(n>0,'no festival props '..id)
  assert(U.shot(game,dir..'/festival-'..id..'.png'));print('FESTIVAL',id,n)
  local target;V.require('CalendarDecor').each(game.overworld,function(kind,x,y,z)if not target and z<240 then target={x,y,z}end end)
  local px=target[1]+(target[1]<160 and 28 or -28)
  local pz=target[3]+32
  U.teleport(game,'PALLET_TOWN',math.floor(px/16),math.floor(pz/16),'up');P.setLevel('voxel',6);U.wait(30)
  fp.lookBy(math.atan2(target[1]-(game.overworld.player.px+8),target[3]-(game.overworld.player.py+8))-fp.yaw,.2-fp.pitch)
  V.require('DayNight').setting:setValue(id=='summer'and'night'or'day',game);U.wait(25)
  assert(U.shot(game,dir..'/festival-'..id..'-close.png'))
  U.teleport(game,'PALLET_TOWN',8,8,'down');P.setLevel('voxel',1)

 end
 V.require('CalendarEvents').setting:setValue('off',game);V.require('DayNight').setting:setValue('day',game)
 local B=V.require('BicycleColors')
 -- Probe exact protected pixels on each supported hero and all twelve frames.
 for _,role in ipairs{'red','blue','green'}do
  local root=V.mod.path..'/integrated/ascendant_pokemon_overworld/assets/voxel-wardrobe/'..role..'/'
  local data=love.image.newImageData(root..'source-bicycle.png');local mask=love.image.newImageData(root..'protected-bicycle.png')
  local tex=love.graphics.newImage(data);local def={ascendantCharacterAction='bicycle',voxelSpriteDemo=true}
  B.setting:setValue('red',game);local colored=B.texture(tex,def,role);local out=colored:newImageData();local changed=0
  for y=0,data:getHeight()-1,3 do for x=0,data:getWidth()-1,3 do
   local r,g,b,a=data:getPixel(x,y);local R,G,BB,A=out:getPixel(x,y);local m=mask:getPixel(x,y)
   assert(math.abs(a-A)<.01,'bike alpha changed')
   if math.abs(r-R)+math.abs(g-G)+math.abs(b-BB)>.035 then
    assert(m>.99 and b>r*1.5 and b>g*1.1 and b>.18,'rider recoloured');changed=changed+1
   end
  end end
  assert(changed>1000,'frame mask empty '..role);print('BIKE_MASK',role,changed)
  local png=out:encode('png');local f=assert(io.open(dir..'/bike-'..role..'.png','wb'));f:write(png:getString());f:close();png:release();out:release();tex:release();mask:release();data:release()
 end
 -- A failed paint allocation must keep the actor and the world renderer.
 local tex=love.graphics.newImage(V.mod.path..'/integrated/ascendant_pokemon_overworld/assets/voxel-wardrobe/red/source-bicycle.png')
 B.setting:setValue('violet',game)
 local allocate=love.graphics.newCanvas;local tries=0
 love.graphics.newCanvas=function()tries=tries+1;error('QA rejected canvas')end
 local def={ascendantCharacterAction='bicycle',voxelSpriteDemo=true}
 assert(B.texture(tex,def,'red')==tex and B.lastError,'paint failure did not fall back')
 assert(B.texture(tex,def,'red')==tex and tries==1,'paint failure retried every frame')
 love.graphics.newCanvas=allocate;B.setting:setValue('gold',game)
 assert(B.texture(tex,def,'red')~=tex and not B.lastError,'paint failed to recover');B.clear();tex:release()
 print('PASS_BIKE_FAILURE_ISOLATION')
 local T=V.require('TravelPokemonModel');assert(T.enabled(),'travel model setting')
 local canvas=love.graphics.newCanvas(768,512)
 for _,spec in ipairs{{'PIDGEOT',18,'fly'},{'LAPRAS',131,'surf'},{'CHARIZARD',6,'fly'},{'GYARADOS',130,'surf'}}do
  local shot={frame=40};local mon={species=spec[1]}
  love.graphics.push('all');love.graphics.setCanvas(canvas);love.graphics.origin();love.graphics.clear(.12,.17,.23,1)
  for i,direction in ipairs{'down','left','up'}do
   assert(T.draw(shot,mon,spec[2],spec[3],direction,(i-.5)*256,256,230,1),shot.travelModel and shot.travelModel.error or 'travel draw failed')
  end
  shot.frame=70
  for i,direction in ipairs{'down','left','up'}do assert(T.draw(shot,mon,spec[2],spec[3],direction,(i-.5)*256,512,230,1))end
  love.graphics.pop()
  local out=canvas:newImageData();local png=out:encode('png');local f=assert(io.open(dir..'/travel-'..spec[1]..'.png','wb'));f:write(png:getString());f:close();png:release();out:release()
  print('TRAVEL',spec[1],shot.travelModel.variant,shot.travelModel.actor.anim);T.release(shot)
 end
 canvas:release()
 print('PASS_VIDEO_REMAINING_RENDER');love.event.quit(0)
end
