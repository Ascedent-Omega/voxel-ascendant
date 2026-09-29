return function(game)
 assert(os.getenv('POKEPORT_IDENTITY')=='vasc-video-polish-qa');love.audio.setVolume(0)
 local root=assert(os.getenv('QA_VASC_ROOT'));local g=love.graphics
 local modules={PixelCanvas={new=function(w,h)local ok,c=pcall(g.newCanvas,w,h,{dpiscale=1});return ok,c end}}
 local T=assert(loadfile(root..'/lib/TiltShift.lua')){require=function(n)return assert(modules[n],n)end}
 local w,h=800,450;local data=love.image.newImageData(w,h)
 for y=0,h-1 do for x=0,w-1 do
  local checker=(math.floor(x/24)+math.floor(y/24))%2
  data:setPixel(x,y,.15+.6*checker,.2+.5*x/w,.1+.7*y/h,1)
 end end
 local input=g.newImage(data);data:release();input:setFilter('nearest','nearest')
 local function render(optimized)
  T.optimized=optimized;g.push('all');g.origin();g.setScissor();g.setDepthMode();g.setMeshCullMode('none')
  local c=T.apply(input);assert(c~=input,'blur fell back');g.pop();return c:newImageData()
 end
 for level=1,3 do
  T.setLevel(level);local a=render(false);local b=render(true)
  local band,mean,allmax,n=0,0,0,0
  for y=0,h-1 do for x=0,w-1 do
   local r,gg,bb=a:getPixel(x,y);local r2,g2,b2=b:getPixel(x,y)
   local e=math.max(math.abs(r-r2),math.abs(gg-g2),math.abs(bb-b2))
   if math.abs((y+.5)/h-.5)<T.PRESETS[level].band-.005 then band=math.max(band,e)end
   mean=mean+e;n=n+1;allmax=math.max(allmax,e)
  end end
  assert(band<=1.01/255,'sharp band changed '..band)
  assert(mean/n<.035,'excess blur deviation '..mean/n)
  print('BLUR_QUALITY',level,'band',band,'mean',mean/n,'max',allmax)
  local dir=os.getenv('SHOT_DIR');if dir then
   for _,p in ipairs{{a,'reference'},{b,'reduced'}}do local bytes=p[1]:encode('png');local f=assert(io.open(dir..'/blur-'..level..'-'..p[2]..'.png','wb'));f:write(bytes:getString());f:close();bytes:release()end
  end
  a:release();b:release()
 end
 T.setLevel(0);assert(T.apply(input)==input);T.invalidate();T.invalidate();input:release()
 print('PASS_BLUR_QUALITY');love.event.quit(0)
end
