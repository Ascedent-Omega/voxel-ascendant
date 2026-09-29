-- Local volcanic weather and render-only tremors. One regional clock keeps
-- houses and outdoors in sync; no movement, collision or story state changes.
local V=...
local M={clock=0,playable=false}
function M.region(map)
 local d=map and map.def
 if not d or d.generation==2 then return false end
 local id=map.id or d.id or ''
 return id=='CINNABAR_ISLAND' or id:match('^CINNABAR_')~=nil
  or id:match('^POKEMON_MANSION_[1-3]F$')~=nil or id=='POKEMON_MANSION_B1F'
end
local function envelope(t,duration,fade)
 if t<0 or t>=duration then return 0 end
 return math.min(1,t/fade,(duration-t)/fade)
end
function M.ashAt(clock)
 local cycle=math.floor(clock/180)
 return envelope(clock%180-(38+(cycle*29)%46),28+(cycle*17)%19,6)
end
function M.quakeAt(clock)
 local cycle=math.floor(clock/180)
 local t=clock%180-(68+(cycle*37)%67)
 local amount=envelope(t,2.8+(cycle%3)*.4,.55)
 return (math.sin(t*39)+.35*math.sin(t*71))*.65*amount,
  math.sin(t*47)*.38*amount,amount
end
function M.update(dt,game,level)
 local world=game and game.overworld
 M.playable=not not ((level or 0)>0 and V.require('CinnabarVolcano').active()
  and world and M.region(world.map) and game.stack and game.stack:top()==world
  and not world.flyAnim and not world.script
  and not (world.runner and world.runner:isRunning()))
 M.map=M.playable and world.map or nil
 M.clock=V.require('Weather').clock or 0
end
function M.ashAmount(map)
 if not M.playable or M.map~=map or map.id~='CINNABAR_ISLAND'
  or not V.require('CinnabarVolcano').active() then return 0 end
 return M.ashAt(M.clock)
end
function M.paintAsh(g,w,h,cell,amount)
 local size=math.max(1,math.min(3,cell or 1))
 g.setColor(.27,.25,.24,.075*amount);g.rectangle('fill',0,0,w,h)
 for i=1,76 do
  local speed=7+i%9
  local x=(i*127.7+M.clock*(10+i%5)+math.sin(M.clock*.7+i)*9)%(w+24)-12
  local y=(i*79.3+M.clock*speed)%(h+24)-12
  local c=i%3==0 and .69 or .34
  g.setColor(c,c*.97,c*.91,(.32+i%4*.09)*amount)
  g.rectangle('fill',math.floor(x/size)*size,math.floor(y/size)*size,size,size)
 end
end
function M.camera(map,cx,cy,rig)
 if not M.playable or M.map~=map or not V.require('CinnabarVolcano').active()then return cx,cy end
 local x,y=M.quakeAt(M.clock)
 -- FirstPerson owns a fresh render rig each frame; native camera and actor
 -- coordinates never receive these offsets, so there can be no drift.
 if rig then
  for _,p in ipairs{rig.eye,rig.focus}do p[1]=p[1]+x;p[2]=p[2]+y end
 end
 return cx+x,cy+y
end
return M
