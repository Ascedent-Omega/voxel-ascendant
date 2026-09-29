-- Compatibility entry: the shared update owner handles both generations.
local V=...
return {onLightning=function(...)return V.require('WeatherAudio').onLightning(...)end,
 update=function()end}
