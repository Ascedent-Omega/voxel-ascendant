return function(game)
 assert(os.getenv('POKEPORT_IDENTITY')=='vasc-video-polish-qa');love.audio.setVolume(0);io.stdout:setvbuf('no')
 local root=assert(os.getenv('QA_VASC_ROOT'))
 local modules={CanvasPresentation={OS='Linux'},ModSetting={new=function()return{get=function()return true end,setGate=function()end}end},Sky={clock=0},DayNight={},Shadows={enabled=function()return false end}}
 local V={mod={read=function(_,p)local f=assert(io.open(root..'/'..p));local s=f:read('*a');f:close();return s end}}
 V.require=function(n)if not modules[n]then modules[n]=assert(loadfile(root..'/lib/'..n..'.lua'))(V)end;return modules[n]end
 local L=V.require('LocalLights')
 local actual=assert(loadfile(root..'/lib/LocalLightGrid.lua'))(V)
 local reference=assert(loadfile(assert(os.getenv('QA_GRID_REFERENCE'))))(V)
 local g=love.graphics;local blankData=love.image.newImageData(1,1);blankData:setPixel(0,0,1,1,1,1)
 local blank=g.newImage(blankData);blankData:release()
 local map={};local pool={}
 for i=1,180 do
  local owner=i%3==0 and {lo={i*80,-2,-20},hi={i*80+24,80,0}}or{}
  pool[i]={x=i*80,y=i%4*8,z=i%7*40,radius=96,power=1,normal={0,0,1},color={1,.6,.2},owner=owner}
 end
 local function frame()return {map=map,allLights=pool,allBlockers={},blockers={}}end
 local function hash(image)
  local w,h=image:getDimensions();local c=g.newCanvas(w,h,{dpiscale=1})
  g.push('all');g.setCanvas(c);g.origin();g.setShader();g.setDepthMode();g.setBlendMode('replace');g.setColor(1,1,1,1);g.draw(image);g.pop()
  local d=c:newImageData();local s=love.data.hash('sha256',d:getString());d:release();c:release();return s
 end
 local expected=reference.prepare(frame(),L,blank)
 local clock=love.timer.getTime;local fake=0
 love.timer.getTime=function()fake=fake+.00015;return fake end
 local result,steps
 for i=1,2000 do
  actual.beginFrame(false);result=actual.prepare(frame(),L,blank);steps=i
  if not actual.pending()then break end
  assert(result==nil,'new map exposed partial grid')
 end
 love.timer.getTime=clock
 assert(result and steps>2 and steps<2000,'staged grid did not finish')
 for _,key in ipairs{'indices','data','visibility'}do assert(hash(result[key])==hash(expected[key]),key..' bytes changed')end
 assert(result.staticKey==expected.staticKey and result.staticPower==expected.staticPower,'static cache identity changed')
 print('PASS_INDEX_TEXTURE_EQUIVALENCE',steps)
 -- Stop specifically after allocation while pixels are still being filled.
 pool[180].x=pool[180].x+200
 love.timer.getTime=function()fake=fake+.00015;return fake end
 local pendingData
 for i=1,2000 do
  actual.beginFrame(false);assert(actual.prepare(frame(),L,blank)==result,'partial replacement exposed')
  for j=1,100 do local k,v=debug.getupvalue(actual.pending,j);if not k then break end
   if k=='pending'and v and v.data then pendingData=v.data end
  end
  if pendingData then break end
 end
 assert(pendingData and actual.pending(),'did not reach pending pixel phase')
 actual.cancelPending();assert(not actual.pending())
 assert(not pcall(pendingData.getWidth,pendingData),'cancelled CPU image retained')
 love.timer.getTime=clock
 assert(hash(result.indices)==hash(expected.indices),'cancellation damaged active texture')
 print('PASS_INDEX_TEXTURE_CANCEL_OWNERSHIP')
 actual.invalidate();reference.invalidate();blank:release();love.event.quit(0)
end
