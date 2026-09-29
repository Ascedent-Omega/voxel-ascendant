local modules={ModSetting={new=function(_,_,_,_,default)return{value=default,get=function(s)return s.value end}end}}
local V={require=function(n)if not modules[n]then modules[n]=assert(loadfile('lib/'..n..'.lua'))(V)end;return modules[n]end}
-- Bind after construction (Lua locals are not visible in their initializer).
V.require=function(n)if not modules[n]then modules[n]=assert(loadfile('lib/'..n..'.lua'))(V)end;return modules[n]end
local C=V.require('CalendarEvents');local H=V.require('Halloween')
for _,date in ipairs{{month=9,day=30},{month=11,day=1},{month=10,day=0},{month=10,day=32},{month='10',day=1}}do assert(C.at(date)==nil)end
for d=1,31 do assert(C.at{year=2026,month=10,day=d}=='halloween');assert(C.at{year=2027,month=10,day=d}=='halloween')end
local old=os.date;os.date=function()return{month=10,day=1}end;C.update(1);assert(C.active('halloween'))
os.date=function()return{month=11,day=1}end;C.update(1);assert(not C.active('halloween'))
os.date=function()error('clock unavailable')end;C.update(1);assert(not C.active('halloween'));os.date=old
C.setting.value='halloween';assert(C.active('halloween'))
assert(not H.costume({ascendantRole='pokemon_151'},'npc'));assert(not H.costume({ascendantRole='red'},'npc'))
local costumes=0;for i=1,100 do if H.costume({ascendantRole='lass'},'actor'..i)then costumes=costumes+1 end end
assert(costumes>10 and costumes<50,'costumes should dress a subset')
local world={map={id='POKEMON_TOWER_3F',def={tileset='CEMETERY',generation=1}}}
local top=world;local game={overworld=world,save={options={sfxVol=0}},stack={top=function()return top end}}
for i=1,400 do H.update(.1,game,7);if H.age then break end end
assert(H.age,'no apparition');top={};H.update(.1,game,7);assert(not H.age and not H.mapId,'menu retained scare')
top=world;H.update(.1,game,7);H.wait=0;H.update(.1,game,7);assert(H.age)
world.map={id='PEWTER_GYM',def={tileset='GYM'}};H.update(.1,game,7);assert(not H.age,'scare leaked into another room')
C.setting.value='off';assert(not C.active('halloween')and not H.costume({ascendantRole='lass'},'actor4'))
print('PASS calendar boundaries, real-month independence, annual recurrence, clock failure, costume identity and apparition menu/map lifetime')

-- Native audio contract: one lazily generated source, SFX gain, no menu bleed.
local samples,plays,stops,volume=0,0,0,0
local source={setVolume=function(_,v)volume=v end,stop=function()stops=stops+1 end,
 setPitch=function()end,play=function()plays=plays+1 end}
love={sound={newSoundData=function()return{setSample=function()samples=samples+1 end,release=function()end}end},
 audio={newSource=function()return source end}}
C.setting.value='halloween';game.save.options.sfxVol=3
world.map={id='POKEMON_TOWER_3F',def={tileset='CEMETERY'}};top=world
for i=1,30 do H.update(.1,game,7)end
assert(samples>30000,'scream waveform not generated')
H.wait=0;H.update(.1,game,7);assert(plays==1 and math.abs(volume-.32*3/7)<1e-8)
top={};local before=stops;H.update(.1,game,7);assert(stops>before and not H.age)
top=world;game.save.options.sfxVol=0;H.update(.1,game,7);H.wait=0;H.update(.1,game,7)
assert(plays==1 and volume==0,'muted SFX still played')
print('PASS generated scream, effect gain, muted effects and menu stop')
for id,event in pairs(C.events)do
 for day=event.first,event.last do assert(C.at{month=event.month,day=day}==id)end
 assert(C.at{month=event.month,day=event.last+1}==nil)
 C.setting.value=id;assert(C.active(id));if id~='halloween'then assert(not C.active('halloween'))end
end
C.setting.value='off';for id in pairs(C.events)do assert(not C.active(id))end
print('PASS all four calendar festivals, complete month boundaries and preview isolation')
-- Pallet's authored façades have no nativeDoors metadata. Their reviewed
-- decoration pads stay left of the native warp and inside the frontage.
modules.VoxelItems={models={pallet_red_house={},pallet_blue_house={},pallet_oak_lab={}},decorColors={clay=15}}
local props={
 {kind='pallet_red_house',tx=8,ty=6,w=8,h=6,claimed=true},
 {kind='pallet_blue_house',tx=24,ty=6,w=8,h=6,claimed=true},
 {kind='pallet_oak_lab',tx=20,ty=16,w=12,h=8,claimed=true}}
modules.VoxelFurniture={find=function()return props end,enabled=function()return true end}
modules.Weather={isOutdoor=function()return true end}
modules.LedgeElevation={basisAtCell=function()return 0 end};modules.Voxel3D={}
C.setting.value='spring';local count=0
H.eachPumpkin({map={id='PALLET_TOWN'}},function(x,y,z,p)
 count=count+1
 assert(x-7>=p.tx*8 and x+4<=(p.tx+p.w)*8)
 assert(z-4>=p.ty*8 and z+4<=(p.ty+p.h)*8)
 local door=({pallet_red_house=80,pallet_blue_house=208,pallet_oak_lab=192})[p.kind]
 assert(x+4<door,'seasonal prop covers native door')
end,'spring')
assert(count==3)
C.setting.value='off';H.eachPumpkin({map={id='PALLET_TOWN'}},function()error('disabled decoration')end,'spring')
print('PASS Pallet festival frontage, native door clearance and OFF')
