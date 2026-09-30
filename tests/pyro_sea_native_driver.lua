return function(game)
 io.stdout:setvbuf('no')
 assert((os.getenv('POKEPORT_IDENTITY')or''):match('^vasc%-.*%-qa$'))
 local out=assert(os.getenv('HABITAT_QA_ROOT'))
 local U=require('tests.drivers.util')
 local Q=dofile(assert(os.getenv('BLAINE_KASC_ROOT'))..'/tests/habitat_playthrough/drivers/common.lua')(game)
 Q.setup();Q.V.setupCard.suspended=true
 love.window.hasFocus=function()return true end;love.window.isVisible=function()return true end
 love.window.setMode(1100,760,{resizable=true,vsync=1});love.audio.setVolume(0)
 local function find(fn,name,seen)
  if type(fn)~='function'then return end;seen=seen or{};if seen[fn]then return end;seen[fn]=true
  for i=1,200 do local k,v=debug.getupvalue(fn,i);if not k then break end;if k==name then return v end end
  for i=1,200 do local k,v=debug.getupvalue(fn,i);if not k then break end;local x=find(v,name,seen);if x then return x end end
 end
 local V=assert(find(Q.V.lib.require('VoxelScene').render,'V'))
 local B,BS=V.require('OverworldBattle'),V.require('BattleScene')
 local settings=Q.V.setupCard.new(game).settings
 settings.terarriumIdleAnimation:setValue(false,game)
 settings.terarriumDome:setValue('clear',game)
 require('src.render.Pipelines').setLevel('voxel',7)
 for key,value in pairs{apo_hd_walking_sprites=true,apo_human_art_style='voxel',voxelCharacterCardEnabled=true,battleSpriteStyle='hd'}do
  assert(settings[key],key):setValue(value,game)
 end
 local renders=0;local render=BS.render
 BS.render=function(...)local im=render(...);if im then renders=renders+1 end;return im end
 game.save.party={require('src.pokemon.Pokemon').new(game.data,'GOROCHU',65)}
 local R=Q.K.blaineVolcanoRoute
 -- Old v2 edge saves migrate to the new walkable edge on entry.
 for _,x in ipairs{16,17,32,33}do
  U.teleport(game,R.CHAMBER,x,16,'up');Q.settle()
  assert(game.overworld.player.cellX==(x<20 and 18 or 31),'old edge save stranded')
 end
 U.teleport(game,R.CHAMBER,25,13,'up');Q.settle();U.wait(60)
 local review=V.require('BattleArena').review(game.overworld.map,false)
 print('BLAINE_REVIEW',#review.candidates,table.concat(review.rejected,'|'),review.reason)
 B.setting:setValue(true,game)
 game.save.flags.EVENT_BEAT_BLAINE=nil;game.save.inventory.VOLCANOBADGE=nil;game.save.defeatedTrainers={}
 game.save.flags.EVENT_BEAT_CHAMPION_RIVAL=nil;game.save.hallOfFame={}
 local npc
 for _,n in ipairs(game.overworld.npcs)do if n.def.name=='CINNABARGYM_BLAINE'then npc=n end end
 assert(npc)
 game.overworld:engageTrainer(npc)
 local function ready()
  local battle
  for i=1,1500 do
   local t=game.stack:top()
   if t.enemy and t.enemy.mon then battle=t end
   if battle and t==battle and battle.phase=='menu'and not battle.current and not battle.sendingOut and not battle.enemySendingOut then return battle end
   U.wait(1);if i%18==0 then U.tap(game,'a')end
  end
  error('battle startup')
 end
 local battle=ready();U.wait(50)
 local ar=assert(B.arena());assert(V.require('BlaineVolcano').profile(ar.map)=='arena');print('BLAINE_STAGE',ar.presentationMode,ar.cam,ar.shape,ar.mid[1],ar.mid[2],ar.player[1],ar.player[2],ar.enemy[1],ar.enemy[2])
 local found=false
 for _,p in ipairs(V.require('BattleMapProps').capture(game.overworld,ar.map,{}).furniture)do
  if p.extra and p.extra.sightFoundation then found=true;assert(not V.require('SightClearance').propBounds(p))end
 end
 assert(found,'platform missing from retained battle furniture')
 assert(U.shot(game,out..'/blaine-map.png'))
 assert(ar.presentationMode=='MAP'and ar.shape=='blaine_center','Blaine not centred MAP')
 for i=1,3 do U.wait(45);assert(U.shot(game,out..'/blaine-fountains-'..i..'.png'))end
 B.finish();while game.stack:top()~=game.overworld do game.stack:pop()end
 local map=require('src.world.MapLoader').load(game.data,'ROUTE_20');local x,y
 for yy=3,map.heightCells-4 do for xx=3,map.widthCells-4 do if not x and map:isWaterCell(xx,yy)and not map:isWalkableCell(xx,yy)then x,y=xx,yy end end end
 assert(x);U.teleport(game,'ROUTE_20',x,y,'down');Q.settle();game.overworld.player.surfing=true
 B.setting:setValue('terarrium',game);settings.terarriumBehindRed:setValue(false,game)
 battle=require('src.battle.BattleState').newWild(game,'TENTACRUEL',60);game.overworld:pushBattle(battle);ready()
 for _,mode in ipairs{'side','behind'}do
  settings.terarriumBehindRed:setValue(mode=='behind',game)
  local before=renders;U.wait(60)
  ar=assert(B.arena());print('SEA_STAGE',mode,ar.terarrium and ar.terarrium.seaActorHeight,renders-before)
  assert(ar.terarrium and ar.terarrium.seaActorHeight and renders>before+10,'Sea renderer stalled')
  assert(U.shot(game,out..'/sea-'..mode..'.png'))
 end
 U.tap(game,'a');U.wait(10);assert(U.shot(game,out..'/sea-moves.png'))
 U.tap(game,'a');U.wait(100);assert(U.shot(game,out..'/sea-attack.png'))
 love.window.setMode(540,960,{resizable=true,vsync=1});require('src.core.TouchControls'):setPreview(true)
 U.wait(35);assert(U.shot(game,out..'/sea-portrait.png'))
 print('PYRO_SEA_NATIVE_PASS');love.event.quit()
end
