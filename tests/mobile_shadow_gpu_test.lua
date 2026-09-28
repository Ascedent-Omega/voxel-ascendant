-- Run in native LÖVE. Mobile OS receipts exercise real GPU production code;
-- this is not a physical phone certification.
local root=assert(arg[1]);local g=love.graphics
for _,prefix in ipairs({'','gen2/'}) do
 for _,platform in ipairs({'iOS','Android','OS X'}) do
  local modules={CanvasPresentation={OS=platform},VoxelState={angle=.65,FOCAL=240},
    Quality={shadowsOff=function()return false end,shadowSizes=function()return{512,1024}end,shadowTarget=function()return 1.4 end},
    Gen1CavePanoramas={maps={},extensionMaps={}}}
  local V={require=function(n)
    if not modules[n] then
      local path=root..'/'..prefix..'lib/'..n..'.lua'
      local f=loadfile(path) or assert(loadfile(root..'/lib/'..n..'.lua'))
      modules[n]=f(V)
    end
    return modules[n]
  end}
  -- Lua's local isn't in scope inside its own initializer.
  V.require=function(n)
    if not modules[n] then
      local f=loadfile(root..'/'..prefix..'lib/'..n..'.lua') or assert(loadfile(root..'/lib/'..n..'.lua'))
      modules[n]=f(V)
    end
    return modules[n]
  end
  local S=V.require('ShadowMap');local D=V.require('DeviceShadows')
  local outer=g.newCanvas(96,64,{dpiscale=1});local depth=g.newCanvas(96,64,{format='depth16',readable=false,dpiscale=1})
  g.setCanvas{outer,depthstencil=depth};g.setScissor(3,4,21,22);g.setColor(.2,.3,.4,.5)
  g.setDepthMode('less',false);g.translate(7,9)
  assert(S.available(),prefix..platform..' '..tostring(D.reason))
  if D.mobile then
    assert(D.state=='ready' and D.resolution==512)
    local bound=g.getCanvas();assert((type(bound[1])=='table' and bound[1][1] or bound[1])==outer,'probe lost colour attachment');assert((type(bound.depthstencil)=='table' and bound.depthstencil[1] or bound.depthstencil)==depth,'probe lost depth attachment')
    local x,y,w,h=g.getScissor();assert(x==3 and y==4 and w==21 and h==22,'probe lost scissor')
    local tx,ty=g.transformPoint(0,0);assert(tx==7 and ty==9,'probe lost transform')
  end
  assert(S.begin(64,64,128,96))
  if D.mobile then
    assert(S.res==512,'unbounded phone shadow size');assert(g.getScissor()==nil,'inherited crop cuts shadow map')
  end
  S.finish('test');assert(S.active())
  if D.mobile then local bound=g.getCanvas();assert((type(bound[1])=='table' and bound[1][1] or bound[1])==outer,'pass lost nested attachment') end
  assert(S.begin(64,64,128,96));S.abort();assert(not S.active())
  g.setCanvas();g.origin();g.setScissor();g.setDepthMode();g.setColor(1,1,1,1)
  if D.mobile then
    assert(S.protected(function()assert(S.begin(64,64,128,96));error('injected caster failure')end)==false)
    assert(not S.active() and not S.available(),'failed caster did not latch fallback')
  end
  S.invalidate();outer:release();depth:release()
  print('PASS native shadow GPU '..prefix..platform..' probe, depth, orientation, nested canvas, abort')
 end
end
for _,platform in ipairs({'iOS','Android'}) do
 local noop=function()end
 local modules={CanvasPresentation={OS=platform},VoxelState={angle=.65,FOCAL=240},
  Gen1CavePanoramas={maps={},extensionMaps={}},VoxelGrid={},WorldCurve={},Sky={},DayNight={},GlassMask={},
  Shadows={enabled=function()return true end}}
 local V={}
 V.require=function(n)
  if not modules[n] then modules[n]=assert(loadfile(root..'/lib/'..n..'.lua'))(V) end
  return modules[n]
 end
 local gpu=V.require('Voxel3D');local sh=assert(gpu.shader(false))
 assert(sh:hasUniform('sunMap'),'device-admitted receiver lacks shadows')
 assert(sh:hasUniform('sunModel'),'actor caster transform missing')
 for _,variant in ipairs({'mobile-core','mobile-shadow','mobile-shadow-aerial','full','mobile-safe'}) do
  for _,lit in ipairs({false,true}) do
   local raw=assert(gpu._shaderSource(variant,false,lit))
   local compiled=g.newShader(raw)
   if variant:find('mobile-shadow',1,true) then
    local target=g.newCanvas(32,32,{format='rgba8',dpiscale=1})
    local data=love.image.newImageData(1,1);data:setPixel(0,0,1,1,1,1)
    local white=g.newImage(data);data:setPixel(0,0,63/255,.75,0,1)
    local packed=g.newImage(data);data:release()
    local mesh=g.newMesh(gpu.FORMAT,{{-.9,-.9,0,0,0,1},{.9,-.9,0,1,0,1},{.9,.9,0,1,1,1},{-.9,.9,0,0,1,1}},'fan','static')
    mesh:setTexture(white)
    local function send(n,... )if compiled:hasUniform(n)then compiled:send(n,...)end end
    for name in raw:gmatch('uniform Image ([%w_]+)')do send(name,white)end
    local id={1,0,0,0,0,1,0,0,0,0,1,0,0,0,0,1}
    send('vp','row',id);send('model','row',id);send('sunModel','row',id)
    send('sunVP','row',{0,0,0,.5,0,0,0,.5,0,0,0,.5,0,0,0,1})
    send('dayTint',{1,1,1});send('actorWaterline',-100);send('eye',{0,0,3})
    send('sunReceive',1);send('sunMap',packed);send('sunTexel',{1/512,1/512})
    local function draw(dark)
     send('sunDark',dark);g.setCanvas(target);g.setShader(compiled);g.clear(0,0,0,1)
     g.setBlendMode('replace');g.setColor(1,1,1,1);g.draw(mesh);g.setShader();g.setCanvas()
     local pixels=target:newImageData();local r=pixels:getPixel(16,16);pixels:release();return r
    end
    local light,shade=draw(0),draw(.4)
    assert(light>.9 and shade>.5 and shade<.7,variant..' receiver pixels '..light..'/'..shade)
    send('sunReceive',0);assert(draw(.4)>.9,'presentation cards self-shadowed')
    mesh:release();packed:release();white:release();target:release()
    g.setBlendMode('alpha');g.setColor(1,1,1,1)
   end
   compiled:release()
   local out=os.getenv('VASC_SHADER_OUT')
   if out then
    for _,gles in ipairs({false,true})do
     local vert,frag=g._shaderCodeToGLSL(gles,raw)
     local stem=out..'/'..variant..'-'..tostring(lit)..(gles and '-gles' or '-gl')
     for ext,code in pairs({vert=vert,frag=frag})do local f=assert(io.open(stem..'.'..ext,'w'));f:write(code);f:close()end
    end
   end
  end
 end
 assert(gpu.unlitShader(false):hasUniform('sunMap'),'lighting OFF lost shadows')
 print('PASS native production receivers '..platform..': lit, unlit, aerial fallback, core and desktop')
end
