-- Exact command-stream cache for the opaque prefix of a battle world pass.
-- Sky/panorama, transparent effects, actors, weather and UI remain live. A
-- changed command replays the matching prefix before drawing the changed
-- suffix. No camera threshold, animation throttle or low-resolution target.
local V=...
local R=V.require('RasterResources')
-- Small targets cost less to redraw than to validate/copy. Native comparisons
-- found savings only for larger world targets, so auto keeps those small
-- targets and short command streams on the direct path. `true` is a QA bypass.
local M={enabled='auto',minimumPixels=1500000,minimumCommands=32,
 recording=false,hits=0,captures=0,misses=0,replayed=0}
local active,restoreShader
local dependencyScratch={}
local gates={weatherGround=true,weatherGrass=true,volcanoMagma=true,birdShadow=true,
 sunDark=true,sunReceive=true,weatherCoverOn=true,glassOn=true,roomMaskSize=true,
 silphWindow=true,localMosaicWater=true,localSkyState=true}
function M.changed(program,name)
 if active and active.lastProgram==program then active.changes[name]=true end
end
local function clone(value,old)
 if type(value)~='table'then return value end
 old=type(old)=='table'and old or{}
 for k in pairs(old)do if value[k]==nil then old[k]=nil end end
 for k,v in pairs(value)do old[k]=clone(v,old[k])end
 return old
end
local function equal(a,b)
 if type(a)~='table'or type(b)~='table'then return a==b end
 for k,v in pairs(a)do if not equal(v,b[k])then return false end end
 for k in pairs(b)do if a[k]==nil then return false end end
 return true
end
local function scalar(values,name)
 local row=values[name];return row and row[1]or 0
end
local function relevant(name,values)
 if name=='weatherTime'then
  return scalar(values,'weatherGround')~=0 or scalar(values,'weatherGrass')~=0
 end
 if name=='volcanoTime'then return scalar(values,'volcanoMagma')~=0 end
 if name=='cloudTime'then return scalar(values,'birdShadow')~=0 end
 if name=='weatherCover'then return scalar(values,'weatherCoverOn')~=0 end
 if name=='glassMask'then return scalar(values,'glassOn')~=0 end
 if name=='roomMask'then local row=values.roomMaskSize;return row and row[1][3]~=0 end
 if name=='houseWindowMask'then local row=values.silphWindow;return row and row[1][1]~=0 end
 if name=='sunMap'then return scalar(values,'sunDark')~=0 and scalar(values,'sunReceive')~=0 end
 return true
end
local function uniformEqual(name,row,old,values)
 if name=='localSkyState'and old then
  local s=row[1]
  if (s[1]<.5 or s[2]<.5)and scalar(values,'localMosaicWater')<.5 then
   return s[1]==old[1][1]and s[2]==old[1][2]
  end
 end
 return equal(row,old)
end
local function release(o)if o and o.release then pcall(o.release,o)end end
function M.release(slot)
 local c=slot and slot.battleWorldLayer
 if c then release(c.color);release(c.depth)end
 if slot then slot.battleWorldLayer=nil end
end
function M.preparePrograms()
 if restoreShader~=nil then return false end
 local source=[[
#pragma language glsl3
uniform Image sourceDepth;
vec4 effect(vec4 color,Image tex,vec2 uv,vec2 pixel){
 vec4 p=Texel(tex,uv);
 if(p.a==0.0)discard;
 gl_FragDepth=Texel(sourceDepth,pixel/love_ScreenSize.xy).r;
 return p;
}
]]
 local ok,value=pcall(love.graphics.newShader,source)
 restoreShader=ok and value or false
 if not ok then M.lastError=tostring(value)end
 return true
end
local function rawDraw(mesh,count)
 if count then love.graphics.drawInstanced(mesh,count)else love.graphics.draw(mesh)end
end
local function sendSnapshot(program,values)
 for name,row in pairs(values)do program:send(name,unpack(row,1,row.n))end
end
local function replay(a,n)
 if n==0 then return end
 local g=love.graphics;g.push('all')
 local ok,err=pcall(function()
  g.origin();g.setScissor();g.setStencilTest();g.setColorMask(true,true,true,true)
  g.setMeshCullMode('none');g.setWireframe(false)
  for i=1,n do
   local c=a.previous[i]
   g.setShader(c.program.native);sendSnapshot(c.program.native,c.uniforms)
   g.setColor(unpack(c.color));g.setDepthMode('lequal',true);g.setBlendMode('alpha','alphamultiply')
   local texture=c.mesh:getTexture();local first,last=c.mesh:getDrawRange()
   c.mesh:setTexture(c.texture)
   if c.first then c.mesh:setDrawRange(c.first,c.last)else c.mesh:setDrawRange()end
   local drawn,reason=pcall(rawDraw,c.mesh,c.count)
   c.mesh:setTexture(texture)
   if first then c.mesh:setDrawRange(first,last)else c.mesh:setDrawRange()end
   if not drawn then error(reason,0)end
   M.replayed=M.replayed+1
  end
 end)
 g.pop()
 -- Raw replay must not invalidate the caller's uniform memoization.
 for program in pairs(a.programs)do sendSnapshot(program.native,program.values)end
 if not ok then error(err,0)end
