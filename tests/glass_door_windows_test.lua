local on=true
local door={material='room_glass_door',doorView='test',from=48,upto=80,height=24}
local panel={edge='south',at=128,from=0,upto=128,openings={door}}
local mods={SilphWindows={enabled=function()return on end},Gen1InteriorPanoramas={profileFor=function()return{}end},
 Gen1RoomBounds={forMap=function()return{south=128}end},HouseWindows={perimeter=function()return false end},
 Gen1InteriorLayout={panelsFor=function()return{panel}end}}
local V={require=function(n)return assert(mods[n],n)end}
local W=assert(loadfile('lib/GlassDoorWindows.lua'))(V)
local map={};local a=W.apertures(map)
assert(#a==1 and a[1].bottom==0 and a[1].top==24 and a[1].at==128)
assert(W.matches(map,panel,door));local rects,edges=W.uniforms(map)
assert(#rects==4 and edges[1]==2 and edges[2]==0,'shader bounds/count wrong')
assert(W.apertures(map)==a,'aperture rebuilt every frame')
on=false;assert(#W.apertures(map)==0 and not W.matches(map,panel,door),'OFF ignored');on=true
door.material='room_wood_door';assert(#W.apertures({})==0,'wooden door gained exterior pass')
door.material='room_glass_door';panel.at=64;assert(#W.apertures({})==0,'partition gained outside hole')
print('PASS shared exterior aperture: coordinates, bounded uniforms, retained descriptors, OFF/wood/partition guards')
