local on=true
local profile={nativeRoomPanels=true,theme='home'}
local mods={ModSetting={new=function()return{get=function()return true end}end},
 SilphWindows={enabled=function()return on end},HorizonWall={interiorProfileFor=function()return profile end}}
local C=assert(loadfile('lib/CurrentRoom.lua')){require=function(n)return assert(mods[n],n)end}
local map={id='HOME',def={width=2,height=2,blocks={0,1,1,1},borderBlock=0}}
local view=C.plan(map,{},4,4,{{edge='north',at=16,from=0,upto=64,openings={}}})
for y=0,7 do for x=0,7 do assert(C.visible(view,x*8+4,y*8+4),'window closed by room flood mask')end end
local texture={};local palette={}
assert(C.texture(view,{{kind='wall',class='silph_exterior',texture=palette},
 {kind='wall',class='silph_frame',texture=palette},{kind='wall',class='room_finish:home',texture=texture}})==texture)
print('PASS real-window rooms: complete native footprint, no rear closure, facade palette excluded from room material')
on=false
local a=C.plan(map,{},4,4,{{edge='north',at=16,from=0,upto=64,openings={}}})
local b=C.plan(map,{},6,6,{})
assert(not next(a.blocked)and not next(a.gates),'native shell gained synthetic passage gates')
for k in pairs(a.visible)do assert(b.visible[k],'authored room visibility changed while walking')end
assert(not C.visible(a,4,4),'border void became a new room')
assert(C.visible(a,36,4)and C.visible(a,36,36),'native room clipped behind an invented wall')
print('PASS native rooms without windows: no synthetic gates, stable footprint, border void retained')

mods.Gen1Stairs={perimeterShaft=function(_,warp)return warp.shaft end}
map.id='SILPH_CO_1F';map.def.warps={{shaft={from=16,upto=48,back=-64}}}
local shaft=C.plan(map,{},4,4,{})
assert(shaft.maskNorth==-8 and shaft.maskH==16)
assert(C.visible(shaft,20,-60)and C.visible(shaft,44,-4),'shaft clipped outside native map')
assert(not C.visible(shaft,4,-4)and not C.visible(shaft,52,-4)and not C.visible(shaft,20,-68),'unrelated exterior revealed')
map.def.warps={}
local ordinary=C.plan(map,{},4,4,{})
assert(ordinary.maskNorth==0 and ordinary.maskH==8,'mask extension survived removal of shaft')
print('PASS shaft-only visibility extension, bounded exterior and no-shaft fallback')

mods.HorizonWall.isOutdoorMap=function()return false end
mods.HorizonWall.arenaViewFor=function()return nil end
mods.HorizonWall.classFor=function()return 'cave'end
local authored=true;local items=true
mods.BlaineVolcano={profile=function()return authored and 'arena'or nil end}
mods.VoxelItems={setting={get=function()return items end}}
map.id='KA_BLAINE_VOLCANO_GYM'
assert(not C.enabled(map),'suspended arena still uses cave flood mask')
items=false;assert(C.enabled(map),'native fallback lost room mask');items=true
authored=false;assert(C.enabled(map),'unrecognised map bypassed room mask')
print('PASS exact suspended-arena visibility and native/unsupported fallback')
