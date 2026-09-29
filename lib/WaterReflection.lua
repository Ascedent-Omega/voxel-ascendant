-- The distorted reflection needs fewer pixels than the visible world. Keep
-- the scene/depth used by water at full resolution; only its colour source
-- and the extra cast pass use this smaller, persistent target.
local V=...
local M={scale=.5}
local shader
local source=[[
#pragma language glsl3
uniform Image sourceDepth;
vec4 effect(vec4 color,Image tex,vec2 uv,vec2 pixel) {
  gl_FragDepth=Texel(sourceDepth,pixel/love_ScreenSize.xy).r;
  return Texel(tex,uv)*color;
}
]]
M._source=source
function M.prepareProgram()
  if shader~=nil then return false end
  local ok,result=pcall(love.graphics.newShader,source)
  shader=ok and result or false
  M.lastError=not ok and tostring(result) or nil
  return true
end
local function release(object)
  if object and object.release then pcall(object.release,object) end
end
function M.release(slot)
  local target=slot.waterReflection
  if target then release(target.color);release(target.depth) end
  slot.waterReflection=nil
end
function M.prepare(slot)
  if not (slot and slot.depth) then return end
  if slot.waterReflection~=nil then return slot.waterReflection or nil end
  M.prepareProgram()
  if not shader then slot.waterReflection=false;return end
  -- Small native/retro targets retain their original pixel density.
  local scale=slot.w>=640 and slot.h>=360 and M.scale or 1
  local w,h=math.max(1,math.ceil(slot.w*scale)),math.max(1,math.ceil(slot.h*scale))
  local PixelCanvas=V.require('PixelCanvas')
  local ok,color=PixelCanvas.new(w,h)
  if not ok or not color then slot.waterReflection=false;M.lastError=tostring(color);return end
  local depthOK,depth=PixelCanvas.new(w,h,{format=slot.depth:getFormat(),readable=false})
  if not depthOK or not depth then
    release(color);slot.waterReflection=false;M.lastError=tostring(depth);return
  end
  color:setFilter('nearest','nearest');color:setWrap('clamp','clamp')
  local target={color=color,depth=depth,w=w,h=h}
  slot.waterReflection=target
  return target
end
function M.draw(slot,paint,sceneShader)
  local target=M.prepare(slot)
  if not target then return end
  local g=love.graphics
  local ok,err=pcall(g.setCanvas,{target.color,depthstencil=target.depth})
  if not ok then
    M.release(slot);slot.waterReflection=false;M.lastError=tostring(err);return
  end
  -- Copy colour and terrain depth together. This private depth buffer lets
  -- nearer cast geometry reject hidden fragments without touching the scene
  -- depth sampled by the subsequent full-resolution water pass.
  g.setDepthMode('always',true);g.setBlendMode('replace');g.setColor(1,1,1,1)
  g.setShader(shader);shader:send('sourceDepth',slot.depth)
  g.draw(slot.canvas,0,0,0,target.w/slot.w,target.h/slot.h)
  g.setBlendMode('alpha');g.setDepthMode('lequal',true);g.setShader(sceneShader)
  if paint and sceneShader then
    local painted,message=pcall(paint)
    M.lastPaintError=not painted and tostring(message) or nil
  end
  g.setShader();g.setDepthMode();g.setCanvas(slot.canvas)
  return target.color,slot.depth
end
function M.invalidate()
  release(shader);shader=nil;M.lastError=nil;M.lastPaintError=nil
end
return M
