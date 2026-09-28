return function(game)
 assert((os.getenv('POKEPORT_IDENTITY')or''):match('^vasc%-.*%-qa$'),'isolated QA identity required')
 io.stdout:setvbuf('no');love.window.hasFocus=function()return true end;love.window.isVisible=function()return true end
 local U=require('tests.drivers.util');game:startNewGame{intro=false}
 local e=assert(game.mods.exports.VOXEL_ASCENDANT);e.setupCard.suspended=true;e.ascendantContent.promptDisabled=true;e.ascendantContent.onboardingShown=true
 local function find(fn,name,seen)
  if type(fn)~='function'then return end;seen=seen or {};if seen[fn]then return end;seen[fn]=true
  for i=1,200 do local k,v=debug.getupvalue(fn,i);if not k then break end;if k==name then return v end end
  for i=1,200 do local k,v=debug.getupvalue(fn,i);if not k then break end;local x=find(v,name,seen);if x then return x end end
 end
 local V=assert(find(e.lib.require('VoxelScene').render,'V'));local B=V.require('OverworldBattle');local BS=V.require('BattleScene');local C=V.require('BattleCam')
 local settings=e.setupCard.new(game).settings
 for _,k in ipairs({'battleSpriteStyle','pokemonModelSkin','battleHudStyle','shadows','aa'})do if settings[k]then print('SETTING',k,settings[k]:get());settings[k]:setValue(({battleSpriteStyle='stadium2',pokemonModelSkin='stadium2',battleHudStyle='oras',shadows=true,aa=4})[k],game)end end
 local render=BS.render;local counts={};local last;local reasons={};local caseName
 BS.render=function(state,arena,...)
  local ok,shot=pcall(render,state,arena,...);local mode=arena.terarrium and 'TERRARIUM' or arena.presentationMode
  if not ok then print('RENDER_ERROR',caseName,mode,shot);error(shot,0)end
  if shot then counts[mode]=(counts[mode]or 0)+1;last=mode
  else local reason=tostring(BS.lastDeclineReason);if not reasons[reason]then reasons[reason]=true;print('DECLINE',caseName,mode,reason)end end
  return shot
 end
 local D=V.require('Diagnostics');local dw=D.write
 D.write=function(event,fields)if event:find('fallback')or event=='battle-camera-seat-timeout' or event=='battle-map-assignment' then print('DIAG',caseName,event,fields.reason,fields.anchorIndex)end;return dw(event,fields)end
 require('src.render.Pipelines').setLevel('voxel',3)
 game.save.flags.EVENT_FOLLOWED_OAK_INTO_LAB=true;game.save.flags.EVENT_GOT_STARTER=true;game.save.repelSteps=999999
 B.finish();U.teleport(game,'ROUTE_1',15,30,'down')
 love.window.setMode(1196,540,{resizable=true,vsync=1});require('src.core.TouchControls'):setPreview(true)
 game.save.party={require('src.pokemon.Pokemon').new(game.data,'PIDGEOT',14)}
 B.setting:setValue(true,game);U.wait(90);caseName='route1'
 local battle=require('src.battle.BattleState').newWild(game,'RATTATA',6);game.overworld:pushBattle(battle)
 for i=1,1000 do U.wait(1);if game.stack:top()==battle and battle.phase=='menu' and not battle.current and not battle.sendingOut then break end;if i%15==0 then U.tap(game,'a')end end
 U.wait(150);print('MENU',last,battle.phase);assert(U.shot(game,os.getenv('BATTLE_QA')..'/menu.png'))
 local actualSafety=B.battleHudCameraSafe
 if os.getenv('BATTLE_FORCE_OVERLAP')=='1' then C.setScreenSafetyEvaluator(function(b,a,y,c,context)
  local safe,why=actualSafety(b,a,y,c,context)
  if safe~=nil and b.phase=='moveSelect' then return false,'playerHero-under-fight' end
  return safe,why
 end)end
 local frames=counts.MAP or 0
 U.tap(game,'a');U.wait(180);print('FIGHT',last,battle.phase);assert(U.shot(game,os.getenv('BATTLE_QA')..'/fight.png'))
 assert(last=='MAP' and (counts.MAP or 0)>frames+90,'chosen MAP did not keep rendering')
 assert(not counts.TERRARIUM,'automatic mode switch')
 love.window.setMode(540,960,{resizable=true,vsync=1});U.wait(150)
 assert(last=='MAP' and not counts.TERRARIUM,'rotation switched view');assert(U.shot(game,os.getenv('BATTLE_QA')..'/portrait.png'))
 U.tap(game,'b');U.wait(45);assert(battle.phase=='menu','cancel no longer works')
 C.setScreenSafetyEvaluator(actualSafety)
 assert(B.cycleLivePresentation(game));U.wait(180)
 print('MANUAL',last,battle.phase);assert(last=='ARENA','explicit switch did not commit')
 assert(U.shot(game,os.getenv('BATTLE_QA')..'/manual-arena.png'))
 local hp=battle.enemy.mon.hp
 U.tap(game,'a');U.wait(10);assert(battle.phase=='moveSelect','attack menu unavailable after view change')
 U.tap(game,'a')
 for i=1,700 do U.wait(1);if i%20==0 then U.tap(game,'a')end;if battle.ended or (battle.enemy.mon.hp and hp and battle.enemy.mon.hp<hp)then break end end
 assert(battle.ended or (battle.enemy.mon.hp and hp and battle.enemy.mon.hp<hp),'attack did not resolve')
 print('ATTACK_RESOLVED',hp,battle.enemy.mon.hp,battle.ended)
 print('CAMERA_CONTINUITY_PASS',last,counts.MAP,counts.TERRARIUM);love.event.quit()
end
