local glass,pipeline=true,'voxel'
local V={require=function(name)
 if name=='SilphElevatorAudio'then return{install=function()end,start=function()end,finish=function()end}end
 assert(name=='SilphWindows');return{setting={get=function()return glass end}}
end};local E=assert(loadfile('lib/SilphElevator.lua'))(V)
package.loaded['src.render.Pipelines']={worldPipeline=function()return pipeline end}
local function cabin(floor)return{id='SILPH_CO_ELEVATOR',def={width=2,height=2,tileset='LOBBY',warps={{destMap='SILPH_CO_'..floor..'F'}}}}end
local map=cabin(1);assert(E.matches(map)and E.offset(map)==0)
map.def.generation=2;assert(not E.matches(map));map.def.generation=nil
for n=1,11 do assert(E.offset(cabin(n))==-(n==1 and 0 or 32+(n-2)*24))end
local ow={map=map};local game={overworld=ow};local choices,exits=0,0
local List={new=function(_,_,_,opts)return opts end}
local Shake={new=function(_,ow,opts)return{ow=ow,phase='pre',frames=0,onDone=opts.onDone}end,exit=function()exits=exits+1 end}
Shake.update=function(self)self.frames=self.frames+1;if self.frames==200 then self.phase='pa'end end
package.loaded['src.ui.ListMenu']=List;package.loaded['src.world.ElevatorShake']=Shake
E.install();E.install()
local function select(item)
 choices=choices+1
 if not item.cancel then game.ride=Shake.new(game,ow,{onDone=function()map.def.warps[1].destMap=item.value.map end})end
end
local menu=List.new(game,nil,{}, {kind='elevator_floors',onChoose=select})
menu.onChoose({cancel=true});assert(not E.ride and choices==1)
menu.onChoose({value={map='SILPH_CO_11F'}});local r=assert(E.ride)
assert(r.vascFrom==1 and r.vascTo==11 and E.offset(map)==0)
r.phase='shake';local last=0
for t=0,200 do r.frames=t;local height=E.offset(map);assert(height<=last and height>=-248);last=height end
r.phase='pa';assert(E.offset(map)==-248)
Shake.exit(r);r.onDone();assert(E.offset(map)==-248 and not E.ride and exits==1)
menu.onChoose({value={map='SILPH_CO_1F'}});r=assert(E.ride);r.phase='shake';r.frames=100
assert(E.offset(map)==-124);Shake.exit(r) -- interrupted ride: native exit stays 11F
assert(E.offset(map)==-248 and exits==2)
local non={id='CELADON_MART_ELEVATOR',def=map.def};ow.map=non
local other=List.new(game,nil,{}, {kind='elevator_floors',onChoose=select});assert(other.onChoose==select)
assert(E.offset(non)==0 and choices==3)
print('PASS native elevator hook: cancel, floor 1-11 heights, monotone up/down motion, interrupted ride, other elevators untouched')

ow.map=map
local function duration(target)
 menu.onChoose({value={map='SILPH_CO_'..target..'F'}})
 local ride=assert(E.ride);ride.phase='shake'
 local ticks=0
 while ride.phase=='shake'do Shake.update(ride);ticks=ticks+1;assert(ticks<1000)end
 Shake.exit(ride);return ticks
end
-- Native exit remains on 11F: six floors down must get six floors' travel.
assert(duration(5)==378,'six-floor ride still has a one-floor duration')
glass=false;assert(duration(5)==200,'glass OFF changed the native timeline')
glass=true;pipeline='classic';assert(duration(5)==200,'vanilla timeline changed')
print('PASS elevator timing: proportional six-floor travel, native duration with glass OFF or vanilla')
