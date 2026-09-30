local calls=0;local resident={};local fail=false
local Loader={cached=function(id)return resident[id]end,load=function(data,id)
 calls=calls+1;if fail then error('missing optional court')end
 resident[id]={id=id};return resident[id]
end}
package.loaded['src.world.MapLoader']=Loader;package.loaded['src.core.Game']={data={}}
local B=assert(loadfile('lib/BattleArena.lua')){data=function()return{}end,require=function()return{}end}
local map={id='LOWER'}
B.setOverride('LOWER',{spots={{map='UPPER',x=2,y=2},{map='UPPER',x=8,y=8},{map='LOBBY',x=4,y=4}}})
assert(not B.prepare(map)and calls==1);assert(not B.prepare(map)and calls==2)
for i=1,100 do assert(B.prepare(map))end;assert(calls==2,'warm floors decoded again')
resident.UPPER=nil;assert(not B.prepare(map)and calls==3,'evicted floor not rewarmed')
B.setOverride('LOWER',{map='OPTIONAL',x=1,y=1});fail=true
assert(not B.prepare(map));assert(B.prepare(map));assert(calls==4,'failed optional floor retried every frame')
B.setOverride('LOWER',false);assert(B.prepare(map)and calls==4)
print('PASS foreign arena floor preload: bounded, deduplicated, warm, eviction, overrides and failed optional maps')
