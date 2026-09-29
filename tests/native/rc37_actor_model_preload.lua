return function(game)
 assert(os.getenv('POKEPORT_IDENTITY')=='vasc-video-polish-qa');love.audio.setVolume(0)
 io.stdout:setvbuf('no')
 local gen2=os.getenv('POKEPORT_GAME')=='gold'or os.getenv('POKEPORT_GAME')=='crystal'
 if gen2 then
  local Save=require('src.core.gen2.Save');local save=Save.newGame{version='crystal',playerName='MODELQA'}
  game.save=save;game:adoptSave(save);game.world.save=save
  require('src.mods.Runtime').emit('save.created',{game=game,save=save});game:continueGame(save)
 else game:startNewGame{intro=false}end
 local ex=game.mods.exports.VOXEL_ASCENDANT
 if ex.setupCard then ex.setupCard.suspended=true end
 ex.ascendantContent.promptDisabled=true;ex.ascendantContent.onboardingShown=true
 local function find(fn,name,seen)
  if type(fn)~='function'then return end;seen=seen or{};if seen[fn]then return end;seen[fn]=true
  for i=1,100 do local k,v=debug.getupvalue(fn,i);if not k then break end;if k==name then return v end end
  for i=1,100 do local k,v=debug.getupvalue(fn,i);if not k then break end;local x=find(v,name,seen);if x then return x end end
 end
 local V=assert(find(gen2 and ex.dexModelPreview.draw or ex.lib.require('VoxelScene').render,'V'))
 if not gen2 then V.require('Gen1PalletVillage').buildings:setValue(true,game,true)end
 local pack=assert(ex.cobblemonModels);local R=ex.lib.require('Voxel3D')
 assert(pack.prewarmEntities and R.prewarmWorldCards and R.worldCardsReady)
 local content=V.require('CobblemonContent');local record=content.record;local loads=0
 content.record=function(...)loads=loads+1;return record(...)end
 local world={entities={}}
 for _,spec in ipairs{{16},{19},{20},{43},{56},{62},{143},{25,'female'},{25,'shiny'}}do
  world.entities[#world.entities+1]={ascendantPokemonModelSource='cobblemon',ascendantPokemonModelDex=spec[1],
   ascendantPokemonModelAppearance={gender=spec[2]=='female'and 'female'or nil,shiny=spec[2]=='shiny'},px=0,py=0}
 end
 local steps=0;local t=love.timer.getTime()
 while not R.worldCardsReady(world)and steps<100 do
  assert(R.prewarmWorldCards(world),'pending models made no progress');steps=steps+1
 end
 assert(R.worldCardsReady(world)and steps==#world.entities,'model gate missing')
 local prepMs=(love.timer.getTime()-t)*1000;local before=loads
 -- Evict the ordinary 12 MiB LRU; actual prepared actors still own their data.
 collectgarbage('collect')
 local rows={};local Mon=V.require('StadiumMon')
 for _,e in ipairs(world.entities)do
  local start=love.timer.getTime();local mon=Mon.new('overworld',pack)
  assert(mon:setSpecies(e.ascendantPokemonModelDex,true,e.ascendantPokemonModelAppearance))
  assert(mon.model and mon.rig and pack.image(mon.model,1))
  rows[#rows+1]={dex=e.ascendantPokemonModelDex,ms=(love.timer.getTime()-start)*1000}
  mon:release()
 end
 assert(loads==before,'first actor use reloaded prepared model')
 for i=1,30 do assert(R.worldCardsReady(world))end
 assert(loads==before,'readiness loaded a model')
 content.record=record
 local f=assert(io.open(assert(os.getenv('SHOT_DIR'))..'/preload.json','w'))
 f:write(require('src.link.Json').encode{generation=gen2 and 2 or 1,steps=steps,loads=loads,prepMs=prepMs,rows=rows,residency=pack.residency()});f:close()
 print('PASS_ACTOR_MODEL_PRELOAD',gen2 and 2 or 1,steps,loads,prepMs)
 love.event.quit(0)
end
