-- Isolated native LOVE host: POKEPORT_DRIVER, disposable POKEPORT_IDENTITY, VASC_PERF_DIR.
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


 local dir=assert(os.getenv('VASC_PERF_DIR'))
 local D=V.require('Gen1GlassDoors');local F=V.require('FirstPerson')
 print('NEW_MAPS',game.data.maps.KA_BLAINE_GYM_TUNNEL~=nil,game.data.maps.KA_BLAINE_VOLCANO_GYM~=nil)
 F.lookBy=function()end
 local loader=require('src.world.MapLoader');local json=require('src.link.Json')
 local before={}
 for _,id in ipairs{'KA_BLAINE_GYM_TUNNEL','KA_BLAINE_VOLCANO_FOOT','KA_BLAINE_VOLCANO_GYM'}do
  local d=game.data.maps[id];before[id]=json.encode{blocks=d.blocks,warps=d.warps}
 end
 for _,row in ipairs{{'REDS_HOUSE_1F',2,5},{'BLUES_HOUSE',2,5},{'OAKS_LAB',4,9},{'VIRIDIAN_NICKNAME_HOUSE',2,5},{'VIRIDIAN_SCHOOL_HOUSE',2,5},{'ROUTE_7_GATE',3,3},{'ROUTE_16_GATE_1F',3,5},{'ROUTE_12_GATE_1F',4,4}}do
  U.teleport(game,row[1],row[2],row[3],'down');ready(row[1]);local map=game.overworld.map
  local profile=assert(V.require('Gen1InteriorPanoramas').profileFor(map));local count=0;local target,panel
  for _,p in ipairs(V.require('Gen1InteriorLayout').panelsFor(map,profile))do for _,d in ipairs(p.openings)do
   if d.singleLeaf or d.material=='room_glass_door'then
    count=count+1;target=target or d;panel=panel or p
    if d.material then assert(D.texture(d.doorView),'missing picture '..d.doorView)end
    print('DOOR',row[1],p.edge,d.from,d.upto,d.singleLeaf,d.material,d.doorView)
   end
  end end
  assert(count>0,'missing matching entrance '..row[1])
  local horiz=panel.edge=='north'or panel.edge=='south'
  local step=({north=1,south=-1,west=1,east=-1})[panel.edge]
  local along=(target.from+target.upto)/2;local across=panel.at+step*24
  local p=game.overworld.player;p.px=(horiz and along or across)-8;p.py=(horiz and across or along)-8
  p.cellX=math.floor(p.px/16);p.cellY=math.floor(p.py/16)
  F.yaw=({north=math.pi,south=0,east=math.pi/2,west=-math.pi/2})[panel.edge];F.pitch=.08
  U.wait(45)
  if target.material then local found=false;for _,st in pairs(D.states)do if st.amount>0 then found=true end end;assert(found,'door did not open '..row[1]);assert(D.source,'audio not prewarmed')end
  U.shot(game,dir..'/'..row[1]..'-door.png')
 end
 local links={
 {'CINNABAR_GYM',3,3,3,2,'KA_BLAINE_GYM_TUNNEL',44,8},
 {'KA_BLAINE_GYM_TUNNEL',44,8,45,8,'CINNABAR_GYM',3,3},
 {'KA_BLAINE_GYM_TUNNEL',5,5,5,4,'KA_BLAINE_VOLCANO_FOOT',15,19},
 {'KA_BLAINE_VOLCANO_FOOT',15,19,15,20,'KA_BLAINE_GYM_TUNNEL',5,5},
 {'KA_BLAINE_VOLCANO_FOOT',15,13,15,12,'KA_BLAINE_VOLCANO_GYM',24,28},
 {'KA_BLAINE_VOLCANO_GYM',24,28,24,29,'KA_BLAINE_VOLCANO_FOOT',15,13}}
 for _,v in ipairs(links)do
  U.teleport(game,v[1],v[2],v[3],'up');ready(v[1]);local ow=game.overworld;local p=ow.player
  assert(ow.map:isWalkableCell(v[4],v[5]),'trigger blocked '..v[1])
  p.px=v[4]*16;p.py=v[5]*16;p.cellX=v[4];p.cellY=v[5];ow:onStepComplete()
  for i=1,3600 do if game.overworld.map.id==v[6]and not game.overworld.transitioning then break end;U.wait(1)end
  assert(game.overworld.map.id==v[6],'transition failed '..v[1]);ready(v[6])
  assert(game.overworld.player.cellX==v[7]and game.overworld.player.cellY==v[8],'landing moved')
  print('TRANSITION',v[1],v[6],v[7],v[8])
 end
 for id,snapshot in pairs(before)do local d=game.data.maps[id];assert(snapshot==json.encode{blocks=d.blocks,warps=d.warps},'native geometry changed '..id)end
 local arena=loader.load(game.data,'KA_BLAINE_VOLCANO_GYM')
 assert(not V.require('CurrentRoom').enabled(arena),'arena clipped by cave mask')
 assert(not arena:isWalkableCell(3,10)and not arena:isWaterCell(3,10),'lava became traversable')
 assert(V.require('Gen1GymInteriors').exitDoor(loader.load(game.data,'CINNABAR_GYM')),'patched Cinnabar exit absent')
 print('PASS native doors, prewarmed audio, packaged views, six KASC links, exact landings, unchanged blocks/warps, arena mask and impassable lava')
 print('PASS volcano inspection');love.event.quit()
end
