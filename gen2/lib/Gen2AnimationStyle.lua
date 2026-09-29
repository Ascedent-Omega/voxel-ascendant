-- One style per native battle; option changes apply to the next encounter.
local V=...
local M={}
function M.original(screen)
  if type(screen)~="table" then return V.mod.options:get("gen2MoveAnimations")=="original" end
  if screen._vascOriginalAnimations==nil then
    screen._vascOriginalAnimations=V.mod.options:get("gen2MoveAnimations")=="original"
  end
  return screen._vascOriginalAnimations
end
function M.install()
  local Battle=require("src.ui.gen2.BattleState")
  if Battle._vascAnimationStyleInstalled then return end
  local new=Battle.new
  Battle.new=function(...)
    local screen=new(...)
    M.original(screen)
    return screen
  end
  Battle._vascAnimationStyleInstalled=true
end
return M
