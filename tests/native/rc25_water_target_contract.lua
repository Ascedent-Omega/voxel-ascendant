return function(game)
 assert(os.getenv('POKEPORT_IDENTITY')=='vasc-video-polish-qa');love.audio.setVolume(0)
 local root=assert(os.getenv('QA_VASC_ROOT'));local V={}
 local modules={};V.require=function(n)if not modules[n]then modules[n]=assert(loadfile(root..'/lib/'..n..'.lua'))(V)end;return modules[n]end
 local R=V.require('WaterReflection');local g=love.graphics
 local valid,why=g.validateShader(false,R._source);assert(valid,why)
 local esOK,esWhy=g.validateShader(true,R._source);assert(esOK,esWhy)
 local sceneShader=g.newShader([[#pragma language glsl3
 uniform float depthValue;
 vec4 effect(vec4 color,Image t,vec2 uv,vec2 sc){gl_FragDepth=depthValue;return color;}
 ]])
 local depthRead=g.newShader([[uniform Image source;
 vec4 effect(vec4 c,Image t,vec2 uv,vec2 sc){float v=Texel(source,sc/love_ScreenSize.xy).r;return vec4(v,v,v,1);}
 ]])
 local function captureDepth(slot)
  local c=g.newCanvas(slot.w,slot.h,{dpiscale=1});g.push('all');g.setCanvas(c);g.setDepthMode();g.setShader(depthRead);depthRead:send('source',slot.depth);g.setBlendMode('replace');g.rectangle('fill',0,0,slot.w,slot.h);g.pop()
  local d=c:newImageData();c:release();return d
 end
 local function assertPixel(data,x,y,expected)
  local r,gr,b=data:getPixel(x,y)
  assert(math.abs(r-expected[1])<.005 and math.abs(gr-expected[2])<.005 and math.abs(b-expected[3])<.005,('wrong colour at %s,%s: %s,%s,%s'):format(x,y,r,gr,b))
 end
 for _,size in ipairs{{641,361},{160,144},{854,478}}do
  local w,h=unpack(size);local slot={w=w,h=h,canvas=g.newCanvas(w,h,{dpiscale=1}),depth=g.newCanvas(w,h,{format='depth24',readable=true,dpiscale=1})}
  slot.depth:setFilter('nearest','nearest');slot.depth:setDepthSampleMode()
  g.push('all');g.origin();g.setCanvas{slot.canvas,depthstencil=slot.depth};g.clear(0,0,0,0,0,1);g.setDepthMode('always',true);g.setBlendMode('replace');g.setShader(sceneShader)
  sceneShader:send('depthValue',.8);g.setColor(0,0,1,1);g.rectangle('fill',0,0,w,h)
  sceneShader:send('depthValue',.2);g.setColor(1,0,0,1);g.rectangle('fill',0,0,w*.5,h*.5)
  local before=captureDepth(slot)
  -- Cast geometry uses viewport-relative positions like the real 3-D shader.
  local target=assert(R.prepare(slot));local allocations=g.getStats().canvases
  local mirror,originalDepth=R.draw(slot,function()
   sceneShader:send('depthValue',.5);g.setColor(0,1,0,1);g.rectangle('fill',0,0,target.w,target.h)
   sceneShader:send('depthValue',.7);g.setColor(1,1,0,1);g.rectangle('fill',0,0,target.w,target.h)
  end,sceneShader)
  assert(originalDepth==slot.depth and not R.lastPaintError,R.lastPaintError)
  local data=mirror:newImageData();assertPixel(data,math.floor(target.w*.25),math.floor(target.h*.75),{0,1,0});assertPixel(data,math.floor(target.w*.25),math.floor(target.h*.25),{1,0,0});assertPixel(data,math.floor(target.w*.75),math.floor(target.h*.5),{0,1,0});data:release()
  local after=captureDepth(slot);assert(before:getString()==after:getString(),'reflection changed original terrain depth');before:release();after:release()
  local originalNew=g.newCanvas;local extra=0;g.newCanvas=function(...)extra=extra+1;return originalNew(...)end
  for i=1,10 do assert(R.prepare(slot)==target)end
  g.newCanvas=originalNew;assert(extra==0,'preparation allocated again')
  g.pop();R.release(slot);slot.canvas:release();slot.depth:release()
 end
 R.invalidate();sceneShader:release();depthRead:release()
 print('PASS_WATER_TARGET_CONTRACT: GL/GLES shader, odd/small target, original-depth preservation, cast occlusion, persistent reuse and release')
 love.event.quit(0)
end
