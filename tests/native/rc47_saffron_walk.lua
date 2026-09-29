return function(game)
 assert(os.getenv('POKEPORT_IDENTITY')=='vasc-video-polish-qa')
 love.audio.setVolume(0)
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
 local dx,dz=0,0
 fp.moveVector=function()return dx,dz end;fp.moveWorld=function(x,z)return x,z end
 V.require('LocalLights').setting:setValue(true,game,true)
 V.require('Gen1PalletVillage').buildings:setValue(true,game,true)
 local trace,wrap=assert(loadfile(assert(os.getenv('QA_VASC_ROOT'))..'/tests/native/rc27_model_trace.lua'))()(V,game)
 for _,spec in ipairs{{'WaterReflection','draw'},{'Voxel3D','beginWater'},{'Voxel3D','endWater'},{'Water','begin'},{'Water','draw'},{'Water','finish'},{'PropVisibility','visibleWater'},{'ShadowMap','begin'},{'ShadowMap','draw'}}do wrap(V.require(spec[1]),spec[2],table.concat(spec,'.'))end
 local grid=V.require('LocalLightGrid');local prepare=grid.prepare;local instrumented
 grid.prepare=function(...)
  local vis=find(prepare,'visibility')
  if vis and vis~=instrumented then wrap(vis,'prepare','GridVisibility.prepare');instrumented=vis end
  return prepare(...)
 end
 game.save.flags.EVENT_FOLLOWED_OAK_INTO_LAB=true;game.save.flags.EVENT_GOT_STARTER=true
 game.save.flags.EVENT_BEAT_BROCK=true;game.save.flags.EVENT_BEAT_PEWTER_GYM_TRAINER_0=true
 V.require('CalendarEvents').setting:setValue('halloween',game)
 V.require('Weather').setting:setValue(os.getenv('QA_WEATHER')or'rain',game)
 V.require('VoxelGrid').setting:setValue(false,game,true)
 V.require('DayNight').setting:setValue('night',game,true)
 love.window.setMode(1710,958,{resizable=true,vsync=0})
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
 V.require('DayNight').setting:setValue('night',game,true)


 P.setLevel('tiltshift',0);P.setLevel('voxel',1)




 local Scene=V.require('VoxelScene');local H=V.require('HorizonWall');local Chunk=V.require('ChunkMesher')
 local R=V.require('RegionPreparation');local Atlas=V.require('TerrainAtlas');local Loader=require('src.world.MapLoader')
 local json=require('src.link.Json')
 local cached=R.cachedScene;local reused=0
 R.cachedScene=function(...)
  if os.getenv('QA_DISABLE_REGION_HOLD')then return end
  local canvas=cached(...);if canvas then reused=reused+1 end;return canvas
 end
 V.require('WorldResidency').setting:setValue(tonumber(os.getenv('QA_CACHE_MB'))or 512,game,true)
 P.setLevel('voxel',tonumber(os.getenv('QA_CAMERA_LEVEL'))or 7);V.require('SilphWindows').setting:setValue(true,game,true)
 V.require('AntiAlias').resolution:setValue('balanced',game,true)
 U.teleport(game,'SAFFRON_CITY',18,18,'down')
 game.overworld:startWarpTo('SAFFRON_CITY',15,15,'down')
 for i=1,15000 do if not game.overworld.transitioning then break end;U.wait(1)end
 assert(not game.overworld.transitioning and Scene.readyForReveal(game.overworld),'initial native arrival incomplete')
 assert(game.stack:top()==game.overworld)

 print('WATER_LEVEL',V.require('Water').level())
 local rows={};local measures={};local now=love.timer.getTime
 local function tick(phase)
  local t,measuredFrame=now(),trace.frame;U.wait(1)
  rows[#rows+1]={phase=phase,traceFrame=measuredFrame,ms=(now()-t)*1000,x=game.overworld.player.px,y=game.overworld.player.py}
 end
 for i=1,120 do tick('settle')end
 fp.yaw=math.pi;fp.pitch=-.08
 assert(U.shot(game,dir..'/saffron-street.png'))
 local function route(tx,ty)
  local world=game.overworld;local map=world.map;local p=world.player
  local w,h=map.def.width*2,map.def.height*2
  local start={p.cellX,p.cellY};local q={start};local seen={[start[2]*w+start[1]]=true};local previous={}
  local probe=setmetatable({},{__index=p});local found,best=start,math.huge
  for i=1,10000 do
   local c=q[i];if not c then break end
   local d=(c[1]-tx)^2+(c[2]-ty)^2;if d<best then found,best=c,d end
   if d==0 then break end
   probe.cellX,probe.cellY=c[1],c[2];probe.px,probe.py=c[1]*16,c[2]*16
   for _,v in ipairs{{1,0},{-1,0},{0,1},{0,-1}}do
    local x,y=c[1]+v[1],c[2]+v[2];local key=y*w+x
    if x>=0 and y>=0 and x<w and y<h and not seen[key]and not map:warpAtCell(x,y)
      and V.require('FreeMove')._blockedCell(world,probe,x,y)==nil then
     seen[key]=true;previous[key]=c;q[#q+1]={x,y}
    end
   end
  end
  local path={};while found~=start do table.insert(path,1,found);found=assert(previous[found[2]*w+found[1]])end
  return path
 end
 local qa={route=route};wrap(qa,'route','QA.pathToExit')
 for round=1,2 do
  for _,target in ipairs{{10,15},{10,25},{25,25},{25,15},{15,15}}do
   local reached=false
   for attempt=1,20 do
    local path=qa.route(target[1],target[2]);reached=true
    for _,cell in ipairs(path)do
     local arrived=false
     for i=1,120 do
      local p=game.overworld.player;local x,z=cell[1]*16-p.px,cell[2]*16-p.py
      if math.abs(x)<.25 and math.abs(z)<.25 then arrived=true;break end
      local speed=V.require('FreeMove').WALK
      dx=math.max(-1,math.min(1,x/speed));dz=math.max(-1,math.min(1,z/speed))
      if math.abs(x)>math.abs(z)then dz=0 else dx=0 end
      fp.yaw=math.atan2(-dx,-dz);tick('walk')
      assert(game.overworld.map.id=='SAFFRON_CITY','unexpected warp')
      if i>20 and V.require('FreeMove')._blockedCell(game.overworld,p,cell[1],cell[2])then break end
     end
     if not arrived then reached=false;break end
    end
    dx,dz=0,0
    if reached then break end
   end
   assert(reached,'street path blocked repeatedly')
   print('PASS_SAFFRON_WAYPOINT',round,target[1],target[2],game.overworld.player.cellX,game.overworld.player.cellY)
   for i=1,90 do fp.yaw=fp.yaw+math.pi*2/90;tick('turn')end
  end
 end
 local f=assert(io.open(dir..'/walk.json','w'));f:write(assert(json.encode({frames=rows,camera=V.require('VoxelState').level,buildings=V.require('Gen1PalletVillage').buildings:get(),lights=V.require('LocalLights').setting:get()})));f:close()
 assert(U.shot(game,dir..'/saffron-end.png'))
 print('PASS_SAFFRON_NIGHT_WALK',#rows);love.event.quit(0)
end
