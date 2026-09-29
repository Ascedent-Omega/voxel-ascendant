-- One line per saved playthrough, before a real voxel teleport departure.
local V=...
local M={KEY='firstVoxelTeleportStarkV1'}
local pending=setmetatable({},{__mode='k'})
function M.before(game,world,resume)
 if not V.require('VoxelState').active() or V.mod.save:get(M.KEY,false) then return false end
 local save,map,player=game.save,world.map,world.player
 local old=pending[world]
 if old then
  local stacked=false
  for _,screen in ipairs(game.stack and game.stack.states or{})do if screen==old.box then stacked=true end end
  if old.save==save and old.map==map and old.player==player and stacked then return true end
  pending[world]=nil
 end
 if not save or not game.stack then return false end
 local text=V.require('SetupLocale').text("I don't feel so good, Mr. Stark.",
  'Ich fühle mich nicht so gut, Mr. Stark.')
 local record={save=save,map=map,player=player}
 local box=require('src.render.TextBox').new(game,text,function()
  if pending[world]~=record then return end
  pending[world]=nil
  -- A reset or external map change must not execute an old departure.
  if game.save~=save or game.overworld~=world or world.map~=map or world.player~=player then return end
  V.mod.save:set(M.KEY,true)
  resume()
 end)
 record.box=box;pending[world]=record
 game.stack:push(box)
 return true
end
function M.install(game)
 local world=game and game.overworld
 if not world or world.__vascFirstTeleportLine then return end
 world.__vascFirstTeleportLine=true
 local take=world.takeWarp
 if take then world.takeWarp=function(self,warp,...)
  local args,n={...},select('#',...)
  local p=self.player
  local pad=p and self.map and self.map.warpPadOrHoleAt
   and self.map:warpPadOrHoleAt(p.cellX,p.cellY)=='pad'
  if pad and warp and warp.destMap and M.before(game,self,function()
   take(self,warp,(unpack or table.unpack)(args,1,n))
  end) then return true end
  return take(self,warp,(unpack or table.unpack)(args,1,n))
 end end
 local escape=world.beginTeleportOut
 if escape then world.beginTeleportOut=function(self,...)
  local args,n={...},select('#',...)
  -- TELEPORT is outdoors; DIG and ESCAPE ROPE are indoor departures.
  local Map=require('src.world.Map')
  local defaults=require('src.world.FieldDefaults')
  local outdoors=self.map and Map.isOutside(self.map.def,defaults.field(game.data,'outsideTilesets'))
  if outdoors and M.before(game,self,function()
   escape(self,(unpack or table.unpack)(args,1,n))
  end)then return end
  return escape(self,(unpack or table.unpack)(args,1,n))
 end end
end
return M
