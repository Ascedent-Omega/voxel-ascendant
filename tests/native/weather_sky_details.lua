return function(V,out,generation)
 local g=love.graphics;local sky=V.require('Sky');local style=V.require('SkyStyle')
 assert(#sky.CONSTELLATIONS==6,'original trio or starters missing')

 local audio=V.require('WeatherAudio')
 assert(audio.installed and not next(audio.failed),'audio installation/decoding failed')
 assert(audio.sources.rain and audio.sources['snow-wind'],'rain/snow loops not warmed')
 local Cover=V.require('WeatherCover');local map=audio.map
 assert(Cover.revision(map)>0 and(Cover.textureBytes or 0)>0,'roof geometry/texture not published')
 local sheltered,roofs=0,0
 for z=2,map.def.height*32-2,4 do for x=2,map.def.width*32-2,4 do
  local top=Cover.height(map,x,z)
  if top then
   roofs=roofs+1
   local _,_,ground=V.require('WorldWeather').surface(map,x,z)
   if Cover.sheltered(map,x,z,ground or 0)then sheltered=sheltered+1 end
  end
 end end
 print('COVER_COUNTS',generation,roofs,sheltered,map.id,map.def.width,map.def.height)
 assert(roofs>0 and sheltered>0,'map has no recognised roof/shelter geometry')
 print('COVER_NATIVE',generation,roofs,sheltered,Cover.textureBytes)
 local oldVolume=audio.scale({save={options={sfxVol=0}}});assert(oldVolume==0)
 local previousWeather=sky.frameWeather()
 for _,weather in ipairs{'rain','storm','snow','fog','clear','heat'}do
  sky.setFrameWeather(weather)
  assert(sky.bodyObscured()==(weather~='clear' and weather~='heat'),'celestial weather visibility')
 end
 sky.setFrameWeather(previousWeather)
 for _,gles in ipairs{false,true}do local valid,why=g.validateShader(gles,style.CLOUD_GLSL);assert(valid,why)end

 -- Production foliage transform: green becomes snow, trunks remain brown,
 -- amount zero restores the exact input, and authored shadow tones survive.
 local frost=V.require('ScenerySnow')
 local program=frost.GLSL..[[
 vec4 effect(vec4 c,Image tex,vec2 uv,vec2 sc){vec4 p=Texel(tex,uv);return vec4(snowFoliage(p.rgb,scenerySnow),p.a);}
 ]]
 for _,gles in ipairs{false,true}do local valid,why=g.validateShader(gles,program);assert(valid,why)end
 local sh=g.newShader(program);local pixels=love.image.newImageData(3,1)
 pixels:setPixel(0,0,.12,.5,.08,1);pixels:setPixel(1,0,.35,.20,.08,1);pixels:setPixel(2,0,.03,.10,.02,1)
 local tex=g.newImage(pixels);tex:setFilter('nearest','nearest');local target=g.newCanvas(3,1)
 local function render(amount)
  g.push('all');g.setCanvas(target);g.origin();g.setScissor();g.setDepthMode();g.setShader(sh);g.setColor(1,1,1,1);g.clear();sh:send('scenerySnow',amount);g.draw(tex);g.pop()
  return target:newImageData()
 end
 local bare=render(0);local snowy=render(1)
 local r0,g0,b0=bare:getPixel(0,0);assert(math.abs(r0-.12)<.01 and math.abs(g0-.5)<.01)
 local rr,gg,bb=snowy:getPixel(0,0);assert(rr>.90 and gg>.92 and bb>.94,'green canopy failed to turn white')
 local br,bg,bl=snowy:getPixel(1,0);assert(math.abs(br-.35)<.01 and math.abs(bg-.20)<.01,'brown trunk coated')
 local sr,sg,sb=snowy:getPixel(2,0);assert(sr>r0 and sr<rr-.1 and sb>sg,'foliage relief lost')
 bare:release();snowy:release();target:release();tex:release();pixels:release();sh:release()
 print('PASS_NATIVE_FOLIAGE_SNOW_PIXELS_AND_CLEAR_RESTORATION',generation)
 local expected=generation==1 and {'SQUIRTLE','BULBASAUR','CHARMANDER'}or{'CHIKORITA','CYNDAQUIL','TOTODILE'}
 local names=generation==1 and {'Schiggy','Bisasam','Glumanda'}or{'Endivie','Feurigel','Karnimani'}
 local canvas=g.newCanvas(1200,450);g.push('all');g.setCanvas(canvas);g.origin();g.setScissor();g.setShader();g.setDepthMode();g.clear(.025,.044,.085,1)
 local font=g.newFont(20);g.setFont(font)
 for i=1,3 do
  local def=sky.CONSTELLATIONS[i+3];assert(def.id==expected[i])
  local sa,ca,se,ce=math.sin(def.az),math.cos(def.az),math.sin(def.el),math.cos(def.el)
  local forward={sa*ce,se,ca*ce};local right={ca,0,-sa};local up={-sa*se,ce,-ca*se}
  local span=.34;local ray={base={},du={},dv={}}
  for k=1,3 do ray.du[k]=right[k]*span;ray.dv[k]=-up[k]*span;ray.base[k]=forward[k]-ray.du[k]*.5-ray.dv[k]*.5 end
  for pi=1,#def.points do local _,_,visible=sky.projectDirection(ray,400,400,sky.constellationDirection(def,pi));assert(visible,'starter clipped at centre')end
  g.push();g.translate((i-1)*400,0);g.setScissor((i-1)*400,0,400,400)
  sky._paintStars(400,400,400,2,1,ray,1,{weather='clear'})
  g.setScissor();g.setColor(1,1,1,1);g.printf(names[i],0,415,400,'center');g.pop()
 end
 g.pop();local data=canvas:newImageData();local f=assert(io.open(out..'gen'..generation..'-starters.png','wb'));f:write(data:encode('png'):getString());f:close();data:release();canvas:release();font:release()
 -- Read back the production shader with a pure-white source texel. Even its
 -- brightest authored cloud pixel must be neutral grey during rain/storm.
 local texels=love.image.newImageData(1,1);texels:setPixel(0,0,1,1,1,1);local tex=g.newImage(texels);local target=g.newCanvas(4,4)
 for _,weather in ipairs{'rain','storm'}do for _,night in ipairs{0,1}do
  g.push('all');g.setCanvas(target);g.origin();g.setScissor();g.setDepthMode();g.clear(0,0,0,0)
  local old,active=style.beginClouds(g,weather);assert(active)
  g.setColor(style.wetCloudTint(weather,night));g.draw(tex,0,0,0,4,4);g.setShader(old);g.pop()
  local pixels=target:newImageData();local r,gg,b=pixels:getPixel(1,1);pixels:release()
  assert(math.abs(r-gg)<.005 and math.abs(gg-b)<.005 and r<.53 and r>.1,'white or tinted wet-cloud highlight')
 end end
 target:release();tex:release();texels:release()
 -- Exercise the real event painter, including the guaranteed post-rain path.
 local events=V.require('SkyEvents');events.prewarm(32)
 local progress,enabled=events.rainbowProgress,events.enabled
 events.rainbowProgress=function()return .5 end;events.enabled=function()return false end
 local ctx={skyEnabled=true,g=g,w=1200,h=800,cell=2,alpha=1,clock=50,weather='clear',project=function()return 600,300 end,daylight=0}
 g.push('all');assert(events.paint(ctx,'back')==0,'guaranteed rainbow appears at night')
 ctx.daylight=1;assert(events.paint(ctx,'back')==1,'daytime post-rain rainbow lost');g.pop()
 events.rainbowProgress,events.enabled=progress,enabled
 print('PASS_NATIVE_STARTERS_GREY_CLOUD_PIXELS_DAYLIGHT_RAINBOW_AND_CELESTIAL_WEATHER',generation)
end
