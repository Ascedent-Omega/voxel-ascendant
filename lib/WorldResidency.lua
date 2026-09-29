-- Bounded return cache shared by terrain, animated atlases and scenery.
-- Current hosts expose no physical/available RAM API to mods. AUTO is a
-- conservative allowance, not a fabricated RAM measurement. Users can raise
-- the allowance explicitly; no filesystem, FFI or platform escape is used.
local V = ...
local M = {}
local MB = 1024 * 1024
M.setting = V.require('ModSetting').new('worldCacheMB', 'MAP CACHE',
  {'auto', 128, 256, 512, 1024, 2048},
  {'AUTO', '128 MB', '256 MB', '512 MB', '1 GB', '2 GB'}, 'auto')
local serial, used, sizes, retained = 0, {}, {}, {}
local platform
local function mobile()
  if platform == nil then
    local ok, api = pcall(require, 'src.core.Platform')
    local got, info = false, nil
    if ok and api.detect then got, info = pcall(api.detect) end
    platform = got and (info.mobile or info.console) == true or false
  end
  return platform
end
function M.budget()
  local value = tonumber(M.setting:get())
  return (value or (mobile() and 128 or 512)) * MB
end
function M.capacity()
  return math.max(3, math.min(32, math.floor(M.budget() / (32 * MB))))
end
-- Count unique mesh allocations including animation variants. Vertex storage
-- is conservatively doubled for the CPU/GPU copies; index storage is included.
-- A shared texture is owned by Assets, not by an individual cache entry.
function M.measure(entry)
  local seen, images, bytes = {}, {}, 0
  local function ownedImage(image)
    if not image or images[image] then return end
    images[image] = true
    local width,height = image:getDimensions()
    bytes = bytes + width * height * 8
  end
  local function walk(v)
    local t = type(v)
    if (t ~= 'table' and t ~= 'userdata') or seen[v] then return end
    seen[v] = true
    if v.typeOf and v:typeOf('Mesh') then
      bytes = bytes + v:getVertexCount() * 80
    elseif t == 'table' then
      if v.ownsTexture then ownedImage(v.texture) end
      ownedImage(v.materialMask)
      for _, value in pairs(v) do walk(value) end
    end
  end
  walk(entry)
  return bytes
end
function M.record(id, entry)
  sizes[id] = math.max(64 * 1024, M.measure(entry))
end
function M.touch(id)
  serial = serial + 1
  used[id] = serial
end
function M.keep(live)
  serial = serial + 1
  for id in pairs(live) do used[id] = serial end
  local rows = {}
  for id, age in pairs(used) do
    if not live[id] then rows[#rows + 1] = {id=id, age=age} end
  end
  table.sort(rows, function(a,b)
    if a.age == b.age then return a.id < b.id end
    return a.age > b.age
  end)
  local keep, count, bytes = {}, 0, 0
  local limit, capacity = M.budget() * .65, M.capacity()
  -- Required visible geometry is never evicted to accommodate optional history.
  for id in pairs(live) do
    keep[id], count = true, count + 1
    bytes = bytes + (sizes[id] or 8 * MB)
  end
  for _, row in ipairs(rows) do
    local size = sizes[row.id] or 8 * MB
    if count < capacity and bytes + size <= limit then
      keep[row.id], count, bytes = true, count + 1, bytes + size
    else used[row.id], sizes[row.id] = nil, nil end
  end
  retained = keep
  M.last = {budget=M.budget(), maps=count, estimatedTerrainBytes=bytes,
    capacity=capacity, automatic=M.setting:get()=='auto', ramDetection=false}
  return keep
end
function M.retained() return retained end
function M.sceneryBudget() return M.budget() * .35 end
function M.reset() used, sizes, retained, serial = {}, {}, {}, 0 end
return M
