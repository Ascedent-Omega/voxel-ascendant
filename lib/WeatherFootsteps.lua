-- Short procedural surface steps for VASC weather. No audio asset is bundled:
-- the tiny mono buffers are synthesized lazily on the first relevant step,
-- respect the engine SFX volume, and are reused thereafter.

local V = ...
local WeatherFootsteps = {}
local AmbientAudio = V.require("AmbientAudio")
WeatherFootsteps.setting=V.require("ModSetting").new("surfaceFootsteps","FOOTSTEPS",{true,false},{"ON","OFF"},true)

local RATE, VARIANTS = 22050, 3
local DURATION = { snow=.27, splash=.15, snowBike=.24, splashBike=.22, wood=.12,stone=.10,grass=.13,ash=.15 }
local banks = { snow = {}, splash = {}, snowBike={}, splashBike={},wood={},stone={},grass={},ash={} }
local cursor = { snow = 0, splash = 0, snowBike=0, splashBike=0,wood=0,stone=0,grass=0,ash=0 }

local function clamp(n)
  return math.max(-1, math.min(1, n))
end

local function build(kind, variant)
  if not (love and love.sound and love.sound.newSoundData
          and love.audio and love.audio.newSource) then return nil end
  local count = math.floor(RATE * DURATION[kind])
  local ok, data = pcall(love.sound.newSoundData, count, RATE, 16, 2)
  if not ok or not data then return nil end
  local snow = kind == 'snow' or kind == 'snowBike'
  local bike = kind == 'snowBike' or kind == 'splashBike'
  local seed = 9137 + variant * 7919 + (snow and 337 or 977)
  local previous, filtered = 0, 0
  for i = 0, count - 1 do
    seed = (seed * 1103515245 + 12345) % 2147483647
    local noise = seed / 1073741823.5 - 1
    local t = i / RATE
    local envelope = bike and math.sin(math.pi*t/DURATION[kind])^2
                     or math.exp(-t * (snow and 24 or 30))
    local sample
    if kind=='wood'or kind=='stone'or kind=='grass'then
      filtered=filtered*.68+noise*.32
      local pitch=kind=='wood'and 130 or kind=='stone'and 310 or 85
      local tap=math.sin(t*math.pi*2*(pitch+variant*9))*math.exp(-t*65)
      sample=(filtered*(kind=='grass'and .5 or .16)+tap*(kind=='grass'and .08 or .22))*envelope
    elseif kind=='ash'then
      filtered=filtered*.48+noise*.52
      local grains=.3+.7*math.max(0,math.sin(t*(240+variant*17)))
      sample=filtered*grains*.42*envelope
    elseif snow then
      -- Three close granular compressions make a dry, soft crunch rather
      -- than a generic white-noise hiss.
      filtered=filtered*.82+noise*.18
      local attack=math.min(1,t/.006)
      local thump=math.sin(2*math.pi*(76+variant*4)*t)*math.exp(-t*38)
      local crush=math.exp(-t*15)*(.25+.75*math.max(0,math.sin(t*(100+variant*13))))
      local heel=math.exp(-math.abs(t-.065)*65)
      sample=attack*(thump*.42+filtered*(crush*.8+heel*.32))
    else
      -- Filtered noise is the wet sole; the low decaying chirp is the small
      -- displaced-water "plop". The source stays short, while the volume duck
      -- gives it a clear foreground instant without masking the whole track.
      filtered = filtered * .72 + noise * .28
      local plop = math.sin(t * math.pi * 2 * (145 + variant * 17))
                   * math.exp(-t * 38)
      sample = filtered * envelope * (bike and .9 or .48)
               + plop * (bike and .06 or .30)
    end
    previous = noise
    pcall(data.setSample, data, i, 1, clamp(sample))
    pcall(data.setSample, data, i, 2, clamp(sample))
  end
  local sourceOK, source = pcall(love.audio.newSource, data, "static")
  if data.release then data:release()end
  if not sourceOK then return nil end
  return source
end

