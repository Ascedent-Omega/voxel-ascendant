-- Native presentation probe: queue an animation, without executing move mechanics.
return function(game)
 io.stdout:setvbuf('no')
 local U=require('tests.drivers.util')
 local Q=dofile(assert(os.getenv('SEVII_KASC_ROOT'))..'/tests/habitat_playthrough/drivers/common.lua')(game)
 Q.setup();game.save.options.colors='redpp';game:applyOptions();Q.V.setupCard.suspended=true
 love.window.hasFocus=function()return true end;love.window.isVisible=function()return true end
 love.window.setMode(1100,760,{resizable=true,vsync=1});love.audio.setVolume(0)
 local S=Q.K.seviiExpedition;local camera=tonumber(os.getenv('SEVII_ANIMATION_CAMERA')or'0')
 local pipeline=require('src.render.Pipelines');pipeline.setLevel('voxel',camera);pipeline.syncOptions(game.save.options)
 U.teleport(game,S.ONE,12,17,'down');Q.settle();U.wait(180)
 pipeline.setLevel('voxel',camera);pipeline.syncOptions(game.save.options);U.wait(60)
 assert(pipeline.level('voxel')==camera,'requested animation camera not active')
 Q.V.lib.require('OverworldBattle').setting:setValue(camera>0 and'terarrium'or false,game)
 local b=require('src.battle.BattleState').newWild(game,'PIDGEOT',60)
 game.overworld:pushBattle(b)
 for _=1,2000 do if game.stack:top()==b and b.phase=='menu'then break end;Q.tap('a')end
 assert(b.phase=='menu','native battle not ready')
 local diagnostics={};for key,value in pairs(b.animPlayer or{})do diagnostics[key]=type(value)end
 print('SEVII_ANIMATION_PLAYER_FIELDS',require('src.link.Json').encode(diagnostics))
 local native=b.animPlayer.data and b.animPlayer or assert(b.animPlayer.native,'native animation child missing')
 local out=assert(os.getenv('HABITAT_QA_ROOT'));local list={}
 local aliases=dofile(assert(os.getenv('SEVII_KASC_ROOT'))..'/sevii_battle_animations.lua')(
  {events={on=function()end}}, {maps={}}).aliases
 local names={};for id in pairs(aliases)do names[#names+1]=id end;table.sort(names)
 for _,id in ipairs(names)do
  assert(game.data.moves[id],'missing real move '..id)
  assert(native.data.moveAnims[aliases[id]],'missing native donor '..aliases[id])
  b:animNext(id,false);b.phase='messages';b.afterQueue='menu'
  local maxSteps,frames,captured=0,0,false
  for _=1,3000 do
   U.wait(1)
   if b.animPlaying then
    maxSteps=math.max(maxSteps,#(native.steps or{}))
    frames=frames+1
    local step=native.steps and native.steps[native.stepIndex]
    local visible=step and step.sprites and #step.sprites>0
    if frames>=10 and visible and not captured and(id=='SYNTHESIS'or id=='DISCHARGE'or id=='FALSE_SWIPE')then
     assert(U.still(game,out..'/'..id..'-animation.png'));captured=true
    end
   end
   if b.phase=='menu'and #b.queue==0 and not b.animPlaying then break end
  end
  assert(b.phase=='menu','animation did not finish '..id)
  if not captured and(id=='SYNTHESIS'or id=='DISCHARGE'or id=='FALSE_SWIPE')then assert(U.still(game,out..'/'..id..'-animation.png'))end
  list[#list+1]={id=id,donor=aliases[id],steps=maxSteps,frames=frames,scope='native queue presentation only; move mechanics not executed'}
  print('SEVII_NATIVE_ANIMATION',id,maxSteps,frames)
  if os.getenv('SEVII_EXPECT_FIXED')=='1'then assert(maxSteps>0 and frames>5,'missing compiled animation '..id)end
 end
 local f=assert(io.open(out..'/animation-render.json','w'));f:write(require('src.link.Json').encode({camera=pipeline.level('voxel'),rows=list,owner=native._kascSeviiAnimations}));f:close()
 print('SEVII_NATIVE_ANIMATION_RENDER_PASS',#list,camera);love.event.quit()
end
