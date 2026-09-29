-- The unused Mart warp dresses the first blank facade east of the central
-- passage as a shop. Give its decorative entrance a voxel-only explanation.
local V=...
local M={}
function M.matches(world,x,y)
 return world and world.map and world.map.id=='CELADON_CITY'
  and x==39 and y==19 and V.require('VoxelState').active()
  and V.require('Gen1PalletVillage').buildings:get()
end
function M.install()
 local OW=require('src.world.OverworldController')
 if OW.__vascClosedShop then return end
 local interact=OW.interact
 function OW:interact(...)
  local p=self.player
  local x,y=p:facingCell()
  if M.matches(self,x,y)and not self:npcAtCell(x,y)then
   local game=require('src.core.Game')
   local text=V.require('SetupLocale').text(
    'Sorry! The department store put us out of business.',
    'Sorry! Wegen des Kaufhauses sind wir insolvent.')
   game.stack:push(require('src.render.TextBox').new(game,text))
   return
  end
  return interact(self,...)
 end
 OW.__vascClosedShop=true
end
return M