-- Fill one reusable sound buffer per covered update, before the first step.
function WeatherFootsteps.prepare()
  if not WeatherFootsteps.setting:get() then return false end
  for _,kind in ipairs{'snow','splash','wood','stone','grass','ash','snowBike','splashBike'} do
    for variant=1,VARIANTS do
      if banks[kind][variant]==nil then
        banks[kind][variant]=build(kind,variant) or false
        return true
      end
    end
  end
  return false
end

local function sfxScale(game)
  local options = game and game.save and game.save.options
  local value = options and tonumber(options.sfxVol)
  if value == nil then return 1 end
  return math.max(0, math.min(7, value)) / 7
end

function WeatherFootsteps.surface(world)
 local map,p=world and world.map,world and world.player
 if not(map and p and map.def)then return nil end
 if type(map.isGrassCell)=='function'and map:isGrassCell(p.cellX,p.cellY)then return 'grass'end
 local set=map.def.tileset
 if set=='OVERWORLD'and type(map.cellTile)=='function'then
  local scenery=V.require('Gen1OutdoorScenery')
  local material=scenery.material(map,scenery.profile(map),map:cellTile(p.cellX,p.cellY),p.cellX*2,p.cellY*2+1)
  if material==-183 then return 'ash'end
  if material==-130 or material==-131 then return 'wood'end
  if material==-162 or material==-163 or material==-165 or material==-173
    or material==-168 or material==-169 or material==-170 then return 'stone'end
 end
 if set=='OVERWORLD'or set=='FOREST'then return 'grass'end
 if set=='REDS_HOUSE_1'or set=='REDS_HOUSE_2'or set=='HOUSE'or set=='SHIP'or set=='MANSION'then return 'wood'end
 return 'stone'
end

function WeatherFootsteps.onStep(game, mode, surfaceAmount)
  local world = game and (game.overworld or game.world)
  if not WeatherFootsteps.setting:get()or not (world and world.player) then return false end
  local player = world.player
  if player.surfing then return false end
  local scale = sfxScale(game)
  if scale <= 0 then return false end
  if mode == 'rain' or mode == 'storm' or mode == 'snow' then
    local Audio=V.require('WeatherAudio')
    if not Audio.shelter(game) then
      return Audio.step(game,mode,surfaceAmount,WeatherFootsteps.surface(world))
    end
    mode='clear'
  end
  surfaceAmount = tonumber(surfaceAmount)
  local kind = mode == "snow" and (surfaceAmount == nil or surfaceAmount > .08)
               and "snow"
               or ((mode == "rain" or mode == "storm") and "splash" or nil)
  if not kind then
    if game.save and game.save.onBike then return false end
    kind=WeatherFootsteps.surface(world)
  end
  if not kind then return false end
  local snow, bike = kind == 'snow', game.save and game.save.onBike
  if bike then kind = kind .. 'Bike' end
  cursor[kind] = cursor[kind] % VARIANTS + 1
  local source = banks[kind][cursor[kind]]
  if not source then
    source = build(kind, cursor[kind])
    banks[kind][cursor[kind]] = source or false
  end
  if not source then return false end
  local coat = snow
               and (.65 + .35 * math.max(0, math.min(1, surfaceAmount or 1)))
               or 1
  local dry=kind=='wood'or kind=='stone'or kind=='grass'or kind=='ash'
  local volume = (dry and .24 or snow and .68 or .58) * scale * coat
  if bike then volume=volume*.85 end
  if source.stop then pcall(source.stop, source) end
  if source.setVolume then pcall(source.setVolume, source, volume) end
  if source.setPitch then
    pcall(source.setPitch, source, .96 + cursor[kind] * .025)
  end
  if source.play then
    local ok = pcall(source.play, source)
    if ok and not dry and AmbientAudio and type(AmbientAudio.duck) == "function" then
      AmbientAudio.duck(bike and .78 or (snow and .60 or .66),
                        bike and .16 or (snow and .30 or .24))
    end
    return ok
  end
  return false
end

return WeatherFootsteps
