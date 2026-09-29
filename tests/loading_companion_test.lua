local t,active=0,true
love={timer={getTime=function()return t end}}
package.loaded['src.render.Pipelines']={worldPipeline=function()return active and 'voxel'or 'vanilla'end}
local ready,failed,enabled=false,false,true
local modules={SilphWindows={enabled=function()return enabled end},HorizonWall={cacheStatus=function()return{ready=ready,failed=failed}end}}
local L=assert(loadfile('lib/LoadingCompanion.lua')){require=function(n)return assert(modules[n],n)end}
local a,b={id='PALLET_TOWN'},{id='ROUTE_12_GATE_1F'}
local game={overworld={map=a}}
L.probe(a,false,'warp');assert(not L.status().visible)
t=.1;L.probe(a,true,'warp');assert(not L.status().visible,'warm warp flashes loader')
t=1;L.probe(a,false,'warp');t=1.2;L.probe(a,false,'warp');assert(L.status().visible)
L.probe(a,true,'warp');assert(not L.status().visible,'ready wait extended for animation')
L.probe(a,false,'warp');t=2;L.update(game);assert(not L.status().visible,'abandoned transition retained')
L.windows(game);t=2.3;L.update(game);assert(L.status().visible)
ready=true;L.update(game);assert(not L.status().visible)
ready=false;L.windows(game);failed=true;L.update(game);assert(not L.status().visible,'failed build retained loader')
failed=false;L.windows(game);game.overworld.map=b;L.update(game);assert(not L.status().visible)
game.overworld.map=a;L.windows(game);enabled=false;L.update(game);assert(not L.status().visible)
enabled=true;L.windows(game);active=false;t=5;assert(not L.status().visible);L.update(game)
L.probe(a,false,'warp');L.windows(game);assert(not L.status().visible,'vanilla received loader')
print('PASS loading companion: cold/warm, ready immediately, cancel, failure, map change, toggle and vanilla')
-- The final compositor must cover a native 2D re-blit during Continue, but
-- must not hide a validation report stacked above preparation.
local rects={}
love.graphics=setmetatable({getDimensions=function()return 640,480 end,
 newFont=function()return{}end,rectangle=function(...)rects[#rects+1]={...}end},
 {__index=function()return function()end end})
package.loaded['src.render.Assets']={register=function()end}
local top={vascContinue=true};game.stack={top=function()return top end}
active=true;L.probe(a,false,'continue');L.draw(game)
assert(rects[1][1]=='fill'and rects[1][2]==0 and rects[1][3]==0
 and rects[1][4]==640 and rects[1][5]==480,'Continue does not cover final world composite')
rects={};top={};L.draw(game)
assert(rects[1][2]~=0,'Continue hid validation report')
print('PASS Continue final composite cover and validation-report visibility')

-- A zero-in native fade can be re-blitted by the world compositor just like
-- Continue. Cover it from the first pending frame, before icon debounce.
L.clear();top={alpha=function()return 1 end};rects={}
L.probe(a,false,'warp');assert(not L.status().visible and L.status().cover)
L.draw(game);assert(#rects==1 and rects[1][2]==0 and rects[1][4]==640,'cold warp leaked before debounce')
t=t+4;L.probe(a,false,'warp');rects={};L.draw(game)
assert(L.status().visible and rects[1][2]==0,'long warp lost opaque cover')
top={};rects={};L.draw(game);assert(rects[1][2]~=0,'warp cover hid error/report')
L.probe(a,true,'warp');rects={};L.draw(game);assert(#rects==0,'warm arrival got artificial delay')
active=false;L.probe(a,false,'warp');rects={};L.draw(game);assert(#rects==0,'vanilla got cover')
print('PASS warp final cover: immediate, long wait, report visibility, immediate release and vanilla')
