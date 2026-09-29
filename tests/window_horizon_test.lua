local modules={};local V={require=function(k)return assert(modules[k],k)end}
modules.SilphElevator={matches=function(map)return map.id=='SILPH_CO_ELEVATOR'end}
modules.SilphWindows={matches=function()return true end,source=function()return'CELADON_CITY'end}
modules.WorldPlacement={position=function(id)return({
 CELADON_CITY={x=0,y=0,anchor='kanto'},CINNABAR_ISLAND={x=-1500,y=3700,anchor='kanto'},
 OTHER={x=0,y=0,anchor='johto'}})[id]end}
local World=assert(loadfile('lib/RooftopWorld.lua'))(V)
local entry={map={id='CELADON_MART_5F'},w=320,h=128}
assert(World.radius({map={id='SILPH_CO_ELEVATOR'}})==3200,'moving elevator must retain its bounded live horizon')
local defs={};for _,id in ipairs{'CELADON_CITY','CINNABAR_ISLAND','OTHER'}do defs[id]={width=20,height=20,tileset='OVERWORLD'}end
local included={};for _,m in ipairs(World.maps(entry,defs))do included[m.id]=true end
assert(included.CELADON_CITY and included.CINNABAR_ISLAND,'window horizon ends before volcano source map')
assert(not included.OTHER,'window horizon crossed world components')
modules.ModSetting={new=function()return{}end}
modules.HouseWindows={describe=function()return{width=96,depth=64}end}
modules.RooftopWorld={geometry=function(e,d,emit)
 emit(-2000,-70,4000,400,4,400,8)
end,mountains=function()end}
local W=assert(loadfile('lib/SilphWindows.lua'))(V)
local count=0
W.geometry(entry,defs,function(x,y,z,w,h,d,c)
 count=count+1;assert(y==-70 and z>3000 and c==8,'far shore lost its floor height/material')
end)
assert(count==1,'house near-crop removed the far shore before capture')
print('PASS window horizon includes connected Cinnabar and retains far shore through room projection')
