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
 local Collision=require('src.world.Collision')
 local profiles=assert(loadfile(os.getenv('VASC_REPO')..'/integrated/ascendant_pokemon_overworld/src/human_seat_profiles.lua'))()
 for _,id in ipairs{'REDS_HOUSE_1F','BLUES_HOUSE','CELADON_DINER','CELADON_MANSION_3F','CINNABAR_LAB_TRADE_ROOM','CELADON_MART_ROOF'}do
  P.setLevel('voxel',1);U.teleport(game,id,3,3,'down');U.wait(100)
  local world=game.overworld
  local function seatOwner(fn,seen)
   if type(fn)~='function'then return end;seen=seen or{};if seen[fn]then return end;seen[fn]=true
   local owns=false;local self
   for i=1,100 do local k,v=debug.getupvalue(fn,i);if not k then break end;if k=='humanJohtoSeat'then owns=true elseif k=='self'then self=v end end
   if owns and self then return self end
   for i=1,100 do local k,v=debug.getupvalue(fn,i);if not k then break end;local got=seatOwner(v,seen);if got then return got end end
  end
  local owner=seatOwner(V.require('Voxel3D').draw);assert(owner and not owner.humanJohtoSeatError,owner and owner.humanJohtoSeatError or 'missing seat renderer')
  local api=find(V.require('Voxel3D').draw,'humanJohtoSeat')
  for _,actor in ipairs(world.npcs)do
   for _,p in ipairs(profiles.byGeneration[1][id]or{})do if actor.def.index==p.index then
    local d=actor.sprite.def
    local pose=api and api:pose(game,{sprite=actor.sprite},nil,love.timer.getTime())
    assert(pose and pose.contact,'NPC seat not rendered: '..id)
    print('ACTOR',id,p.index,actor.cellX,actor.cellY,actor.px,actor.py,d.ascendantRole,d.ascendantAtlasImage,d.voxelSpriteDemo,pose and pose.row,pose and pose.contact and pose.contact.height)
   end end
  end
  local found=false
  for y=0,world.map.def.height*2-1 do for x=0,world.map.def.width*2-1 do
   if not found and Seats.chairAt(world,x,y)and not world:npcAtCell(x,y)then
    for _,delta in ipairs{{1,0,'left'},{-1,0,'right'},{0,1,'up'},{0,-1,'down'}}do
     local xx,yy=x+delta[1],y+delta[2]
     if world.map:inBounds(xx,yy)and world.map:isWalkableCell(xx,yy)and not Seats.chairAt(world,xx,yy)and not world:npcAtCell(xx,yy)and not world.map:warpAtCell(xx,yy)then
      local p=world.player;p.cellX,p.cellY,p.px,p.py,p.facing=xx,yy,xx*16,yy*16,delta[3]
      assert(not Collision.canMove(world.map,world.entities,p,delta[3]),'grid entered chair')
      assert(V.require('FreeMove')._blockedCell(world,p,x,y)=='tile','free walk entered chair')
      U.tap(game,'a');U.wait(15);assert(Seats.current(world),'A failed on '..id)
      local pose=api:pose(game,{sprite=p.sprite},nil,love.timer.getTime());assert(pose and pose.contact,'no player support')
      assert(U.shot(game,dir..'/seat-'..id..'.png'))
      U.hold(game,delta[3],1);U.wait(1)
      assert(not Seats.current(world)and (p.cellX~=x or p.cellY~=y),'movement stayed on chair')
      found=true;break
     end
    end
   end
  end end
  assert(found or id=='CELADON_MANSION_3F','no usable test chair in '..id)
  print('PASS_CHAIR',id)
 end
 print('PASS_NATIVE_KANTO_SEATS');love.event.quit(0)
end
