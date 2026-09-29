-- Voxel world mode: tilt-shift post-process (the miniature-diorama look).
--
-- A depth-of-field fake that reads perfectly on a tilted voxel scene: a
-- horizontal band through the view centre (where the camera focuses -- the
-- player) stays sharp, and the frame blurs progressively toward the top
-- and bottom edges, with a slight saturation lift to sell the model-photo
-- feel. It runs on the finished voxel canvas as two separable gaussian
-- passes, so it costs two fullscreen draws and touches nothing in the 3D
-- pass itself.
--
-- This is a render pipeline in its own right -- a worldPresent pass, which
-- is the stage that post-processes the finished world BEFORE the UI
-- composites over it. That placement is the whole point: a miniature-photo
-- blur belongs on the diorama, not on the dialog box in front of it.
--
-- The engine owns the level: the T-SHIFT options row, its hotkey, the
-- OFF -> 1 -> 2 -> 3 -> OFF ladder and persistence in
-- save.options.pipelines all come from the render_pipelines record in
-- main.lua, and the current level arrives through update(). Each step
-- narrows the sharp band, deepens the blur and pushes the saturation a
-- little further.
--
-- Because worldPresent only runs when some pipeline rendered the world,
-- this draws over the voxel scene and nothing else. With it off (or on any
-- failure -- headless, no shader support) apply() hands the canvas back
-- untouched, so every other path is byte-for-byte what it always was.

local V = ...
-- Reduced intermediates remain opt-in until they show a frame-time win.
local TiltShift = { optimized = false }

TiltShift.level = 0
TiltShift.LABELS = { "OFF", "1", "2", "3" }

-- The strength ladder. `spacing` is the gap between the gaussian's taps
-- at full blur, as a fraction of the canvas height (so the miniature
-- reads the same in a window and fullscreen; the blur's reach is 4x the
-- spacing per pass, and the two passes compound). `band` is the
-- half-height of the fully sharp zone and `range` the ramp to full blur,
-- both in canvas-uv units. The focus line sits at the vertical centre
-- because that is where the voxel camera parks the player.
TiltShift.FOCUS_Y = 0.5
TiltShift.PRESETS = {
  [1] = { spacing = 0.0016, band = 0.14, range = 0.42, saturation = 1.10 },
  [2] = { spacing = 0.0028, band = 0.10, range = 0.36, saturation = 1.18 },
  [3] = { spacing = 0.0042, band = 0.07, range = 0.30, saturation = 1.28 },
}

local SHADER = [[
  uniform vec2 dir;        // one texel step along the axis being blurred
  uniform float focusY;
  uniform float band;
  uniform float range;
  uniform float spacing;   // gap between taps at full blur, in texels
  uniform float boost;     // 0 = plain blur pass, 1 = final pass (color pop)
  uniform float saturation;
  vec4 effect(vec4 color, Image tex, vec2 tc, vec2 sc) {
    float d = abs(tc.y - focusY) - band;
    float s = clamp(d / range, 0.0, 1.0);
    s = s * s;             // ease in, so the band edge has no visible seam
    // 9 taps a small step apart: dense enough that even the strongest
    // preset blurs smoothly instead of ghosting into streaks
    vec2 o = dir * (s * spacing);
    // Inside the sharp band all nine taps address exactly the same pixel.
    // Keep its original sample; only the genuinely blurred rows need taps.
    vec4 sum = Texel(tex, tc);
    if (s > 0.0) {
    sum *= 0.2270270270;
    sum += (Texel(tex, tc + o) + Texel(tex, tc - o)) * 0.1945945946;
    sum += (Texel(tex, tc + 2.0 * o) + Texel(tex, tc - 2.0 * o)) * 0.1216216216;
    sum += (Texel(tex, tc + 3.0 * o) + Texel(tex, tc - 3.0 * o)) * 0.0540540541;
    sum += (Texel(tex, tc + 4.0 * o) + Texel(tex, tc - 4.0 * o)) * 0.0162162162;
    }
    if (boost > 0.5) {
      float luma = dot(sum.rgb, vec3(0.299, 0.587, 0.114));
      sum.rgb = mix(vec3(luma), sum.rgb, saturation);
    }
    return sum * color;
  }
]]

local COMPOSITE = [[
 uniform Image blurred;
 uniform float focusY;
 uniform float band;
 uniform float saturation;
 vec4 effect(vec4 color,Image tex,vec2 tc,vec2 sc) {
  vec4 sharp=Texel(tex,tc);
  float luma=dot(sharp.rgb,vec3(.299,.587,.114));
  sharp.rgb=mix(vec3(luma),sharp.rgb,saturation);
  float blend=smoothstep(0.0,.06,abs(tc.y-focusY)-band);
  return mix(sharp,Texel(blurred,tc),blend)*color;
 }
]]
local composite
local halfA,halfB,output,hw,hh,ow,oh
local function release(canvas)if canvas and canvas.release then canvas:release()end end
local function reducedCanvases(w,h)
 local rw,rh=math.ceil(w/2),math.ceil(h/2)
 if output and ow==w and oh==h then return halfA,halfB,output end
 local PixelCanvas=V.require('PixelCanvas')
 local ok,a=PixelCanvas.new(rw,rh);if not ok then return end
 local okB,b=PixelCanvas.new(rw,rh);if not okB then release(a);return end
 local okC,c=PixelCanvas.new(w,h);if not okC then release(a);release(b);return end
 a:setFilter('linear','linear');b:setFilter('linear','linear');c:setFilter('nearest','nearest')
 release(halfA);release(halfB);release(output)
 halfA,halfB,output,hw,hh,ow,oh=a,b,c,rw,rh,w,h
 return a,b,c
