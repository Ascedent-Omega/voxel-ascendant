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
 local P=V.require('VoxelItems');local furniture=V.require('VoxelFurniture')
 local rows={{'PALLET_TOWN','REDS_HOUSE_1F','pallet_red_house'},{'PALLET_TOWN','BLUES_HOUSE','pallet_blue_house'},{'PALLET_TOWN','OAKS_LAB','pallet_oak_lab'},
 {'VIRIDIAN_CITY','VIRIDIAN_NICKNAME_HOUSE'},{'VIRIDIAN_CITY','VIRIDIAN_SCHOOL_HOUSE'},{'CERULEAN_CITY','BIKE_SHOP'},{'INDIGO_PLATEAU','INDIGO_PLATEAU_LOBBY'}}
 for _,row in ipairs(rows)do
  local w;for _,warp in ipairs(game.data.maps[row[1]].warps)do if warp.destMap==row[2]then w=warp;break end end
  assert(w);require('src.render.Pipelines').setLevel('voxel',6)
  U.teleport(game,row[1],w.x,w.y+3,'up');ready(row[2]);F.yaw=math.pi;F.pitch=.03;U.wait(60)
  local found=0;local glass=row[2]=='BIKE_SHOP'or row[2]=='INDIGO_PLATEAU_LOBBY'
  for _,prop in ipairs(furniture.find(game.overworld.map))do
   local model=P.models[prop.kind];local match=prop.kind==row[3]
   for _,door in ipairs(model and model.nativeDoors or{})do if door.dest==row[2]then match=true end end
   if match then
    found=found+1;assert(model,'missing facade model');assert(prop.claimed,'unclaimed facade')
    assert((model.slidingDoors~=nil)==glass,'wrong exterior door style '..row[2])
    if not glass then
     local color=P.decorColors[V.require('Gen1DoorStyles').variant(row[2])];local seen=false
     for _,box in ipairs(model.boxes)do if box[7]==color then seen=true end end;assert(seen,'missing shared wood colour')
    end
   end
  end
  assert(found==1,'expected one matching facade '..row[2]..' '..found)
  U.shot(game,dir..'/'..row[2]..'-outside.png')
  print('PASS FACADE',row[2],glass and 'glass'or V.require('Gen1DoorStyles').variant(row[2]))
 end
 print('PASS native public and home facade QA');love.event.quit()
end
