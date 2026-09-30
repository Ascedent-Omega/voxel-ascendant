-- Observe CPU pixels only while a synchronous native battle call creates its
-- images. No persistent graphics hook and no inference from species/path alone:
-- the receipt belongs to the exact Image and bytes uploaded through core LOVE.
local Sources = { captures = 0 }
local images = setmetatable({}, { __mode = 'k' })
local dataPaths = setmetatable({}, { __mode = 'k' })
local assets, graphics, upload, loadData, wrappedUpload, wrappedData
local active,unavailable = false,false
local ring=setmetatable({}, {__mode='v'})
local sizes,position,totalBytes={},0,0
local MAX_BYTES,MAX_IMAGES=4*1024*1024,128
local function reserve(bytes)
  repeat
    position=position%MAX_IMAGES+1
    if ring[position] then images[ring[position]]=nil end
    ring[position]=nil
    totalBytes=totalBytes-(sizes[position]or 0);sizes[position]=nil
  until totalBytes+bytes<=MAX_BYTES
  sizes[position]=bytes;totalBytes=totalBytes+bytes
  return position
end
local function remember(image, data)
  local path = dataPaths[data]
  if not path or not data.typeOf or not data:typeOf('ImageData')
      or data:getFormat() ~= 'rgba8' then return end
  local w,h = data:getDimensions()
  -- Large/custom art stays on its provider's normal path. These receipts are
  -- for native battle pics, not an unbounded copy of all GPU assets.
  if w <= 0 or h <= 0 or w*h > 65536 then return end
  local iw,ih = image:getDimensions()
  local pw,ph = image:getPixelDimensions()
  if iw ~= w or ih ~= h or pw ~= w or ph ~= h then return end
  local bytes = data:getString()
  if #bytes ~= w*h*4 then return end
  local slot=reserve(#bytes)
  images[image] = {path=path,w=w,h=h,bytes=bytes}
  ring[slot]=image
  Sources.captures = Sources.captures + 1
end
local function initialize()
  local ok,value = pcall(require,'src.render.Assets')
  if not ok or type(value) ~= 'table' then return false end
  local g = love and love.graphics
  if not (g and type(g.newImage)=='function' and type(value.imageData)=='function'
      and type(string.dump)=='function') then return false end
  -- A foreign upload wrapper may modify pixels before/after uploading. Its
  -- provenance cannot be proved here, so leave it entirely untouched.
  -- Standard Lua can dump Lua functions but never C functions. This uses no
  -- debug library (the mod sandbox deliberately does not expose one).
  if pcall(string.dump,g.newImage) then return false end
  assets,graphics,upload,loadData = value,g,g.newImage,value.imageData
  local function loaded(path,data,...)
    if active and type(path)=='string' and path:sub(1,23)=='assets/generated/battle'
        and path:sub(24,24)=='/' and type(data)=='userdata' then dataPaths[data]=path end
    return data,...
  end
  wrappedData = function(path,...)
    return loaded(path,loadData(path,...))
  end
  wrappedUpload = function(data,...)
    local image = upload(data,...)
    -- The core upload has completed; copying its unmodified input is optional.
    -- A receipt failure must never turn a successful image upload into a fault.
    if active and dataPaths[data] then
      pcall(remember,image,data)
    end
    return image
  end
  return true
end
local function finish(ok,...)
  active = false
  if graphics.newImage == wrappedUpload then graphics.newImage = upload end
  if assets.imageData == wrappedData then assets.imageData = loadData end
  if not ok then error((...),0) end
  return ...
end
function Sources.capture(fn,...)
  if active then return fn(...) end
  if unavailable then return fn(...) end
  if not graphics and not initialize() then unavailable=true;return fn(...) end
  -- If another owner changes either seam after initialization, fail open.
  -- Retained wrappers also delegate inertly after this scope has ended.
  if graphics.newImage ~= upload or assets.imageData ~= loadData
      or (graphics.isGammaCorrect and graphics.isGammaCorrect()) then
    return fn(...)
  end
  active = true
  graphics.newImage,assets.imageData = wrappedUpload,wrappedData
  return finish(pcall(fn,...))
end
function Sources.get(image)
  return images[image]
end
function Sources.invalidate()
  ring=setmetatable({}, {__mode='v'});sizes,position,totalBytes={},0,0
  unavailable=false
  images = setmetatable({}, { __mode = 'k' })
  dataPaths = setmetatable({}, { __mode = 'k' })
end
return Sources
