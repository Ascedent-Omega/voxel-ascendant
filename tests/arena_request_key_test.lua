local mode='raised';local C={cacheRevision=3};local H={cacheRevision=7}
local modules={ChunkMesher=C,HorizonWall=H,LedgeElevation={mode=function()return mode end}}
local B=assert(loadfile('lib/BattleArena.lua')){data=function()return{}end,require=function(n)return modules[n]or{}end}
local map={id='ROUTE_1',widthCells=20,heightCells=40,def={},tileset={}}
local function key(x,y,surf)return assert(B.requestKey(map,x or 5,y or 7,surf))end
local previous=key();for i=1,100 do assert(previous==key())end
local function changed(mutate)
 mutate();local current=key();assert(current~=previous,'changed placement reused preflight');previous=current
end
changed(function()C.cacheRevision=C.cacheRevision+1 end)
changed(function()H.cacheRevision=H.cacheRevision+1 end)
changed(function()mode='flat'end)
changed(function()map.def={}end)
changed(function()map.tileset={}end)
changed(function()map.widthCells=21 end)
changed(function()map.heightCells=41 end)
changed(function()B.setOverride(map.id,false)end)
assert(key(5.1,7)~=key(5.9,7),'distinct fractional search origins collapsed')
assert(key(5,7,true)~=key(5,7,false),'surfing result reused on land')
assert(key(5,7)~=key(6,7)and key(5,7)~=key(5,8))
local other={id=map.id,widthCells=map.widthCells,heightCells=map.heightCells,def=map.def,tileset=map.tileset}
assert(key()~=B.requestKey(other,5,7,false),'same-ID replacement retained old preflight')
assert(B.requestKey(nil,5,7)==nil)
print('PASS arena request receipt: exact origin, terrain/scenery publication, mode, dimensions, data replacement, authoring revision and map identity')
-- Exercise the actual preflight consumer: unchanged requests consume once;
-- edited geometry resolves a fresh arena instead of returning the old table.
local file=assert(io.open('lib/OverworldBattle.lua'));local source=file:read('*a');file:close()
local keySource=assert(source:match('(local function stageRequestKey%b().-\nend)\n\nlocal function canStageFront'))
local stageSource=assert(source:match('(function OverworldBattle.stageFor%b().-\nend)\n\nlocal RENDERER_SESSION_SCHEMA'))
local calls=0;local fresh={map=map,tag='fresh'}
B.find=function()calls=calls+1;return fresh end
local env=setmetatable({BattleArena=B,OverworldBattle={ARENA='arena',FLAT_B='flatB'},selectedBattleMode=function()return'map'end},{__index=_G})
local keyChunk=assert(loadstring(keySource..'\nreturn stageRequestKey'));setfenv(keyChunk,env);env.stageRequestKey=keyChunk()
local stageChunk=assert(loadstring(stageSource));setfenv(stageChunk,env);stageChunk()
local state={map=map,player={cellX=5,cellY=7,surfing=false}};local plan={mode='map'};local prior={tag='cached'}
env.staged={key=env.stageRequestKey(state,'map'),ready=true,arena=prior}
assert(env.OverworldBattle.stageFor(state,plan)==prior and calls==0 and not env.staged.ready)
assert(env.OverworldBattle.stageFor(state,plan)==fresh and calls==1,'consumed preflight was reused')
env.staged={key=env.stageRequestKey(state,'map'),ready=true,arena=prior};C.cacheRevision=C.cacheRevision+1
assert(env.OverworldBattle.stageFor(state,plan)==fresh and calls==2,'terrain edit consumed stale arena')
env.staged={key=env.stageRequestKey(state,'map'),ready=true,arena=prior};H.cacheRevision=H.cacheRevision+1
assert(env.OverworldBattle.stageFor(state,plan)==fresh and calls==3,'scenery publication consumed stale arena')
print('PASS actual stageFor consumes unchanged preflight once and resolves again after terrain/scenery changes')
