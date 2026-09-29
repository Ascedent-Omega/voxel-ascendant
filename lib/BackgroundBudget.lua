-- Optional scenery work yields to sustained slow foreground frames. Required
-- terrain and covered loads retain their own explicit progress budgets.
local B={enabled=true,skipped=0,throttled=0}
local tick=0
function B.allowance(requested,covered)
 if not B.enabled or covered then return requested end
 local timer=love and love.timer
 local dt=timer and timer.getDelta and timer.getDelta()
 if type(dt)~='number' or dt~=dt or dt<=0 then return math.min(requested,.001)end
 tick=tick+1
 local spare=1/60-dt-.001
 if spare<=0 then
  -- Bounded progress, even on a 30-Hz device, without work every slow frame.
  if tick%60==0 then B.throttled=B.throttled+1;return math.min(requested,.00025)end
  B.skipped=B.skipped+1;return 0
 end
 return math.min(requested,spare*.5)
end
function B.reset()tick=0;B.skipped=0;B.throttled=0 end
return B
