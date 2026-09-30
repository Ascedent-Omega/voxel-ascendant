local Q=assert(loadfile('lib/ArenaQueryCache.lua'))()
local value=1
local C=Q.new({open=function()return value end})
local m={id='map',widthCells=10,heightCells=10,def={},tileset={}}
local config={shape={x=1},flag=false}
local function pack(...)return{n=select('#',...),...}end
local calls=0
local function solve()
 calls=calls+1;C.read('open',m,1,2,false)
 return nil,{map=m,pick=config.shape,value=value},nil
end
local function run(key)return pack(C.run(key or'key',config,solve))end
local first=run();assert(first.n==3 and first[1]==nil and first[2].value==1 and first[3]==nil)
local second=run();assert(calls==1 and second.n==3 and second[2]~=first[2] and second[2].map==m and second[2].pick==config.shape)
value=2;assert(run()[2].value==2 and calls==2)
config.flag=true;run();assert(calls==3)
config.shape.x=2;run();assert(calls==4)
config.shape={x=2};run();assert(calls==5)
-- The small request ring does not keep every map/cell ever visited alive.
for i=1,9 do run('key-'..i)end
local before=calls;run('key');assert(calls==before+1)
C.clear();C.maxFacts=0
run();run();assert(calls==before+3,'over-budget proof was cached')
C.maxFacts=32768;config.loop=config;run();run();assert(calls==before+5,'cyclic configuration was cached');config.loop=nil
setmetatable(config.shape,{__index={}});run();run();assert(calls==before+7,'dynamic configuration was cached');setmetatable(config.shape,nil)
-- Errors cannot strand a live recorder and accidentally admit the next solve.
local fault={}
local ok,err=pcall(C.run,'fault',{},function()C.read('open',m,1,2,false);error(fault)end)
assert(not ok and err==fault);local a=run();local b=run();assert(a[2].value==b[2].value and C.hits>0)
-- A query that changes twice within a solve has no stable proof.
C.clear();before=calls
local function changing()calls=calls+1;C.read('open',m,1,2,false);value=value+1;C.read('open',m,1,2,false);return value end
C.run('unstable',{},changing);C.run('unstable',{},changing);assert(calls==before+2)
print('PASS arena query proof budgets, identity/content changes, nil result arity, bounded retention, errors and unstable queries')
