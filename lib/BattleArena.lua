-- Overworld battles: where the fight is staged.
--
-- A battle in this mod happens ON THE MAP, so it needs a patch of ground
-- clear enough to stand two Pokemon on and point a camera down. This module
-- finds it: the nearest patch of open cells, in the shape below.
--
--     x x x
--     x O x        O   the enemy's mon
--     x x x
--     x x x
--     x P x        P   the player's mon
--     x x x
--
-- Every `x` is an OPEN cell -- one with no obstruction, i.e. one the player
-- could walk onto. The two mons stand three cells apart down the middle
-- column, with a one-cell apron all round so the camera looks across floor
-- rather than into a wall.
--
-- When no map has room for that -- a corridor, a cave, a shop floor -- the
-- search relaxes to the narrow shape, which is the same three-cell gap with
-- the apron given up:
--
--     O
--     x
--     x
--     P
--
-- and if even that will not fit, the caller gets nil and the battle draws
-- the way it always did. A mod that cannot find a stage does not invent
-- one.
--
-- Nothing here MOVES anybody: the arena is where the CAMERA goes and where
-- the two mons are staged for the shot. The player's own cell, the party,
-- every script and flag are exactly where the battle left them, which is
-- what keeps a trainer's post-battle dialogue talking to someone still
-- standing in front of them.

-- the mod namespace (see main.lua): V.require loads a sibling module
local V = ...

local BattleArena = {}
local queryReaders={}
local geometryScope
local QueryCache=V.require('ArenaQueryCache')
local resultCache=QueryCache and QueryCache.new and QueryCache.new(queryReaders)
local function query(kind,...)
  if resultCache then return resultCache.read(kind,...)end
  return queryReaders[kind](...)
end


-- ------- the authored spot
--
-- Every map gets one or more reviewed fallbacks in data/battle_arenas.lua.
-- Before using them, an outdoor/cave fight may use a nearby, visible clearing
-- on the player's own terrain course. This restores local variety without
-- returning to an unconstrained "nearest walkable cell" that can put a rival
-- between two houses. Two reasons for keeping the reviewed layer.
--
-- A fight should look the same every time it happens somewhere. Picking the
-- nearest patch means Route 1 has a dozen different battle scenes depending
-- on which step of the grass you were on, some of them behind a tree.
--
-- And "open ground" is not the same question as "you can SEE the two of
-- them". The camera is low and a long way back, so a hedge, a ledge lip or a
-- building corner anywhere along that line hides a mon completely while the
-- cells it stands on are perfectly walkable. That is what `clearance` below
-- measures, and it is what the authored list is chosen against.
--
-- A map with no entry falls back to the search, so a mod that adds maps, or
-- an entry that goes stale, degrades to the old behaviour rather than to no
-- battle.
-- An entry may also name ANOTHER MAP to stage on:
--
--   ["MT_MOON_B2F"] = { map = "MT_MOON_1F", x = 12, y = 8, shape = "wide" }
--
-- because some maps simply have nowhere to put a fight. A cave's lower floor
-- can be nothing but two-cell-wide corridors between rock walls; a gym is a
-- room full of furniture. Rather than stage a battle there badly -- both
-- Pokemon behind a boulder -- the fight is shot on a floor of the SAME cave,
-- or a floor of the same building, that does have the room for it. It is the
-- same place, and no worse a fiction than a battle happening on ground the
-- player is not standing on, which is what every one of these already is.
local authored = nil
local overrides = {}

-- Front-sprite preflight runs before the battle object exists and may reuse a
-- search result, but only for the exact overworld request. Map IDs alone are
-- insufficient: a reloaded map with the same ID has new collision state, and
-- the two ends of a long route need different nearby anchors.
local requestMapIds = setmetatable({}, { __mode = "k" })
local nextRequestMapId = 0
local requestRevision = 0
local function placementRevision(name,field)
  local ok,module=pcall(V.require,name)
  return ok and type(module)=='table'and module[field]or 0
end

function BattleArena.requestKey(map, cellX, cellY, surfing)
  if type(map) ~= "table" then return nil end
  local serial = requestMapIds[map]
  if not serial then
    nextRequestMapId = nextRequestMapId + 1
    serial = nextRequestMapId
    requestMapIds[map] = serial
  end
  -- The one-shot encounter preflight can outlive a terrain refresh. A Cut,
  -- reload or newly published scenery must not consume the old placement
  -- merely because the same player and map objects are still in use.
  local ok,elevation=pcall(V.require,'LedgeElevation')
  local terrainMode
  if ok and elevation and type(elevation.mode)=='function'then
    local modeOK,value=pcall(elevation.mode)
    if modeOK then terrainMode=value end
  end
  return table.concat({ tostring(map.id or ""), tostring(serial),
    tostring(tonumber(cellX) or -1), tostring(tonumber(cellY) or -1),
    surfing and "water" or "land", tostring(requestRevision),
    tostring(map.widthCells),tostring(map.heightCells),
    tostring(map.def),tostring(map.tileset),tostring(terrainMode),
    tostring(placementRevision('ChunkMesher','cacheRevision')),
    tostring(placementRevision('HorizonWall','cacheRevision')) }, "\0")
end

-- Optional native-editor output.  It is a per-map overlay, not a replacement
-- for data/battle_arenas.lua: an absent key deliberately keeps the shipped
-- review, while `false` deliberately refuses a voxel arena.  Runtime
-- setOverride() remains the top authoring/debug layer above both tables.
local editorAuthored = {}
local editorLoaded = false

local function copyValue(value, seen)
  if type(value) ~= "table" then return value end
  seen = seen or {}
  if seen[value] then return seen[value] end
  local copy = {}
  seen[value] = copy
  for key, child in pairs(value) do
    copy[copyValue(key, seen)] = copyValue(child, seen)
  end
  return copy
end

local function finiteInteger(value)
  return type(value) == "number" and value == value
         and value ~= math.huge and value ~= -math.huge
         and value == math.floor(value)
end

local function validOptionalString(value)
  return value == nil or type(value) == "string" and value ~= ""
end

local function validateEntry(entry, inherited, context)
  if type(entry) ~= "table" then
    return false, context .. " must be a table"
  end
  local function field(name)
    if entry[name] ~= nil then return entry[name] end
    return inherited and inherited[name] or nil
  end
  if not finiteInteger(field("x")) or not finiteInteger(field("y")) then
    return false, context .. " needs integer x/y cells"
  end
  for _, name in ipairs({ "shape", "cam", "map" }) do
    if not validOptionalString(field(name)) then
      return false, context .. "." .. name .. " must be a non-empty string"
    end
  end
  return true
end