end
local function restoreTarget(c,slot)
 local g=love.graphics;g.push('all')
 local ok,err=pcall(function()
  g.origin();g.setScissor();g.setStencilTest();g.setColorMask(true,true,true,true)
  g.setMeshCullMode('none');g.setWireframe(false)
  g.setColor(1,1,1,1);g.setBlendMode('replace','premultiplied');g.setDepthMode('always',true)
  g.setShader(restoreShader);restoreShader:send('sourceDepth',c.depth)
  g.draw(c.color)
 end)
 g.pop()
 if not ok then M.lastError=tostring(err)end
 return ok
end
-- Render the exact command stream against transparent color. Alpha now records
-- coverage even for a surviving fragment whose depth equals the far plane.
local function capture(a)
 local g=love.graphics;g.push('all')
 local ok,err=pcall(function()
  g.setCanvas({a.cache.color,depthstencil=a.cache.depth})
  g.clear(0,0,0,0,true,true)
  replay(a,a.n)
 end)
 g.pop()
 if not ok then M.lastError=tostring(err)end
 return ok
end
local function allocate(c,slot)
 if c.color then return true end
 local P=V.require('PixelCanvas')
 local ok,color=P.new(slot.w,slot.h)
 if not ok or not color then return false end
 local good,depth=P.new(slot.w,slot.h,{format=slot.depth:getFormat(),readable=true})
 if not good or not depth then release(color);return false end
 color:setFilter('nearest','nearest');depth:setFilter('nearest','nearest')
 if depth.setDepthSampleMode then depth:setDepthSampleMode()end
 c.color,c.depth=color,depth
 return true
end
function M.begin(slot,vp,program)
 if active then M.finish()end
 if not(M.enabled and slot and slot.depth and restoreShader)then return false end
 if M.enabled=='auto'and slot.w*slot.h<M.minimumPixels then return false end
 local c=slot.battleWorldLayer
 if not c then c={commands={},scratch={}};slot.battleWorldLayer=c end
 if c.failed or(M.enabled=='auto'and c.tooSmall)then return false end
 if vp then
  local camera=c.camera or{};local changed=false
  for i=1,16 do if camera[i]~=vp[i]then changed=true;camera[i]=vp[i]end end
  c.camera=camera
  local values=program and program.values
  local sun=values and scalar(values,'sunDark')~=0 and values.sunMap and values.sunMap[1]or nil
  local revision=R.revision(sun)
  local shadowChanged=c.sun~=sun or c.sunRevision~=revision
  c.sun,c.sunRevision=sun,revision
  if changed or shadowChanged then
   c.ready=false
   if #c.commands>0 then c.commands={};c.scratch={}end
   M.movingSkips=(M.movingSkips or 0)+1
   return false
  end
 end
 active={cache=c,slot=slot,previous=c.commands,next=c.scratch,programs={},changes={},n=0,matching=true}
 M.recording=true
 return true
end
function M.finish()
 local a=active;if not a then return false end
 active=nil
 M.recording=false
 local g=love.graphics;g.push('all')
 local ok,result=pcall(function()
  -- A barrier may be observed after another pass has changed its state.
  -- Complete the postponed prefix on its original target, then restore caller.
  g.setCanvas({a.slot.canvas,depthstencil=a.slot.depth})
  local c=a.cache;local same=a.matching and a.n==#a.previous
  if a.matching then
   if same and c.ready then
    if restoreTarget(c,a.slot)then M.hits=M.hits+1;M.savedDraws=(M.savedDraws or 0)+math.max(0,a.n-1)
    else c.ready=false;c.failed=true end
   else
    c.ready=false
    if same and a.n>0 then
     if allocate(c,a.slot)and capture(a)and restoreTarget(c,a.slot)then
      c.ready=true;M.captures=M.captures+1
     else c.failed=true end
    end
   end
   if not c.ready then replay(a,a.n)end
  else c.ready=false;M.misses=M.misses+1 end
  for i=#a.next,a.n+1,-1 do a.next[i]=nil end
  M.lastCommands=a.n
  c.commands,c.scratch=a.next,a.previous
  if M.enabled=='auto'and a.n<M.minimumCommands then
   c.tooSmall=true;c.ready=false;c.commands={};c.scratch={}
  end
  return same and c.ready
 end)
 g.pop()
 if not ok then a.cache.ready=false;error(result,0)end
 return result
