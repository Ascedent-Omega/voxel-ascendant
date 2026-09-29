local created,released,compiled=0,0,0
local reject,bindReject,painted
local state={}
local function object(w,h)
 created=created+1
 return {w=w,h=h,release=function()released=released+1 end,setFilter=function()end,setWrap=function()end}
end
local P={new=function(w,h,opts)
 if reject=='color' or (reject=='depth' and opts)then return false,'allocation rejected' end
 return true,object(w,h)
end}
love={graphics={newShader=function()
 compiled=compiled+1;if reject=='shader' then error('compile rejected')end
 return{send=function()end,release=function()end}
end,setCanvas=function(value)if bindReject and type(value)=='table' and value.depthstencil then error('bind rejected')end;state.canvas=value end,
setDepthMode=function(mode,write)state.depth=mode;state.write=write end,
setBlendMode=function(mode)state.blend=mode end,setColor=function()end,setShader=function(s)state.shader=s end,
draw=function()assert(state.depth=='always' and state.write,'copy did not write depth')end}}
local function load()return assert(loadfile('lib/WaterReflection.lua'))({require=function(n)assert(n=='PixelCanvas');return P end})end
local function slot(w,h)return{w=w,h=h,canvas={},depth={getFormat=function()return'depth24'end}}end
local R=load();assert(R.prepareProgram());assert(not R.prepareProgram() and compiled==1)
local s=slot(1710,955);local t=assert(R.prepare(s));assert(t.w==855 and t.h==478)
for i=1,40 do assert(R.prepare(s)==t)end;assert(created==2)
local mirror,depth=R.draw(s,function()
 assert(state.depth=='lequal' and state.write and state.shader=='scene');painted=true
end,'scene')
assert(painted and mirror==t.color and depth==s.depth)
assert(state.canvas==s.canvas and state.depth==nil and state.shader==nil)
R.draw(s,function()error('paint rejected')end,'scene');assert(R.lastPaintError:find('paint rejected'))
assert(state.canvas==s.canvas and state.depth==nil)
R.release(s);assert(released==2 and s.waterReflection==nil)
local small=slot(160,144);assert(R.prepare(small).w==160);R.release(small)
for _,failure in ipairs{'shader','color','depth','bind'}do
 reject=failure;bindReject=failure=='bind';local module=load();local subject=slot(641,361)
 local before=compiled;local made,dropped=created,released
 assert(module.draw(subject,function()error('must not paint')end,'scene')==nil)
 assert(subject.waterReflection==false)
 for i=1,20 do assert(module.draw(subject,nil,'scene')==nil)end
 assert(compiled-before==1,'optional failure retried every frame')
 assert(created-made==released-dropped,'failed target leaked resources')
end
print('PASS water reflection: reuse, odd sizes, small targets, depth isolation, paint recovery, allocation/compile/bind failure and release')
