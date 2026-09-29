local key='auto'
local R=assert(loadfile('shared/RainStrength.lua')){require=function(n)
 assert(n=='ModSetting');return{new=function()return{get=function()return key end}end}
end}
assert(R.profile('rain').key=='normal' and R.profile('storm').key=='heavy')
local W=assert(loadfile('shared/WorldWeather.lua')){require=function()error('unexpected dependency')end}
local previous=0
local map={inBounds=function()return true end}
local normal,heavy
for _,level in ipairs{'light','normal','heavy'}do
 key=level;local p=R.profile('rain')
 local verts,n=W.build(map,{160,0,160},false,nil,function()return 24,false end,p)
 assert(n>previous and n<=W.MAX_QUADS);previous=n
 for i=1,#verts,6 do assert(verts[i][2]==24 and verts[i][9]==0,'rain passes through roof or splashes underneath')end
 if level=='normal'then normal=p.audio end;if level=='heavy'then heavy=p.audio end
end
assert(heavy>normal);key='corrupt';assert(R.profile('rain').key=='normal')
local S=assert(loadfile('shared/ScenerySnow.lua'))()
assert(S.amount{weather='snow',outdoor=true,amount=.7}==.7)
for _,c in ipairs{{weather='snow',outdoor=false},{weather='rain',outdoor=true},{weather='snow',outdoor=true,surfaces=false},{weather='snow',outdoor=true,amount=0/0}}do assert(S.amount(c)==0)end
print('PASS ordered bounded rain strengths, roof endpoints, audio gains and scenery snow gates')
