-- Open voxel terraces may launch FLY; native badge, party and destination
-- checks remain authoritative. Never reclassify maps for other field moves.
local V=...
local M={}
function M.allowed(game)
 local map=game and game.overworld and game.overworld.map
 return require('src.render.Pipelines').worldPipeline()=='voxel'
  and V.require('VoxelState').active() and map
  and V.require('Gen1Rooftops').matches(map)
  and (map.id=='CELADON_MART_ROOF' or V.require('Gen1Rooftops').gate(map)) or false
end
function M.call(game,fn,...)
 if not M.allowed(game)then return fn(...)end
 local Map=require('src.world.Map');local original=Map.isOutside
 local def=game.overworld.map.def
 local wrapper=function(candidate,...)
  if candidate==def and M.allowed(game)then return true end
  return original(candidate,...)
 end
 Map.isOutside=wrapper
 local function finish(ok,...)
  if Map.isOutside==wrapper then Map.isOutside=original end
  if not ok then error((...),0)end
  return ...
 end
 return finish(pcall(fn,...))
end
function M.install(game)
 local Party=require('src.ui.PartyMenu')
 local bridge=Party.__vascRooftopFly
 if not bridge then
  bridge={original=Party.update};Party.__vascRooftopFly=bridge
  Party.update=function(self,...)
   local row=self.submenu and self.subItems and self.subItems[self.subIndex]
   local input=self.game and self.game.input
   if not self.battle and row and row.action=='fly' and input
       and input:wasPressed('a') and not input:wasPressed('up')
       and not input:wasPressed('down') and not input:wasPressed('b')then
    return bridge.call(self.game,bridge.original,self,...)
   end
   return bridge.original(self,...)
  end
 end
 bridge.call=M.call
 local API=require('src.world.WorldAPI')
 local api=API.__vascRooftopFly
 if not api then
  api={original=API.canFly};API.__vascRooftopFly=api
  API.canFly=function(self,...)return api.call(self.game,api.original,self,...)end
 end
 api.call=M.call
 -- KASC's Field Kit has an explicit policy seam and keeps all its own
 -- machine/unlock checks. Register once, refresh the provider on reload.
 local field=V.require('KantoAscendantCompat').fieldTech(V.mod)
 if field and type(field.registerMapPolicyProvider)=='function'then
  local policy=field.__vascRooftopFly
  if not policy then
   policy={allowed=M.allowed}
   local ok=field.registerMapPolicyProvider('vasc-open-rooftops',function(g,move)
    if move=='FLY' and policy.allowed(g)then return {allowFlyInside=true}end
   end)
   if ok then field.__vascRooftopFly=policy end
  else policy.allowed=M.allowed end
 end
end
return M
