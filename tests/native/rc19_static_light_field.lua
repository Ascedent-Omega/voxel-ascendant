return function(game)
 assert(os.getenv('POKEPORT_IDENTITY')=='vasc-video-polish-qa');love.audio.setVolume(0)
 local root=assert(os.getenv('QA_VASC_ROOT'))
 local modules={CanvasPresentation={OS='OS X'},ModSetting={new=function()return{get=function()return true end,setGate=function()end}end},Sky={clock=0},DayNight={},Shadows={enabled=function()return false end}}
 local V={mod={read=function(_,p)local f=assert(io.open(root..'/'..p));local s=f:read('*a');f:close();return s end}}
 V.require=function(n)if modules[n]then return modules[n]end;local m=assert(loadfile(root..'/lib/'..n..'.lua'))(V);modules[n]=m;return m end
 local L=V.require('LocalLights');local F=V.require('StaticLightField');local Grid=V.require('LocalLightGrid')
 local g=love.graphics;local map={def={width=24,height=24}}
 local owner={lo={-8,-8,-16},hi={8,64,-8}}
 local pool={};for i=1,12 do pool[i]={x=(i-1)*96,y=24,z=0,radius=64,power=1.5,normal={0,0,1},owner=owner}end
 local blocks={owner,{lo={-32,-8,24},hi={32,64,28}}}
 local sh=g.newShader(L.glsl()..[[
 uniform vec3 probe;uniform vec3 normal;uniform float mode;
 vec4 effect(vec4 c,Image t,vec2 uv,vec2 sc){vec3 value=mode>1.5?localWaterLight(probe,vec3(0,1,0)):(mode>.5?localActorIrradiance(probe,normal):localIrradiance(probe,normal));return vec4(value,1);}
 ]])
 local target=g.newCanvas(1,1,{dpiscale=1})
 local function setup()
  L.clear();local frame=L.current();frame.map=map;frame.tint={1,1,1}
  L.assign(pool,blocks,{0,0,0},false);F.beginFrame(true);L.send(sh,true)
  return frame
 end
 for i=1,16 do setup()end
 assert(not F.lastError,F.lastError);assert(F.last and not F.pending(),'field not completed')
 local function sample(p,n,mode,cached)
  sh:send('probe',p);sh:send('normal',n);sh:send('mode',mode or 0);sh:send('staticFieldOn',cached and 1 or 0)
  g.push('all');g.origin();g.setCanvas(target);g.setShader(sh);g.setBlendMode('replace');g.setColor(1,1,1,1);g.rectangle('fill',0,0,1,1);g.pop()
  local d=target:newImageData();local r,gr,b=d:getPixel(0,0);d:release();return r,gr,b
 end
 local worst=0
 for _,n in ipairs{{1,0,0},{-1,0,0},{0,1,0},{0,-1,0},{0,0,1},{0,0,-1}}do
  for _,y in ipairs{0,8,16,24,32,40}do for z=2,62,4 do
   local p={2,y,z};local a=sample(p,n,0,false);local b=sample(p,n,0,true)
   worst=math.max(worst,math.abs(a-b))
  end end
 end
 assert(worst<.035,'lattice irradiance mismatch '..worst)
 -- Fractional positions on both sides of a thin wall must stay dark behind it.
 local leak=0
 for z=28,44 do for x=-15,15,3 do local p={x,0,z};local raw=sample(p,{0,1,0},0,false);local cached=sample(p,{0,1,0},0,true);leak=math.max(leak,cached-raw)end end
 assert(leak<.035,'cached field leaks through wall '..leak)
 local gridBefore=Grid.prepare(L.current(),L,nil).staticKey
 local reordered={};for i=#pool,1,-1 do reordered[#reordered+1]=pool[i]end;pool=reordered
 blocks={blocks[2],blocks[1]};setup()
 assert(Grid.prepare(L.current(),L,nil).staticKey==gridBefore,'map completion order changed disk key')
 blocks={blocks[2],blocks[1]};setup()
 local before=F.rebuilds;for _,l in ipairs(pool)do l.power=l.power*.5 end
 setup();assert(F.rebuilds==before and not F.pending(),'uniform day/night strength rebaked field')
 local a=sample({2,0,10},{0,1,0},0,false);local b=sample({2,0,10},{0,1,0},0,true);assert(math.abs(a-b)<.035,'day/night scaling incorrect')
 for _,mode in ipairs{1,2}do assert(sample({2,0,10},{0,1,0},mode,false)==sample({2,0,10},{0,1,0},mode,true),'actor/water changed')end
 assert(sample({2,160,10},{0,1,0},0,false)==sample({2,160,10},{0,1,0},0,true),'height fallback changed')
 local n={.707,.707,0};assert(sample({2,0,10},n,0,false)==sample({2,0,10},n,0,true),'sloped surface changed')
 pool[1].kind='torch';for i=1,16 do setup()end
 assert(not F.pending(),'source-class change did not finish')
 local dynamicBakes=F.rebuilds;pool[1].power=pool[1].power*.7;setup()
 assert(F.rebuilds==dynamicBakes and not F.pending(),'dynamic flicker rebuilt static field')
 local torch={pool[1].x+2,0,10}
 assert(math.abs(sample(torch,{0,1,0},0,false)-sample(torch,{0,1,0},0,true))<.02,'cell dynamic-light bit omitted torch')
 blocks[2].lo[3]=16;setup();assert(F.pending(),'blocker changes kept stale field')
 blocks[2].lo[3]=24;setup();assert(not F.pending(),'returning to ready field retained stale job')
 -- Changing bake inputs must not allocate a replacement every frame.
 local realTime=love.timer.getTime;local tick=realTime();love.timer.getTime=function()return tick end
 local allocate=g.newCanvas;local allocations=0
 g.newCanvas=function(...)allocations=allocations+1;return allocate(...)end
 blocks[2].lo[3]=16;setup();assert(F.pending())
 for i=1,20 do tick=tick+.02;blocks[2].lo[3]=16+i*.1;setup()end
 assert(allocations==1 and not F.pending(),'unstable inputs churned allocations or blocked reveal')
 tick=tick+.16;for i=1,16 do setup()end
 assert(not F.pending() and allocations==2,'settled input did not finish replacement')
 love.timer.getTime=realTime;g.newCanvas=allocate
 blocks[2].lo[3]=15;setup();assert(F.pending())
 L.send(sh,false);assert(not F.pending(),'OFF retained pending bake');assert(sample({2,0,10},{0,1,0},0,true)==0,'OFF retained light')
 F.invalidate();assert(not F.pending())
 local originalCanvas=g.newCanvas;local attempts=0
 g.newCanvas=function(...)attempts=attempts+1;error('QA rejected optional field allocation')end
 for i=1,3 do setup()end
 assert(F.lastError and attempts==1 and not L.failure,'field failure disabled lighting or retried')
 assert(sample({98,0,10},{0,1,0},0,false)>0,'fallback lost working lights')
 g.newCanvas=originalCanvas;F.invalidate()
 local huge=F.plan({grid={0,0,1000000,1000000}},4096,true)
 assert(not huge,'unbounded field allocation')
 local files={};V.mod.cache={
  read=function(_,path)return files[path]end,
  write=function(_,path,data)files[path]=data;return true end,
  info=function(_,path)return files[path]and{size=#files[path]}end}
 local disk=V.require('StaticLightDiskCache');local key=assert(disk.key('fixture'))
 disk.write(key,target);assert(disk.writes==1,'cache write failed')
 local restored=assert(disk.read(key,1,1),'disk roundtrip failed');restored:release()
 for path,data in pairs(files)do files[path]=data:sub(1,148)..string.char(255,255,255,127)..data:sub(153)end
 assert(not disk.read(key,1,1),'oversized decompression accepted')
 print('PASS_STATIC_FIELD',worst,leak,before,'diskHits',disk.hits);love.event.quit(0)
end
