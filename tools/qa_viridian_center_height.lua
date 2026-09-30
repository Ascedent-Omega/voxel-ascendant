return function(game)
 love.audio.setVolume(0);io.stdout:setvbuf('no');love.window.hasFocus=function()return true end;love.window.isVisible=function()return true end
 love.keyboard.isDown=function()return false end;love.joystick.getJoysticks=function()return{}end
 love.window.setMode(960,640,{vsync=0})
 local U=require('tests.drivers.util');game:startNewGame{intro=false}
 local e=assert(game.mods.exports.VOXEL_ASCENDANT);assert(not game.mods.exports.ASCENDANT_COBBLE_CHARACTERS,'test must run without separate Card')
 e.setupCard.suspended=true;e.ascendantContent.promptDisabled=true;e.ascendantContent.onboardingShown=true
 game.save.flags.EVENT_FOLLOWED_OAK_INTO_LAB=true;game.save.flags.EVENT_GOT_STARTER=true
 U.teleport(game,'PALLET_TOWN',8,9,'down');require('src.render.Pipelines').setLevel('voxel',7);U.wait(60)
 local function find(fn,name,seen)
 if type(fn)~='function'then return end;seen=seen or{};if seen[fn]then return end;seen[fn]=true
 for i=1,100 do local k,v=debug.getupvalue(fn,i);if not k then break end;if k==name then return v end end
 for i=1,100 do local k,v=debug.getupvalue(fn,i);if not k then break end;local x=find(v,name,seen);if x then return x end end end
 local V=assert(find(e.lib.require('VoxelScene').render,'V'));local scene=V.require('VoxelScene')
 local function ready(label)
  for n=1,2400 do if n>60 and V.require('VoxelState').ready and not scene.pendingReason then print('READY',label,n);return end;if n%180==0 then if n==540 then U.shot(game,'/Users/maarten/Documents/Recompile/artifacts/performance-t6-t27-20260929/transitions/wait.png')end;local h=V.require('HorizonWall').cacheStatus(V.require('VisibleNeighborhood').apply(game.overworld));print('WAIT',label,n,game.stack:top()==game.overworld,V.require('VoxelState').ready,require('src.render.Pipelines').worldPipeline(),require('src.render.Pipelines').level('voxel'),game.stack:top().screenId,scene.pendingReason,h.ready,h.failed,V.require('ChunkMesher').pending())end;U.wait(1)end
  error('TIMEOUT '..label..' '..tostring(scene.pendingReason))
 end


 V.require('Weather').setting:setValue('clear',game,true);V.require('DayNight').setting:setValue('day',game,true)



 local dir=assert(os.getenv('VASC_PERF_DIR'));local F=V.require('FirstPerson');F.lookBy=function()end
 local L=V.require('LedgeElevation');L.setting:setValue('world',game,true)
 for _,view in ipairs{{23,28,math.pi,.30,'center-step'},{19,29,2.5,.45,'stairs'},{24,26,.65,.5,'upper-terrace'}}do
  U.teleport(game,'VIRIDIAN_CITY',view[1],view[2],'up');ready(view[5])
  F.yaw=view[3];F.pitch=view[4];U.wait(90);U.shot(game,dir..'/'..view[5]..'.png')
 end
 require('src.render.Pipelines').setLevel('voxel',1);F.yaw=math.pi;F.pitch=.4
 for _,x in ipairs{15,19}do
  U.teleport(game,'VIRIDIAN_CITY',x,28,'up');ready('stair-walk')
  local ow=game.overworld;local player=ow.player
  for n=1,120 do
   if player.cellY<=26 then break end
   U.hold(game,'up',1)
  end
  U.wait(30);print('WALK RESULT',x,player.cellX,player.cellY,game.stack:top()==ow);assert(player.cellX==x and player.cellY<=26,'native stair walk blocked')
  print('PASS native uphill walking',x,player.cellX,player.cellY,scene.groundAt(ow.map,player.cellX,player.cellY))
 end
 -- Existing door transition must still land in the Center and return to its upper terrace.
 U.teleport(game,'VIRIDIAN_CITY',23,26,'up');ready('Center door')
 for n=1,180 do if game.overworld.map.id~='VIRIDIAN_CITY'then break end;U.hold(game,'up',1)end
 for n=1,1200 do if game.overworld.map.id=='VIRIDIAN_POKECENTER'and not game.overworld.transitioning then break end;U.wait(1)end
 assert(game.overworld.map.id=='VIRIDIAN_POKECENTER');ready('Center interior')
 print('PASS native Center entrance')
 for _,mode in ipairs{'flat','local','world'}do
  require('src.render.Pipelines').setLevel('voxel',7)
  L.setting:setValue(mode,game,true);U.teleport(game,'VIRIDIAN_CITY',19,29,'up');ready(mode)
  F.yaw=math.pi;F.pitch=.4;U.wait(90);U.shot(game,dir..'/'..mode..'.png')
  local e=L.map(game.overworld.map,game.data)
  assert(e:at(23,26)-e:at(23,28)==(mode=='world'and 6 or 0))
  print('PASS live height setting',mode)
 end
 print('PASS Vertania Center height native QA');love.event.quit()
end
