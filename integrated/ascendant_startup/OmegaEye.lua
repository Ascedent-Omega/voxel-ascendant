local M={durations={0.27,0.06,0.07,0.07,0.06,0.07,0.07,0.06,0.07,0.07,0.06,0.07,0.07,0.06,0.07,0.07,0.06,0.07,0.07,0.06,0.07,0.07,0.06,0.07,0.07,0.06,0.07,0.07,0.06,0.07,0.07,0.06,0.07,0.07,0.06,0.07,0.07,0.06,0.07,0.07,0.06,0.07,0.07,0.06,0.07,0.07,0.06,0.07,0.07,0.06,0.07,0.07,0.06,0.14,0.2,0.06,0.07,0.07,0.06,0.07,0.07,0.2,0.06,0.07,0.07,0.06,0.07,0.07,0.06,0.07,0.13,0.07,0.27,0.06,0.07,0.4,0.07,0.06,0.07,0.07,0.07},holdFrame=74}
-- Audio onsets measured from the unchanged GameCube recording. Frame anchors
-- follow the eye, Omega/triangle switches and the original blink/zoom poses.
M.beats={{0,0},{.351,8},{.705,17},{1.219,24},{1.478,30},{1.997,36},
 {2.257,41},{2.511,47},{2.770,50},{3.030,56},{3.414,64},{3.813,71},{4.327,74}}
M.resolveAt=4.327
M.captionAt=3.813
local starts={};local cursor=0
for i,seconds in ipairs(M.durations)do starts[i]=cursor;cursor=cursor+seconds end
function M.frameAt(seconds)
 if seconds<=0 then return 0 end
 if seconds>=M.resolveAt then return M.holdFrame end
 local source=0
 for i=2,#M.beats do
  local a,b=M.beats[i-1],M.beats[i]
  if seconds<=b[1]then
   local k=(seconds-a[1])/(b[1]-a[1])
   source=starts[a[2]+1]+(starts[b[2]+1]-starts[a[2]+1])*k;break
  end
 end
 local frame=0
 for i=1,M.holdFrame+1 do if starts[i]<=source+.000001 then frame=i-1 else break end end
 return frame
end
return M
