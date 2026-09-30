local M=assert(loadfile('lib/Mat4.lua'))()
local S=assert(loadfile('lib/ShadowMap.lua'))({require=function(n)
 if n=='Mat4' then return M end
 return {}
end})
S.slack=.003;S.SNUG=.9
local function equal(a,b)
 for i=1,16 do assert(a[i]==b[i],'snug value changed at '..i)end
end
local function copy(m)local out={};for i=1,16 do out[i]=m[i]end;return out end
local matrix=M.identity()
for case=1,2000 do
 for j=1,16 do matrix[j]=(case*j%173-86)/17 end
 S.KX=(case%17-8)/7;S.KZ=(case%23-11)/9;S.slack=case/123456;S.SNUG=case%7/6
 local got=S.snugStatic(matrix);equal(got,S.snug(matrix));assert(got==S.snugStatic(matrix))
 local held=copy(got)
 matrix[case%16+1]=matrix[case%16+1]+1
 local edited=S.snugStatic(matrix);assert(edited~=got);equal(edited,S.snug(matrix));equal(got,held)
end
local original=S.snugStatic(nil);local snapshot=copy(original)
for _,field in ipairs{'KX','KZ','slack','SNUG'}do
 S[field]=S[field]+.01
 local updated=S.snugStatic(nil);assert(updated~=original);equal(updated,S.snug(nil));equal(original,snapshot)
 original,snapshot=updated,copy(updated)
end
-- Default API retains fresh caller-owned matrices. Static draw consumers retain
-- immutable results; a later light/source change must never overwrite them.
assert(S.snug(nil)~=S.snug(nil))
local owner={};local source=M.translationFor(owner,16,0,32)
local transformed=S.snugStatic(source);local retained=copy(transformed)
local replacement=M.translationFor(owner,32,0,32)
assert(source~=replacement);assert(S.snugStatic(replacement)~=transformed);equal(transformed,retained)
-- No key/value cycle may retain expired neighbor transforms.
local weak=setmetatable({},{__mode='v'})
do local temporary=M.translate(99,3,12);weak[1]=temporary;weak[2]=S.snugStatic(temporary) end
collectgarbage('collect');collectgarbage('collect');assert(weak[1]==nil and weak[2]==nil)
for i=1,2000 do S.snugStatic(source);S.snugStatic(nil)end
collectgarbage('collect');collectgarbage('stop')
local before=collectgarbage('count')
for i=1,10000 do S.snugStatic(source);S.snugStatic(nil)end
local cached=collectgarbage('count')-before
before=collectgarbage('count')
for i=1,10000 do S.snug(source);S.snug(nil)end
local direct=collectgarbage('count')-before
collectgarbage('restart')
assert(cached<1 and direct>1000,'static shadow transforms still allocate each draw')
print('PASS 2000 exact projective transforms; source/light invalidation, retained matrices, weak ownership; 20000 calls KiB cached='..cached..' direct='..direct)