local function validateEditorTable(incoming)
  if type(incoming) ~= "table" then
    return nil, "battle_arenas.generated must return a table"
  end
  local normalized = {}
  for mapId, pick in pairs(incoming) do
    if type(mapId) ~= "string" or mapId == "" then
      return nil, "battle_arenas.generated has an invalid map ID"
    end
    if pick == false then
      normalized[mapId] = false
    elseif type(pick) ~= "table" then
      return nil, mapId .. " must be an arena table or false"
    else
      if pick.adaptive ~= nil and type(pick.adaptive) ~= "boolean" then
        return nil, mapId .. ".adaptive must be boolean"
      end
      for _, name in ipairs({ "shape", "cam", "map" }) do
        if not validOptionalString(pick[name]) then
          return nil, mapId .. "." .. name
                      .. " must be a non-empty string"
        end
      end
      if pick.spots ~= nil then
        if type(pick.spots) ~= "table" then
          return nil, mapId .. ".spots must be an ordered table"
        end
        local count = 0
        for key in pairs(pick.spots) do
          if not finiteInteger(key) or key < 1 then
            return nil, mapId .. ".spots contains a non-array key"
          end
          count = count + 1
        end
        if count ~= #pick.spots then
          return nil, mapId .. ".spots must not contain holes"
        end
        for index, child in ipairs(pick.spots) do
          local ok, err = validateEntry(
            child, pick, string.format("%s.spots[%d]", mapId, index))
          if not ok then return nil, err end
        end
      else
        local ok, err = validateEntry(pick, nil, mapId)
        if not ok then return nil, err end
      end
      normalized[mapId] = copyValue(pick)
    end
  end
  return normalized
end

local function loadInitialEditorTable()
  if editorLoaded then return end
  editorLoaded = true
  local ok, incoming = pcall(V.data, "battle_arenas.generated")
  if not ok then return end
  local validated = validateEditorTable(incoming)
  if validated then editorAuthored = validated end
end

local MISSING_MARKER = {}
local editorReload = {
  initialized = false,
  marker = nil,
  failedMarker = nil,
}

local function markerKey(marker)
  return marker == nil and MISSING_MARKER or tostring(marker)
end

local function readEditorMarker()
  if not (V.mod and type(V.mod.read) == "function") then return false end
  local ok, marker = pcall(V.mod.read, V.mod,
                           "data/scenery_editor.reload")
  if not ok then return false end
  return true, markerKey(marker)
end

-- Prime independently from HorizonWall. Both consumers watch the same
-- marker-last publication, but each commits only its own generated module.
do
  local readable, key = readEditorMarker()
  if readable then
    editorReload.initialized, editorReload.marker = true, key
  end
end

function BattleArena.pollEditorReload()
  loadInitialEditorTable()
  local readable, key = readEditorMarker()
  if not readable then return false end
  if not editorReload.initialized then
    -- The marker may be created for the first time after the mod started.
    -- Treat that first readable revision as a publication instead of merely
    -- adopting it as a baseline; loadInitialEditorTable() may already have
    -- observed the generated module as absent.
    editorReload.initialized = true
  end
  if key == editorReload.marker then return false end
  if type(V.readDataFresh) ~= "function"
     or type(V.commitData) ~= "function" then
    if editorReload.failedMarker ~= key then
      editorReload.failedMarker = key
      return false, "runtime cannot stage battle_arenas.generated"
    end
    return false
  end

  local readOK, incoming = pcall(V.readDataFresh,
                                 "battle_arenas.generated")
  if not readOK then
    if editorReload.failedMarker ~= key then
      editorReload.failedMarker = key
      return false, "battle_arenas.generated could not be read: "
                    .. tostring(incoming)
    end
    return false
  end
  local validated, err = validateEditorTable(incoming)
  if not validated then
    if editorReload.failedMarker ~= key then
      editorReload.failedMarker = key
      return false, err
    end
    return false
  end

  -- Swap only after the complete document validates and the shared data cache
  -- accepts it. A failed marker remains pending and is retried, keeping the
  -- previous editor table intact.
  local commitOK, committed = pcall(V.commitData,
                                    "battle_arenas.generated", incoming)
  if not commitOK or committed ~= true then
    if editorReload.failedMarker ~= key then
      editorReload.failedMarker = key
      return false, "battle_arenas.generated could not be committed: "
                    .. tostring(committed)
    end
    return false
  end
  editorAuthored = validated
  requestRevision = requestRevision + 1
  editorReload.marker, editorReload.failedMarker = key, nil
  return true
end

local function authoredFor(mapId,map)
  -- `~= nil`, not truthiness: `false` is a meaningful entry here (an
  -- authored refusal), so it has to reach the caller rather than read as
  -- "nothing set" and fall through to the data file
  BattleArena.pollEditorReload()
  local forced = overrides[mapId]
  if forced ~= nil then return forced end
  local edited = editorAuthored[mapId]
  if edited ~= nil then return edited end
  if mapId=='KA_BLAINE_VOLCANO_GYM' and map then
    local court=V.require('BlaineVolcano').battleCourt(map)
    if court then return court end
  end
  if authored == nil then
    local ok, list = pcall(V.data, "battle_arenas")
    authored = (ok and type(list) == "table") and list or false
  end
  if not authored then return nil end
  return authored[mapId]
end

BattleArena.authoredFor = authoredFor

-- Force one map's entry at runtime, ahead of the data file. The authoring
-- tool's handle: it is how a spot chosen by eye is staged and photographed
-- before it is written down, and the only way to check a cross-floor entry
-- without editing the shipped list first. Pass nil to drop it again.
function BattleArena.setOverride(mapId, entry)
  overrides[mapId] = entry
  requestRevision = requestRevision + 1
end

