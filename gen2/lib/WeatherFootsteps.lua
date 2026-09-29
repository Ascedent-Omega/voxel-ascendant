local V=...
local M={}
function M.onStep(game,mode,amount)
 local world=game and(game.world or game.overworld)
 local p=world and world.player;local map=world and world.map
 if not(p and map)then return false end
 local grass=map.isGrassCell and map:isGrassCell(p.cellX,p.cellY)
 return V.require('WeatherAudio').step(game,mode,amount,grass and 'grass' or 'stone')
end
return M
