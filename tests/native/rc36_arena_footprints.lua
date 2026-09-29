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
 local reference=assert(loadfile(assert(os.getenv('QA_ARENA_REFERENCE'))))(V)
 local candidate=V.require('BattleArena')
 local function same(a,b,path,seen)
  path=path or '';assert(type(a)==type(b),'type '..path)
  if type(a)~='table'then assert(a==b,'value '..path);return end
  if a==b then return end
  seen=seen or{};if seen[a]==b then return end;seen[a]=b
  for k,v in pairs(a)do same(v,b[k],path..'.'..tostring(k),seen)end
  for k in pairs(b)do assert(a[k]~=nil,'extra '..path..'.'..tostring(k))end
 end
 local rows={}
 for _,id in ipairs{'CELADON_CITY','ROUTE_7','ROUTE_16','SAFFRON_CITY','SILPH_CO_1F','POKEMON_MANSION_2F','ROCK_TUNNEL_1F'}do
  local map=require('src.world.MapLoader').load(game.data,id)
  for _,surfing in ipairs{false,true}do
   for _,origin in ipairs{{0,0},{math.floor(map.widthCells/2),math.floor(map.heightCells/2)},{map.widthCells-1,map.heightCells-1}}do
    local row={map=id,x=origin[1],y=origin[2],surfing=surfing}
    local function run(module,label)
     local calls=0;local original=map.isWalkableCell
     map.isWalkableCell=function(self,...)calls=calls+1;return original(self,...)end
     local start=love.timer.getTime()
     local arena,review=module.find(map,origin[1],origin[2],surfing)
     row[label..'Ms']=(love.timer.getTime()-start)*1000;row[label..'Cells']=calls
     map.isWalkableCell=original
     return arena,review
    end
    local a,ar=run(reference,'reference');local b,br=run(candidate,'candidate')
    same(a,b);same(ar,br)
    local c,cr=run(candidate,'warmCandidate');local d,dr=run(reference,'warmReference')
    same(c,d);same(cr,dr);rows[#rows+1]=row
    print('ARENA_PAIR',id,origin[1],origin[2],surfing,row.referenceMs,row.candidateMs,row.referenceCells,row.candidateCells)
    U.wait(1)
   end
  end
 end
 local f=assert(io.open(dir..'/arena-results.json','w'));f:write(json.encode(rows));f:close()
 print('PASS_ARENA_FOOTPRINTS',#rows);love.event.quit()
end
