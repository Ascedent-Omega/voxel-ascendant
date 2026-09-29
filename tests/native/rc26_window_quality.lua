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
 if os.getenv('QA_STALL_TRACE')then assert(loadfile(assert(os.getenv('QA_VASC_ROOT'))..'/tests/native/rc26_travel_trace.lua'))()(V,game)end
 game.save.flags.EVENT_FOLLOWED_OAK_INTO_LAB=true;game.save.flags.EVENT_GOT_STARTER=true
 game.save.flags.EVENT_BEAT_BROCK=true;game.save.flags.EVENT_BEAT_PEWTER_GYM_TRAINER_0=true
 V.require('CalendarEvents').setting:setValue('halloween',game)
 V.require('Weather').setting:setValue(os.getenv('QA_WEATHER')or'rain',game)
 V.require('VoxelGrid').setting:setValue(false,game,true)
 V.require('DayNight').setting:setValue(os.getenv('QA_CLOCK')or'night',game,true)
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




 local json=require('src.link.Json')
 local Scene=V.require('VoxelScene');local Chunk=V.require('ChunkMesher');local LL=V.require('LocalLights')
 local water=V.require('Water');local weather=V.require('Weather')
 local diagnostics=assert(ex.runtimePerformanceDiagnostics)
 local results={};local count=tonumber(os.getenv('QA_FRAMES'))or 360
 love.window.setMode(1710,958,{resizable=true,vsync=0})
 V.require('AntiAlias').resolution:setValue('balanced',game,true)
 V.require('WorldResidency').setting:setValue(128,game,true)
 V.require('PerformanceOverlay').enabled:setValue(false,game,true)
 V.require('DayNight').setting:setValue(os.getenv('QA_CLOCK')or'night',game,true)
 P.setLevel('voxel',6);P.setLevel('tiltshift',3)


 local buildings=V.require('Gen1PalletVillage').buildings
 local previousBuildings=buildings:get()
 buildings:setValue(not os.getenv('QA_VANILLA_BUILDINGS'),game,true)
 local restoreQuit=love.event.quit
 love.event.quit=function(...)
  buildings:setValue(previousBuildings,game,true)
  return restoreQuit(...)
 end
 local N=V.require('NativeWindowLights');local current=N.append
 local reference=assert(loadfile(assert(os.getenv('QA_LIGHT_BASELINE'))))(V).append
 local args;local render=Scene.render
 Scene.render=function(...)args={n=select('#',...),...};return render(...)end
 fp.moveVector=function()return 0,0 end
 local function equal(a,b)
  assert(type(a)==type(b),'light value type changed')
  if type(a)~='table'then assert(a==b,'light value changed');return end
  for k,v in pairs(a)do equal(v,b[k])end
  for k in pairs(b)do assert(a[k]~=nil,'extra light value')end
 end
 local results={}
 for _,id in ipairs{'CELADON_CITY','ROUTE_7','SAFFRON_CITY'}do
  U.teleport(game,id,id=='ROUTE_7'and 2 or 24,id=='ROUTE_7'and 3 or 23,'right')
  for i=1,1800 do
   local plan=Scene.planStatus().active
   if V.require('VoxelState').ready and plan.rootId==id and not Chunk.hasPriorityWork()then break end
   U.wait(1)
  end
  for i=1,360 do fp.yaw=i/360*math.pi*2;fp.pitch=-.08;U.wait(1)end
  local structures=V.require('Structures')
  local view={map=game.overworld.map,neighbors={}}
  assert(structures.peek(view.map),'root analysis not published')
  for _,nb in ipairs(game.overworld.neighbors or{})do
   if structures.peek(nb.map)then view.neighbors[#view.neighbors+1]=nb end
  end
  local oldForMap=structures.forMap
  structures.forMap=function(map)assert(structures.peek(map),'reference attempted cold build');return oldForMap(map)end
  local a,b,c,d={},{},{},{}
  current(view,a,b,.8,{0,0,0});reference(view,c,d,.8,{0,0,0});equal(a,c);equal(b,d)
  structures.forMap=oldForMap
  for angle=1,4 do
   fp.yaw=(angle-1)*math.pi*.5;U.wait(12);assert(args)
   local delta,clock=love.timer.getDelta,love.timer.getTime;local frozen=clock()
   love.timer.getDelta=function()return 0 end;love.timer.getTime=function()return frozen end
   N.append=reference;local before=assert(Scene.render(unpack(args,1,args.n))):newImageData()
   N.append=current;local after=assert(Scene.render(unpack(args,1,args.n))):newImageData()
   love.timer.getDelta=delta;love.timer.getTime=clock
   local difference,maximum=0,0
   for y=0,before:getHeight()-1 do for x=0,before:getWidth()-1 do
    local r,g,bl=before:getPixel(x,y);local rr,gg,bb=after:getPixel(x,y)
    local delta=math.max(math.abs(r-rr),math.abs(g-gg),math.abs(bl-bb))
    maximum=math.max(maximum,delta);if delta>0 then difference=difference+1 end
   end end
   results[#results+1]={map=id,angle=angle,difference=difference,max=maximum,nativeLights=#a,blockers=#b}
   print('LIGHT_PIXEL_COMPARE',id,angle,difference,maximum,#a,#b)
   if angle==1 or difference>0 then
    for label,image in pairs{reference=before,candidate=after}do
     local data=image:encode('png');local f=assert(io.open(dir..'/'..id..'-'..angle..'-'..label..'.png','wb'));f:write(data:getString());f:close();data:release()
    end
   end
   before:release();after:release()
   -- Equivalent floating-point light fields can round at an 8-bit boundary.
   -- Light positions/powers/blockers above remain exactly equal as numbers.
   assert(maximum<=1/255+.00001,'published scene changed beyond one color step')
  end
 end
 if os.getenv('QA_VANILLA_BUILDINGS')then
  local count=0;for _,row in ipairs(results)do count=count+row.nativeLights end
  assert(count>0,'native window-light contract not exercised')
 end
 local f=assert(io.open(dir..'/results.json','w'));f:write(assert(json.encode(results)));f:close()
 print('PASS_WINDOW_LIGHT_QUALITY');love.event.quit(0)
end
