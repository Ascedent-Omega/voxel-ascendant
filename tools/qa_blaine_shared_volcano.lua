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


 local dir=assert(os.getenv('VASC_PERF_DIR'))
 local D=V.require('Gen1GlassDoors');local F=V.require('FirstPerson')
 print('NEW_MAPS',game.data.maps.KA_BLAINE_GYM_TUNNEL~=nil,game.data.maps.KA_BLAINE_VOLCANO_GYM~=nil)
 F.lookBy=function()end
 for _,item in ipairs{{'KA_BLAINE_VOLCANO_FOOT',15,18,math.pi,'shared-cone',-.22},{'KA_BLAINE_VOLCANO_FOOT',15,18,math.pi,'shared-level',.18},{'KA_BLAINE_VOLCANO_FOOT',10,17,2.9,'shared-side',-.12},{'KA_BLAINE_VOLCANO_FOOT',10,17,math.pi,'shared-summit',-.95}}do
  U.teleport(game,item[1],item[2],item[3],'up');ready(item[1]);F.yaw=item[4];F.pitch=item[6];U.wait(90)
  for _,prop in ipairs(V.require('VoxelFurniture').find(game.overworld.map))do if prop.kind:find('ember_vent',1,true)then assert(not game.overworld.map:isWalkableCell(math.floor(prop.tx/2),math.floor(prop.ty/2)),'vent blocks native walkable cell')end end
  if item[5]=='shared-cone'then
   local parts=V.require('BlaineVolcano').buildHorizon({map=game.overworld.map},nil,{})
   for _,part in ipairs(parts)do
    local mesh=part.mesh
    for i=1,mesh:getVertexCount(),4 do
     local lo,hi={1e9,1e9,1e9},{-1e9,-1e9,-1e9}
     for j=i,i+3 do local x,y,z=mesh:getVertex(j);for axis,v in ipairs{x,y,z}do lo[axis]=math.min(lo[axis],v);hi[axis]=math.max(hi[axis],v)end end
     if hi[2]>.5 and lo[2]<32 then
      for y=math.floor(lo[3]/16),math.ceil(hi[3]/16)-1 do for x=math.floor(lo[1]/16),math.ceil(hi[1]/16)-1 do
       assert(not game.overworld.map:isWalkableCell(x,y),'cone blocks native lane '..x..','..y)
      end end
     end
    end
    mesh:release()
   end
  end
  print('POSE',item[1],game.overworld.player.cellX,game.overworld.player.cellY,V.require('CurrentRoom').enabled(game.overworld.map))
  U.shot(game,dir..'/'..item[1]..'-'..item[5]..'.png')
 end
 local map=game.overworld.map
 for _,prop in ipairs(V.require('VoxelFurniture').find(map))do
  for _,b in ipairs(V.require('VoxelItems').models[prop.kind].boxes)do
   if b[2]<32 and b[2]+b[5]>.5 then
    for y=math.floor((prop.ty*8+b[3])/16),math.ceil((prop.ty*8+b[3]+b[6])/16)-1 do
     for x=math.floor((prop.tx*8+b[1])/16),math.ceil((prop.tx*8+b[1]+b[4])/16)-1 do
      assert(not map:isWalkableCell(x,y),'foot furniture blocks native lane '..x..','..y)
     end
    end
   end
  end
 end
 print('PASS all native walk cells clear of cone, lava and foreground props')
 for _,link in ipairs{{'KA_BLAINE_VOLCANO_FOOT',15,13,15,12,'KA_BLAINE_VOLCANO_GYM',24,28},{'KA_BLAINE_VOLCANO_GYM',24,28,24,29,'KA_BLAINE_VOLCANO_FOOT',15,13}}do
  U.teleport(game,link[1],link[2],link[3],'up');ready(link[1]);local ow=game.overworld;local p=ow.player
  p.px=link[4]*16;p.py=link[5]*16;p.cellX=link[4];p.cellY=link[5];ow:onStepComplete()
  for i=1,3600 do if game.overworld.map.id==link[6]and not game.overworld.transitioning then break end;U.wait(1)end
  assert(game.overworld.map.id==link[6]);ready(link[6]);assert(game.overworld.player.cellX==link[7]and game.overworld.player.cellY==link[8])
  print('PASS shared cone native transition',link[1],link[6])
 end
 local P=V.require('VoxelItems');P.setting:setValue(false,game,true);U.wait(90);ready('items off')
 assert(not V.require('BlaineVolcano').horizon(game.overworld.map))
 P.setting:setValue(true,game,true);U.wait(90);ready('items on')
 assert(V.require('BlaineVolcano').horizon(game.overworld.map))
 print('PASS shared volcano inspection, native lanes, transitions and setting rollback');love.event.quit()
end
