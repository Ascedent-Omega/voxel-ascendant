-- Small shared audio focus owner for weather details. It never owns music or
-- changes the saved volume: the engine's music.volume seam receives a brief
-- multiplier and returns smoothly to the user's configured level.

local V = ...
local AmbientAudio = {
  remaining = 0, duration = 0, target = 1,
  installed = false, lastWeatherKey = nil, windSource = nil,
}

local function finite(value, fallback)
  if type(value) ~= "number" or value ~= value
      or value == math.huge or value == -math.huge then return fallback end
  return value
end

function AmbientAudio.factor()
  if AmbientAudio.remaining <= 0 or AmbientAudio.duration <= 0 then return 1 end
  local left = math.max(0, math.min(1,
    AmbientAudio.remaining / AmbientAudio.duration))
  -- Hold the dip briefly, then use a smooth return with no volume step.
  local recovery = 1 - left
  recovery = recovery * recovery * (3 - 2 * recovery)
  return AmbientAudio.target + (1 - AmbientAudio.target) * recovery
end

function AmbientAudio.duck(target, seconds)
  target = math.max(.35, math.min(1, finite(target, 1)))
  seconds = math.max(0, finite(seconds, 0))
  if seconds <= 0 then return false end
  AmbientAudio.target = math.min(AmbientAudio.target, target)
  AmbientAudio.remaining = math.max(AmbientAudio.remaining, seconds)
  AmbientAudio.duration = math.max(AmbientAudio.duration, seconds)
  return true
end

function AmbientAudio.update(dt)
  dt = math.max(0, finite(dt, 0))
  AmbientAudio.remaining = math.max(0, AmbientAudio.remaining - dt)
  if AmbientAudio.remaining == 0 then
    AmbientAudio.duration, AmbientAudio.target = 0, 1
  end
end

function AmbientAudio.install(mod)
  if AmbientAudio.installed then return true end
  if not (mod and mod.hooks and type(mod.hooks.wrap) == "function") then
    return false
  end
  mod.hooks:wrap("music.volume", function(next, volume, ctx)
    return next((tonumber(volume) or 0) * AmbientAudio.factor(), ctx)
  end)
  V.require("WeatherAudio").install(mod)
  AmbientAudio.installed = true
  return true
end

-- Render events only schedule an envelope; loading and playback happen in
-- WeatherAudio's single update owner, including stereo/VR duplicate draws.
function AmbientAudio.weatherEvent(event, game)
  return V.require("WeatherAudio").gust(event)
end

return AmbientAudio
