return function(game)
 assert(os.getenv('POKEPORT_IDENTITY')=='vasc-video-polish-qa')
 love.audio.setVolume(0);io.stdout:setvbuf('no')
 local root=assert(os.getenv('VASC_REPO'));local oldArg=arg;arg={root}
 assert(loadfile(root..'/tests/local_light_grid_test.lua'))();arg=oldArg
 local f=assert(io.open(root..'/lib/TiltShift.lua'));local source=f:read('*a');f:close()
 local optimized=assert(source:match('local SHADER = %[%[(.-)%]%]'))
 local reference=optimized:gsub('vec4 sum = Texel%(tex, tc%);%s*if %(s > 0%.0%) {%s*sum %*= 0%.2270270270;',
  'vec4 sum = Texel(tex, tc) * 0.2270270270;')
 reference=reference:gsub('}%s*if %(boost > 0%.5%) {','if (boost > 0.5) {')
 assert(reference~=optimized)
 local g=love.graphics;local a,b=g.newShader(reference),g.newShader(optimized)
 local w,h=128,96;local data=love.image.newImageData(w,h)
 for y=0,h-1 do for x=0,w-1 do data:setPixel(x,y,(x%7)/6,(y%5)/4,((x+y)%11)/10,1)end end
 local input=g.newImage(data);input:setFilter('linear','linear');data:release()
 local first,second=g.newCanvas(w,h),g.newCanvas(w,h);first:setFilter('linear','linear')
 local function render(shader,preset)
  g.push('all');g.origin();g.setScissor();g.setDepthMode();g.setMeshCullMode('none');g.setBlendMode('replace');g.setColor(1,1,1,1);g.setShader(shader)
  shader:send('focusY',.5);shader:send('band',preset[1]);shader:send('range',preset[2]);shader:send('spacing',preset[3]);shader:send('saturation',preset[4])
  g.setCanvas(first);shader:send('dir',{1/w,0});shader:send('boost',0);g.draw(input)
  g.setCanvas(second);shader:send('dir',{0,1/h});shader:send('boost',1);g.draw(first);g.pop()
  return second:newImageData()
 end
 for _,p in ipairs{{.14,.42,.75,1.10},{.10,.36,1.5,1.18},{.07,.30,3,1.28}}do
  local expected,actual=render(a,p),render(b,p);local maxError=0
  for y=0,h-1 do for x=0,w-1 do
   local r,g,b,a=expected:getPixel(x,y);local rr,gg,bb,aa=actual:getPixel(x,y)
   maxError=math.max(maxError,math.abs(r-rr),math.abs(g-gg),math.abs(b-bb),math.abs(a-aa))
  end end
  assert(maxError<=1.01/255,'sharp-band optimization changed blur: '..maxError)
  print('TILT_SHIFT_MAX_ERROR',maxError);expected:release();actual:release()
 end
 input:release();first:release();second:release();a:release();b:release()
 print('PASS_RENDER_OPTIMIZATIONS');love.event.quit(0)
end
