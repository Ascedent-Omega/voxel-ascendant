local g=love.graphics
local CP=assert(loadfile('lib/CanvasPresentation.lua'))({})
local setting='clear';local reported
local modules={ModSetting={new=function()return{get=function()return setting end}end},
 CanvasPresentation=CP,DayNight={tod=function()return'DAY'end},
 SkyEvents={rainbowProgress=function()end},CinnabarActivity={ashAmount=function()return 0 end},
 RainStrength={profile=function(mode)return{drops=mode=='storm'and 4 or 3}end},
 PerformanceDiagnostics={reportWeather=function(r)reported=r end}}
local W=assert(loadfile('lib/Weather.lua'))({require=function(n)return assert(modules[n],n)end})
local w,h=160,96;local canvas=g.newCanvas(w,h,{dpiscale=1})
local depth=g.newCanvas(w,h,{format='depth24stencil8',readable=true,dpiscale=1})
local map={id='ROUTE_1',def={outdoor=true,tileset='OVERWORLD'}}
local function paint(mode,battle,bound)
 setting=mode;W.clock=200.25;reported=nil
 g.setCanvas({canvas,depthstencil=depth});g.clear(.3,.6,.2,1,true,true)
 g.setColor(.9,.1,.2,1);g.setDepthMode('lequal',true);g.rectangle('fill',4,6,13,27)
 if not bound then g.setCanvas()end
 local before=g.getCanvas();local setCanvas=g.setCanvas;local binds=0
 g.setCanvas=function(...)binds=binds+1;return setCanvas(...)end
 local fn=battle and W.applyBattle or W.apply;assert(fn(canvas,w,h,map,2,mode,false,bound)==canvas)
 g.setCanvas=setCanvas
 assert(reported and reported.visualActive,'weather failed '..mode)
 if bound then assert(binds==0,'bound weather rebound framebuffer')end
 local after=g.getCanvas();assert(type(before)==type(after),'caller target lost')
 local cmp,writes=g.getDepthMode();assert(cmp=='lequal'and writes,'caller depth state lost')
 g.setCanvas();g.setDepthMode();local data=canvas:newImageData();local bytes=data:getString();data:release();return bytes
end
local count=0
for _,os in ipairs{'OS X','Android','iOS'}do
 CP.OS=os
 for _,battle in ipairs{false,true}do
  for _,mode in ipairs{'clear','rain','snow','fog','storm','heat'}do
   assert(paint(mode,battle,false)==paint(mode,battle,true),os..' weather differs '..mode)
   count=count+1
  end
 end
end
print('PASS bound weather',count,'exact GPU comparisons, desktop/Android/iOS transforms, world/battle, no framebuffer rebind')
