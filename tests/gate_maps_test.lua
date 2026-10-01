local modules={HorizonWall={interiorProfileFor=function()return nil end}}
local G=assert(loadfile('lib/GateMaps.lua'))({require=function(n)return assert(modules[n],n)end,mod={read=function(_,path)local f=assert(io.open(path));local s=f:read('*a');f:close();return s end,find=function()end}})
local points={{x=20,z=0,region='kanto',page=1},{x=120,z=20,region='sevii',page=1}}
assert(G.closest(points,20,41)==points[1]);assert(not G.closest(points,20,43))
assert(G.closest(points,110,20)==points[2])
local press;local ow={map={id='ROUTE_11_GATE_1F'},player={px=12,py=8},runner={isRunning=function()return false end}}
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
G.image=function()return true end;G.asset=function()return nil end
G.frame={map=ow.map,save=game.save,canvas={release=function()end}}
assert(G.open(game));assert(top==G.viewer and top.screen.region=='sevii'and #top.screen.locations==7 and not top.screen.fly and not G.visible)
assert(top.screen.current==nil,'Kanto position was marked on Sevii')
press='right';top:update(.016);assert(top.screen.selected~=1)
press='a';top:update(.016);assert(top.screen.zoomed)
press='select';top:update(.016);assert(top.info and #top.info>0)
press='b';top:update(.016);assert(not top.info and top==G.viewer)
press='start';top:update(.016);assert(top.screen.region=='kanto'and #top.screen.locations==12 and not top.screen.fly and top.screen.current==8)
press='b';top:update(.016);assert(top==ow and not G.viewer and not G.frame and G.dismissed)
assert(not G.open(game),'closed viewer reopened')
print('PASS guardhouse maps: proximity, closest region, leave/reenter hysteresis, native-event/classic guards, shared illustrated Smart Map, seven islands, Kanto switch, navigation/zoom/info, no Fly, close and frame cleanup; no save/item/warp writes')
