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
 U.teleport(game,'VIRIDIAN_CITY',23,29,'up');ready('benchmark');F.yaw=math.pi;F.pitch=.05;U.wait(120)
 assert(D.source,'door sound was not prewarmed')
 local timers,previews,images,soundData,activeImages={},0,0,0,0
 local function timed(obj,key)
  local old=obj[key];obj[key]=function(...)
   local start=love.timer.getTime();local a,b,c=old(...);local elapsed=(love.timer.getTime()-start)*1000
   local t=timers[key]or{};timers[key]=t;t[#t+1]=elapsed;return a,b,c
  end
 end
 timed(D,'update');timed(D,'drawExterior');timed(D,'play');timed(scene,'render')
 local view=D.drawView;D.drawView=function(...)previews=previews+1;return view(...)end
 local assets=V.require('CompactBackgroundAssets');local img=assets.newImage
 assets.newImage=function(path,...)if path:find('/assets/doors/',1,true)then images=images+1;if path:find('/VIRIDIAN_POKECENTER-',1,true)then activeImages=activeImages+1 end;print('DOOR_IMAGE_CREATED',path)end;return img(path,...)end
 local audio=love.sound.newSoundData;love.sound.newSoundData=function(...)soundData=soundData+1;return audio(...)end
 local results={}
 local function measure(label,n)
  timers={};previews=0;images=0;soundData=0;activeImages=0;local start=love.timer.getTime();U.wait(n)
  local row={label=label,frames=n,frameMs=(love.timer.getTime()-start)*1000/n,previews=previews,doorImagesCreated=images,activeDoorImagesCreated=activeImages,soundDataCreated=soundData,timings={}}
  for key,t in pairs(timers)do table.sort(t);local total=0;for _,v in ipairs(t)do total=total+v end
   row.timings[key]={mean=total/#t,p95=t[math.max(1,math.ceil(#t*.95))],peak=t[#t],calls=#t}
  end
  results[#results+1]=row;print('BENCH',assert(require('src.link.Json').encode(row)))
  assert(soundData==0,'door opening decoded audio')
  assert(activeImages==0,'opening allocated the active door image')
 end
 measure('closed',180);assert(previews==0,'hidden previews still rendered')
 local p=game.overworld.player;p.px=23*16;p.py=26*16;p.cellX=23;p.cellY=26
 measure('first-open',60);U.wait(60);measure('open-steady',180)
 local update=D.update
 D.update=function(...)update(...);for _,s in pairs(D.states)do if s.open then s.amount=.5+.5*math.sin(D.clock*8)end end end
 measure('moving-steady',180)
 D.update=update;U.wait(60);measure('open-repeat',180)
 local out=assert(io.open(dir..'/door-benchmark.json','w'));out:write(assert(require('src.link.Json').encode(results)));out:close()
 print('PASS no closed previews, audio prewarmed and zero active-door image/audio allocation while opening or moving; background neighborhood loads recorded separately')
 U.teleport(game,'KA_BLAINE_VOLCANO_GYM',24,24,'up');ready('compact arena final');F.yaw=math.pi;F.pitch=.42;U.wait(90)
 U.shot(game,dir..'/compact-arena-final.png')
 U.teleport(game,'KA_BLAINE_VOLCANO_FOOT',15,18,'up');ready('volcano final');F.yaw=math.pi;F.pitch=.18;U.wait(90)
 for _,prop in ipairs(V.require('VoxelFurniture').find(game.overworld.map))do if prop.kind:find('ember_vent',1,true)then assert(not game.overworld.map:isWalkableCell(math.floor(prop.tx/2),math.floor(prop.ty/2)),'vent blocks walkable cell')end end
 U.shot(game,dir..'/volcano-foot-final.png')
 print('PASS final volcano visuals and native vent clearance');love.event.quit()
end
