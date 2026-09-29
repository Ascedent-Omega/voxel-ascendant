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
 V.require('CinnabarVolcano').setting:setValue('connected',game)
 P.setLevel('voxel',1);U.teleport(game,'CINNABAR_ISLAND',8,10,'down');U.wait(150)
 local items=V.require('VoxelItems');local count=0
 for _,prop in ipairs(V.require('VoxelFurniture').find(game.overworld.map))do
  if prop.kind:match('^cinnabar_palm_')then
   assert(prop.claimed,'palm not claimed');count=count+1
   local m=items.models[prop.kind];assert(not m.seasonalFoliage,'palm must stay evergreen')
   for _,b in ipairs(m.boxes)do
    if b[2]<24 then assert(b[1]>=0 and b[3]>=0 and b[1]+b[4]<=16 and b[3]+b[6]<=16,'palm trunk blocks adjacent route')end
   end
   local mesh=assert(items.resolveKind(prop.kind));assert(items.bounds(mesh),'missing canopy culling bounds')
  end
 end
 assert(count==3,'native palm anchors changed')
 assert(U.shot(game,dir..'/zinnober-palmen-spielansicht.png'))
 local frame=fp.frame
 fp.frame=function(...)local rig,x,z=frame(...);if rig then
  rig.eye={160,135,385};rig.focus={150,10,175};rig.fov=1.05
 end;return rig,x,z end
 P.setLevel('voxel',6)
 for i=1,1200 do if fp.blend>=1 then break end;U.wait(1)end
 U.wait(30);assert(U.shot(game,dir..'/zinnober-palmen-kueste.png'))
 fp.frame=function(...)local rig,x,z=frame(...);if rig then
  rig.eye={124,60,279};rig.focus={103,23,230};rig.fov=.90
 end;return rig,x,z end
 U.wait(25);assert(U.shot(game,dir..'/zinnober-palme-detail.png'))
 V.require('DayNight').setting:setValue('night',game);U.wait(35)
 assert(U.shot(game,dir..'/zinnober-palme-nacht.png'))
 fp.frame=frame;P.setLevel('voxel',0);U.wait(25)
 assert(U.shot(game,dir..'/zinnober-palmen-vanilla.png'))
 print('PASS_NATIVE_CINNABAR_PALMS',count);love.event.quit(0)
end
