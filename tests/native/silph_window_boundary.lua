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

 local W=V.require('SilphWindows');local Portal=V.require('SilphWindowVisibility')
 local frame=fp.frame
 local function pixel(path,x,y)
  local f=assert(io.open(path,'rb'));local bytes=f:read('*a');f:close()
  local data=love.filesystem.newFileData(bytes,'shot.png');local image=love.image.newImageData(data)
  local r,g,b=image:getPixel(x,y);image:release();data:release();return r,g,b
 end
 for _,floor in ipairs(os.getenv('SILPH_FLOOR')and{tonumber(os.getenv('SILPH_FLOOR'))}or{1,2,6,10,11})do
  P.setLevel('voxel',1);U.teleport(game,'SILPH_CO_'..floor..'F',3,5,'up');ready()
  for _,level in ipairs(floor==1 and {1,3,5}or{1})do
   P.setLevel('voxel',level);U.wait(80)
   local stats=assert(Portal.last,'orbit visibility missing');assert(stats.rejected>0);assert(stats.accepted+stats.rejected<1600,'exterior batch budget')
   print('ORBIT_WINDOW_BATCHES',floor,level,stats.accepted,stats.rejected)
   local path=dir..'/silph-'..floor..'-orbit-'..level..'.png'
   assert(U.shot(game,path))
   if floor==1 and level==1 then
    local r,g,b=pixel(path,12,12);assert(r<.005 and g<.005 and b<.005,'cutaway background is not black')
   end
  end
  fp.frame=function(...)local rig,x,z=frame(...);if rig then
   local x=game.overworld.map.def.width*16
   rig.eye={x,24,3};rig.focus={x,42,-80};rig.fov=.95
  end;return rig,x,z end
  P.setLevel('voxel',6);for i=1,1200 do if fp.blend>=1 then break end;U.wait(1)end
  U.wait(40);assert(U.shot(game,dir..'/silph-'..floor..'-near-glass.png'))
  assert(Portal.last and Portal.last.rejected>0)
  if floor==1 then
   local r,g,b=pixel(dir..'/silph-1-near-glass.png',600,50)
   assert(b>.2 and b>r,'sky through first-person glazing was blackened')
  end
  fp.frame=frame
  if floor==1 then
   P.setLevel('voxel',7);U.teleport(game,'SILPH_CO_1F',15,12,'up');ready()
   U.wait(80)
   local G=V.require('Voxel3D');local BG=V.require('SilphCutawayBackground')
   assert(BG.inside(480,288,50,G.eye),'native third-person camera outside room')
   assert(BG.lastPieces==0,'third person blackened the backdrop')
   assert(U.shot(game,dir..'/silph-1-third-person.png'))
   local third=fp.frame
   fp.frame=function(...)local rig,x,z=third(...);if rig then rig.focus={rig.eye[1],49,rig.eye[3]-24}end;return rig,x,z end
   U.wait(40);assert(U.shot(game,dir..'/silph-1-third-ceiling.png'))
   local r,g,b=pixel(dir..'/silph-1-third-ceiling.png',600,50)
   assert(r>.05 and math.abs(b-r)<.18,'third-person ceiling missing or replaced by sky/black')
   fp.frame=frame
  end
 end
 assert(W.height({id='SILPH_CO_1F',def={width=15,height=9,tileset='FACILITY'}})==0)
 print('PASS_NATIVE_SILPH_WINDOW_BOUNDARY');love.event.quit(0)
end
