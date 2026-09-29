-- Slow, bounded resolution changes. Never react to loading, menus or one
-- isolated stall; retain full-resolution UI and the selected visual effects.
local M={scale=.75}
local elapsed,total,count,cooldown=0,0,0,0
function M.observe(dt,playing)
 if not playing or not dt or dt<=0 or dt>.15 then elapsed,total,count=0,0,0;return end
 cooldown=math.max(0,cooldown-dt)
 elapsed,total,count=elapsed+dt,total+dt,count+1
 if elapsed<1 then return end
 local mean=total/count;elapsed,total,count=0,0,0
 if cooldown>0 then return end
 local before=M.scale
 if mean>1/55 then M.scale=math.max(.5,M.scale-.10)
 elseif mean<1/85 then M.scale=math.min(1,M.scale+.05)end
 if M.scale~=before then cooldown=3 end
end
function M.reset()M.scale=.75;elapsed,total,count,cooldown=0,0,0,0 end
return M
