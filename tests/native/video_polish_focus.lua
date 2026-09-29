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
 if not os.getenv('PORTRAIT_ONLY')then
 for _,q in ipairs{{'GAME_CORNER',10,13},{'LAVENDER_TOWN',8,8},{'VERMILION_CITY',10,10},{'CELADON_MART_ELEVATOR',1,2},{'SILPH_CO_ELEVATOR',1,2},{'ROCKET_HIDEOUT_ELEVATOR',1,2}}do
  U.teleport(game,q[1],q[2],q[3],'up');P.setLevel('voxel',7);U.wait(130)
  print('PROPS',q[1]);for _,p in ipairs(V.require('VoxelFurniture').find(game.overworld.map))do print('PROP',p.kind,p.tx,p.ty,p.claimed,V.require('VoxelFurniture').enabled(p))end
  local n=0;V.require('Halloween').eachPumpkin(game.overworld,function(x,y,z,p)
   n=n+1
   if n==1 then fp.lookBy(math.atan2(-(x-(game.overworld.player.px+8)),z-(game.overworld.player.py+8))-fp.yaw,.2-fp.pitch)end
  end)
  U.wait(30);assert(U.shot(game,dir..'/'..q[1]..'-focus.png'))
 end
 U.teleport(game,'PEWTER_GYM',4,10,'up');P.setLevel('voxel',6);U.wait(100)
 for _,phase in ipairs{'day','dusk','night'}do
  V.require('DayNight').setting:setValue(phase,game)
  fp.lookBy(math.pi-fp.yaw,-1.5-fp.pitch);U.wait(30)
  assert(U.shot(game,dir..'/mosaic-'..phase..'.png'))
 end
 P.setLevel('voxel',7)
 for _,species in ipairs{'MEW','PIDGEOT'}do
  local entry=Screens.push(game,'DexEntryMenu',{species=species,forceOwned=true});U.wait(4)
  assert(entry.__vascDexSource=='cobblemon',species..' Dex source')
  local actor=assert(entry._vascDexModel.actor)
  local scale,info=V.require('CobblemonOverworldSize').scale(actor,species=='MEW'and 151 or 18)
  print('SIZE',species,scale,info.height,info.span)
  assert(scale>0)
  assert(U.shot(game,dir..'/'..species..'-model.png'));game.stack:pop()
 end
 end
 U.teleport(game,'VIRIDIAN_CITY',13,20,'up');U.wait(60)
 local NPC=require('src.world.NPC');local npc=NPC.new(game.data,game.overworld.map.id,{index=999,name='QA_FOLLOWER',sprite='SPRITE_PIKACHU',movement='STAY',range='NONE',x=13,y=19})
 npc.pikachuFollower=true;npc.sprite.def.pokemonSpecies='MEW'
 local talk=require('src.world.PikachuFollower').talk
 local portrait=find(talk,'portrait');if portrait then local ok,pic=pcall(portrait,game,npc,'MEW');print('PORTRAIT_PROBE',ok,pic);print('PORTRAIT_PATH',require('src.pokemon.Sprites').path(game.data,'MEW','front',{kind='overworld',mon={species='MEW'}}));local pal=require('src.render.PaletteFX').monPal(game.data,'MEW');for i,c in ipairs(pal or{})do print('PORTRAIT_COLOR',i,unpack(c))end;if ok and pic then local data=pic:newImageData();local png=data:encode('png');local file=assert(io.open(dir..'/MEW-portrait-source.png','wb'));file:write(png:getString());file:close();data:release();pic:release()end end
 local emote=talk(game,game.overworld,npc)
 assert(emote.pikaPic=='vasc-follower:MEW','follower portrait unavailable');U.wait(10)
 assert(U.shot(game,dir..'/MEW-conversation.png'))
 print('PASS_VIDEO_POLISH_FOCUS');love.event.quit(0)
end
