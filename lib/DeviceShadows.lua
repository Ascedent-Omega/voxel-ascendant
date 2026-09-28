-- Per-renderer shadow admission. No phone-model allowlist and no saved result:
-- a driver/OS change is tested again next launch. Desktop keeps its old path.
local V = ...
local P = V.require('CanvasPresentation')
local D = { mobile = P.OS == 'iOS' or P.OS == 'Android', resolution = 512,
            flipY = false, state = 'untested', reason = nil }
local identity = {1,0,0,0, 0,1,0,0, 0,0,1,0, 0,0,0,1}
local function release(o) if o and o.release then pcall(o.release,o) end end
function D.fail(reason)
  D.state, D.reason = 'unsupported', tostring(reason)
  print('VASC device shadows: '..tostring(P.OS)..' fallback: '..D.reason)
  return false
end
function D.enabled() return not D.mobile or D.state == 'ready' end

-- Use the production depth writer, explicit linear colour and a persistent
-- depth attachment. Draw near, then far at the SAME coordinates: readback
-- must prove depth rejection as well as packed precision and UV orientation.
-- The sample shader reads texture coordinates directly; it does not inherit
-- the game's rotated/flipped screen presenter or its viewport transform.
function D.prepare(writer)
  if not D.mobile then return true end
  if D.state ~= 'untested' then return D.enabled() end
  D.state = 'testing'
  local g = love.graphics
  local owned, pushed = {}, false
  local function own(o) owned[#owned+1]=o; return o end
  local function canvas(w,h,opts)
    local ok,c=V.require('PixelCanvas').new(w,h,opts)
    if not ok then error(c,0) end
    return own(c)
  end
  local ok,err=pcall(function()
    local renderer,version,vendor,device=g.getRendererInfo()
    D.renderer=table.concat({renderer or '',version or '',vendor or '',device or ''},' / ')
    local limit=g.getSystemLimits().texturesize or 0
    assert(limit>=256,'texture size below 256')
    D.resolution=limit>=512 and 512 or 256
    local map=canvas(D.resolution,D.resolution,{format='rgba8',msaa=0})
    map:setFilter('nearest','nearest');map:setWrap('clamp','clamp')
    local depth
    for _,format in ipairs({'depth16','depth24','depth32f'}) do
      local made,c=V.require('PixelCanvas').new(D.resolution,D.resolution,{format=format,readable=false,msaa=0})
      if made then depth=own(c);D.depthFormat=format;break end
    end
    assert(depth,'no usable depth attachment')
    local out=canvas(1,1,{format='rgba8',msaa=0})
    local sample=own(g.newShader([[
      uniform Image shadow;
      vec4 effect(vec4 c, Image t, vec2 uv, vec2 sc) {
        vec4 a=Texel(shadow,vec2(.25,.25));
        vec4 b=Texel(shadow,vec2(.25,.75));
        return vec4(a.r+a.g/255.0,b.r+b.g/255.0,0.0,1.0);
      }
    ]]))
    local function quad(z)
      return own(g.newMesh({{'VertexPosition','float',3},{'VertexTexCoord','float',2},{'VertexShade','float',1}},
        {{-.8,-.8,z,0,0,1},{-.2,-.8,z,1,0,1},{-.2,-.2,z,1,1,1},{-.8,-.2,z,0,1,1}},'fan','static'))
    end
    local near,far=quad(-.5),quad(.5)
    g.push('all');pushed=true
    g.origin();g.setScissor();g.setStencilTest();g.setColorMask(true,true,true,true)
    g.setCanvas({map,depthstencil=depth});g.clear(1,1,0,1,0,1)
    g.setDepthMode('lequal',true);g.setMeshCullMode('none')
    g.setBlendMode('replace','premultiplied');g.setColor(1,1,1,1)
    g.setShader(writer)
    writer:send('lightVP','row',identity);writer:send('model','row',identity)
    writer:send('sprite',0)
    if writer:hasUniform('objectOnly') then writer:send('objectOnly',0) end
    g.draw(near);g.draw(far)
    g.setCanvas(out);g.setDepthMode();g.setShader(sample);sample:send('shadow',map)
    g.rectangle('fill',0,0,1,1)
    g.setCanvas();g.setShader()
    local pixels=own(out:newImageData());local a,b=pixels:getPixel(0,0)
    local direct=math.abs(a-.25)<.012 and b>.98
    local flipped=math.abs(b-.25)<.012 and a>.98
    assert(direct or flipped,'packed depth/UV/depth-test mismatch: '..a..','..b)
    D.flipY=flipped
  end)
  local restored,restoreError=true,nil
  if pushed then restored,restoreError=pcall(g.pop) end
  for i=#owned,1,-1 do release(owned[i]) end
  if not restored then error('shadow probe graphics restore failed: '..tostring(restoreError),0) end
  if not ok then return D.fail(err) end
  D.state='ready'
  print('VASC device shadows: '..tostring(P.OS)..' '..tostring(D.renderer)..' ready '..D.resolution..'px, flipY='..tostring(D.flipY))
  return true
end
return D
