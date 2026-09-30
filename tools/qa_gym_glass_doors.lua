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
 local dir=assert(os.getenv('VASC_PERF_DIR'));local D=V.require('Gen1GlassDoors');local F=V.require('FirstPerson');F.lookBy=function()end
 local gyms=V.require('Gen1GymInteriors');local loader=require('src.world.MapLoader')
 local function leaderCount()
  local n=0;for _,npc in ipairs(game.overworld.npcs or{})do if npc.def.name=='CINNABARGYM_BLAINE'then n=n+1 end end;return n
 end
 local K=game.mods.exports.kanto_ascendant
 if K and K.blaineVolcanoRoute then
  U.teleport(game,'CINNABAR_GYM',3,4,'up');ready('old Blaine room')
  assert(leaderCount()==0,'Blaine still exists in native old room')
  F.yaw=math.pi;F.pitch=.12;U.wait(60);U.shot(game,dir..'/blaine-old-room.png')
  assert(game:writeSave());local save=assert(require('src.core.SaveData').load('red'));game:restoreSave(save);U.wait(120)
  assert(game.overworld.map.id=='CINNABAR_GYM'and leaderCount()==0,'save reload restored old Blaine')
  U.teleport(game,'KA_BLAINE_VOLCANO_GYM',25,14,'up');ready('moved Blaine');assert(leaderCount()==1,'volcano must contain exactly one Blaine')
  F.yaw=math.pi;F.pitch=.12;U.wait(60);U.shot(game,dir..'/blaine-volcano.png')
  print('PASS KASC Blaine absent old room including save reload, exactly once in volcano')
 end
 local ids={};for id in pairs(gyms.profiles)do ids[#ids+1]=id end;table.sort(ids)
 for _,id in ipairs(ids)do
  local p=assert(gyms.exitDoor(loader.load(game.data,id)))
  local x=math.floor((p.from+p.upto)/32);local y=p.at/16-4
  require('src.render.Pipelines').setLevel('voxel',6)
  U.teleport(game,id,x,y,'down');ready(id);F.yaw=0;F.pitch=.06;U.wait(60)
  local back=assert(game.data.maps[p.city].warps[p.warp.destWarp]);game.overworld:rememberOutdoor(p.city,back.x,back.y)
  assert(D.texture(D.outViewKey(game.overworld.map,p.warp)),'missing gym outside image')
  local state=V.require('VisibleNeighborhood').apply(game.overworld)
  local rims=V.require('HorizonWall').cachedMeshes(state);local leaves=0
  for _,rim in ipairs(rims or{})do
   if rim.slidingDoor and not rim.doorView then leaves=leaves+1 end
   assert(rim.class~='room_door','old wooden gym exit remains')
  end
  assert(leaves==2,'gym sliding leaf count '..id..' '..leaves)
  U.shot(game,dir..'/'..id..'-closed.png')
  local player=game.overworld.player;player.cellY=p.at/16-2;player.py=player.cellY*16
  local source=D.source;local preview=D.texture(D.outViewKey(game.overworld.map,p.warp))
  local newImage,newMesh,newSound=love.graphics.newImage,love.graphics.newMesh,love.sound.newSoundData
  local allocations=0;local audioAllocations=0
  love.graphics.newImage=function(...)allocations=allocations+1;print('OPEN_IMAGE',debug.traceback());return newImage(...)end
  love.graphics.newMesh=function(...)allocations=allocations+1;print('OPEN_MESH',debug.traceback());return newMesh(...)end
  love.sound.newSoundData=function(...)allocations=allocations+1;audioAllocations=audioAllocations+1;return newSound(...)end
  U.wait(45)
  love.graphics.newImage=newImage;love.graphics.newMesh=newMesh;love.sound.newSoundData=newSound
  local opened=false;for _,s in pairs(D.states)do if s.amount==1 then opened=true end end
  assert(opened and D.source,'gym door failed opening/prewarm '..id)
  assert(audioAllocations==0 and source==D.source and preview==D.texture(D.outViewKey(game.overworld.map,p.warp)),'door resources not retained')
  local after=V.require('HorizonWall').cachedMeshes(V.require('VisibleNeighborhood').apply(game.overworld))
  assert(after==rims,'door opening rebuilt arena mesh cache')
  print('OPEN_ALLOCATIONS',id,allocations,'door mesh/preview/audio identities retained')
  U.shot(game,dir..'/'..id..'-open.png')
  require('src.render.Pipelines').setLevel('voxel',1)
  for n=1,360 do if game.overworld.map.id~=id then break end;U.hold(game,'down',1)end
  for n=1,1200 do if game.overworld.map.id==p.city and not game.overworld.transitioning then break end;U.wait(1)end
  assert(game.overworld.map.id==p.city,'gym town exit failed '..id);ready(p.city)
  print('PASS GYM',id,'two glass leaves, retained picture/audio, retained door resources, native town exit')
 end
 for _,id in ipairs{'REDS_HOUSE_1F','BLUES_HOUSE','OAKS_LAB','VIRIDIAN_NICKNAME_HOUSE','VIRIDIAN_SCHOOL_HOUSE'}do
  U.teleport(game,id,id=='OAKS_LAB'and 4 or 2,id=='OAKS_LAB'and 8 or 4,'down');ready(id)
  require('src.render.Pipelines').setLevel('voxel',6);F.yaw=0;F.pitch=.06;U.wait(60)
  local map=game.overworld.map;local count=0
  for _,p in ipairs(V.require('Gen1InteriorLayout').panelsFor(map,V.require('Gen1InteriorPanoramas').profileFor(map)))do
   for _,d in ipairs(p.openings)do if not d.stair and not d.open then
    assert(d.singleLeaf and d.material==V.require('Gen1DoorStyles').material(id),'house is not matching single wood '..id);count=count+1
   end end
  end
  assert(count>0);U.shot(game,dir..'/'..id..'-wood.png')
  assert(not next(D.states),'house retained sliding animation')
  print('PASS HOUSE',id,'single matching wood, no slider')
 end
 print('PASS gym and house native door QA');love.event.quit()
end
