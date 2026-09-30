local M=assert(loadfile('lib/BattleShadowStamp.lua'))()
local function image()return{typeOf=function(_,kind)return kind=='Image'end}end
local src={inkIdentity=image()};local matrix={1,0,0,8,0,1,0,0,0,0,1,16,0,0,0,1}
local cards={{side='enemy',tex={},source=src,shadowModel=matrix}}
local b={fx={}};local textures={vascRenderBattle=b}
local stable=M.signature(cards,1,textures,false)
assert(M.signature(cards,2,textures,false)==stable,'idle token still invalidates shadows')
matrix[4]=9;assert(M.signature(cards,2,textures,false)~=stable,'attack displacement ignored');matrix[4]=8
local old=src.inkIdentity;src.inkIdentity=image();assert(M.signature(cards,2,textures,false)~=stable,'art change ignored');src.inkIdentity=old
assert(M.signature({},2,textures,false)~=stable,'hidden/fainted actor ignored')
for _,field in ipairs{'growIn','shrinkOut','animPlaying'}do
 b[field]=true;assert(M.signature(cards,1,textures,false)~=M.signature(cards,2,textures,false),field..' frozen');b[field]=nil
end
for _,fx in ipairs{{faint={frames=5}},{flash=1},{blink={frames=5}},{shakeX=3}}do
 b.fx=fx;assert(M.signature(cards,1,textures,false)~=M.signature(cards,2,textures,false),'effect frozen')
end
b.fx={};src.inkTransient=true;assert(M.signature(cards,1,textures,false)~=M.signature(cards,2,textures,false));src.inkTransient=nil
src.inkIdentity=nil;assert(M.signature(cards,1,textures,false)~=M.signature(cards,2,textures,false),'unknown provider frozen')
src.inkIdentity={typeOf=function()return false end};assert(M.signature(cards,1,textures,false)~=M.signature(cards,2,textures,false),'mutable Canvas source frozen')
src.inkIdentity=old;assert(M.signature(cards,1,textures,true)~=M.signature(cards,2,textures,true),'animated 3D model frozen')
print('PASS battle shadow stamps: idle reuse, art, geometry, visibility, effects and conservative animated/unknown providers')
