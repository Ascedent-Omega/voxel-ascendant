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

 P.setLevel('tiltshift',0)
 local Seats=V.require('WorldSeats');local Volcano=V.require('CinnabarVolcano')
 Volcano.setting:setValue('connected',game)
 local Map=require('src.world.Map')
 local profiles=assert(loadfile(os.getenv('VASC_REPO')..'/integrated/ascendant_pokemon_overworld/src/human_seat_profiles.lua'))()
 local resolved,total=0,0
 for id,entries in pairs(profiles.byGeneration[1])do
  local def=game.data.maps[id]
  if def then
   local map=Map.new(def,game.data.tilesets[def.tileset]);local world={map=map}
   for _,p in ipairs(entries)do
    local actual=Seats.npcProfile(world,p);total=total+1
    if actual.contact then resolved=resolved+1 else
     print('MISSING_SEAT',id,p.cellX,p.cellY,p.row)
     for _,prop in ipairs(V.require('VoxelFurniture').find(map))do
      if math.abs(prop.tx-p.cellX*2)<4 and math.abs(prop.ty-p.cellY*2)<4 then print('NEARBY',prop.kind,prop.tx,prop.ty,prop.claimed)end
     end
    end
   end
  end
 end
 assert(resolved==45 and total==45,'incomplete Kanto seat ownership')
 print('SEAT_COVERAGE',resolved,total)
 P.setLevel('voxel',1);U.teleport(game,'REDS_HOUSE_1F',4,4,'left');U.wait(120)
 assert(U.shot(game,dir..'/kanto-reds-house.png'))
 P.setLevel('voxel',1);U.teleport(game,'CELADON_DINER',3,4,'left');U.wait(120)
 assert(U.shot(game,dir..'/kanto-diner.png'))
 P.setLevel('voxel',1);U.teleport(game,'CINNABAR_ISLAND',2,9,'left');U.wait(240)
 assert(U.shot(game,dir..'/cinnabar-orbit.png'))
 -- Verify the native western water lane, both surf directions, and its
 -- native collision verdicts. This is more than a screenshot.
 local world=game.overworld;local map=world.map;local Collision=require('src.world.Collision')
 local checked=0
 for y=1,map.def.height*2-2 do
  for x=0,3 do if map:isWaterCell(x,y)then
   local mover={cellX=x,cellY=y,surfing=true}
   for _,dir in ipairs{'up','down'}do
    local dx,dy=Collision.target(x,y,dir)
    if map:isWaterCell(dx,dy)then
     assert(Collision.canMove(map,{},mover,dir),'native water blocked')
     checked=checked+1
    end
   end
  end end
 end
 assert(checked>20,'western surf lane missing')
 assert(map:isWaterCell(2,9)and map:isWaterCell(2,10),'surf start not water')
 world.player.surfing=true;local before=world.player.cellY
 U.hold(game,'down',35);U.wait(40)
 assert(world.player.cellY>before and world.player.surfing,'actual surf movement failed')
 print('PASS_NATIVE_SURF_CORRIDOR',checked,world.player.cellY-before)
 assert(U.shot(game,dir..'/cinnabar-surf-channel.png'))
 P.setLevel('voxel',1);U.teleport(game,'CINNABAR_ISLAND',8,10,'down');U.wait(100)
 assert(U.shot(game,dir..'/cinnabar-ash-ground.png'))
 P.setLevel('voxel',1);U.teleport(game,'CINNABAR_ISLAND',2,9,'left');U.wait(80)

 local frame=fp.frame
 fp.frame=function(...)local rig,x,z=frame(...);if rig then
  rig.eye={200,620,760};rig.focus={-430,290,144};rig.fov=1.05
 end;return rig,x,z end
 P.setLevel('voxel',6);U.wait(100);assert(U.shot(game,dir..'/volcano-day.png'))
 U.wait(60);assert(U.shot(game,dir..'/volcano-flow.png'))
 fp.frame=function(...)local rig,x,z=frame(...);if rig then
  rig.eye={-260,890,510};rig.focus={-700,604,144};rig.fov=.88
 end;return rig,x,z end
 U.wait(35);assert(U.shot(game,dir..'/volcano-crater.png'))
 fp.frame=function(...)local rig,x,z=frame(...);if rig then
  rig.eye={400,750,650};rig.focus={-260,200,144};rig.fov=1.15
 end;return rig,x,z end
 U.wait(35);assert(U.shot(game,dir..'/volcano-coast.png'))
 V.require('DayNight').setting:setValue('night',game);U.wait(70);assert(U.shot(game,dir..'/volcano-night.png'))
 V.require('DayNight').setting:setValue('day',game);fp.frame=frame
 P.setLevel('voxel',0);U.wait(50);assert(not require('src.render.TileRenderer')._vascVolcano,'Vanilla renderer was modified')
 assert(U.shot(game,dir..'/volcano-2d.png'))
 Volcano.setting:setValue('classic',game);U.wait(50)
 assert(U.shot(game,dir..'/volcano-2d-classic.png'))
 P.setLevel('voxel',1);U.wait(200);assert(U.shot(game,dir..'/volcano-classic.png'))
 Volcano.setting:setValue('connected',game);U.wait(200)
 P.setLevel('voxel',1);U.teleport(game,'CELADON_MART_ROOF',6,5,'down');U.wait(260)
 local pos=assert(V.require('RooftopWorld').lastMountains.volcano,'roof volcano absent')
 print('ROOF_VOLCANO',pos.x,pos.z,pos.height)
 fp.frame=function(...)local rig,x,z=frame(...);if rig then
  rig.eye={104,24,90};rig.focus={pos.x-700,pos.height*.48-100,pos.z+144};rig.fov=.92
 end;return rig,x,z end
 P.setLevel('voxel',6);U.wait(80);assert(U.shot(game,dir..'/volcano-from-mart.png'))
 fp.frame=frame
 print('PASS_NATIVE_KANTO_VOLCANO');love.event.quit(0)
end
