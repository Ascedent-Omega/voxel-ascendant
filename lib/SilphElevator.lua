-- Presentation follows the native floor menu and ElevatorShake timeline.
-- The host alone owns exit warps, input locks, audio and completion callbacks.
local V=...
local M={}
function M.matches(map)
 local d=map and map.def
 return map and map.id=='SILPH_CO_ELEVATOR'and d and d.generation~=2
  and d.width==2 and d.height==2 and d.tileset=='LOBBY'
end
function M.floor(map)
 return tonumber(((map.def.warps or{})[1]or{}).destMap and map.def.warps[1].destMap:match('^SILPH_CO_(%d+)F$'))or 1
end
function M.height(n)return n==1 and 0 or 32+(n-2)*24 end
function M.progress(ride)
 if ride.phase=='pre'then return 0 end
 if ride.phase~='shake'then return 1 end
 local t=math.max(0,math.min(1,(ride.frames or 0)/200))
 return t*t*(3-2*t)
end
function M.offset(map)
 if not M.matches(map)then return 0 end
 local r=M.ride
 if r and r.ow.map==map then
  local t=M.progress(r)
  return -(M.height(r.vascFrom)+(M.height(r.vascTo)-M.height(r.vascFrom))*t)
 end
 return -M.height(M.floor(map))
end
function M.install()
 if M.installed then return end;M.installed=true
 V.require('SilphElevatorAudio').install()
 local List=require('src.ui.ListMenu');local make=List.new
 List.new=function(game,title,items,opts,...)
  if opts and opts.kind=='elevator_floors'and game.overworld and M.matches(game.overworld.map)then
   local choose=opts.onChoose
   if choose then
    opts.onChoose=function(item,...)
     local floor=item.value and tonumber((item.value.map or''):match('^SILPH_CO_(%d+)F$'))
     M.pending=floor and {map=game.overworld.map,floor=floor,from=M.floor(game.overworld.map)}or nil
     local result=choose(item,...);M.pending=nil;return result
    end
   end
  end
  return make(game,title,items,opts,...)
 end
 local Shake=require('src.world.ElevatorShake');local new,exit,update=Shake.new,Shake.exit,Shake.update
 Shake.update=function(self,...)
  if self==M.ride and self.phase=='shake'and V.require('SilphWindows').setting:get()
   and require('src.render.Pipelines').worldPipeline()=='voxel'then
   self.vascElapsed=self.vascElapsed+1
   local frame=math.floor(self.vascElapsed*200/self.vascTicks)
   if frame<=self.frames then return end
  end
  return update(self,...)
 end
 Shake.new=function(game,ow,opts)
  local r=new(game,ow,opts)
  if M.matches(ow.map)and M.pending and M.pending.map==ow.map then
   r.vascFrom=M.pending.from;r.vascTo=M.pending.floor
   r.vascTicks=math.max(200,90+math.abs(r.vascTo-r.vascFrom)*48);r.vascElapsed=0;M.ride=r
   V.require('SilphElevatorAudio').start(game,r)
  end
  return r
 end
 Shake.exit=function(self,...)
  V.require('SilphElevatorAudio').finish(self)
  if M.ride==self then M.ride=nil end
  return exit(self,...)
 end
end
return M
