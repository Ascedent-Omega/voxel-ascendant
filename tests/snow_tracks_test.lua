local deep='deep';local land=true
local mods={DeepSnow={setting={get=function()return deep end}},WorldWeather={surface=function()return 0,true,0,land end}}
local S=assert(loadfile('shared/SnowTracks.lua')){require=function(n)return assert(mods[n],n)end}
local p={px=0,py=0};local map={};local game={save={options={sfxVol=0}},overworld={player=p,map=map}}
S.update(.1,game,'snow');for i=1,20 do p.px=i*6;S.update(.1,game,'snow')end
assert(#S.marks==20,'muted walking must leave prints')
assert(S.marks[1].z~=S.marks[2].z,'left/right feet not alternating')
local verts,n=S.vertices(function()return 2 end);assert(n==40 and #verts==n*6)
for _,q in ipairs(verts)do assert(q[2]>2 and q[2]<2.1 and q[10]>.6)end
p.jumping=true;p.px=p.px+6;S.update(.1,game,'snow');assert(#S.marks==20)
p.jumping=false;p.px=p.px+100;S.update(.1,game,'snow');assert(#S.marks==20,'teleport stamped snow')
land=false;p.px=p.px+6;S.update(.1,game,'snow');assert(#S.marks==20,'roof/water stamped')
land=true;for i=1,100 do p.px=p.px+6;S.update(.1,game,'snow')end;assert(#S.marks==S.MAX,'unbounded trail')
for i=1,400 do S.update(.15,game,'snow')end;assert(#S.marks==0,'tracks do not fade')
p.px=p.px+6;S.update(.1,game,'snow');assert(#S.marks==1);deep='normal';S.update(.1,game,'snow');assert(#S.marks==0)
print('PASS muted tracks, alternating soles, surface heights, hop/teleport/water exclusion, bound, fade and disable cleanup')
