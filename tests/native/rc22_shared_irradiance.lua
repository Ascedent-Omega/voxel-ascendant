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
 uniform vec3 probe;uniform vec3 normal;uniform float mode;uniform float shared;
 vec4 effect(vec4 c,Image t,vec2 uv,vec2 sc){vec3 value=shared>.5 ? localCombinedIrradiance(probe,normal,mode) : mode>1.5?localWaterLight(probe,vec3(0,1,0)):(mode>.5?localActorIrradiance(probe,normal):localIrradiance(probe,normal));return vec4(value,1);}
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

 local samples,worst=0,0
 local function compare()
  for _,cached in ipairs{false,true}do for mode=0,1 do
   for _,n in ipairs{{1,0,0},{-1,0,0},{0,1,0},{0,-1,0},{0,0,1},{0,0,-1},{.707,.707,0}}do
    for _,y in ipairs{-12,0,24,64,128}do for x=-32,180,11 do
     local p={x,y,17};sh:send('shared',0);local a,b,c=sample(p,n,mode,cached)
     sh:send('shared',1);local d,e,f=sample(p,n,mode,cached)
     worst=math.max(worst,math.abs(a-d),math.abs(b-e),math.abs(c-f));samples=samples+1
    end end
   end
  end end
 end
 compare()
 pool[1].kind='torch';for i=1,16 do setup()end;compare()
 pool={pool[1],pool[2]};for i=1,16 do setup()end;compare()
 -- Sunlight through a portal and stained glass on the same receiver.
 local pixel=love.image.newImageData(1,1);pixel:setPixel(0,0,1,1,1,1)
 local white=g.newImage(pixel);pixel:release()
 sh:send('localVisibility',white);sh:send('localPortalCount',1)
 sh:send('localPortalP0',{0,24,0,1});sh:send('localPortalRect0',{-64,64,0,64});sh:send('localPortalN0',{1,0,0})
 sh:send('localPortalSun',{-1,.2,0,1});sh:send('localPortalColor',{1,.8,.5});sh:send('localPortalShadow',{0,0,0})
 sh:send('localMosaicArt',white);sh:send('localMosaicArea',{32,16,96,80});sh:send('localMosaicColor',{.2,.5,.3,.8})
 compare()
 assert(worst==0,'shared irradiance changed pixels '..worst)
 print('PASS_SHARED_IRRADIANCE',samples,'pixel error',worst);love.event.quit(0)
end
