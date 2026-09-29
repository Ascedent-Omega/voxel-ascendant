local active=true
local modules={CinnabarVolcano={active=function()return active end},Weather={clock=0}}
local M=assert(loadfile('lib/CinnabarActivity.lua')){require=function(n)return assert(modules[n],n)end}
local function map(id,generation)return{id=id,def={generation=generation or 1}}end
local island=map('CINNABAR_ISLAND');local lab=map('CINNABAR_LAB_TRADE_ROOM')
for _,id in ipairs{'CINNABAR_ISLAND','CINNABAR_GYM','CINNABAR_POKECENTER','CINNABAR_MART','CINNABAR_LAB','CINNABAR_LAB_FOSSIL_ROOM','POKEMON_MANSION_1F','POKEMON_MANSION_B1F'}do assert(M.region(map(id)),id)end
assert(not M.region(map('PALLET_TOWN'))and not M.region(map('CINNABAR_ISLAND',2)))
local world={map=island};local top=world
local game={overworld=world,stack={top=function()return top end}}
local function update(clock,level)modules.Weather.clock=clock;M.update(.016,game,level or 1)end
update(48);assert(M.ashAmount(island)==1)
local rects=0;M.paintAsh({setColor=function()end,rectangle=function()rects=rects+1 end},320,240,1,1);assert(rects==77)
world.map=lab;update(48);assert(M.ashAmount(lab)==0,'ash leaked indoors')
update(69);local x,y=M.camera(lab,100,200);assert(x~=100 and y~=200,'indoor tremor missing')
local rig={eye={1,2,3},focus={4,5,6}}
M.camera(lab,100,200,rig);assert(math.abs((rig.eye[1]-1)-(x-100))<1e-10)
assert(rig.eye[3]==3 and rig.focus[3]==6)
for _,level in ipairs{0,1}do
 active=level==0;update(69,level);local a,b=M.camera(lab,100,200);assert(a==100 and b==200)
end
active=true;top={};update(69);assert(not M.playable,'menu must pause tremors')
top=world;world.script={};update(69);assert(not M.playable,'script must pause tremors');world.script=nil
world.map=map('PALLET_TOWN');update(69);assert(not M.playable)
local ash,quake=0,0
for t=0,1799 do
 local a=M.ashAt(t);local x,y,q=M.quakeAt(t)
 assert(a>=0 and a<=1 and q>=0 and q<=1 and math.abs(x)<1 and math.abs(y)<.4)
 if a>0 then ash=ash+1 end;if q>0 then quake=quake+1 end
end
assert(ash>200 and ash<500 and quake>10 and quake<45,'effects must be occasional')
print('PASS Cinnabar ash outdoors, shared indoor tremors, bounded cadence/amplitude, menu/script/Vanilla/classic gates')
