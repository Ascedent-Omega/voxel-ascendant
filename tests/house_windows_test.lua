local mods={};local V={require=function(n)return assert(mods[n],n)end}
local enabled=true
mods.Gen1PalletVillage={buildings={get=function()return enabled end}}
local profile={theme='home',tileset='HOUSE',width=4,height=4,shellHeight=40}
mods.Gen1InteriorPanoramas={profiles={HOME=profile,HOME_1F=profile,HOME_2F=profile,UNKNOWN=profile}}
local defs={TOWN={tileset='OVERWORLD',warps={{x=5,y=5,destMap='HOME'},{x=5,y=5,destMap='HOME_1F'}}},
 SHORTCUT={tileset='OVERWORLD',warps={{x=20,y=20,destMap='HOME_2F'}}}}
package.loaded['src.core.Game']={data={maps=defs,tilesets={OVERWORLD={}}}}
package.loaded['src.world.Map']={new=function(def)return{def=def}end}
mods.VoxelFurniture={findBuildings=function()return{{kind='house',tx=8,ty=6}}end}
mods.Gen1RoomBounds={forMap=function()return{west=0,east=128,north=16,south=128}end}
mods.VoxelItems={models={house={frameW=64,depth=48,glassKind='glass'},glass={boxes={
 {7,9,41,6,10,1,7},{41,9,41,12,10,1,7}, -- real front panes
 {19,12,41,10,6,1,7}, -- glass in entrance must not become another window
 {3,10,12,1,4,3,7},{3,15,12,1,4,3,7}, -- split panes merge once
 {28,26,47,3,5,1,7},{32,26,47,4,5,1,7}, -- attic
 {10,32,10,20,1,20,7}, -- roof skylight, not a wall window
 }}}}
mods.Gen1InteriorLayout={panelsFor=function()return{
 {edge='south',at=128,from=0,upto=128,openings={{from=32,upto=64,height=24}}},
 {edge='west',at=0,from=16,upto=128,openings={}},
 {edge='north',at=16,from=0,upto=128,openings={}},
 {edge='east',at=128,from=16,upto=128,openings={}},
}end}
local H=assert(loadfile('lib/HouseWindows.lua'))(V)
local function map(id)return{id=id,def={tileset='HOUSE',width=4,height=4}}end
local m=map('HOME');local h=assert(H.describe(m));assert(#h.panes==3 and h.height==0)
for _,p in ipairs(h.panes)do
 assert(p.edge~='north'and p.edge~='east','invented facade windows')
 assert(p.bottom==12 and p.top==30)
 if p.edge=='south'then assert(p.upto<=31 or p.from>=65,'doorway overlaps window')end
end
local attic=assert(H.describe(map('HOME_2F')));assert(#attic.panes==1 and attic.height==24 and attic.panes[1].edge=='south')
assert(H.source(map('HOME_2F'))=='TOWN','upper-floor shortcut replaced the ground-floor facade')
assert(not H.describe(map('UNKNOWN')),'unknown exterior invented')
local changed=map('HOME');changed.def.width=5;assert(not H.describe(changed),'modified footprint claimed')
changed=map('HOME');changed.def.generation=2;assert(not H.describe(changed))
enabled=false;assert(not H.describe(m),'building OFF retained live windows')
enabled=true;assert(H.describe(m),'building ON failed to restore')
local a=H.anchor{map=m,w=128,h=128};assert(a.x==64-(64+32)and a.z==64-(48+24)and a.y==0)
print('PASS house windows: native entrance, real facade, attic, door/roof exclusion, split pane merge, toggle, unknown/custom/generation guards')

local pixels={};local cleanup
package.loaded['src.render.Assets']={register=function(f)cleanup=f end}
love={image={newImageData=function(w,h)
 assert(w==512 and h==4)
 return{setPixel=function(_,x,y,r)pixels[y*512+x]=r end,release=function()end}
end},graphics={newImage=function()return{setFilter=function()end,release=function()end}end}}
assert(H.mask(m));assert(pixels[512+18]==1 and not pixels[512+48],'door glass became a window')
assert(not pixels[18],'opaque rear wall lost its mask')
cleanup()
print('PASS compact facade mask: real window visible, entrance and opaque rear wall hidden')

local host={kind='host',tx=0,ty=0};local neighbour={kind='next',tx=8,ty=0}
local models={next={frameW=64,depth=48,boxes={{0,0,0,64,22,48}}}}
local pane={63,10,12,1,8,10}
assert(not H.exposed('east',pane,{frameW=64,depth=48},host,{host,neighbour},models),'shared wall got window')
neighbour.tx=12
assert(H.exposed('east',pane,{frameW=64,depth=48},host,{host,neighbour},models),'street view rejected')
neighbour.tx=8;pane[2]=30
assert(H.exposed('east',pane,{frameW=64,depth=48},host,{host,neighbour},models),'view above neighbour rejected')
print('PASS neighbouring wall exclusion and upper-floor clearance')
