-- Warm a semantic destination while the engine's existing warp fade covers
-- the overworld.  This module never changes the warp, map, transition or
-- renderer state: it only puts the already-known destination into
-- ChunkMesher's generation-checked in-memory queue.  Any failure therefore
-- falls back to the exact Game/KASC path that was going to run anyway.

local V = ...

local ChunkMesher = V.require("ChunkMesher")
local HorizonWall = V.require("HorizonWall")
local Voxel = V.require("VoxelState")

local Destinations = V.require("WarpDestinations")
local WarpPrefetch = {}

local MARKER = "__voxelAscendantWarpPrefetchV1"
local OWNER = "VOXEL_ASCENDANT"

local function enabled()
  if type(Voxel.active) == "function" then
    local ok, value = pcall(Voxel.active)
    if ok and value then return true end
  end
  local setting = ChunkMesher.preloadSetting
  if setting and type(setting.get) == "function" then
    local ok, value = pcall(setting.get, setting)
    if ok and value then return true end
  end
  return false
end

local function arm(state, game, mapId)
  -- Loading Map objects may allocate renderer state.  Keep that work out of
  -- startWarpTo itself: the wrapper records the destination and region intent,
  -- then returns to the engine's unmodified transition implementation.
  -- Areas beyond gates/caves and large indoor complexes warm once on entry; native warp behavior and
  -- the actual loading-screen release remain owned by TransitionReveal.
  V.require('RegionPreparation').arm(game,mapId)
  state.pending = { game = game, mapId = mapId }
  state.warmingMap = nil
  state.warmingBodyOnly = nil
  state.warmingHorizon = nil
end

-- The body and its enclosing horizon are separate asynchronous caches. Keep
-- advancing the exact destination-only enclosure during the existing fade,
-- even after the body has finished. Never build a guessed connected union or
-- call prewarm() here (that path may decode all assets synchronously).
local function advanceHorizon(state, ow, covered)
  local target = state.warmingHorizon
  if not target then return end
  if not covered or not enabled() or ow.map == target.map then
    state.warmingHorizon = nil
    return
  end
  -- A bounded horizon resume still costs work. Let the priority terrain lane
  -- finish first, then do at most one ordinary meshes() call per update.
  if type(ChunkMesher.ready) ~= 'function' then return end
  local okBody, bodyReady = pcall(ChunkMesher.ready, target.map, target.bodyOnly)
  if not okBody or not bodyReady then return end
  if type(HorizonWall.meshes) ~= 'function' then
    state.warmingHorizon = nil
    return
  end
  local ok, _, ready, failed = pcall(HorizonWall.meshes, target.scene)
  if not ok or ready or failed then state.warmingHorizon = nil end
end

-- Prepare the nearest real door before the player crosses it. Only a closed
-- destination (or semantic body) can be requested without inventing connection
-- masks. No speculative map is made urgent or added to the rendered world.
local function predict(state, game, ow)
  if not enabled() or not Voxel.ready or ChunkMesher.hasPriorityWork() then return end
  local timer = love and love.timer
  if timer and timer.getDelta and timer.getDelta() > 1/40 then return end
  local ok, platform = pcall(require, 'src.core.Platform')
  if ok and platform.detect().mobile then return end
  local p, map = ow.player, ow.map
  if not (p and map and map.def and game.data) then return end
  local x,y = p.cellX, p.cellY
  if not(x and y) then return end
  local key=map.id..':'..x..':'..y
  if state.predictedCell==key then return end
  state.predictedCell=key
  local best, distance
  for _,w in ipairs(map.def.warps or{}) do
    local id=Destinations.resolve(game, ow, w)
    local dest=id and game.data.maps[id]
    if dest and id~=map.id then
      local d=math.abs(w.x-x)+math.abs(w.y-y)
      if d<=7 and (not distance or d<distance) then best,distance=id,d end
    end
  end
  if not best then return end
  local loaded, target=pcall(require('src.world.MapLoader').load,game.data,best)
  if not loaded or not target then return end
  local body=HorizonWall.preferBody(target)==true
  if not body and next(target.def.connections or{}) then return end
  V.require('WorldResidency').touch(best)
  ChunkMesher.request(target,body,nil,false,0)
