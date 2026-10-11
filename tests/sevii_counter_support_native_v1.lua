return function(game)
 io.stdout:setvbuf('no');local out=assert(os.getenv('SEVII_QA_OUTPUT'));local U=require('tests.drivers.util')
 local Q=dofile(assert(os.getenv('SEVII_KASC_ROOT'))..'/tests/habitat_playthrough/drivers/common.lua')(game)
 Q.setup();Q.V.setupCard.suspended=true;game.save.options.colors='redpp';game:applyOptions();love.window.hasFocus=function()return true end
 love.window.setMode(1100,760,{resizable=true,vsync=1});love.audio.setVolume(0)
 local function find(fn,name,seen)
  if type(fn)~='function'then return end;seen=seen or{};if seen[fn]then return end;seen[fn]=true
  for i=1,200 do local k,v=debug.getupvalue(fn,i);if not k then break end;if k==name then return v end end
  for i=1,200 do local k,v=debug.getupvalue(fn,i);if not k then break end;local r=find(v,name,seen);if r then return r end end
 end
 local V=assert(find(Q.V.lib.require('VoxelScene').render,'V'));local scene=V.require('VoxelScene');local F=V.require('VoxelFurniture');local Items=V.require('VoxelItems')
 V.require('DayNight').setting:setValue('day',game);V.require('Weather').setting:setValue('off',game)
 local P=require('src.render.Pipelines');P.setLevel('voxel',1);P.setLevel('tiltshift',0);P.syncOptions(game.save.options)
 Items.setting:setValue(true,game)
 local fixed=os.getenv('SEVII_COUNTER_FIXED')=='1';local report={points={},walks={},scope='Actual packaged actor footing on eight authenticated original open floor cells of the Joyful Game Corner U-counter; real left-aisle input from (1,3) to (1,2). QA teleports/champion, no encounters, Voxel Items ON/OFF. Separate expanded terrain plus actual uploaded furniture mesh oracle verifies physical floors. No complete setting/geometry/mobile claim.'}
 local function write()local f=assert(io.open(out..'/counter-support.json','w'));f:write(require('src.link.Json').encode(report));f:close()end
 local id='KA_SEVII_TWO_ISLAND_JOYFUL_GAME_CORNER'
 for i,p in ipairs{{1,3},{1,2},{3,2},{4,2},{5,1},{5,2},{6,2},{7,2}}do
  U.teleport(game,id,p[1],p[2],'up');Q.settle();U.wait(60)
  local map=game.overworld.map;assert(map:isWalkableCell(p[1],p[2]))
  local actual=scene.groundAt(map,p[1],p[2]);assert(actual==(fixed and 0 or 14),'counter footing differs')
  report.points[#report.points+1]={map=id,x=p[1],y=p[2],actual=actual,physical=0};write()
  if i==1 or i==5 then assert(U.still(game,out..'/counter-'..i..'.png'))end
 end
 U.teleport(game,id,1,3,'up');Q.settle();Q.walkTo(1,2);Q.settle()
 local h=scene.groundAt(game.overworld.map,1,2);assert(h==(fixed and 0 or 14));report.walks[#report.walks+1]={fromX=1,fromY=3,toX=1,toY=2,actual=h};write()
 Items.setting:setValue(false,game);Q.settle();U.wait(60);local off=scene.groundAt(game.overworld.map,1,2);assert(off==0,'disabled furniture still lifts actor');report.itemsOff=off
 Items.setting:setValue(true,game);Q.settle();U.wait(60);local on=scene.groundAt(game.overworld.map,1,2);assert(on==(fixed and 0 or 14));report.itemsRestored=on
 report.completed=true;write();print('SEVII_NATIVE_COUNTER_SUPPORT_PROOF_COMPLETE',#report.points,#report.walks,fixed);love.event.quit()
end
