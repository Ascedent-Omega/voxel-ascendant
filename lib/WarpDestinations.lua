-- Predict the same destination as the native step, including LAST_MAP and
-- mod reroutes. A failed resolver must never preload its unmodified fallback.
local M = {}
function M.resolve(game, ow, warp)
  local ok, api = pcall(require, 'src.world.Warp')
  if not ok or type(api.destination) ~= 'function' then return nil end
  local resolved, id = pcall(api.destination, game.data, warp, ow.lastOutdoor)
  if resolved and game.data.maps[id] then return id end
end
return M