end

function WarpPrefetch.install(game)
  local ow = game and game.overworld
  if type(ow) ~= "table" or type(ow.startWarpTo) ~= "function" then
    return false
  end

  local existing = rawget(ow, MARKER)
  if existing ~= nil then
    -- Hot reload reuses the live OverworldState.  Adopt our existing wrapper
    -- instead of stacking another one; an inconsistent/foreign marker is
    -- deliberately left alone.
    if type(existing) ~= "table" or existing.owner ~= OWNER
       or ow.startWarpTo ~= existing.wrapper then
      return false
    end
    existing.arm = arm
    existing.game = game
    return true
  end

  local state = {
    owner = OWNER,
    game = game,
    original = ow.startWarpTo,
    arm = arm,
  }
  state.wrapper = function(self, mapId, ...)
    state.arm(state, state.game, mapId)
    -- Tail return preserves every original return value and every argument,
    -- including optional Fly/onDone/options records.
    return state.original(self, mapId, ...)
  end
  rawset(ow, MARKER, state)
  ow.startWarpTo = state.wrapper
  return true
end

function WarpPrefetch.update(game, covered)
  local ow = game and game.overworld
  if type(ow) ~= "table" then return false end
  local state = rawget(ow, MARKER)
  if type(state) ~= "table" or state.owner ~= OWNER
     or ow.startWarpTo ~= state.wrapper then
    return false
  end
  if not covered then
    state.warmingMap = nil
    state.warmingBodyOnly = nil
  elseif state.warmingMap and type(ChunkMesher.ready) == "function" then
    local readyOK, ready = pcall(ChunkMesher.ready, state.warmingMap,
      state.warmingBodyOnly == true)
    if readyOK and ready then
      state.warmingMap = nil
      state.warmingBodyOnly = nil
    end
  end
  if not covered then predict(state, game, ow) end
  advanceHorizon(state, ow, covered)
  local pending = state.pending
  if not pending or not covered then return state.warmingMap ~= nil end
  state.pending = nil
  if not enabled() or type(pending.mapId) ~= "string" then return false end

  local ok, map = pcall(function()
    local loader = require("src.world.MapLoader")
    return loader.load(pending.game and pending.game.data, pending.mapId)
  end)
  if not ok or not map then return false end

  local bodyOK, bodyOnly = pcall(HorizonWall.preferBody, map)
  if not bodyOK then return false end
  bodyOnly = bodyOnly == true
  if not bodyOnly then
    -- Ordinary interiors need their complete border ring, but most of them
    -- (including Oak's Lab) are closed maps with no streamed neighbours. They
    -- can be built exactly during the door fade instead of dropping their
    -- cold structure analysis into the first visible frames. A non-semantic
    -- destination with connections still waits for VoxelScene, which owns the
    -- neighbour masks required by its full-ring cache key.
    local connections = map.def and map.def.connections
    if type(connections) == "table" and next(connections) ~= nil then
      return false
    end
  end
  -- This is the exact current-map slot VoxelScene requests after the warp:
  -- body-only under semantic scenery, otherwise the complete unmasked ring of
  -- a closed interior. Starting it here makes the later request a cache hit.
  local requestOK = pcall(ChunkMesher.request, map, bodyOnly, nil, true)
  if requestOK then
    state.warmingMap = map
    state.warmingBodyOnly = bodyOnly
    if map ~= ow.map then
      state.warmingHorizon = {
        map = map, bodyOnly = bodyOnly,
        scene = { map=map, neighbors={}, worldMaps=game.data and game.data.maps },
      }
    end
  end
  return requestOK
end

WarpPrefetch.MARKER = MARKER

return WarpPrefetch
