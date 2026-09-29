-- Use time spent inside native gatehouses to prepare one outgoing area.
-- No render state, native collision, warp timing or save data is changed.
local V = ...
local M = {}
local Chunk = V.require('ChunkMesher')
local Horizon = V.require('HorizonWall')
local Residency = V.require('WorldResidency')
local Atlas = V.require('TerrainAtlas')
local Destinations = V.require('WarpDestinations')
local current

-- Distance from the arrival door identifies the other side even when both
-- ends resolve through LAST_MAP to different doors on the same outdoor map.
function M.destination(game, ow)
  local p, warps = ow.player, ow.map.def.warps or {}
  if not p then return nil end
  local exits, entrance, near = {}, nil, math.huge
  for _, warp in ipairs(warps) do
    local id = Destinations.resolve(game, ow, warp)
    local def = id and game.data.maps[id]
    if def and (def.outdoor == true or def.tileset == 'OVERWORLD'
        or def.tileset == 'FOREST' or def.tileset == 'PLATEAU') then
      local d = math.abs(warp.x-p.cellX)+math.abs(warp.y-p.cellY)
      local row = {id=id, x=warp.x, y=warp.y}
      exits[#exits+1] = row
      if d < near then entrance, near = row, d end
    end
  end
  if not entrance then return nil end
  local chosen, far = entrance, -1
  for _, row in ipairs(exits) do
    local d = math.abs(row.x-entrance.x)+math.abs(row.y-entrance.y)
    if d > far then chosen, far = row, d end
  end
  return chosen.id
end

local function advance(game, ow, covered)
  if not V.require('VoxelState').active() or not V.require('GateDoors').isGate(ow.map.id) then
    current = nil
    return
  end
  if current and (current.owner ~= ow.map or current.overworld ~= ow) then current = nil end
  -- Capture the arrival position before waiting for the gatehouse to finish.
  if not current then
    current = {owner=ow.map, overworld=ow, id=M.destination(game,ow), phase='waiting'}
  end
  if not current.id or current.failed then return end
  if not V.require('VoxelState').ready or Chunk.hasPriorityWork() then return end
  local timer = love and love.timer
  if not covered and timer and timer.getDelta and timer.getDelta() > 1/40 then return end
  local platform = require('src.core.Platform').detect()
  local mobile = platform.mobile or platform.console
  local c = current
  local allowance = mobile and 1 or math.min(5,math.max(1,Residency.capacity()-1))
  if c.allowance ~= allowance then
    c.scene, c.maps, c.pending, c.allowance = nil, nil, nil, allowance
    c.phase = 'waiting'
  end
  local loader = require('src.world.MapLoader')
  if not c.scene then
    local map = loader.load(game.data,c.id)
    c.scene = {map=map, neighbors={}, worldMaps=game.data.maps}
    c.body = Horizon.preferBody(map) == true
    -- Full-border variants need the exact live masks. Leave those to the
    -- established warp path rather than caching a subtly different border.
    if not c.body and next(map.def.connections or {}) then c.failed=true; return end
    c.maps = {{map=map,body=c.body}}
    c.pending = {}
    -- Respect the live desktop ring and budget; low-memory/mobile starts with
    -- only the destination. Never speculate through arbitrary two-hop areas.
    local limit = allowance
    if c.body and not mobile and V.require('VisibleNeighborhood').setting:get() then
      local rows = require('src.world.OverworldController').computeNeighbors(game.data.maps,c.id,1)
      if #rows+1 <= limit then c.pending=rows end
    end
    c.phase='terrain'
    return -- at most one map allocation per update
  end
  if #c.pending > 0 then
    local row=table.remove(c.pending,1)
    local map=loader.load(game.data,row.id)
    c.scene.neighbors[#c.scene.neighbors+1]={map=map,ox=row.ox,oy=row.oy}
    c.maps[#c.maps+1]={map=map,body=true}
    return
  end
  -- Scenery and terrain have separate shared budgets. Start the exact future
  -- enclosure alongside terrain rather than serialising two long cold builds.
  -- Nothing becomes visible until the ordinary destination reveal checks pass.
  local sceneryReady = true
  if c.body and not mobile then
    sceneryReady = Horizon.cacheStatus(c.scene).ready
    if not sceneryReady then
      local _, ready, failed = Horizon.prepareOptional(c.scene,ow)
      if failed then c.failed=true; return end
      sceneryReady = ready
    end
  end
  -- One terrain job at a time, on the existing rank-zero queue. Aux geometry
  -- belongs to that same job; the pump uses spare gate frame time up to 3ms.
  for _, row in ipairs(c.maps) do
    if not Chunk.ready(row.map,row.body) or not Chunk.auxReady(row.map) then
      Residency.touch(row.map.id)
      Chunk.request(row.map,row.body,nil,false,0)
      if not row.queued then
        -- Admit future geometry through the same LRU budget as ordinary map
        -- changes. Otherwise every speculative target bypasses cache trimming
        -- until the player actually leaves the room.
        for _, planned in ipairs(c.maps) do Residency.touch(planned.map.id) end
        Chunk.setLive({[ow.map.id]=true})
        Atlas.setLive({[ow.map.id]=true})
        row.queued=true
        local retained=Residency.retained()
        for _, planned in ipairs(c.maps) do
          if planned.queued and not retained[planned.map.id] then
            -- Do not rebuild/evict/rebuild in a loop when this optional area
            -- cannot fit. The real warp still owns its normal loading cover.
            c.failed='cache budget'
            return
          end
        end
      end
      c.phase='terrain'
      return
    end
  end
  for _, row in ipairs(c.maps) do
    if not Atlas.prepared(row.map) then
      c.phase='textures'
      Atlas.prepare(row.map)
      return
    end
  end
  if not sceneryReady then c.phase='scenery'; return end
  c.phase='ready'
end

function M.update(game, covered)
  local ow=game and game.overworld
  if not (ow and ow.map and game.data) then current=nil; return end
  -- Optional preparation must never invalidate an already drawable room.
  local ok, err=pcall(advance,game,ow,covered)
  if not ok and current then current.failed=tostring(err) end
  return current ~= nil and current.id ~= nil and not current.failed and current.phase ~= 'ready'
end
function M.status()
  if not current then return nil end
  return {gate=current.owner.id,destination=current.id,phase=current.phase,
    failed=current.failed,maps=current.maps and #current.maps or 0}
end
return M
