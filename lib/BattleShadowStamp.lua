-- Reusable side canvases are not content identities. Only stable source art
-- plus the actual sun-facing matrices can prove unchanged card silhouettes.
local M={}
function M.signature(cards,token,textures,modelsStanding)
 local parts={};local dynamic=modelsStanding==true
 local battle=textures and textures.vascRenderBattle
 if battle then
  dynamic=dynamic or battle.animPlaying==true or not not battle.growIn or not not battle.shrinkOut
  for _,value in pairs(battle.fx or{})do
   if value and value~=0 then dynamic=true;break end
  end
 end
 for _,card in ipairs(cards or{})do
  local source=card.source or{}
  local identity=source.inkIdentity
  -- Unknown providers and mutable source canvases keep the live token.
  -- The existing ink-identity contract is also used for bounds caching.
  local kind=type(identity)
  local immutable=false
  if (kind=='table' or kind=='userdata') and type(identity.typeOf)=='function' then
   local ok,value=pcall(identity.typeOf,identity,'Image');immutable=ok and value==true
  end
  if not immutable or source.inkTransient then dynamic=true end
  parts[#parts+1]=tostring(card.side)
  parts[#parts+1]=tostring(card.tex)
  parts[#parts+1]=tostring(identity)
  for _,n in ipairs(card.shadowModel or{})do parts[#parts+1]=tostring(n)end
 end
 if dynamic then parts[#parts+1]='live:'..tostring(token)end
 return table.concat(parts,',')
end
return M
