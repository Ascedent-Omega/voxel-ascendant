return function(game)
 assert(os.getenv('POKEPORT_IDENTITY')=='vasc-video-polish-qa')
 love.audio.setVolume(0);io.stdout:setvbuf('no')
 local root=assert(os.getenv('VASC_REPO'))
 local modules={CanvasPresentation={OS='iOS'},ModSetting={new=function()return{get=function()return true end,setGate=function()end}end},Sky={clock=0},DayNight={},Shadows={enabled=function()return false end}}
 local V={require=function(n)return assert(modules[n],n)end}
 local L=assert(loadfile(root..'/lib/LocalLights.lua'))(V)
 local actual=assert(loadfile(root..'/lib/LightVisibility.lua'))(V)
 local reference=assert(loadfile(assert(os.getenv('QA_VISIBILITY_REFERENCE'))))(V)
 local g=love.graphics;local data=love.image.newImageData(1,1);data:setPixel(0,0,1,1,1,1)
 local blank=g.newImage(data);data:release()
 local pool,blocks={},{}
 for i=1,65 do
  pool[i]={x=i*128,y=16,z=0,radius=56,power=1,normal={0,0,0},owner={}}
  blocks[i]={lo={i*128-40,-2,8},hi={i*128+40,40,12}}
 end
 local function check(label,n,expectedReuse,expectedRender)
  local sources={};for i=1,n do sources[i]=pool[i]end
  local frame={lights=sources,blockers=blocks,perLightBlockers=true}
  local policy={MAX_LIGHTS=n,MAX_PORTALS=0,MAX_BLOCKERS=L.MAX_BLOCKERS,glsl=L.glsl}
  local a=actual.prepare(frame,policy,blank);local b=reference.prepare(frame,policy,blank)
  local x,y=a:newImageData(),b:newImageData()
  assert(x:getWidth()==y:getWidth()and x:getHeight()==y:getHeight(),label..' dimensions')
  assert(love.data.hash('sha256',x:getString())==love.data.hash('sha256',y:getString()),label..' visibility changed')
  x:release();y:release()
  assert(actual.last.reused==expectedReuse,label..' reuse '..actual.last.reused)
  assert(actual.last.rendered==expectedRender,label..' renders '..actual.last.rendered)
  print('PASS_VISIBILITY_REUSE',label,actual.last.reused,actual.last.rendered)
 end
 check('initial',64,0,64)
 check('append and grow',65,64,1)
 blocks[1].hi[3]=24;check('one blocker changed',65,64,1)
 pool[1],pool[65]=pool[65],pool[1];check('reordered',65,65,0)
 check('shrink and narrow',32,32,0)
 pool[2].radius=65;check('one radius changed',32,31,1)
 actual.invalidate();reference.invalidate();check('invalidated',32,0,32)
 actual.invalidate();reference.invalidate();blank:release()
 local previousArg=arg;arg={root}
 assert(loadfile(root..'/tests/local_light_grid_test.lua'))();arg=previousArg
 print('PASS_VISIBILITY_CACHE');love.event.quit(0)
end
