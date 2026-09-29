local root=assert(arg[1]);local modules={CanvasPresentation={OS='iOS'},ModSetting={new=function()return{get=function()return true end,setGate=function()end}end},Sky={clock=0},DayNight={},Shadows={enabled=function()return false end}}
local V={mod={read=function(_,p)local f=assert(io.open(root..'/'..p));local s=f:read('*a');f:close();return s end}}
V.require=function(n)if modules[n]then return modules[n]end;local m=assert(loadfile(root..'/lib/'..n..'.lua'))(V);modules[n]=m;return m end
local L=V.require('LocalLights');local Grid=V.require('LocalLightGrid')
local pool={};for i=1,72 do pool[i]={x=i*128,y=16,z=0,radius=56,power=1,normal={0,0,0},color={1,.5,.2},owner={}}end
for i=1,36 do pool[i].geometryKey={}end -- immutable authored instances; others use value checks
local layout=Grid.layout(pool);assert(layout.stride==2,'disjoint lights should cost one lamp per cell')
local g=love.graphics
local shader=g.newShader(L.glsl()..[[
uniform vec3 probe;uniform float mode;
vec4 effect(vec4 c,Image t,vec2 uv,vec2 screen) {
 vec3 light=localIrradiance(probe,vec3(0,1,0));
 if(mode>.5)light=localActorIrradiance(probe,vec3(0,1,0));
 return vec4(light,1.0);
}]])
local canvas=g.newCanvas(1,1,{dpiscale=1})
local function setup(focus,buildings)
 L.clear();L.current().map={def={width=200,height=20}};L.current().tint={1,1,1}
 L.assign(pool,buildings or {},focus,false);L.send(shader,true)
end
local function probe(x,y,z,mode)
 shader:send('probe',{x,y,z});shader:send('mode',mode or 0)
 g.push('all');g.setCanvas(canvas);g.origin();g.setShader(shader);g.setBlendMode('replace');g.setColor(1,1,1,1);g.rectangle('fill',0,0,1,1);g.pop()
 local d=canvas:newImageData();local r=d:getPixel(0,0);d:release();return r
end
setup({128,0,0});local first=probe(128,0,0)
assert(first>.25,'first lamp dark')
for i=1,72 do assert(math.abs(probe(i*128,0,0)-first)<.02,'screen-wide lamp '..i..' dark')end
assert(probe(128,0,100)==0,'sphere range ignored')
assert(probe(128,16,10,1)>.1,'actor illumination missing')
local rebuilds=Grid.last.visibilityRebuilds
setup({9216,0,0})
assert(Grid.last.visibilityRebuilds==rebuilds,'player movement rebuilt geometry')
for i=1,72 do assert(math.abs(probe(i*128,0,0)-first)<.02,'walking changed lamp '..i)end
-- Every light receives its own blocker budget, not the four nearest the hero.
local walls={};for i=1,72 do walls[i]={lo={i*128-40,-2,8},hi={i*128+40,40,12}}end
setup({128,0,0},walls)
assert(probe(128,0,20)==0 and probe(9216,0,20)==0,'distant wall leaks')
local before=Grid.last.visibilityRebuilds;pool[1].power=.5;setup({128,0,0},walls)
assert(Grid.last.visibilityRebuilds==before,'flicker rebaked visibility')
local original=pool[1]
pool[1]={x=128,y=16,z=400,radius=56,power=1,normal={0,0,0},color={1,.5,.2},owner={},geometryKey={}}
setup({128,0,400},walls)
assert(probe(128,0,400)>.25 and probe(128,0,0)==0,'replacement geometry receipt kept stale lighting')
pool[1]=original
L.clear(true);L.send(shader,false);assert(probe(128,0,0)==0,'OFF retains light')
L.invalidate();setup({128,0,0});assert(probe(9216,0,0)>.25,'reset lost distant lights')
print('PASS 72 simultaneous lights, mobile budget, actors, movement invariance, range, per-light walls, cached flicker, OFF and reset')
-- Cold grid CPU work must share one allowance across every shader consumer.
-- Keep the previous complete grid during same-map staging, then publish all
-- new indices/data/visibility together. No partial list may reach the shader.
local stagedMap={def={width=200,height=20}}
local function stagedFrame()
 L.clear();L.current().map=stagedMap;L.current().tint={1,1,1}
 L.assign(pool,{}, {128,0,0},false)
 return L.current()
end
Grid.invalidate();stagedFrame();L.send(shader,true) -- initial synchronous reference
local oldGrid=Grid.prepare(L.current(),L,nil)
local saved=pool[72];pool[72]={x=9500,y=16,z=0,radius=56,power=1,normal={0,0,0},color={1,.5,.2},owner={}}
local clock=love.timer.getTime;local fake=0
love.timer.getTime=function()fake=fake+.0002;return fake end
local f=stagedFrame();Grid.beginFrame(false);L.send(shader,true)
assert(Grid.pending(),'cold replacement not staged')
assert(Grid.prepare(f,L,nil)==oldGrid,'partial grid replaced complete lighting')
local groups=0;local groupSources=Grid.sources
Grid.sources=function(...)groups=groups+1;return groupSources(...)end
local frames=0
while Grid.pending()and frames<100 do
 -- Ordinary fixtures rebuild their empty owner records each frame; this
 -- must not defeat geometry matching and trigger repeated grouping.
 for i=37,72 do pool[i].owner={}end
 Grid.beginFrame(false);stagedFrame();L.send(shader,true);frames=frames+1
end
Grid.sources=groupSources
assert(groups==1,'regrouped immutable lights during every pending frame: '..groups)
love.timer.getTime=clock
assert(not Grid.pending()and frames>1 and frames<100,'staged grid failed to finish')
assert(probe(9500,0,0)>.25 and probe(9216,0,0)==0,'staged data/indices/visibility not atomic')
-- A pending job may not outlive reset/OFF or publish its stale geometry.
love.timer.getTime=function()fake=fake+.0002;return fake end
pool[72]=saved;Grid.beginFrame(false);stagedFrame();L.send(shader,true);assert(Grid.pending())
L.clear(true);L.send(shader,false);assert(not Grid.pending(),'OFF retained pending work')
Grid.invalidate();love.timer.getTime=clock
print('PASS light staging: bounded CPU steps, previous complete lighting retained, atomic publication, OFF cancellation; '..frames..' frames')

-- A new map also uses bounded steps, without leaking the old map's grid.
Grid.invalidate();Grid.beginFrame(true)
love.timer.getTime=clock
for i=1,100 do stagedFrame();Grid.beginFrame(true);L.send(shader,true);if not Grid.pending()then break end end
assert(not Grid.pending())
stagedMap={def={width=210,height=20}}
pool[72]={x=9800,y=16,z=0,radius=56,power=1,normal={0,0,0},color={1,.5,.2},owner={}}
love.timer.getTime=function()fake=fake+.0002;return fake end
Grid.beginFrame(false);local fresh=stagedFrame()
assert(Grid.prepare(fresh,L,nil)==nil and Grid.pending(),'new map rebuilt synchronously or exposed old grid')
assert(Grid.prepare(fresh,L,nil)==nil,'same-frame retry exposed previous map')
for i=1,100 do Grid.beginFrame(false);stagedFrame();L.send(shader,true);if not Grid.pending()then break end end
love.timer.getTime=clock
assert(not Grid.pending()and probe(9800,0,0)>.25,'new map failed to publish complete lighting')
print('PASS new-map lighting staging and repeated shader consumers')
