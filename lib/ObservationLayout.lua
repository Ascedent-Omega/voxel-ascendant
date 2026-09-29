-- Route 12: the fishing scope looks south; the Tower scope belongs on the
-- opposite rail, away from the stair landing. Native 2D data stays untouched.
local V=...
local M={}
local ID='ROUTE_12_GATE_2F'
local TEXT='TEXT_ROUTE12GATE2F_RIGHT_BINOCULARS'
function M.matches(map)
 return map and map.id==ID and V.require('Gen1Rooftops').gate(map)
end
function M.enabled(map)
 return M.matches(map)and V.require('VoxelState').active()and V.require('VoxelItems').setting:get()
end
function M.apply(P,props,map)
 if not M.matches(map)then return end
 for _,p in ipairs(props)do
  if p.kind=='observation_binoculars'and p.tx==12 and p.ty==4 then
   local kind='observation_binoculars_tower'
   if not P.models[kind]then
    local original=P.models[p.kind];local model={}
    for k,v in pairs(original)do model[k]=v end
    model.boxes={}
    for _,box in ipairs(original.boxes)do local b={};for k,v in ipairs(box)do b[k]=v end
     b[1]=16-b[1]-b[4];b[3]=24-b[3]-b[6];model.boxes[#model.boxes+1]=b
    end
    P.models[kind]=model
   end
   p.claimTx,p.claimTy=p.tx,p.ty;p.tx,p.ty,p.kind=4,11,kind
  end
 end
end
function M.install()
 local Map=require('src.world.Map')
 if Map.__vascObservationLayout then return end
 local walk,sign=Map.isWalkableCell,Map.signAtCell
 function Map:isWalkableCell(x,y)
  if M.enabled(self)then
   if x==6 and y==2 then return true end
   if x==2 and y==6 then return false end
  end
  return walk(self,x,y)
 end
 function Map:signAtCell(x,y)
  if M.enabled(self)then
   if x==6 and y==2 then return nil end
   if x==2 and y==6 then
    local original=sign(self,6,2)
    if original and original.text==TEXT then return original end
   end
  end
  return sign(self,x,y)
 end
 Map.__vascObservationLayout=true
 local OW=require('src.world.OverworldController')
 local show=OW.showMapText
 function OW:showMapText(text,npc,done)
  local p=self.player
  if text==TEXT and not npc and M.enabled(self.map)
      and p.cellX==2 and p.cellY==5 and p.facing=='down'then
   -- The original synchronous sign handler only accepts facing up. Adapt
   -- that check at the relocated scope; keep its native localized dialogue.
   local facing=p.facing;p.facing='up'
   local ok,result=pcall(show,self,text,npc,done)
   p.facing=facing
   if not ok then error(result,0)end
   return result
  end
  return show(self,text,npc,done)
 end
end
return M
