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
  for n=1,2400 do if n>60 and V.require('VoxelState').ready and not scene.pendingReason then print('READY',label,n);return end;if n%180==0 then local h=V.require('HorizonWall').cacheStatus(V.require('VisibleNeighborhood').apply(game.overworld));print('WAIT',label,n,game.stack:top()==game.overworld,V.require('VoxelState').ready,require('src.render.Pipelines').worldPipeline(),require('src.render.Pipelines').level('voxel'),game.stack:top().screenId,scene.pendingReason,h.ready,h.failed,V.require('ChunkMesher').pending())end;U.wait(1)end
  error('TIMEOUT '..label..' '..tostring(scene.pendingReason))
 end



 V.require('Weather').setting:setValue('clear',game,true);V.require('DayNight').setting:setValue('day',game,true)
 local dir=assert(os.getenv('VASC_PERF_DIR'));local D=V.require('Gen1GlassDoors');local F=V.require('FirstPerson');F.lookBy=function()end
 local gyms=V.require('Gen1GymInteriors');local loader=require('src.world.MapLoader')
 local function leaderCount()
  local n=0;for _,npc in ipairs(game.overworld.npcs or{})do if npc.def.name=='CINNABARGYM_BLAINE'then n=n+1 end end;return n
 end
 local K=game.mods.exports.kanto_ascendant
 local maps=game.data.maps;local w
 for _,warp in ipairs(maps.SAFFRON_CITY.warps)do if warp.destMap=='SAFFRON_GYM'then w=warp;break end end
 assert(w)
 for _,time in ipairs{'day','night'}do
  V.require('DayNight').setting:setValue(time,game,true)
  U.teleport(game,'SAFFRON_CITY',w.x,w.y+2,'up');ready('gym '..time)
  game.overworld.npcs={};game.overworld.entities={};D.update=function()end;D.states={};D.map=game.overworld.map
  F.yaw=math.pi;F.pitch=.06;U.wait(60);U.shot(game,dir..'/saffron-glass-close-'..time..'.png')
  print('PASS GLASS',time,V.require('Gen1PalletVillage').windowLight())
 end

 local count,rooms=0,0
 local P=V.require('Gen1InteriorPanoramas')
 for id in pairs(P.profiles)do if game.data.maps[id]then
  local map=loader.load(game.data,id);local profile=P.profileFor(map)
  if profile then
   rooms=rooms+1
   for _,panel in ipairs(V.require('Gen1InteriorLayout').panelsFor(map,profile))do
    for _,door in ipairs(panel.openings)do if door.singleLeaf and not door.open and not door.breach then
     assert(door.upto-door.from<=door.height*2/3+.001,'stretched wood '..id);count=count+1
    end end
   end
  end
 end end
 print('PASS ALL ROOM PROPORTIONS',rooms,count)
 print('PASS close glass and all-room aspect audit');love.event.quit()
end
