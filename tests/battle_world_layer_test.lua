-- Real GPU comparison: color/depth cache, changing inputs, draw range, barriers.
local V={};local modules={}
function V.require(n)if not modules[n]then modules[n]=assert(loadfile('lib/'..n..'.lua'))(V)end;return modules[n]end
local C=V.require('BattleWorldLayer');local R=V.require('RasterResources');local O=V.require('OpaqueProgram')
O.observe=C.changed
local g=love.graphics
C.preparePrograms()
local source=[[
#pragma language glsl3
#ifdef VERTEX
uniform vec3 offset;
vec4 position(mat4 matrix,vec4 pos){return vec4(pos.xyz+offset,1.0);}
#endif
#ifdef PIXEL
uniform vec3 tint;
uniform Image mask;
vec4 effect(vec4 color,Image tex,vec2 uv,vec2 pixel){vec4 p=Texel(tex,uv);if(p.a<.5)discard;return vec4(p.rgb*tint*Texel(mask,uv).rgb,1)*color;}
#endif
]]
local shader=g.newShader(source);O.register(shader,source);local p=O.wrap(shader)
local mesh=R.seal(g.newMesh({{'VertexPosition','float',3},{'VertexTexCoord','float',2}},{{-.9,-.8,0,0,0},{.7,-.8,0,1,0},{.7,.2,0,1,1},{-.9,-.8,0,0,0},{.7,.2,0,1,1},{-.9,.2,0,0,1}},'triangles','static'))
local d=love.image.newImageData(4,4);d:mapPixel(function(x,y)return x/3,y/3,.2,(x==0 and y==2)and 0 or 1 end)
local tex=R.seal(g.newImage(d));tex:setFilter('nearest','nearest');mesh:setTexture(tex)
local slot={w=64,h=48,canvas=g.newCanvas(64,48,{dpiscale=1}),depth=g.newCanvas(64,48,{format='depth24stencil8',readable=true,dpiscale=1})}
slot.depth:setDepthSampleMode();slot.depth:setFilter('nearest','nearest')
local maskData=love.image.newImageData(1,1);maskData:setPixel(0,0,1,1,1,1)
local mask=R.seal(g.newImage(maskData));p:send('mask',mask)
assert(p.resources.mask,'sampler not indexed')
local offset={0,0,0};local tint={1,1,1};local bg={.1,.2,.3,1};local mode=0
local function frame(enabled)
 C.enabled=enabled;g.setCanvas({slot.canvas,depthstencil=slot.depth});g.clear(bg,true,true)
 g.origin();g.setShader(shader);g.setColor(1,1,1,1);g.setBlendMode('alpha','alphamultiply');g.setDepthMode('lequal',true);g.setMeshCullMode('none')
 p:send('offset',offset);p:send('tint',tint)
 local begun=C.begin(slot);if enabled then assert(begun,tostring(C.lastError))end
 if not C.draw(p,mesh,tex)then g.draw(mesh)end
 if mode==1 then
  p:send('offset',{.15,.15,-.3});p:send('tint',{.2,1,.7})
  if not C.draw(p,mesh,tex)then g.draw(mesh)end
 elseif mode==2 then
  -- Flush postponed commands before content mutation, then draw with new data.
  R.changing(tex);d:setPixel(2,2,.9,.1,.6,1);tex:replacePixels(d)
 end
 C.finish()
 -- Moving foreground geometry tests that cached depth is restored as well.
 p:send('offset',{-.4,-.3,.2});p:send('tint',{.8,.2,.7});g.draw(mesh)
 g.setShader();g.setDepthMode();g.setCanvas()
 local data=slot.canvas:newImageData();local bytes=data:getString();data:release();return bytes
end
local function compare(label)
 local reference=frame(false)
 for i=1,4 do assert(frame(true)==reference,label..' mismatch at '..i..' '..tostring(C.lastError))end
 print('PASS',label,C.hits,C.captures,C.misses)
