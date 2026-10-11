return function(game)
 io.stdout:setvbuf('no');local U=require('tests.drivers.util');local out=assert(os.getenv('SEVII_QA_OUTPUT'))
 local Q=dofile(assert(os.getenv('SEVII_KASC_ROOT'))..'/tests/habitat_playthrough/drivers/common.lua')(game)
 Q.setup();love.window.hasFocus=function()return true end;love.window.isVisible=function()return true end;Q.V.setupCard.suspended=true;game.save.options.colors='redpp';game:applyOptions()
 love.window.setMode(1100,760,{resizable=true,vsync=1});love.audio.setVolume(0)
 local function find(fn,name,seen)
  if type(fn)~='function'then return end;seen=seen or{};if seen[fn]then return end;seen[fn]=true
  for i=1,200 do local k,v=debug.getupvalue(fn,i);if not k then break end;if k==name then return v end end
  for i=1,200 do local k,v=debug.getupvalue(fn,i);if not k then break end;local r=find(v,name,seen);if r then return r end end
 end
 local V=assert(find(Q.V.lib.require('VoxelScene').render,'V'));local M=V.require('KascSeviiScenery')
 local Style=V.require('BattleArenaStyle');local Loader=require('src.world.MapLoader');local Json=require('src.link.Json')
 local f=assert(io.open(assert(os.getenv('SEVII_STYLE_ORACLE')),'r'));local headers=Json.decode(f:read('*a'));f:close();local bySource={};for _,h in ipairs(headers)do bySource[h.source]=h end
 local report={maps={},battles={},mismatches=0,scope='Independent authenticated BPRD header map types versus actual native style resolver; ordinary Kanto family reuse. Native portable battle frames at recorded source coordinates, QA teleports/team; no mobile or continuous balance claim.'}
 local function write()local f=assert(io.open(out..'/source-style.json','wb'));f:write(Json.encode(report));f:close()end
 local ids={};for id in pairs(Q.K.seviiExpedition.maps)do ids[#ids+1]=id end;table.sort(ids)
 for _,id in ipairs(ids)do
  local map=Loader.load(game.data,id);local p=assert(M.profile(map));local h=assert(bySource[p.source]);local expected
  if p.kind=='cave'then expected='cave'
  elseif p.kind=='canopy'then expected='forest'
  elseif p.source=='OneIsland_TreasureBeach'then expected='coast'
  elseif p.kind=='mountain'and p.exterior then expected='moon_approach'
  elseif h.type==1 then expected='city'
  elseif h.type==3 then expected='grass'
  else expected='interior'end
  local actual=Style.resolve(map).id
  local row={map=id,source=p.source,mapType=h.type,kind=p.kind,outdoor=p.outdoor,exterior=p.exterior,expected=expected,actual=actual}
  if expected~=actual then report.mismatches=report.mismatches+1 end
  if os.getenv('SEVII_STYLE_FIXED')then assert(expected==actual,'native style mismatch '..id..' '..actual..' expected '..expected);assert(p.sourceMapType==h.type,'source type export differs '..id)end
  report.maps[#report.maps+1]=row
 end
 print('SEVII_NATIVE_STYLE_AUDIT',#report.maps,report.mismatches);write()
 if os.getenv('SEVII_STYLE_SCREENSHOTS')then
  local P=require('src.render.Pipelines');P.setLevel('voxel',1);P.setLevel('tiltshift',0);P.syncOptions(game.save.options)
  V.require('DayNight').setting:setValue('day',game);V.require('Weather').setting:setValue('off',game);V.require('VascControls').hintAlpha=function()return 0 end
  local B=V.require('OverworldBattle');local BS=V.require('BattleScene');local raw=BS.render;local renders=0
  local declines={};BS.render=function(...)local im=raw(...);if im then renders=renders+1 else local why=tostring(BS.lastDeclineReason);if not declines[why]then declines[why]=true;print('SEVII_STYLE_FRAME_DECLINE',why)end end;return im end
  local mode=os.getenv('SEVII_COMPONENT_BATTLE_MODE')or'arena';local camera=tonumber(os.getenv('SEVII_STYLE_CAMERA')or'1');P.setLevel('voxel',camera);P.syncOptions(game.save.options);B.setting:setValue(mode,game)
  for _,case in ipairs{{'town','OneIsland',13,14},{'route','OneIsland_KindleRoad',12,20},{'mountain','MtEmber_Exterior',20,20}}do
   local id,x,y=Q.K.seviiExpedition.location(case[2],case[3],case[4]);local map=Loader.load(game.data,id);local best=math.huge;local ax,ay
   for yy=0,map.heightCells-1 do for xx=0,map.widthCells-1 do local d=(xx-x)^2+(yy-y)^2
    if d<best and map:isWalkableCell(xx,yy)and not map:warpAtCell(xx,yy)then best,ax,ay=d,xx,yy end
   end end
   assert(ax);U.teleport(game,id,ax,ay,'up');Q.settle();local stable=0;for frame=1,3000 do U.wait(1);if camera==0 or (not V.require('VoxelScene').pendingReason and not V.require('WorldSceneHold').loading(game.overworld))then stable=stable+1 else stable=0 end;if stable>=90 then break end end;assert(stable>=90,'source scene did not present '..id);assert(U.still(game,out..'/'..case[1]..'-world.png'))
   for _,mon in ipairs(game.save.party)do mon.hp=mon.stats.hp;mon.status=nil end
   local battle=require('src.battle.BattleState').newWild(game,'PIDGEOT',55);game.overworld:pushBattle(battle)
   local ready
   for i=1,2400 do if game.stack:top()==battle and battle.phase=='menu'and not battle.current and not battle.sendingOut and not battle.enemySendingOut then ready=true;break end;U.wait(1);if i%18==0 then U.tap(game,'a')end end
   if not ready then local top=game.stack:top();print('SEVII_STYLE_BATTLE_NOT_READY',battle.phase,top==battle,top.title,top.screenId)end
   assert(ready,'battle menu absent '..id);local before=renders;U.wait(90);local arena=camera==1 and assert(B.arena()) or {};if camera==1 then assert(renders>before+10,'portable renderer stalled '..id)end
   local actual=camera==0 and'NATIVE'or arena.terarrium and'TERRARIUM'or arena.presentationMode;print('SEVII_STYLE_ACTUAL_STAGE',mode,actual,arena.presentationMode,arena.fallbackReason,B.setting:get());local expectedMode=({arena='DISCS',flatB='DISCS',terarrium='TERRARIUM'})[mode];if camera==1 then assert(actual==expectedMode,'portable stage mismatch '..id..' '..tostring(actual));if mode=='arena'then assert(arena.requestedMode=='ARENA' and arena.fallbackReason,'unreviewed ARENA missing explicit recovery receipt')end end
   assert(U.still(game,out..'/'..case[1]..'-'..mode..'.png'));report.battles[#report.battles+1]={map=id,x=ax,y=ay,source=case[2],camera=camera,requested=mode,mode=actual,fallback=arena.fallbackReason,style=Style.resolve(map).id,renders=renders-before};write()
   B.finish();while game.stack:top()~=game.overworld do game.stack:pop()end
   print('SEVII_NATIVE_SOURCE_STYLE_BATTLE',case[1],actual,Style.resolve(map).id)
  end
 end
 assert(#report.maps==266);if os.getenv('SEVII_STYLE_FIXED')then assert(report.mismatches==0)end
 report.completed=true;write();print('SEVII_NATIVE_SOURCE_STYLE_PROOF_PASS',#report.maps,report.mismatches,#report.battles);love.event.quit()
end
