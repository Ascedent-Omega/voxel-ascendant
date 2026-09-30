local O=assert(loadfile('lib/OpaqueMaterials.lua'))()
local P=assert(loadfile('lib/OpaqueProgram.lua'))()
local g=love.graphics
local source=[[
#pragma language glsl3
#ifdef VERTEX
vec4 position(mat4 m,vec4 p){return vec4(p.xyz,1);}
#endif
#ifdef PIXEL
vec4 effect(vec4 color,Image tex,vec2 uv,vec2 pixel){vec4 p=Texel(tex,uv);if (p.a < 0.5) discard;return vec4(p.rgb,1)*color;}
#endif
]]
local d=love.image.newImageData(16,8)
for y=0,7 do for x=0,15 do d:setPixel(x,y,x/15,y/7,.4,(x>=8 and(x+y)%3==0)and 0 or 1)end end
local texture=g.newImage(d);texture:setFilter('nearest','nearest');O.texture(texture,d)
local rows,indices={},{};local c=O.collector(16,8)
for i=1,1024 do
 local alpha=math.floor((i-1)/256)%2==1
 local u0,u1=alpha and .55 or .05,alpha and .94 or .44
 O.quad(c,u0,.05,u1,.94)
 local x=((i*17)%31)/20-1;local y=((i*11)%29)/20-1;local z=i%5*.02
 local base=#rows
 for _,v in ipairs{{x,y,z,u0,.05},{x+.4,y,z,u1,.05},{x+.4,y+.4,z,u1,.94},{x,y+.4,z,u0,.94}}do rows[#rows+1]=v end
 for _,k in ipairs{1,2,3,1,3,4}do indices[#indices+1]=base+k end
end
local mesh=g.newMesh({{'VertexPosition','float',3},{'VertexTexCoord','float',2}},rows,'triangles','static');mesh:setVertexMap(indices);mesh:setTexture(texture);O.remember(mesh,c)
assert(not O.allowed(mesh,texture));local ranges=assert(O.ranges(mesh,texture));assert(#ranges==4)
assert(O.ranges(mesh,texture)==ranges,'ranges rebuilt each draw')
local shader=g.newShader(source);P.register(shader,source);assert(P.prepare(shader));local p=P.wrap(shader)
local target=g.newCanvas(97,73,{dpiscale=1});local depth=g.newCanvas(97,73,{format='depth24stencil8',dpiscale=1})
local function paint(split,alpha)
 g.setCanvas({target,depthstencil=depth});g.clear(.1,.2,.3,1,true,true);g.origin();g.setShader(shader)
 g.setColor(1,1,1,alpha);g.setBlendMode('alpha','alphamultiply');g.setDepthMode('lequal',true)
 if split then assert(P.drawRanges(p,mesh,ranges))else g.draw(mesh)end
 assert(mesh:getDrawRange()==nil and g.getShader()==shader,'draw state lost')
 g.setShader();g.setDepthMode();g.setCanvas();local data=target:newImageData();local bytes=data:getString();data:release();return bytes
end
for _,alpha in ipairs{1,.6}do assert(paint(false,alpha)==paint(true,alpha),'primitive order/alpha changed')end
local reference=paint(false,.6);local draw=g.draw;local fired=false
-- Fail in the second opaque range, after previous ranges already drew.
g.draw=function(object,...)
 local first=mesh:getDrawRange()
 if object==mesh and first==3073 and not fired then fired=true;error('injected opaque refusal')end
 return draw(object,...)
end
assert(paint(true,.6)==reference,'partial failure duplicated earlier blended ranges');g.draw=draw
assert(fired and p.opaque==false,'optional failure not latched')
mesh:setDrawRange(7,6);assert(not P.drawRanges(p,mesh,ranges));mesh:setDrawRange()
-- New texture alpha must invalidate the per-image proof even with same identity.
d:mapPixel(function(x,y,r,g,b,a)return r,g,b,0 end);O.texture(texture,d)
assert(O.ranges(mesh,texture)==nil,'reuploaded alpha retained opaque ranges')
print('PASS ordered opaque/alpha ranges: exact GPU color/depth, coplanar blends, late failure and refreshed texture proof')

d:mapPixel(function(x,y)return x/15,y/7,.4,x>=8 and 0 or 1 end);O.texture(texture,d)
local partial=O.collector(16,8);local partialMesh={}
for i=1,512 do if i<=256 then O.quad(partial,-1,0,.2,1)else O.quad(partial,.05,.05,.44,.94)end end
O.remember(partialMesh,partial);local mixed=assert(O.ranges(partialMesh,texture))
assert(#mixed==2 and not mixed[1].opaque and mixed[2].opaque,'unknown UV page tainted known range')
local fragmented=O.collector(16,8);local fragmentedMesh={}
for i=1,2304 do local alpha=math.floor((i-1)/256)%2==1;O.quad(fragmented,alpha and .55 or .05,.05,alpha and .94 or .44,.94)end
O.remember(fragmentedMesh,fragmented);assert(O.ranges(fragmentedMesh,texture)==nil,'fragmentation budget exceeded')
print('PASS unknown UV isolation and bounded draw fragmentation')
