local O=assert(loadfile('lib/OpaqueMaterials.lua'))()
local P=assert(loadfile('lib/OpaqueProgram.lua'))()
local Mat=assert(loadfile('lib/Mat4.lua'))()
local tex={getFilter=function()return 'nearest','nearest'end}
local alpha=true
local data={getDimensions=function()return 16,8 end,getPixel=function(_,x,y)return 1,1,1,(alpha and x==12 and y==4)and 0 or 1 end}
O.texture(tex,data)
local mesh={};local c=O.collector(16,8);O.quad(c,.01,.01,.49,.99);O.remember(mesh,c)
assert(O.allowed(mesh,tex),'unrelated alpha tile rejects solid geometry')
local cut={};local d=O.collector(16,8);O.quad(d,.6,.2,.9,.8);O.remember(cut,d)
assert(not O.allowed(cut,tex),'alpha tile certified opaque')
assert(not O.allowed({},tex),'unknown UVs certified against mixed image')
alpha=false;O.texture(tex,data);assert(O.allowed({},tex),'fully opaque image needs no UV restriction')
tex.getFilter=function()return 'linear','linear'end;assert(not O.allowed(mesh,tex))
tex.getFilter=function()return 'nearest','nearest'end;O.enabled=false;assert(not O.allowed(mesh,tex));O.enabled=true
local sends=0;local bound;local fail=false
local function shader()return {hasUniform=function()return true end,send=function()if fail then error('injected')end;sends=sends+1 end}end
love={graphics={newShader=function(src)assert(not src:find('discard%s*;'));return shader()end,setShader=function(s)bound=s end}}
assert(not P.source('if (newMask) discard;'),'unknown mask silently removed')
local sh=shader();P.register(sh,'if (p.a < 0.5) discard;');assert(P.prepare(sh));assert(not P.prepare(sh))
local pair=P.wrap(sh);local row={1,2,3};pair:send('curve',row);local n=sends;pair:send('curve',row);assert(sends==n)
row[1]=4;pair:send('curve',row);assert(sends==n+1 and pair.values.curve[1][1]==4)
pair:send('cutaway',{0,0,0,0});pair:send('actorWaterline',-30000);pair:send('roomMaskSize',{1,1,0});pair:send('silphWindow',{0,0,0,0})
assert(P.worldSafe(pair));pair:send('roomMaskSize',{1,1,2});assert(not P.worldSafe(pair));pair:send('roomMaskSize',{1,1,0})
pair:send('cutaway',{0,0,0,1});assert(not P.worldSafe(pair));pair:send('cutaway',{0,0,0,0})
pair:send('actorWaterline',2);assert(not P.worldSafe(pair));pair:send('actorWaterline',-30000)
pair:send('silphWindow',{64,64,12,9});assert(not P.worldSafe(pair));pair:send('silphWindow',{0,0,0,0})
assert(P.bind(pair)and bound==pair.opaque);local n=sends;P.bind(pair);assert(sends==n)
P.wrap(sh);pair:send('curve',row);assert(sends==n+1,'new pass must restore native uniform ownership')
fail=true;assert(not pcall(pair.send,pair,'broken',4));assert(not pair.values.broken);fail=false;pair:send('broken',4)
local native=shader();P.register(native,'if (p.a < 0.5) discard;');P.prepare(native);local rejected=P.wrap(native)
love.graphics.draw=function()error('lazy driver failure')end
assert(not P.draw(rejected,{}));assert(rejected.opaque==false and bound==native,'failed optional draw did not restore native shader')
assert(not P.bind(rejected),'rejected optional program retried')
local native2=shader();P.register(native2,'if (newMask) discard;');assert(P.prepare(native2));assert(P.native(P.wrap(native2))==native2 and not P.status(native2).opaque,'unknown mask did not fall back')
local owner={};local a=Mat.translationFor(owner,1,2,3);assert(a==Mat.translationFor(owner,1,2,3))
local b=Mat.translationFor(owner,4,2,3);assert(a~=b and a[4]==1 and b[4]==4,'changed translation mutated retained draw')
print('PASS opaque proof, alpha fallback, masks, scratch uniforms, failure retry and immutable translations')
