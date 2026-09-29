for _,osName in ipairs{'Android','iOS'} do
 local windows=true;local map={id='SILPH_CO_2F'}
 local modules={Gen1Rooftops=assert(loadfile('lib/Gen1Rooftops.lua'))(),SilphFountains={prepared=function()return true end},CanvasPresentation={OS=osName},VoxelState={ready=true},Mat4={identity=function()return{}end},
  SilphWindows={enabled=function()return windows end},HorizonWall={enabled=function()return true end}}
 local V={mod={}}
 function V.require(n)
  if not modules[n]then
   modules[n]=n=='MobileSceneryGate' and assert(loadfile('lib/MobileSceneryGate.lua'))(V) or {}
  end
  return modules[n]
 end
 package.loaded['src.render.PaletteFX']={};package.loaded['src.world.Map']={}
 local S=assert(loadfile('lib/VoxelScene.lua'))(V)
 for i=1,100 do local k=debug.getupvalue(S.readyForReveal,i);if not k then break end;if k=='readyMap'then debug.setupvalue(S.readyForReveal,i,map)end end
 local state={map=map};local gate=modules.MobileSceneryGate
 assert(not S.readyForReveal(state),'cold windows revealed')
 gate.noteSafeCanvas(map,{});gate.noteCoreReady(map)
 assert(not S.readyForReveal(state),'bare room revealed')
 gate.noteResource(map,'horizon',true);gate.noteResource(map,'panorama',true)
 assert(not S.readyForReveal(state),'unpainted scene revealed')
 assert(gate.beginProbe(map));gate.finishProbe(map,true,{})
 assert(S.readyForReveal(state),'completed window scene blocked')
 gate.invalidate();gate.enterMap(map);gate.fail(map,'fixture')
 assert(S.readyForReveal(state),'terminal error must fail open')
 gate.invalidate();windows=false;assert(S.readyForReveal(state),'windows OFF must not wait')
 modules.VoxelState.ready=false;assert(not S.readyForReveal(state),'window policy bypassed terrain gate')
 modules.VoxelState.ready=true
 map.id='CELADON_MART_ROOF';map.def={tileset='LOBBY',width=10,height=4}
 gate.invalidate();assert(not S.readyForReveal(state),'cold rooftop revealed with windows OFF')
 assert(S.revealTimeout(state)==60,'rooftop keeps short timeout')
 gate.noteSafeCanvas(map,{});gate.noteCoreReady(map)
 gate.noteResource(map,'horizon',true);gate.noteResource(map,'panorama',true)
 assert(not S.readyForReveal(state),'unpainted rooftop revealed')
 assert(gate.beginProbe(map));gate.finishProbe(map,{})
 assert(S.readyForReveal(state),'painted rooftop blocked')
 modules.HorizonWall.enabled=function()return false end
 gate.invalidate();assert(S.readyForReveal(state),'scenery OFF blocks rooftop')
 assert(S.revealTimeout(state)==nil,'scenery OFF extends timeout')
 print('PASS '..osName..' window reveal: cold, prepared, painted, failed and OFF')
end
