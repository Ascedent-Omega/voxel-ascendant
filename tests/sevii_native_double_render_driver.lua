-- Native four-actor rendering and actor-free transition cover regression.
return function(game)
 io.stdout:setvbuf('no')
 local root=assert(os.getenv('SEVII_KASC_ROOT'));local out=assert(os.getenv('SEVII_QA_OUTPUT'))
 local U=require('tests.drivers.util');local Q=dofile(root..'/tests/habitat_playthrough/drivers/common.lua')(game)
 require('src.world.OverworldController').rollEncounter=function()return nil end
 game:startNewGame{intro=false};game.save.options.colors='redpp';game:applyOptions()
 local K=assert(game.mods.exports.kanto_ascendant);local S=K.seviiExpedition;local T=S.trainers
 game.mods.modOptions.kanto_ascendant.living_world_enabled=false
 game.save.flags.EVENT_FOLLOWED_OAK_INTO_LAB=true;game.save.flags.EVENT_GOT_STARTER=true;game.save.flags.EVENT_BEAT_CHAMPION_RIVAL=true
 S.persist({version=1,stage=3,chapterOneComplete=true,samples={heat=true,drift=true}});K.generationRules.resolve(game);S.install(game)
 local Pokemon=require('src.pokemon.Pokemon');game.save.party={Pokemon.new(game.data,'MEWTWO',100),Pokemon.new(game.data,'BLASTOISE',100)}
 local function find(fn,name,seen)
  if type(fn)~='function'then return end;seen=seen or{};if seen[fn]then return end;seen[fn]=true
  for i=1,200 do local k,v=debug.getupvalue(fn,i);if not k then break end;if k==name then return v end end
  for i=1,200 do local k,v=debug.getupvalue(fn,i);if not k then break end;local x=find(v,name,seen);if x then return x end end
 end
 local V=assert(find(game.mods.exports.VOXEL_ASCENDANT.lib.require('VoxelScene').render,'V'))
 local BS=V.require('BattleScene');local B=V.require('OverworldBattle');local render=BS.render
 local last
 local counts={covers=0,fourActorFrames=0,coverDeclines=0,actorDeclines=0}
 BS.render=function(state,arena,textures,...)
  local frame=render(state,arena,textures,...)
  if arena.doubleBattle then
   if textures then
    last={state=state,arena=arena,token=(...)}
    if frame then
     for _,slot in ipairs{'player','player2','enemy','enemy2'}do assert(frame.actorVisuals[slot],'missing live actor '..slot)end
     counts.fourActorFrames=counts.fourActorFrames+1
    else counts.actorDeclines=counts.actorDeclines+1 end
   elseif frame then counts.covers=counts.covers+1 else counts.coverDeclines=counts.coverDeclines+1 end
  end
  return frame
 end
 local row=T.rows[1];U.teleport(game,row.map,row.x,row.y+1,'up');Q.settle();Q.tap('a');U.wait(8)
 local menu=game.stack:top();assert(menu.items)
 local wanted;for i,item in ipairs(menu.items)do if item.value=='battle'then wanted=i end end
 assert(wanted);for _=1,20 do if menu.index==wanted then Q.tap('a');break end;Q.tap(menu.index>wanted and'up'or'down')end
 local battle
 for _=1,2400 do
  for _,state in ipairs(game.stack.states)do if state.seviiTrainerKey==row.id then battle=state end end
  if battle and game.stack:top()==battle and battle.phase=='menu'and not battle.current then break end
  U.wait(1)
 end
 assert(battle and battle.doubleBattle,'native double battle started');U.wait(90)
 assert(last,'native battle renderer not called');assert(BS.render(last.state,last.arena,nil,last.token),'actor-free cover declined')
 U.wait(3)
 local arena=assert(B.arena());counts.mode=arena.terarrium and 'TERRARIUM' or arena.presentationMode;counts.terarrium=arena.terarrium==true;counts.fallback=arena.fallbackReason;counts.map=game.overworld.map.id
 assert(U.shot(game,out..'/four-actor-battle.png'))
 local f=assert(io.open(out..'/four-actor-render.json','w'));f:write(require('src.link.Json').encode(counts));f:close()
 print('SEVII_NATIVE_DOUBLE_RENDER',require('src.link.Json').encode(counts))
 assert(counts.covers>0,'no successful actor-free double cover');assert(counts.fourActorFrames>30,'no sustained native four-actor rendering')
 local requested=os.getenv('SEVII_COMPONENT_BATTLE_MODE') or 'MAP'
 local expected=({arena='ARENA',flatB='DISCS',terarrium='TERRARIUM',MAP='MAP'})[requested]
 assert(counts.mode==expected,'unexpected battle stage '..tostring(counts.mode)..' requested '..requested)
 print('SEVII_NATIVE_DOUBLE_RENDER_PASS');love.event.quit()
end
