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
 game.save.flags.EVENT_FOLLOWED_OAK_INTO_LAB=true;game.save.flags.EVENT_GOT_STARTER=true
 game.save.flags.EVENT_BEAT_BROCK=true;game.save.flags.EVENT_BEAT_PEWTER_GYM_TRAINER_0=true
 V.require('CalendarEvents').setting:setValue('halloween',game)
 V.require('Weather').setting:setValue(os.getenv('QA_WEATHER')or'rain',game)
 V.require('VoxelGrid').setting:setValue(false,game,true)
 V.require('DayNight').setting:setValue('night',game,true)
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




 local H=V.require('HorizonWall');local W=V.require('SilphWindows');local LL=V.require('LocalLights');local Scene=V.require('VoxelScene')
 local Chunk=V.require('ChunkMesher');local Neighborhood=V.require('VisibleNeighborhood')
 local json=require('src.link.Json')
 local renderedStats;local rawDraw=love.draw
 love.draw=function(...)rawDraw(...);renderedStats=love.graphics.getStats()end
 local rows={};local config={};local started=love.timer.getTime()
 local function emit(row)
  rows[#rows+1]=row
  print('RESULT_JSON '..assert(json.encode(row)))
  local f=assert(io.open(dir..'/results.json','w'));f:write(assert(json.encode({config=config,rows=rows},{indent=true})));f:close()
 end

 assert(loadstring(assert(V.mod:read('tests/terrain_disk_cache_test.lua'))))()(V)
 local D=V.require('TerrainDiskCache')
 if os.getenv('QA_DISK_EXPANDED')then V.require('Voxel3D').canInstance=function()return false end end
 local originalAllow=D.allowStore
 D.allowStore=function(policy,checkMs,buildMs)local allow=originalAllow(policy,checkMs,buildMs);print('CACHE_DECISION',checkMs,buildMs,allow);return allow end
 local budget=V.require('BuildBudget');local oldBegin,oldFinish=budget.begin,budget.finish
 local buildCPU,activeStart=0,nil
 budget.begin=function(...)oldBegin(...);activeStart=love.timer.getTime()end
 budget.finish=function(...)if activeStart then buildCPU=buildCPU+love.timer.getTime()-activeStart;activeStart=nil end;return oldFinish(...)end
 if os.getenv('QA_DISK_PROFILE')then
  local function now()return buildCPU+(activeStart and love.timer.getTime()-activeStart or 0)end
  for _,name in ipairs{'fingerprint','key','get','put'}do
   local original=D[name]
   D[name]=function(...)local start=now();local result=original(...);print('CACHE_CPU',name,1000*(now()-start));return result end
  end
 end
 local forced=os.getenv('QA_DISK_FORCE')=='1'
 if forced then D.policy=function()return 'qa' end;D.allowStore=function()return true end end
 local warm=os.getenv('QA_DISK_WARM')=='1'
 local baseline=os.getenv('QA_DISK_DISABLE')=='1'
 if baseline then D.available=function()return false end end
 if not warm and not baseline then for i=0,D.SLOTS-1 do V.mod.cache:delete('terrain-pages-v1/'..i..'.bin');V.mod.cache:delete('terrain-pages-v1/skip-'..i..'.bin')end;V.mod.cache:delete('terrain-pages-v1/index.bin')end
 P.setLevel('voxel',7);W.setting:setValue(true,game)
 local function digest(mesh)
  if not mesh then return 'none' end
  local parts={}
  if mesh.__voxelMeshBundle then
   parts[1]=digest(mesh.base)
   for _,inst in ipairs(mesh.instances)do parts[#parts+1]=digest(inst.mesh);parts[#parts+1]=digest(inst.source)end
  else
   for i=1,mesh:getVertexCount()do
    local vals={mesh:getVertex(i)}
    for _,v in ipairs(vals)do parts[#parts+1]=string.format('%.17g,',v)end
    if i%1024==0 then U.wait(1)end
   end
  end
  return love.data.encode('string','hex',love.data.hash('sha256',table.concat(parts)))
 end
 for _,id in ipairs(os.getenv('QA_DISK_MAP')and{os.getenv('QA_DISK_MAP')}or{'REDS_HOUSE_1F','SAFFRON_CITY','SILPH_CO_1F'})do
  local before=D.status();local start=love.timer.getTime();local beforeCPU=buildCPU
  U.teleport(game,id,5,5,'down');Chunk.invalidate(id)
  local map=game.overworld.map;Scene.setPreparationCovered(true)
  Chunk.request(map,true,nil,true,2)
  for i=1,15000 do
   if Chunk.ready(map,true)and Chunk.auxReady(map)then break end
   U.wait(1)
   if i%500==0 then print('DISK_PROGRESS',id,assert(json.encode(D.status())))end
  end
  Scene.setPreparationCovered(false)
  local after=D.status();local seconds=love.timer.getTime()-start
  print('DISK_RESULT',id,warm,seconds,'buildCPUms',1000*(buildCPU-beforeCPU),assert(json.encode(after)))
  assert(after.errors==0,after.lastError)
  if baseline then assert(after.writes==0 and after.hits==0)elseif warm then assert(after.hits>before.hits or (not forced and after.bypasses>before.bypasses),'no disk reuse/learned bypass '..id)else assert(after.writes>before.writes or (not forced and after.bypasses>before.bypasses),'no disk write/decision '..id)end
  local mesh,water=Chunk.pair(map,true);assert(mesh,'mesh missing '..id)
  local checksum=digest(mesh)..digest(water)
  local path=dir..'/'..id..'.digest'
  if warm or baseline then local f=assert(io.open(path,'r'));local expected=f:read('*a');f:close();assert(expected==checksum,'GPU mesh changed '..id)
  else local f=assert(io.open(path,'w'));f:write(checksum);f:close()end
  emit{map=id,warm=warm,baseline=baseline,forced=forced,seconds=seconds,buildCPUms=1000*(buildCPU-beforeCPU),disk=after,digest=checksum}
  U.wait(60);assert(U.shot(game,dir..'/'..id..(baseline and '-baseline.png'or warm and '-warm.png'or'-cold.png')))
 end
 print('PASS_TERRAIN_DISK_CACHE');love.event.quit(0)
end