end
function M.abort()
 if active then active.cache.ready=false;active.cache.commands={};active.cache.scratch={}end
 active=nil
 M.recording=false
end
-- Called after model uniforms and texture selection, before the real draw.
-- Returning true means this command is postponed until validation finishes.
function M.draw(program,mesh,texture,count)
 local a=active;if not a then return false end
 local g=love.graphics
 local rev,source,sourceRev=R.revision(mesh)
 local texRev=R.revision(texture)
 local cr,cg,cb,ca=g.getColor();local depth,writes=g.getDepthMode();local blend,alpha=g.getBlendMode()
 local stencil=g.getStencilTest();local sx=g.getScissor()
 local target=g.getCanvas();local depthTarget
 if type(target)=='table'then
  depthTarget=target.depthstencil
  if target[2]then M.finish();return false end
  target=target[1]
 end
 if type(target)=='table'then
  if target.mipmap~=1 or target.layer then M.finish();return false end
  target=target[1]
 end
 if type(depthTarget)=='table'then depthTarget=depthTarget[1]end
 local mr,mg,mb,ma=g.getColorMask()
 if not(program and program.values and rev~=nil and texRev~=nil and sourceRev~=nil)
  or ca~=1 or depth~='lequal'or not writes or blend~='alpha'or alpha~='alphamultiply'
  or (stencil~=nil and stencil~='always')or sx~=nil or target~=a.slot.canvas or depthTarget~=a.slot.depth or g.getShader()~=program.native
  or g.getMeshCullMode()~='none'or g.isWireframe()or not(mr and mg and mb and ma)then
  M.lastBarrier='draw-state';M.finish();return false
 end
 local values=program.values
 -- Mutable sampler contents participate even if their object identity holds.
 local dependencies=dependencyScratch
 for k in pairs(dependencies)do dependencies[k]=nil end
 -- The uniform owner records sampler arguments when they change, avoiding a
 -- full walk through scalar/matrix lighting uniforms for every world draw.
 for name in pairs(program.resources or values)do if relevant(name,values)then
  local row=values[name]
  for i=1,row.n do
   local v=row[i]
   if type(v)=='userdata'then
    local revision=R.revision(v)
    if revision==nil then M.lastBarrier=name;M.finish();return false end
    dependencies[v]=revision
   end
  end
 end end
 local index=a.n+1;local old=a.previous[index]
 local first,last=mesh:getDrawRange()
 local same=old and old.program==program and old.mesh==mesh and old.texture==texture and old.count==count
  and old.revision==rev and old.source==source and old.sourceRevision==sourceRev
  and old.textureRevision==texRev and old.first==first and old.last==last
  and old.color[1]==cr and old.color[2]==cg and old.color[3]==cb and old.color[4]==ca
  and equal(old.dependencies,dependencies)
 if same then
  local delta=a.matching and a.lastProgram==program and old.previousProgram==program
  if delta then
   for name in pairs(a.changes)do if gates[name]then delta=false;break end end
   if delta then for name in pairs(old.delta or{})do if gates[name]then delta=false;break end end end
  end
  if delta then
   for name in pairs(a.changes)do
    if relevant(name,values)and not uniformEqual(name,values[name],old.uniforms[name],values)then same=false;break end
   end
   if same then for name in pairs(old.delta or{})do
    if relevant(name,values)and not uniformEqual(name,values[name],old.uniforms[name],values)then same=false;break end
   end end
  else
   for name,row in pairs(values)do if relevant(name,values)and not uniformEqual(name,row,old.uniforms[name],values)then same=false;break end end
   if same then for name in pairs(old.uniforms)do if not values[name]then same=false;break end end end
  end
 end
 a.programs[program]=true
 if a.matching and not same then replay(a,a.n);a.matching=false end
 if same then
  -- The previous receipt is immutable while this command is unchanged. Reuse
  -- its uniform snapshots instead of recursively copying the same vectors.
  a.next[index]=old
 else
  local c=a.next[index]or{};a.next[index]=c
  c.program,c.mesh,c.texture,c.count=program,mesh,texture,count
  c.revision,c.source,c.sourceRevision,c.textureRevision=rev,source,sourceRev,texRev
  c.first,c.last=first,last;c.color=c.color or{};c.color[1],c.color[2],c.color[3],c.color[4]=cr,cg,cb,ca
  c.uniforms=clone(values,c.uniforms);c.dependencies=clone(dependencies,c.dependencies)
 end
 local receipt=a.next[index]
 receipt.delta=clone(a.changes,receipt.delta);receipt.previousProgram=a.lastProgram
 for name in pairs(a.changes)do a.changes[name]=nil end
 a.lastProgram=program
 a.n=index
 return a.matching
end
R.barrier=M.finish
return M
