-- A covered transition gets one bounded decode/upload slice per update.
-- State belongs to the encounter; failures fall back to ordinary live loading.
local V=...
local M={}
function M.step(owner)
 if owner.modelPreparationDone then return false end
 local now=love.timer.getTime
 local deadline=now()+.002
 if not owner.modelPreparationJob then
  owner.modelPreparationJob=coroutine.create(function()
   local function checkpoint(force)
    if force or now()>=(owner.modelPreparationDeadline or deadline) then coroutine.yield() end
   end
   local stadium=V.require("Stadium")
   for _,side in ipairs({"enemy","player"}) do
    stadium.prepareResources(owner.battle,side,checkpoint)
    checkpoint(true)
   end
  end)
 end
 -- The deadline must be fresh inside the suspended coroutine too.
 owner.modelPreparationDeadline=deadline
 local job=owner.modelPreparationJob
 local ok=coroutine.resume(job)
 if not ok or coroutine.status(job)=="dead" then
  owner.modelPreparationDone=true;owner.modelPreparationJob=nil
 end
 return true
end
return M
