local modules={HorizonWall={interiorProfileFor=function()return nil end}}
local G=assert(loadfile('lib/GateMaps.lua'))({require=function(n)return assert(modules[n],n)end})
local points={{x=20,z=0,region='kanto',page=1},{x=120,z=20,region='sevii',page=3}}
assert(G.closest(points,20,41)==points[1]);assert(not G.closest(points,20,43))
assert(G.closest(points,110,20)==points[2])
local press;local ow={map={},player={px=12,py=8},runner={isRunning=function()return false end}}
local top=ow;local game={overworld=ow,save={},stack={top=function()return top end,push=function(_,v)top=v end,pop=function()top=ow end},input={wasPressed=function(_,k)return press==k end}}
G.placements=function()return points end
G.update(0,game,1);assert(G.visible and G.visible.region=='kanto')
press='b';G.update(0,game,1);assert(not G.visible and G.dismissed)
press=nil;G.update(0,game,1);assert(not G.visible,'dismissed prompt repeated')
ow.player.px=240;G.update(0,game,1);assert(not G.dismissed)
ow.player.px=12;G.update(0,game,1);assert(G.visible)
ow.player.inputLocked=true;G.update(0,game,1);assert(not G.visible,'native event interrupted');ow.player.inputLocked=false
G.update(0,game,0);assert(not G.visible,'classic renderer received wall prompt')
ow.player.px=112;G.update(0,game,1);assert(G.visible.region=='sevii')
G.image=function()return true end
G.frame={map=ow.map,save=game.save,canvas={release=function()end}}
assert(G.open(game));assert(top==G.viewer and top.page==3 and not G.visible)
press='right';top:update();assert(top.page==1)
press='left';top:update();assert(top.page==3)
press='b';top:update();assert(top==ow and not G.viewer and not G.frame and G.dismissed)
assert(not G.open(game),'closed viewer reopened')
print('PASS guardhouse maps: proximity, closest region, leave/reenter hysteresis, native-event/classic guards, three Sevii pages, close and frame cleanup; no save/item/warp writes')
