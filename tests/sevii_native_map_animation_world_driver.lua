return function(game)
 io.stdout:setvbuf('no');local U=require('tests.drivers.util');local out=assert(os.getenv('SEVII_QA_OUTPUT'))
 local Q=dofile(assert(os.getenv('SEVII_KASC_ROOT'))..'/tests/habitat_playthrough/drivers/common.lua')(game)
 Q.setup();Q.V.setupCard.suspended=true;game.save.options.colors='redpp';game:applyOptions()
 love.window.setMode(1100,760,{resizable=true,vsync=1});love.audio.setVolume(0)
 local function find(fn,name,seen)
  if type(fn)~='function'then return end;seen=seen or{};if seen[fn]then return end;seen[fn]=true
  for i=1,200 do local k,v=debug.getupvalue(fn,i);if not k then break end;if k==name then return v end end
  for i=1,200 do local k,v=debug.getupvalue(fn,i);if not k then break end;local r=find(v,name,seen);if r then return r end end
 end
 local V=assert(find(Q.V.lib.require('VoxelScene').render,'V'));local Source=V.require('SeviiMapAnimations')
 V.require('VascControls').hintAlpha=function()return 0 end
 local camera=tonumber(os.getenv('SEVII_COMPONENT_CAMERA')or'0');local P=require('src.render.Pipelines')
 P.setLevel('voxel',camera);P.setLevel('tiltshift',0);P.syncOptions(game.save.options)
 V.require('DayNight').setting:setValue('day',game);V.require('Weather').setting:setValue('off',game)
 V.require('Gen1OutdoorScenery').ground:setValue(true,game);V.require('VoxelItems').setting:setValue(true,game)
 local R=require('src.render.TileRenderer');local ci
 for i=1,100 do local k=debug.getupvalue(R.animClock,i);if k=='animFrame'then ci=i;break end end
 local frozen;local tick=R.tick
 R.tick=function(...)if frozen then debug.setupvalue(R.animClock,assert(ci),frozen)else return tick(...)end end
 local rawDraw=game.draw;game.draw=function(self,...)if frozen then debug.setupvalue(R.animClock,ci,frozen)end;return rawDraw(self,...)end
 local report={camera=camera,cases={},scope='Real native world frames at identical source coordinates, fixed native animation clock; QA teleports/party and off-weather. No mobile performance claim.'}
 local function write()local f=assert(io.open(out..'/map-animation-world.json','wb'));f:write(require('src.link.Json').encode(report));f:close()end
 for _,case in ipairs{{'flowers','KA_SEVII_FOUR',20,9},{'steam','KA_SEVII_ONE_ISLAND_KINDLE_ROAD_EMBER_SPA',14,9},{'coast','KA_SEVII_KINDLE',14,34}}do
  frozen=nil;U.teleport(game,case[2],case[3],case[4],'up');Q.settle();U.wait(120)
  local row={kind=case[1],map=case[2],x=case[3],y=case[4],captures={}}
  for _,phase in ipairs{17,49}do
   frozen=phase;U.wait(10);assert(U.still(game,out..'/'..case[1]..'-phase'..phase..'.png'))
   local e=Source.receipt(game.overworld.map)
   if camera>0 and not os.getenv('SEVII_ANIMATION_BEFORE')then
    assert(e,'source resources not admitted '..case[2])
    assert(e.tick==phase,'source clock differs from world '..case[2])
    row.foreground=#e.foreground;row.surface=#e.surface;row.paints=e.paints
   end
   if os.getenv('SEVII_ANIMATION_BEFORE')then assert(not e,'before fixture unexpectedly owns animations');row.before=true end
   row.captures[#row.captures+1]=phase
  end
  report.cases[#report.cases+1]=row;write();print('SEVII_ANIMATION_WORLD_CASE',case[1],camera)
 end
 R.tick=tick;report.completed=true;write();print('SEVII_ANIMATION_WORLD_PASS',camera,#report.cases);love.event.quit()
end