-- Cell size in world pixels, the unit every coordinate here is in when it
-- crosses into the renderer (Map's walk grid is 16px cells).
local CELL = 16

-- The search shapes, in preference order, plus explicitly authored rotated
-- variants. `w`/`h` are in cells; `enemy` and
-- `player` are the offsets, from the shape's north-west corner, of the two
-- cells a mon stands on. `axisYaw` rotates the canonical north/south battle
-- and camera basis in world space. Open-ground search retains the wide
-- north/south court when it fits. A shallow court can then use its diagonal
-- before squeezing both teams into a one-cell corridor.
BattleArena.SHAPES = {
  { id = "wide",   w = 3, h = 6, enemy = { 1, 1 }, player = { 1, 4 },
    axisYaw = 0 },
  { id = "narrow", w = 1, h = 4, enemy = { 0, 0 }, player = { 0, 3 },
    axisYaw = 0, narrow = true },
  { id = "narrow_east", w = 4, h = 1,
    enemy = { 3, 0 }, player = { 0, 0 },
    axisYaw = math.pi / 2, narrow = true, authoredOnly = true },
}
-- A broad, shallow room has more usable separation across its diagonal.
-- Inset both feet from the corners, leaving floor for the trainers. The
-- whole six-by-four court must still pass native walkability and camera
-- clearance; existing wide courts keep their original orientation.
BattleArena.SHAPES[4] = { id="diagonal_east", w=6, h=4,
  enemy={4.25,.75}, player={.75,2.25}, axisYaw=math.atan2(3.5,1.5) }
BattleArena.SHAPES[5] = { id="diagonal_west", w=6, h=4,
  enemy={.75,.75}, player={4.25,2.25}, axisYaw=-math.atan2(3.5,1.5) }
-- Complete transverse floor, including a rear/flank apron for each trainer.
-- Only reviewed entries use this court; automatic legacy search is unchanged.
BattleArena.SHAPES[6] = { id="court_east", w=8, h=2,
  enemy={5,0}, player={2,0}, axisYaw=math.pi/2, authoredOnly=true,
  trainerOffsets={player={-18,6},enemy={18,6}} }
-- Rotate the complete four-actor court, including the trainer aprons.
-- These are catalogue-only: a runtime search must not select an unreviewed
-- orientation just because the two Pokemon happen to fit.
BattleArena.SHAPES[7] = { id="court_north", w=2, h=8,
  enemy={0,2}, player={0,5}, axisYaw=0, authoredOnly=true,
  trainerOffsets={player={6,18},enemy={6,-18}} }
BattleArena.SHAPES[8] = { id="court_south", w=2, h=8,
  enemy={0,5}, player={0,2}, axisYaw=math.pi, authoredOnly=true,
  trainerOffsets={player={-6,-18},enemy={-6,18}} }
BattleArena.SHAPES[9] = { id="court_west", w=8, h=2,
  enemy={2,0}, player={5,0}, axisYaw=-math.pi/2, authoredOnly=true,
  trainerOffsets={player={18,-6},enemy={-18,-6}} }
-- Compact clearings retain forty world units between Pokemon and explicit
-- rear trainer seats. Runtime art/hull checks still decide whether unusually
-- large Pokemon fit; these never replace the general-purpose search shapes.
BattleArena.SHAPES[10] = { id="court_small_east", w=6, h=2,
  enemy={3.75,0}, player={1.25,0}, axisYaw=math.pi/2, authoredOnly=true,
  trainerOffsets={player={-12,6},enemy={12,6}} }
BattleArena.SHAPES[11] = { id="court_small_north", w=2, h=6,
  enemy={0,1.25}, player={0,3.75}, axisYaw=0, authoredOnly=true,
  trainerOffsets={player={6,12},enemy={6,-12}} }
BattleArena.SHAPES[12] = { id="court_small_south", w=2, h=6,
  enemy={1,3.75}, player={1,1.25}, axisYaw=math.pi, authoredOnly=true,
  trainerOffsets={player={-6,-12},enemy={-6,12}} }
BattleArena.SHAPES[13] = { id="court_small_west", w=6, h=2,
  enemy={1.25,1}, player={3.75,1}, axisYaw=-math.pi/2, authoredOnly=true,
  trainerOffsets={player={12,-6},enemy={-12,-6}} }
-- Five-cell indoor strips. Both trainer envelopes still pass the same
-- floor/geometry clearance, and live actor hulls may reject oversized art.
-- Used only by explicit room entries, never by the automatic map search.
BattleArena.SHAPES[14] = { id="court_tight_east", w=5, h=2,
  enemy={2.75,0}, player={1,0}, axisYaw=math.pi/2, authoredOnly=true,
  trainerOffsets={player={-8,6},enemy={8,6}} }
BattleArena.SHAPES[15] = { id="court_tight_west", w=5, h=2,
  enemy={1,1}, player={2.75,1}, axisYaw=-math.pi/2, authoredOnly=true,
  trainerOffsets={player={8,-6},enemy={-8,-6}} }
BattleArena.SHAPES[16] = {id='blaine_center',w=8,h=4,
  player={2,1.5},enemy={5,1.5},axisYaw=math.pi/2,authoredOnly=true,
  trainerOffsets={player={-24,10},enemy={24,10}}}
BattleArena.SEARCH_SHAPES = { BattleArena.SHAPES[1],
  BattleArena.SHAPES[4], BattleArena.SHAPES[5], BattleArena.SHAPES[2] }

-- Whether a cell is open ground for the purpose above.
--
-- "Open" is the walk test the player themselves answer to, so an arena can
-- never be laid over a wall, a counter, a tree or a ledge face. Water counts
-- only for a surfer, which is the one case where the player is standing on
-- it too -- a sea battle staged on the beach half a route away would read as
-- a teleport.
--
-- Warp cells are excluded on top of that. They are walkable by definition
-- (they are the doormat), and a fight framed in a doorway both looks wrong
-- and puts the camera inside the building's geometry.
--
-- And TALL GRASS is excluded, which is the surprising one, because grass is
-- where wild battles come from and standing in it is the obvious place to
-- have one. It does not survive contact with the camera. Grass is real
-- geometry in this mode -- a row of tufts about knee height on a Pokemon --
-- drawn with the same camera-ward bias that lets it overdraw a walking
-- character's feet in the free-roam world. From a camera nearly level with
-- the floor that bias stops being feet-deep: the tufts on and around a mon's
-- own tile stand between it and the lens and eat most of the sprite.
--
-- So the arena is laid on bare ground -- the whole footprint, not just the
-- two cells a mon stands on, because the apron south of the near mon is
-- exactly the row whose grass would cover it. Grass FURTHER back toward the
-- camera is fine and stays: it is far enough forward to project low and wide
-- across the bottom of the frame, where it reads as a field rather than as
-- something in the way.
local function rawOpenCell(map, cx, cy, surfing)
  if not map:inBounds(cx, cy) then return false end
  if map:warpAtCell(cx, cy) then return false end
  if map:isWarpTileCell(cx, cy) then return false end
  if map.isGrassCell and map:isGrassCell(cx, cy) then return false end
  if map:isWalkableCell(cx, cy) then return true end
  return (surfing and map:isWaterCell(cx, cy)) or false
end
local function openCell(map,cx,cy,surfing)
  if not(resultCache and resultCache.recording)then return rawOpenCell(map,cx,cy,surfing)end
  return query('open',map,cx,cy,surfing)
end


BattleArena.openCell = openCell

local function entryList(pick)
  if type(pick) ~= "table" then return {} end
  local source = type(pick.spots) == "table" and pick.spots
                 or (#pick > 0 and pick or nil)
  if not source then return { pick } end
  local out = {}
  for _, child in ipairs(source) do
    if type(child) == "table" then
      local entry = {}
      for k, v in pairs(pick) do
        if k ~= "spots" and type(k) ~= "number" then entry[k] = v end
      end
      for k, v in pairs(child) do entry[k] = v end
      out[#out + 1] = entry
    end
  end
  return out
end

BattleArena.entryList = entryList

-- Warm reviewed foreign floors while a loading transition covers the world.
-- MapLoader owns residency and eviction; do not retain extra map/renderers here.
local preparedFloors=setmetatable({},{__mode='k'})
function BattleArena.prepare(map)
 if not(map and map.id)then return true end
 local pick=authoredFor(map.id,map)
 local held=preparedFloors[map]
 if not held or held.pick~=pick or held.revision~=requestRevision then
  held={pick=pick,revision=requestRevision,ids={},failed={}};preparedFloors[map]=held
  local seen={}
  for _,entry in ipairs(entryList(pick))do
   if entry.map and entry.map~=map.id and not seen[entry.map]then
    seen[entry.map]=true;held.ids[#held.ids+1]=entry.map
   end
  end
 end
 if #held.ids==0 then return true end
 local Loader=require('src.world.MapLoader');local Game=require('src.core.Game')
 for _,id in ipairs(held.ids)do
  if not held.failed[id]and not Loader.cached(id)then
   local ok,value=pcall(Loader.load,Game.data,id)
   if not ok or not value then held.failed[id]=true;BattleArena.lastPrepareError=tostring(value)end
   return false -- at most one foreign decode/upload in this preparation call
  end
 end
 return true
end

-- Memoize only cells touched by a candidate footprint during this request.
-- Authored courts and bounded local searches do not need a full-map scan.
-- Nothing survives the request, so live collision/furniture edits are observed
-- on the next search without a separate invalidation contract.
local function openGrid(map, surfing, compact, surface)
  local w, h = map.widthCells, map.heightCells
  local grid = setmetatable({}, { __index = function(cells, index)
    local cx, cy = index % w, math.floor(index / w)
    local free = openCell(map, cx, cy, surfing)
    if free and surface then
      local water = query('water',map,cx,cy)
      free = (surface == 'water' and water) or (surface == 'land' and not water)
    end
    if free and compact then
      -- Walkable seats and pedestal decks are not spare battle aisles.
      free = query('support',map,cx,cy)
    end
    free = not not free
    cells[index] = free
    return free
  end })
  return grid, w, h
end

local function fits(grid, gw, x, y, w, h)
  for cy = y, y + h - 1 do
    local row = cy * gw
    for cx = x, x + w - 1 do
      if not grid[row + cx] then return false end
    end
  end
  return true
end

-- Build the record the renderer reads: the two mons' cells and, in world
-- pixels, the centre of each and of the pair.
local function place(shape, x, y)
  local ex, ey = x + shape.enemy[1], y + shape.enemy[2]
  local px, py = x + shape.player[1], y + shape.player[2]
  local arena = {
    shape = shape.id,
    trainerOffsets = shape.trainerOffsets,
    axisYaw = shape.axisYaw or 0,
    narrow = shape.narrow == true,
    x = x, y = y, w = shape.w, h = shape.h,
    enemyCell = { ex, ey },
    playerCell = { px, py },
    -- world-pixel centres of the two cells a mon stands on
    enemy = { ex * CELL + CELL / 2, ey * CELL + CELL / 2 },
    player = { px * CELL + CELL / 2, py * CELL + CELL / 2 },
  }
  arena.mid = { (arena.enemy[1] + arena.player[1]) / 2,
                (arena.enemy[2] + arena.player[2]) / 2 }
  return arena
end

local function routeMap(map)
  return type(map) == "table"
    and tostring(map.id or ""):match("^ROUTE_%d+$") ~= nil
end

-- Route battles must be photographed from the route itself. A mon footprint
-- could be valid while the long-lens eye sat beyond the map's east/south
-- edge, looking back through the extruded border ring; that is the reported
-- "anchor outside the map" failure. Validate both combat cells and the
-- canonical camera anchor. If only the telephoto rig escapes, promote the
-- candidate to the already-reviewed WIDE rig. If even that is outside, the
-- candidate is refused and the search continues on the same route.
function BattleArena.routeAnchorInBounds(map, arena)
  if not routeMap(map) then return true end
  if not (arena and type(map.inBounds) == "function") then return false end
  if arena.map and arena.map ~= map then return false end
  for _, cell in ipairs({ arena.enemyCell, arena.playerCell }) do
    if not (cell and query('bounds',map,cell[1],cell[2])) then return false end
  end
  local ok,x,y,z=query('camera',arena,0)
  if not ok then
    -- Synthetic/headless map fixtures may not carry a camera implementation;
    -- the two real route footing anchors above still fail closed on bounds.
    return true
  end
  return type(x) == "number" and type(z) == "number"
    and x >= 0 and z >= 0
    and x < map.widthCells * CELL and z < map.heightCells * CELL
end

function BattleArena.keepRouteAnchorInBounds(map, arena)
  if BattleArena.routeAnchorInBounds(map, arena) then return true end
  if not routeMap(map) then return false end
  local previous = arena and arena.cam
  if arena then arena.cam = "wide" end
  if BattleArena.routeAnchorInBounds(map, arena) then return true end
  if arena then arena.cam = previous end
  return false
end

-- ------- can the two of them actually be SEEN there
--
-- The camera sits low and far back on one side, so what hides a mon is not
-- what is on its own tile -- it is anything TALL between the camera and it.
-- A tree two cells to the south-east blocks the near mon completely while
-- every cell of the arena is open ground.
--
-- So the line from the eye to each mon is walked in short steps and the
-- terrain height under each step is compared with how high the line is
-- there. Three lines per mon -- to its feet, its middle and its head --
-- because a hedge that clears the head still cuts the body in half.
--
-- Grass and flowers are deliberately not obstacles: they stand at ankle
-- height, they are what a field looks like, and a mon standing in them
-- reads as standing in a field rather than as being hidden by one.
BattleArena.SAMPLE_STEP = 4      -- world pixels along the line
BattleArena.MON_H = 16           -- how tall a mon stands, in world pixels
BattleArena.CLEAR_EPS = 1.5      -- slack, so a flush kerb is not an obstacle
BattleArena.CAMERA_RADIUS = 3    -- near-plane/body clearance beside a travel path
BattleArena.CAMERA_EDGE_MARGIN = 16 -- keep the lens/frustum off the rendered void
BattleArena.MAX_ANCHOR_DISTANCE = 18 -- keep a fight in its encounter region
BattleArena.SOLID_H = 48         -- conservative tree/wall/building collision column
BattleArena.BORDER_H = 64        -- rendered edge closures are never travel lanes
BattleArena.DECOR_H = 12         -- grass/flower standees can cover a Pokemon

local visibilityVoxelScene = nil
local visibilityTileShape = nil
local visibilityShapes = setmetatable({}, { __mode = "k" })

local function surfaceArtAt(map, cx, cy)
  if not (map and map.inBounds and map:inBounds(cx, cy)
          and type(map.cellTile) == "function") then return nil end
  if visibilityTileShape == nil then
    local ok, tileShape = pcall(V.require, "TileShape")
    visibilityTileShape = ok and tileShape or false
  end
  if not (visibilityTileShape
          and type(visibilityTileShape.forMap) == "function") then return nil end
  local shapes = visibilityShapes[map]
  if not shapes then
    local okShapes, built = pcall(visibilityTileShape.forMap, map)
    if not (okShapes and type(built) == "table") then return nil end
    shapes = built
    visibilityShapes[map] = shapes
  end
  local okTile, tile = pcall(map.cellTile, map, cx, cy)
  local shape = okTile and shapes[tile] or nil
  return type(shape) == "table" and shape.art or nil
end

-- An authored dollhouse room can put its camera just beyond its open front.
-- This authorizes only the lens, never actor footing, routes or map warps.
-- Require both the exact native dimensions and the renderer's room-panel
-- profile so a replacement map cannot inherit an invisible-wall exception.
local cameraAprons=setmetatable({}, {__mode="k"})
function BattleArena.inCameraApron(map, wx, wz)
  if type(map)~="table" then return false end
  local cached=cameraAprons[map]
  if not cached or cached.revision~=requestRevision or cached.id~=map.id or cached.def~=map.def
      or cached.width~=map.widthCells or cached.height~=map.heightCells then
    local pick=authoredFor(map.id,map)
    local apron=type(pick)=="table" and pick.cameraApron
    local valid=not (map.def and (map.def.generation==2 or map.def.outdoor==true))
      and type(apron)=="table" and apron.edge=="south"
      and apron.width==map.widthCells and apron.height==map.heightCells
      and type(apron.depth)=="number" and apron.depth>0 and apron.depth<=96
    if valid then
      local ok,rooms=pcall(V.require,"Gen1InteriorPanoramas")
      local profile=ok and rooms.profileFor and rooms.profileFor(map)
      valid=profile and profile.nativeRoomPanels==true
      if not valid then
        local gymOK,gyms=pcall(V.require,"Gen1GymInteriors")
        local gym=gymOK and gyms.profiles and gyms.profiles[map.id]
        local d=map.def
        valid=gym and d and d.generation~=2 and d.tileset==gym.tileset
          and d.width==gym.width and d.height==gym.height
          and next(d.connections or {})==nil
      end
    end
    cached={revision=requestRevision,id=map.id,def=map.def,width=map.widthCells,height=map.heightCells,
      depth=valid and apron.depth or false}
    cameraAprons[map]=cached
  end
  return cached.depth and wx>=CELL and wx<(map.widthCells-1)*CELL
    and wz>=(map.heightCells-1)*CELL
    and wz<=map.heightCells*CELL+cached.depth or false
end

-- One synchronous camera solve may cast hundreds of overlapping rays.
-- Share cell samples only within that solve; nothing survives into a new
-- frame, option change, terrain edit or battle. Nested queries share the scope.
local visibilitySamples
function BattleArena.withVisibilitySamples(fn,...)
  if visibilitySamples then return fn(...) end
  visibilitySamples={}
  local function pack(...)return {n=select('#',...),...}end
  local result=pack(pcall(fn,...))
  visibilitySamples=nil
  if not result[1] then error(result[2],0) end
  return unpack(result,2,result.n)
end
local function sampleCell(map,cx,cy)
  if not visibilitySamples then return nil end
  local cells=visibilitySamples[map]
  if not cells then cells={};visibilitySamples[map]=cells end
  local key=cx+cy*65536
  local cell=cells[key]
  if not cell then cell={};cells[key]=cell end
  return cell
end

local function rawGroundAt(map, wx, wz)
  local cx, cy = math.floor(wx / CELL), math.floor(wz / CELL)
  if not map:inBounds(cx, cy) then
    -- off the map the border ring is drawn, and on most outdoor maps that
    -- ring is trees; treat it as solid so an arena is never framed through it
    return BattleArena.BORDER_H
  end
  local sample=sampleCell(map,cx,cy)
  if sample and sample.ground~=nil then return sample.ground end
  if visibilityVoxelScene == nil then
    local ok, scene = pcall(V.require, "VoxelScene")
    visibilityVoxelScene = ok and scene or false
  end
  if not (visibilityVoxelScene
          and type(visibilityVoxelScene.groundAt) == "function") then return 0 end
  local ok, h = pcall(visibilityVoxelScene.groundAt, map, cx, cy)
  h=(ok and tonumber(h)) or 0
  if sample then sample.ground=h end
  return h
end

local function groundAt(map,wx,wz)
  if not(resultCache and resultCache.recording)then return rawGroundAt(map,wx,wz)end
  return query('ground',map,math.floor(wx/CELL),math.floor(wz/CELL))
end

-- Footing uses the terrain surface. Camera rays additionally see the tops
-- of grass, flowers and collision columns; those are not another floor.
local function rawHeightAt(map, wx, wz)
  local cx, cy = math.floor(wx / CELL), math.floor(wz / CELL)
  if not map:inBounds(cx, cy) then
    return BattleArena.inCameraApron(map,wx,wz) and 0 or BattleArena.BORDER_H
  end
  local sample=sampleCell(map,cx,cy)
  if sample and sample.height~=nil then return sample.height end
  local h = groundAt(map, wx, wz)
  -- Ground height alone cannot see a house: buildings, walls and trees occupy
  -- collision cells above an otherwise level route. Treat blocked non-water
  -- cells as conservative vertical columns. This matches their gameplay
  -- footprint and also covers collision-backed facades without importing the
  -- renderer's decorative mesh internals into the camera planner.
  if type(map.isWalkableCell) == "function" then
    local okWalk, walkable = pcall(map.isWalkableCell, map, cx, cy)
    local water = false
    if type(map.isWaterCell) == "function" then
      local okWater, value = pcall(map.isWaterCell, map, cx, cy)
      water = okWater and value and true or false
    end
    if okWalk and not walkable and not water then
      h = h + BattleArena.SOLID_H
    end
  end
  local art = surfaceArtAt(map, cx, cy)
  if art == "grass" or art == "flower" then
    h = h + BattleArena.DECOR_H
  end
  if sample then sample.height=h end
  return h
end

local function heightAt(map,wx,wz)
  if not(resultCache and resultCache.recording)then return rawHeightAt(map,wx,wz)end
  local cx,cy=math.floor(wx/CELL),math.floor(wz/CELL)
  if query('bounds',map,cx,cy)then return query('height',map,cx,cy)end
  return query('outsideHeight',map,wx,wz)
end

-- Whether the segment from `eye` to (tx, ty, tz) clears the terrain.
local function lineClear(map, eye, tx, ty, tz)
  local dx, dy, dz = tx - eye[1], ty - eye[2], tz - eye[3]
  local len = math.sqrt(dx * dx + dy * dy + dz * dz)
  if len <= 1 then return true end
  local steps = math.ceil(len / BattleArena.SAMPLE_STEP)
  -- skip the ends: the eye is in open air by construction and the last step
  -- is the mon's own tile, which it is standing on
  for i = 1, steps - 1 do
    local t = i / steps
    local wx = eye[1] + dx * t
    local wy = eye[2] + dy * t
    local wz = eye[3] + dz * t
    if heightAt(map, wx, wz) > wy + BattleArena.CLEAR_EPS then return false end
  end
  return true
end

-- Public camera-director seam.  Arena selection uses the canonical shot above,
-- while the Stadium director needs the same answer for every authored portrait
-- and orbit it visits later.  A score of three is a completely readable actor;
-- zero is a full terrain curtain.  Keeping the test here makes selection and
-- live camera safety agree about trees, walls, ledges and the map border.
function BattleArena.visibility(map, eye, mark, groundY, height)
  if not (map and type(map.inBounds) == "function"
          and type(eye) == "table" and type(mark) == "table") then
    return 3
  end
  groundY = tonumber(groundY) or 0
  height = math.max(4, tonumber(height) or BattleArena.MON_H)
  local score = 0
  for _, hy in ipairs({ 1, height * 0.5, height }) do
    if lineClear(map, eye, mark[1], groundY + hy, mark[2]) then
      score = score + 1
    end
  end
  return score
end

-- An eye may look past foreground scenery, but it may never occupy the map's
-- solid column or leave the rendered map.  The small headroom is deliberately
-- larger than CLEAR_EPS so a low travelling shot cannot skim a canopy/roof.
function BattleArena.cameraClear(map, eye, edgeMargin)
  if not (map and type(map.inBounds) == "function"
          and type(eye) == "table") then return true end
  local wx, wz = tonumber(eye[1]) or 0, tonumber(eye[3]) or 0
  local margin = tonumber(edgeMargin)
  if margin == nil then margin = BattleArena.CAMERA_EDGE_MARGIN end
  margin = math.max(0, margin)
  if query('apron',map,wx,wz) then
    return heightAt(map,wx,wz)+3<(eye[2] or 0)
  end
  if wx < margin or wz < margin
      or wx >= map.widthCells * CELL - margin
      or wz >= map.heightCells * CELL - margin then return false end
  local cx, cy = math.floor(wx / CELL), math.floor(wz / CELL)
  if not query('bounds',map,cx,cy)then return false end
  return heightAt(map, wx, wz) + 3 < (eye[2] or 0)
end

-- Validate the complete camera move, not merely its destination.  Houses,
-- walls and tree columns can sit between two individually valid seats.  Sample
-- a small camera body along the segment so the near plane cannot skim through
-- a facade while the eye point itself just misses it.  A cinematic cut may
-- deliberately use cameraClear() at its destination instead; no physical path
-- is traversed during a cut.
function BattleArena.cameraPathClear(map, fromEye, toEye)
  if not (type(fromEye) == "table" and type(toEye) == "table") then return true end
  if not (map and type(map.inBounds) == "function") then return true end
  local dx = (toEye[1] or 0) - (fromEye[1] or 0)
  local dy = (toEye[2] or 0) - (fromEye[2] or 0)
  local dz = (toEye[3] or 0) - (fromEye[3] or 0)
  local len = math.sqrt(dx * dx + dy * dy + dz * dz)
  local steps = math.max(1, math.ceil(len / BattleArena.SAMPLE_STEP))
  local flat = math.sqrt(dx * dx + dz * dz)
  local ox, oz = BattleArena.CAMERA_RADIUS, 0
  if flat > 1e-6 then
    ox, oz = -dz / flat * BattleArena.CAMERA_RADIUS,
             dx / flat * BattleArena.CAMERA_RADIUS
  end
  for i = 0, steps do
    local t = i / steps
    local eye = {
      (fromEye[1] or 0) + dx * t,
      (fromEye[2] or 0) + dy * t,
      (fromEye[3] or 0) + dz * t,
    }
    if not BattleArena.cameraClear(map, eye)
       or not BattleArena.cameraClear(map, { eye[1] + ox, eye[2], eye[3] + oz })
       or not BattleArena.cameraClear(map, { eye[1] - ox, eye[2], eye[3] - oz }) then
      return false
    end
  end
  return true
end

-- Whether both mons would be in plain view from the battle camera.
function BattleArena.clearance(map, arena)
  local BattleCam = V.require("BattleCam")
  -- the CANONICAL shot: whether a fight fits somewhere is a fact about the
  -- ground, so it must not depend on the drift's phase or on where the
  -- player last swung the camera (see BattleCam.rig's third argument)
  local eh = groundAt(map, arena.enemy[1], arena.enemy[2])
  local ph = groundAt(map, arena.player[1], arena.player[2])
  local groundY = tonumber(arena.anchorHeight) or (eh + ph) / 2
  local recording=resultCache and resultCache.recording
  local eye
  if recording then
    local ok,x,y,z=query('camera',arena,groundY,true)
    if not ok then return true end
    eye={x,y,z}
  else
    local ok,rig=pcall(BattleCam.rig,arena,groundY,true)
    if not(ok and rig and rig.eye)then return true end
    eye=rig.eye
  end
  if not BattleArena.cameraClear(map, eye,
                                 BattleArena.CAMERA_EDGE_MARGIN) then
    return false,"camera-obstruction"
  end
  for _, mark in ipairs({ arena.player, arena.enemy }) do
    if BattleArena.visibility(map, eye, mark, groundY) < 3 then return false,"pokemon-visibility" end
  end
  if arena.trainerOffsets then
    local H=V.require('BattleHeroesBridge')
    local geometry=geometryScope and geometryScope[map]
    if not geometry then
      geometry=H.geometryForMap(map)
      if geometryScope then geometryScope[map]=geometry end
    end
    -- Reserve the full body as well as the foot. The live card/HUD check
    -- still validates actual art, user sizing and manual camera changes.
    for _,side in ipairs({"player","enemy"}) do
      local mark,offset=arena[side],arena.trainerOffsets[side]
      local x,z=mark[1]+offset[1]*1.5,mark[2]+offset[2]*1.5
      for _,dx in ipairs({-8,0,8}) do
        for _,dz in ipairs({-6,0,6}) do
          if not openCell(map,math.floor((x+dx)/CELL),math.floor((z+dz)/CELL),arena.surfing==true) then return false,"trainer-footprint" end
          if math.abs(groundAt(map,x+dx,z+dz)-groundY)>.5 then return false,"trainer-height" end
          local obstacle
          if recording then obstacle=query('geometry',map,x+dx,z+dz)
          else obstacle=geometry(x+dx,z+dz)end
          if obstacle>groundY+.5 then return false,"trainer-geometry" end
        end
        if BattleArena.visibility(map,eye,{x+dx,z},groundY,27)<3 then return false,"trainer-visibility" end
        for _,rise in ipairs({1,13.5,27}) do
          local clear
          if recording then clear=query('geometryRay',map,eye,{x+dx,groundY+rise,z})
          else clear=H.geometryClear(geometry,eye,{x+dx,groundY+rise,z})end
          if not clear then return false,"trainer-geometry-ray" end
        end
      end
    end
  end
  return true
end

local function rawCompactInterior(map)
  -- A low, close camera is also valid in enclosed forest/cave aisles.
  -- Candidate footprints, height and visibility still pass the same checks.
  local tileset=map and map.def and map.def.tileset
  if tileset=='FOREST' or tileset=='CAVERN' then return true end
  local ok, rooms = pcall(V.require, "Gen1InteriorPanoramas")
  return ok and type(rooms) == "table"
    and type(rooms.profileFor) == "function"
    and rooms.profileFor(map) ~= nil
end

local function compactInterior(map)return query('compact',map)end

-- Promote an otherwise safe placement to the short physical rig when the
-- telephoto eye has no collision-backed room. Ships and narrow courts in
-- recognised native interiors may also use a short aisle seat. Every option
-- must pass the same complete visibility and camera-clearance checks
-- before it can own a physical arena.
function BattleArena.keepAnchorSafe(map, arena, allowCompact)
  local safe,why=BattleArena.clearance(map,arena)
  if safe then return true end
  if arena then arena.clearanceReason=why end
  local previous = arena and arena.cam
  if arena then arena.cam = "wide" end
  if BattleArena.clearance(map, arena) then return true end
  local compactRoom = allowCompact and arena and arena.narrow
    and compactInterior(map)
  if arena and (compactRoom
      or tostring(map and map.id or ""):match("^SS_ANNE_")) then
    arena.cam = compactRoom and "compact" or "ship"
    if BattleArena.clearance(map, arena) then return true end
  end
  if arena then arena.cam = previous end
  return false
end

-- The nearest arena to (fromX, fromY) -- the player's cell -- or nil when
-- the map has no safe authored court or local placement.
--
-- Distance is measured from the player to the arena's MIDPOINT, so "nearest"
-- means the fight is staged as close to where it was triggered as the ground
-- allows, rather than merely having a corner nearby.
--
-- Both shapes are searched over the whole map before the next one is tried:
-- a wide arena on the far side of a route still beats a narrow one
-- underfoot, because the wide one is the shot this mode is framed for.
-- Validate courts once per request. The returned review can also be used by
-- the native coverage audit to assign EVERY encounter cell without repeating
-- the expensive geometry rays. It is never retained across map/terrain edits.
function BattleArena.review(map, surfing)
  local review = { map=map, surfing=surfing==true, candidates={}, rejected={} }
  if not (map and map.widthCells) then review.reason="missing-map"; return review end
  local pick = authoredFor(map.id,map)
  review.pick = pick
  if pick == false then review.reason="authored-refusal"; return review end
  local entries = entryList(pick)
  review.total = #entries
  local grids = {}
  for index, entry in ipairs(entries) do
    local shape
    for _, candidate in ipairs(BattleArena.SHAPES) do
      if candidate.id == (entry.shape or "wide") then shape = candidate end
    end
    local host = map
    if shape and entry.map and entry.map ~= map.id then
      host = query('foreign',entry.map)
    end
    local reason
    if not shape or not host or not finiteInteger(entry.x) or not finiteInteger(entry.y) then
      reason = "invalid-court"
    elseif entry.terrain and entry.terrain ~= query('terrain') then
      reason = "terrain-mode"
    elseif entry.surface and entry.surface ~= (surfing and "water" or "land") then
      reason = "surface"
    else
      local surfaces = grids[host]
      if not surfaces then surfaces={}; grids[host]=surfaces end
      local key = entry.surface or "any"
      local cached = surfaces[key]
      if not cached then
        local grid, width = openGrid(host, true, nil, entry.surface)
        cached={grid,width}; surfaces[key]=cached
      end
      if not fits(cached[1],cached[2],entry.x,entry.y,shape.w,shape.h) then
        reason = "footprint"
      else
        local arena = place(shape,entry.x,entry.y)
        arena.map, arena.cam, arena.surfing = host,entry.cam,surfing==true
        arena.anchorSource,arena.anchorIndex = "authored",index
        local eh=groundAt(host,arena.enemy[1],arena.enemy[2])
        local ph=groundAt(host,arena.player[1],arena.player[2])
        arena.anchorHeight=(eh+ph)/2
        arena.anchorHeightDelta=math.abs(eh-ph)
        if not BattleArena.keepRouteAnchorInBounds(map,arena) then
          reason="camera-bounds"
        elseif not BattleArena.keepAnchorSafe(host,arena) then
          reason=arena.clearanceReason or "clearance"
        else
          review.candidates[#review.candidates+1]=arena
        end
      end
    end
    if reason then review.rejected[#review.rejected+1]=index..":"..reason end
  end
  if #review.candidates==0 then
    local surface=surfing and "water" or "land"
    local fallback=type(pick)=="table" and pick.fallbacks and pick.fallbacks[surface]
    if fallback=="terarrium" or type(pick)=="table" and pick.fixed and #entries==0 then
      review.fallbackMode="terarrium"
      review.reason="authored-"..surface.."-terrarium"
    else review.reason="no-safe-map-placement" end
  end
  return review
end

-- Authored courts serve the entire map/surface, including disconnected grass
-- patches and route ends. A distance cap belongs to the local placement search;
-- applying it to fixed courts left legitimate encounters without an assignment.
-- This chooses a court only: it never teleports the overworld player or opens
-- collision/quest gates. Height still ranks before distance.
function BattleArena.assign(review, fromX, fromY)
  local map=review.map
  if not map then return nil end
  local originHeight=groundAt(map,fromX*CELL+CELL/2,fromY*CELL+CELL/2)
  local best,bestScore
  for _,arena in ipairs(review.candidates) do
    local dx,dy=arena.mid[1]/CELL-fromX,arena.mid[2]/CELL-fromY
    local distance=dx*dx+dy*dy
    local fixed=type(review.pick)=="table" and review.pick.fixed
    if fixed or arena.map~=map or distance<=BattleArena.MAX_ANCHOR_DISTANCE^2 then
      local score=distance+arena.anchorIndex*1e-6
      if arena.map==map then
        score=score+math.abs(arena.anchorHeight-originHeight)*100000
          +arena.anchorHeightDelta*1000000
      else score=score+10000000 end
      if not bestScore or score<bestScore then best,bestScore=arena,score end
    end
  end
  return best
end

local function findUncached(map, fromX, fromY, surfing)
  local searchGrids={} -- one collision snapshot per find, including fallback
  local review=BattleArena.withVisibilitySamples(BattleArena.review,map,surfing)
  local pick=review.pick
  if not (map and map.widthCells) or pick==false then return nil,review end
  local authoredBest=BattleArena.assign(review,fromX,fromY)
  local originHeight=groundAt(map,fromX*CELL+CELL/2,fromY*CELL+CELL/2)
  -- A bounded local candidate gives large routes and caves more than one
  -- repeated postcard. It must be on the exact player height, visible from a
  -- canonical battle rig, and close enough that the scene still reads as the
  -- encounter location. Towns/cities additionally require a one-cell open
  -- apron, excluding the narrow house corridors that prompted this change.
  local def = map.def or {}
  local tileset = tostring(def.tileset
    or (map.tileset and map.tileset.id) or "")
  local adaptiveSurface = tileset == "OVERWORLD" or tileset == "FOREST"
                       or tileset == "CAVERN" or tileset == "PLATEAU"
                       or tileset == "SHIP_PORT"
  local adaptive = adaptiveSurface
  if type(pick) == "table" and pick.adaptive ~= nil then
    adaptive = pick.adaptive == true
  end
  if type(pick)=='table' and pick.fixed then adaptive=false end
  local id = tostring(map.id or "")
  local urban = id:match("_CITY$") or id:match("_TOWN$")
  if adaptive then
    local localPick = BattleArena.search(map, fromX, fromY, surfing, true, {
      height = originHeight, maxDistance = BattleArena.MAX_ANCHOR_DISTANCE,
      roomy = urban and true or false, wideOnly = urban and true or false,
    },searchGrids)
    if localPick then
      localPick.map = map
      localPick.anchorSource = "local-height"
      localPick.anchorHeight = originHeight
      return localPick
    end
  end
  if authoredBest then return authoredBest,review end
  -- Reviewed regional courts must not silently turn back into arbitrary
  -- placements when a map mod blocks one. Let the caller use its 3D fallback.
  if type(pick)=='table' and pick.fixed then return nil,review end

  local found
  if not adaptive then found = BattleArena.search(map, fromX, fromY, surfing, true, {
    height = originHeight, maxDistance = BattleArena.MAX_ANCHOR_DISTANCE,
    roomy = urban and true or false, wideOnly = urban and true or false,
  },searchGrids) end
  -- Exhaust the existing placements before adding a shorter indoor camera.
  -- A nearer compact candidate must not displace an already working arena.
  if not found and compactInterior(map) then
    found = BattleArena.search(map, fromX, fromY, surfing, true, {
      height = originHeight, maxDistance = BattleArena.MAX_ANCHOR_DISTANCE,
      compact = true,
    },searchGrids)
  end
  if found then found.map = map end
  return found,review
end

-- The arena at a given north-west corner, whatever the map says about it.
-- The authoring tool's manual override: a spot chosen by eye rather than by
-- the search, so it can be photographed and judged before it is written down.
function BattleArena.at(x, y, shapeId)
  for _, shape in ipairs(BattleArena.SHAPES) do
    if shape.id == (shapeId or "wide") then return place(shape, x, y) end
  end
  return nil
end

-- The nearest arena the map can offer, preferring one the pair can be SEEN
-- in. Two passes rather than one score: a clear arena on the far side of a
-- route beats an obstructed one underfoot, because being able to see the
-- fight is the point, but an obstructed one still beats no battle at all.
function BattleArena.search(map, fromX, fromY, surfing, wantClear, options, grids)
  options = type(options) == "table" and options or nil
  local key=options and options.compact and "compact" or "normal"
  local held=grids and grids[key]
  if not held then
    held={openGrid(map,surfing,options and options.compact)}
    if grids then grids[key]=held end
  end
  local grid,gw,gh=held[1],held[2],held[3]
  local passes = wantClear and { true } or { true, false }
  local shapes = options and options.wideOnly
    and { BattleArena.SEARCH_SHAPES[1] } or BattleArena.SEARCH_SHAPES
  for _,shape in ipairs(shapes)do
    local candidates={}
    local minX,maxX,minY,maxY=0,gw-shape.w,0,gh-shape.h
    local radius=options and options.maxDistance
    if radius then
      radius=math.abs(radius)
      minX=math.max(minX,math.ceil(fromX-(shape.w-1)/2-radius))
      maxX=math.min(maxX,math.floor(fromX-(shape.w-1)/2+radius))
      minY=math.max(minY,math.ceil(fromY-(shape.h-1)/2-radius))
      maxY=math.min(maxY,math.floor(fromY-(shape.h-1)/2+radius))
    end
    for y=minY,maxY do for x=minX,maxX do
      local dx,dy=x+(shape.w-1)/2-fromX,y+(shape.h-1)/2-fromY
      local d=dx*dx+dy*dy
      if (not radius or d<=radius*radius) and fits(grid,gw,x,y,shape.w,shape.h)
        and (not(options and options.roomy) or x>0 and y>0
          and x+shape.w<gw and y+shape.h<gh and fits(grid,gw,x-1,y-1,shape.w+2,shape.h+2))then
        candidates[#candidates+1]={x=x,y=y,d=d,order=#candidates+1}
      end
    end end
    -- Preserve row-major tie-breaking exactly. The first valid nearest court
    -- is the same answer as the exhaustive best-so-far search.
    table.sort(candidates,function(a,b)return a.d<b.d or a.d==b.d and a.order<b.order end)
    for _,needClear in ipairs(passes)do
      for _,at in ipairs(candidates)do
        local cand=place(shape,at.x,at.y)
        local allowed=BattleArena.keepRouteAnchorInBounds(map,cand)
        if allowed and options and options.height~=nil then
          local eh=groundAt(map,cand.enemy[1],cand.enemy[2])
          local ph=groundAt(map,cand.player[1],cand.player[2])
          allowed=math.abs(eh-options.height)<=.01 and math.abs(ph-options.height)<=.01
        end
        if allowed and (not needClear or BattleArena.keepAnchorSafe(map,cand,options and options.compact))then
          return cand
        end
      end
    end
  end
  return nil
end

queryReaders.open=rawOpenCell
queryReaders.water=function(map,x,y)return not not(map.isWaterCell and map:isWaterCell(x,y))end
queryReaders.support=function(map,x,y)
  local ok,f=pcall(V.require,'VoxelFurniture')
  return ok and type(f)=='table' and type(f.supportAt)=='function'
    and f.supportAt(map,x*CELL,y*CELL,true)==nil or false
end
queryReaders.bounds=function(map,x,y)return map:inBounds(x,y)end
queryReaders.ground=function(map,x,y)return rawGroundAt(map,x*CELL,y*CELL)end
queryReaders.height=function(map,x,y)return rawHeightAt(map,x*CELL,y*CELL)end
queryReaders.outsideHeight=rawHeightAt
queryReaders.apron=function(map,x,y)return BattleArena.inCameraApron(map,x,y)end
queryReaders.compact=rawCompactInterior
queryReaders.terrain=function()return V.require('LedgeElevation').mode()end
queryReaders.camera=function(arena,ground,strict)
  local ok,cam
  if strict then ok,cam=true,V.require('BattleCam')
  else ok,cam=pcall(V.require,'BattleCam')end
  if not ok or type(cam)~='table' or type(cam.rig)~='function'then return false end
  local valid,rig=pcall(cam.rig,arena,ground,true)
  if not(valid and rig and rig.eye)then return false end
  return true,rig.eye[1],rig.eye[2],rig.eye[3]
end
queryReaders.foreign=function(id)
  local ok,map=pcall(function()
    return require('src.world.MapLoader').load(require('src.core.Game').data,id)
  end)
  return ok and map or nil
end
-- Geometry factories remain live. Reuse only within one synchronous query
-- validation/solve, not across edits or calls to find.
local function geometryFor(map)
  local held=geometryScope and geometryScope[map]
  if not held then
    held=V.require('BattleHeroesBridge').geometryForMap(map)
    if geometryScope then geometryScope[map]=held end
  end
  return held
end
queryReaders.geometry=function(map,x,z)return geometryFor(map)(x,z)end
queryReaders.geometryRay=function(map,eye,point)
  return V.require('BattleHeroesBridge').geometryClear(geometryFor(map),eye,point)
end
local nativeSeams={}
local function cacheKey(map,x,y,surfing)
  if type(map)~='table'then return nil end
  for key,fn in pairs(nativeSeams)do if BattleArena[key]~=fn then return nil end end
  return BattleArena.requestKey(map,x,y,surfing)
end
function BattleArena.find(map,x,y,surfing)
  if not resultCache then return findUncached(map,x,y,surfing)end
  local pick=map and authoredFor(map.id,map)
  local configuration={pick=pick,x=x,y=y,surfing=surfing,shapes=BattleArena.SHAPES,search=BattleArena.SEARCH_SHAPES,
    step=BattleArena.SAMPLE_STEP,monH=BattleArena.MON_H,clear=BattleArena.CLEAR_EPS,
    radius=BattleArena.CAMERA_RADIUS,edge=BattleArena.CAMERA_EDGE_MARGIN,
    distance=BattleArena.MAX_ANCHOR_DISTANCE,solid=BattleArena.SOLID_H,
    border=BattleArena.BORDER_H,decor=BattleArena.DECOR_H}
  local key=cacheKey(map,x,y,surfing)
  local priorGeometry,priorSamples=geometryScope,visibilitySamples
  geometryScope={};visibilitySamples=nil
  local function done(ok,...)
    geometryScope,visibilitySamples=priorGeometry,priorSamples
    if not ok then error((...),0)end
    return ...
  end
  return done(pcall(resultCache.run,key,configuration,findUncached,map,x,y,surfing))
end
function BattleArena.resultCacheStatus()
  return resultCache and {hits=resultCache.hits,misses=resultCache.misses,rejected=resultCache.rejected}
    or {hits=0,misses=0,rejected=0}
end
function BattleArena.setResultCacheEnabled(enabled)
  if resultCache then resultCache.enabled=enabled~=false;resultCache.clear()end
end
for key,fn in pairs(BattleArena)do
  if type(fn)=='function'and key~='find'and key~='resultCacheStatus'
      and key~='setResultCacheEnabled'then nativeSeams[key]=fn end
end

return BattleArena
