-- Reviewed reuse candidates for a few exact Sevii source areas. The normal
-- arena gallery stays authoritative for Kanto, Johto and unknown maps.
local V=...
local M={}
local bindings={
  ThreeIsland_BerryForest={kind='canopy',style='forest',backdrop='VIRIDIAN_FOREST'},
  SixIsland_PatternBush={kind='canopy',style='forest',backdrop='VIRIDIAN_FOREST'},
  OneIsland_TreasureBeach={kind='water',style='coast',backdrop='ROUTE_19'},
}
-- The imported cave palette already identifies the matching Kanto family.
-- Reuse that family's reviewed ARENA art, just as its materials are reused.
local caves={
  mt_moon={backdrop='MT_MOON_1F',style='cave',outdoor=false},
  rock_tunnel={backdrop='ROCK_TUNNEL_1F',style='cave',outdoor=false},
  seafoam={backdrop='SEAFOAM_ISLANDS_1F',style='cave',outdoor=false},
  diglett={backdrop='DIGLETTS_CAVE',style='cave',outdoor=false},
  cerulean={backdrop='CERULEAN_CAVE_1F',style='cave',outdoor=false},
  victory_road={backdrop='VICTORY_ROAD_1F',style='cave',outdoor=false},
}
local receipts=setmetatable({},{__mode='k'})

local function selected(map)
  local p=V.require('KascSeviiScenery').profile(map)
  local row=p and bindings[p.source]
  if not(row and p.kind==row.kind and p.exterior==true)then return nil end
  return p,row
end

function M.styleFor(map)
  local _,row=selected(map)
  if row then return row.style end
  -- Imported tileset IDs and source names (e.g. RubyPath) need not contain
  -- CAVE. Use the validated scenery contract, just as native cavern maps do.
  local p=V.require('KascSeviiScenery').profile(map)
  if not p then return nil end
  if p.kind=='cave' then return 'cave' end
  if p.kind=='canopy' then return 'forest' end
  if p.kind=='mountain' and p.exterior then return 'moon_approach' end
  -- Imported atlas IDs do not equal OVERWORLD and source route names need
  -- not contain CITY/TOWN. Use the authenticated source header type for the
  -- same existing Kanto city/route/interior families. Reviewed ARENA artwork
  -- remains separately owned by forMap; this adds no painted backdrop.
  if p.sourceMapType==1 then return 'city' end
  if p.sourceMapType==3 then return 'grass' end
  if p.sourceMapType==8 then return 'interior' end
  error('unmapped Sevii battle family map='..tostring(map.id)..' source='..p.source
    ..' mapType='..tostring(p.sourceMapType))
end

function M.forMap(map,reviewedSpecs)
  local p,row=selected(map)
  if not p then
    p=V.require('KascSeviiScenery').profile(map)
    row=p and p.kind=='cave' and caves[p.cave]
  end
  if not(p and type(reviewedSpecs)=='table')then return nil end
  if not row then return nil end
  local spec=reviewedSpecs[row.backdrop]
  if type(spec)~='table'or spec.outdoor~=(row.outdoor~=false) then return nil end
  local previous=receipts[map]
  if previous and previous.spec==spec then return previous end
  local receipt={source=p.source,reviewedBackdropId=row.backdrop,
    style=row.style,mapId=map.id,spec=spec}
  receipts[map]=receipt
  return receipt
end

return M