end

local shader = nil            -- nil = untried, false = unavailable
local ping, pong, cw, ch = nil, nil, 0, 0

local function getShader()
  if shader == nil then
    local ok, sh = pcall(function() return love.graphics.newShader(SHADER) end)
    shader = (ok and sh) or false
  end
  return shader or nil
end

local function getCanvases(w, h)
  if not ping or cw ~= w or ch ~= h then
    local PixelCanvas = V.require("PixelCanvas")
    local ok, a = PixelCanvas.new(w, h)
    if not ok then return nil end
    local okB, b = PixelCanvas.new(w, h)
    if not okB then release(a);return nil end
    -- the gaussian's fractional tap offsets need linear filtering
    a:setFilter("linear", "linear")
    b:setFilter("linear", "linear")
    release(ping);release(pong)
    ping, pong, cw, ch = a, b, w, h
  end
  return ping, pong
end

function TiltShift.setLevel(level)
  level = math.floor(tonumber(level) or 0)
  if level < 0 then level = 0 end
  if level > 3 then level = 3 end
  TiltShift.level = level
end

-- The pipeline's per-frame tick: the engine hands over the level the
-- player has the T-SHIFT row set to.  No tween -- unlike the camera angle,
-- a blur strength has nothing to ease through.
function TiltShift.update(_, level)
  TiltShift.setLevel(level)
end

function TiltShift.levelLabel(level)
  return TiltShift.LABELS[(level or TiltShift.level) + 1] or "OFF"
end

function TiltShift.active()
  return TiltShift.level > 0
end

function TiltShift.reset()
  TiltShift.level = 0
end

-- Run the effect over `canvas` and return the processed canvas. Returns
-- the input unchanged when the effect is off or cannot run (headless, no
-- shader support), so the caller composites exactly what it was handed.
function TiltShift.apply(canvas)
  local preset = TiltShift.PRESETS[TiltShift.level]
  if not (preset and canvas) then return canvas end
  local sh = getShader()
  if not sh then return canvas end
  local w, h = canvas:getDimensions()
  local reduced=TiltShift.optimized and w>=640 and h>=360
  if reduced and composite==nil then
    local ok,c=pcall(love.graphics.newShader,COMPOSITE);composite=ok and c or false
  end
  reduced=reduced and composite~=false
  local a,b,result
  if reduced then a,b,result=reducedCanvases(w,h)else a,b=getCanvases(w,h)end
  if not a then return canvas end

  local spacing = math.max(0.75, math.min(3, h * preset.spacing))
  local prevBlend, prevAlpha = love.graphics.getBlendMode()

  -- the voxel canvas filters nearest for its 1:1 blit; the blur taps need
  -- linear, restored below so the composite path sees what it expects
  canvas:setFilter("linear", "linear")
  love.graphics.setShader(sh)
  love.graphics.setColor(1, 1, 1, 1)
  -- replace, not alpha-blend: these are image-processing copies
  love.graphics.setBlendMode("replace", "premultiplied")
  pcall(sh.send, sh, "focusY", TiltShift.FOCUS_Y)
  pcall(sh.send, sh, "band", preset.band)
  pcall(sh.send, sh, "range", preset.range)
  pcall(sh.send, sh, "spacing", spacing)
  pcall(sh.send, sh, "saturation", preset.saturation)

  local ok = pcall(function()
    love.graphics.setCanvas(a)
    pcall(sh.send, sh, "dir", { 1 / w, 0 })
    pcall(sh.send, sh, "boost", 0)
    love.graphics.draw(canvas,0,0,0,reduced and hw/w or 1,reduced and hh/h or 1)
    love.graphics.setCanvas(b)
    pcall(sh.send, sh, "dir", { 0, 1 / h })
    pcall(sh.send, sh, "boost", 1)
    love.graphics.draw(a)
    if reduced then
      love.graphics.setCanvas(result);love.graphics.setShader(composite)
      composite:send('blurred',b);composite:send('focusY',TiltShift.FOCUS_Y)
      composite:send('band',preset.band);composite:send('saturation',preset.saturation)
      -- Exact full-resolution source in the sharp band, with full-res UI
      -- still composited later by the engine.
      love.graphics.draw(canvas)
    end
  end)

  love.graphics.setCanvas()
  love.graphics.setShader()
  love.graphics.setBlendMode(prevBlend or "alpha", prevAlpha)
  canvas:setFilter("nearest", "nearest")
  return ok and (result or b) or canvas
end

-- Drop the GPU objects (window resize, hot reload).
function TiltShift.invalidate()
  release(ping);release(pong);release(halfA);release(halfB);release(output)
  ping, pong, cw, ch = nil, nil, 0, 0
  halfA,halfB,output,hw,hh,ow,oh=nil,nil,nil,nil,nil,nil,nil
end

return TiltShift