end
compare('stable');assert(C.hits>0,'cache never hit')
bg={.4,.1,.5,1};compare('live sky behind alpha holes')
offset[1]=.1;compare('camera changes');tint[2]=.7;compare('uniform changes')
mode=1;compare('added draw');mode=0;compare('removed draw')
mesh:setDrawRange(1,3);compare('draw range');mesh:setDrawRange();compare('full draw range')
R.changing(tex);d:setPixel(1,1,.2,.9,.5,1);tex:replacePixels(d);compare('same texture identity new pixels')
mode=2;frame(true);mode=0;compare('upload barrier')
R.changing(mask);maskData:setPixel(0,0,.4,.7,.9,1);mask:replacePixels(maskData);compare('same sampler new pixels')
local untrusted=g.newImage(maskData);p:send('mask',untrusted);compare('unknown sampler fallback');assert(C.lastBarrier=='mask')
p:send('mask',mask);compare('certified sampler restored')
C.release(slot);compare('slot release and rebuild')
offset[3]=1;compare('coverage at exact far plane');offset[3]=0
compare('before driver failure')
local draw=g.draw;local failed=false
local cached=slot.battleWorldLayer.color
local reference=frame(false)
g.draw=function(object,...)
 if object==cached and not failed then failed=true;error('injected restore refusal')end
 return draw(object,...)
end
assert(frame(true)==reference,'restore failure changed normal fallback')
g.draw=draw;assert(failed and slot.battleWorldLayer.failed,'driver refusal not latched')
C.release(slot);compare('explicit retry after driver refusal')
-- A foreign pass changes target/scissor before its first observed draw.
-- The postponed prefix must still land on its own scene and restore the caller.
frame(true)
g.setCanvas({slot.canvas,depthstencil=slot.depth});g.clear(.1,.2,.3,1,true,true)
g.setShader(shader);g.setColor(1,1,1,1);g.setDepthMode('lequal',true)
p:send('offset',offset);p:send('tint',tint);C.begin(slot)
assert(C.draw(p,mesh,tex),'expected postponed prefix')
local foreign=g.newCanvas(64,48);g.setCanvas(foreign);g.clear(0,0,0,0);g.setScissor(0,0,1,1)
assert(not C.draw(p,mesh,tex),'foreign target admitted')
assert(g.getCanvas()==foreign,'caller target lost');local x,y,w,h=g.getScissor();assert(w==1 and h==1,'caller scissor lost')
g.setCanvas();g.setScissor();g.setShader();g.setDepthMode()
local untouched=foreign:newImageData();assert(untouched:getString()==string.rep('\0',64*48*4),'cached prefix drawn on foreign target');untouched:release();foreign:release()
assert(R.revision(g.newImage(d))==nil,'unknown mutable image certified')
print('PASS battle world color/depth exact GPU comparisons')
-- Exact camera/shadow changes bypass receipt collection until stable again.
C.release(slot);C.enabled=true
local vp={1,0,0,0,0,1,0,0,0,0,1,0,0,0,0,1}
local shadow=R.seal({});local gateProgram={values={sunDark={1},sunMap={shadow}}}
assert(not C.begin(slot,vp,gateProgram));assert(C.begin(slot,vp,gateProgram));C.finish()
vp[4]=.00000001;assert(not C.begin(slot,vp,gateProgram),'camera threshold introduced')
assert(C.begin(slot,vp,gateProgram));C.finish();R.changing(shadow)
assert(not C.begin(slot,vp,gateProgram),'new shadow depth ignored')
C.release(slot);C.enabled='auto';assert(not C.begin(slot),'small target selected by auto')
C.minimumPixels=1;C.minimumCommands=32;assert(C.begin(slot));C.finish()
assert(not C.begin(slot),'short command stream selected by auto')
C.release(slot);print('PASS exact motion/shadow gates and conservative cost admission')
