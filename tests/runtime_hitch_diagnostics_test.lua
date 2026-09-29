local now=0
love={timer={getTime=function()return now end},graphics={getStats=function()return {drawcalls=12,texturememory=4096}end}}
local mod={exports={}}
local R=assert(loadfile('lib/RuntimePerformanceDiagnostics.lua'))(mod)
local top={name='world'}
local game={overworld={map={id='A'}},stack={top=function()return top end}}
local work=0
local scene=R.wrap('VoxelScene',{setPreparationCovered=function()end,render=function()now=now+work;return nil,'kept',nil end})
game.update=function()end
game.draw=function()return scene.render()end
R.install(game)
local function draw()local a,b,c=game:draw();assert(a==nil and b=='kept' and c==nil)end
for i=1,1000 do now=now+.016;game:update();draw()end
assert(#R.hitches==0,'fast frames must not allocate hitch records')
work=.065;draw();work=0
now=now+.003;game.overworld.map.id='B';top={name='loading'};scene.setPreparationCovered(true);game:update();draw()
local hitch=assert(R.hitches[1]);assert(hitch.fromMap=='A' and hitch.map=='B' and hitch.covered)
assert(math.abs(hitch.ms-68)<.00001 and math.abs(hitch.callbackMs-65)<.00001)
assert(math.abs(hitch.unattributedMs-3)<.00001)
local render
for _,row in ipairs(hitch.rows)do if row.name=='VoxelScene.render'then render=row end end
assert(render and math.abs(render.total-65)<.00001)
now=now+.090;draw()
assert(math.abs(R.hitches[2].unattributedMs-90)<.00001,'outside-callback stall must remain unknown, not GPU')
assert(math.abs(render.total-65)<.00001,'retained rows must not be reused')
local c=R.wrap('ChunkMesher',{pump=function()coroutine.yield();return 8,nil,10 end})
local co=coroutine.create(c.pump);assert(coroutine.resume(co))
now=now+.080;draw()
local ok,a,b,d=coroutine.resume(co);assert(ok and a==8 and b==nil and d==10)
assert(not R.frameRows['ChunkMesher.pump'],'suspended lifetime must not count as CPU work')
local broken=R.wrap('TiltShift',{apply=function()now=now+.001;error('original failure')end})
local success,err=pcall(broken.apply);assert(not success and err:find('original failure',1,true))
assert(#R.stack==0,'error left timing stack unbalanced')
for i=1,60 do now=now+.051;draw()end
assert(#R.hitches==24 and #R.worstHitches==8)
assert(R.worstHitches[1].ms>=90-.00001)
local report=R.evidence();assert(report:find('runtime%-evidence=3') and report:find('fromMap=A map=B',1,true))
print('PASS hitch attribution: nested callbacks, unknown waits, map transitions, bounded retention, yields, errors, nil returns, fast frames')
