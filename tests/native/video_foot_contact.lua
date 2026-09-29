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

 P.setLevel('voxel',1);U.teleport(game,'PALLET_TOWN',8,8,'down');U.wait(75)
 local function owner(fn,name,seen)
  if type(fn)~='function'then return end;seen=seen or{};if seen[fn]then return end;seen[fn]=true
  for i=1,100 do local k,v=debug.getupvalue(fn,i);if not k then break end;if k==name then return fn,i,v end end
  for i=1,100 do local k,v=debug.getupvalue(fn,i);if not k then break end;local a,b,c=owner(v,name,seen);if a then return a,b,c end end
 end
 local meshWanted,textureWanted,seen,phase=nil,nil,{},'idle'
 local fn,index,draw=assert(owner(V.require('Voxel3D').draw,'originalDraw'))
 -- Inspect the actual composited sole, not the transparent rectangle's bottom.
 debug.setupvalue(fn,index,function(mesh,texture,model,...)
  if mesh==meshWanted and texture==textureWanted and texture.typeOf and texture:typeOf('Canvas') and not seen[phase] then
   local pixels=texture:newImageData();local w,h=pixels:getDimensions()
   local soleX,soleY
   for y=h-1,0,-1 do
    for x=0,w-1 do local _,_,_,a=pixels:getPixel(x,y);if a>.5 then soleX,soleY=x,y;break end end
    if soleY then break end
   end
   pixels:release();assert(soleY,'empty human frame')
   local u,v=(soleX+.5)/w,(soleY+1)/h
   local ids=mesh:getVertexMap();local localY
   for k=1,#ids,3 do
    local a,b,c={mesh:getVertex(ids[k])},{mesh:getVertex(ids[k+1])},{mesh:getVertex(ids[k+2])}
    local det=(b[5]-c[5])*(a[4]-c[4])+(c[4]-b[4])*(a[5]-c[5])
    if math.abs(det)>1e-12 then
     local wa=((b[5]-c[5])*(u-c[4])+(c[4]-b[4])*(v-c[5]))/det
     local wb=((c[5]-a[5])*(u-c[4])+(a[4]-c[4])*(v-c[5]))/det;local wc=1-wa-wb
     if math.min(wa,wb,wc)>-.001 then localY=wa*a[2]+wb*b[2]+wc*c[2];break end
    end
   end
   assert(localY,'sole outside rig UVs');seen[phase]=localY
   print('SOLE',phase,'height',localY,'row',soleY,'modelY',model[8])
  end
  return draw(mesh,texture,model,...)
 end)
 for _,style in ipairs{'voxel','hd'}do
  assert(ex.voxelCharacterCard.select(style,game));U.wait(35)
  -- Mode selection rebuilds the rig instance; attach its new prepare method.
  local rig=assert(find(V.require('Voxel3D').draw,'humanRig'));local prep=rig.prepare
  if not rig._footTest then
   local original=prep
   rig.prepare=function(self,record,...)local m,t=original(self,record,...)
    if record.sprite==game.overworld.player.sprite then meshWanted,textureWanted=m,t end
    return m,t end;rig._footTest=true
  end
  for _,facing in ipairs{'left','right','up','down'}do
   P.setLevel('voxel',1);U.teleport(game,'PALLET_TOWN',8,8,facing);U.wait(25)
   phase=style..'-'..facing..'-idle';U.wait(2);assert(U.shot(game,dir..'/'..phase..'.png'))
   for step=1,3 do
    phase='transition';seen.transition=true;U.hold(game,facing,6)
    phase=style..'-'..facing..'-step'..step;assert(U.shot(game,dir..'/'..phase..'.png'))
   end
   U.wait(40)
  end
 end
 assert(seen['voxel-left-idle'] and seen['hd-down-step3'],'missing rendered foot samples')
 seen.transition=nil
 for name,y in pairs(seen)do assert(type(y)~='number' or math.abs(y)<.1,name..' sole is above/below support: '..y)end
 print('PASS_NATIVE_FOOT_CONTACT');love.event.quit(0)
end
