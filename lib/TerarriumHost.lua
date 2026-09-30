-- Narrow opt-in seam. Portable battle lifecycle remains owned by VASC.
local V = ...
local H = {service=nil}
function H.available() return H.service ~= nil end
local seas={ROUTE_19=true,ROUTE_20=true,ROUTE_21=true,PALLET_TOWN=true,
 CINNABAR_ISLAND=true,VERMILION_CITY=true,ROUTE_12=true,ROUTE_13=true}
function H.stage(map,cameraMode,surfing)
 if not H.service then return nil end
 local arena=V.require('VoxelBattleStage').arena(map,nil,nil)
 if not arena then return nil end
 local presentation=map
 if map and map.id=='KA_BLAINE_VOLCANO_GYM' and V.require('BlaineVolcano').profile(map)=='arena' then
  -- Reuse Blaine's authored lava court, lighting and badge. The battle and
  -- arena still own the actual KASC map; this alias is presentation only.
  presentation={id='CINNABAR_GYM',def=map.def}
 end
 if surfing and map and seas[map.id] and not(map.def and map.def.generation==2)then
  presentation={id=map.id,def=map.def,sceneryKey='KANTO_SEA'}
 end
 arena.terarrium=H.service.setup(presentation,cameraMode)
 for _,side in ipairs({'player','enemy'})do
  local p=arena.terarrium.actors[side]
  arena[side]={arena.mid[1]+p[1],arena.mid[2]+p[3]}
  arena[side..'Cell']={(arena[side][1]-8)/16,(arena[side][2]-8)/16}
 end
 arena.presentationMode='DISCS' -- shared renderer lifecycle, separate stage identity
 arena.portableStage='terarrium'
 arena.terarriumService=H.service -- latch exact service for this encounter
 return arena
end
local function register(factory,builtin)
  if H.service and not H.builtIn then return false,'Terarrium already registered' end
  local service=factory({Voxel3D=V.require('Voxel3D'),Mat4=V.require('Mat4'),
   resolveStyle=V.require('BattleArenaStyle').resolve,LocalLights=V.require('LocalLights'),
   silphOccupied=function()
    local game=V.mod.world and V.mod.world.game
    local flags=game and game.save and game.save.flags
    return type(flags)=='table'and not flags.EVENT_BEAT_SILPH_CO_GIOVANNI
   end,
   reportDomeFailure=function(reason)V.require('Diagnostics').write('terrarium-dome-error',{reason=reason,requested='TERRARIUM',actual='TERRARIUM',source='optional-glass-dome'})end,
   reportEffectFailure=function(effect,reason)V.require('Diagnostics').write('terrarium-'..effect..'-error',{reason=reason,requested='TERRARIUM',actual='TERRARIUM',source='optional-'..effect})end,
   playFanfare=function(battle)return require('src.core.Sound').play(battle.data,'Caught_Mon')end})
  for _,name in ipairs({'setup','draw','cast','camera','trainerFoot','release'})do
   if type(service)~='table' or type(service[name])~='function' then return false,'missing '..name end
  end
  if H.builtIn then
   -- Older standalone 0.2.2 calls register unconditionally and keeps its own
   -- endBattle closure. Let its lazy factory finish, but never replace the
   -- built-in renderer or activate that unused service's battle lifecycle.
   service.release()
   return true,'Built-in VASC Terrarium owns the presentation'
  end
  H.service,H.builtIn=service,builtin==true
  return true
end
function H.builtin()
 return {schema='vasc.terarrium-host/v1',revision=3,generation=1,
  register=function(factory)return register(factory,true)end,available=H.available}
end
function H.public()
 return {schema='vasc.terarrium-host/v1',revision=3,generation=1,builtIn=H.builtIn,
  register=function(factory)return register(factory,false)end,available=H.available}
end
return H
