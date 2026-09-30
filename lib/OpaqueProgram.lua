-- Private uniform mirror: native shaders remain the public graphics objects.
local M={}
local pairsByShader=setmetatable({},{__mode='k'})
local function same(a,b)
 if type(a)~='table'or type(b)~='table'then return a==b end
 if #a~=#b then return false end
 for i=1,#a do if not same(a[i],b[i])then return false end end
 return true
end
local function copy(value,held)
 if type(value)~='table'then return value end
 held=type(held)=='table'and held or{}
 for i=1,math.max(#held,#value)do held[i]=copy(value[i],held[i])end
 return held
end
function M.source(source)
 -- Remove only the masks covered by worldSafe/shadowSafe. A future kill
 -- condition must acquire its own admission rule before this variant exists.
 local known={
  'if (cutaway.w > 0.5 && dot(vWorld.xz, cutaway.xy) > cutaway.z) discard;',
  'if (vWorld.y < actorWaterline) discard;',
  'if (p.a < 0.5) discard;',
  'if(silphWindow.x>0.0 && !silphThroughWindow(vWorld))discard;',
  'if(roomMaskSize.z<1.5)discard;',
  'if(Texel(roomMask,(floor(roomLocal/8.0)+vec2(0.5))/(roomMaskSize.xy/8.0)).r<0.5)discard;',
  'if (tc.x > -128.5 && Texel(tex, tc).a < 0.5) discard;',
  'if (objectOnly > 0.5 && vObjectCaster < 0.5 && sprite < 0.5) discard;',
 }
 for _,statement in ipairs(known)do
  local pattern=statement:gsub('(%W)','%%%1')
  source=source:gsub(pattern,'{}')
 end
 if source:find('discard%s*;')then return nil,'unclassified fragment discard'end
 return source
end
function M.register(shader,source)
 pairsByShader[shader]={native=shader,source=source,values={},resources={},dirty={},sent={},epoch=0}
end
function M.prepare(shader)
 local p=pairsByShader[shader]
 if not p or p.opaque~=nil then return false end
 local source,reason=M.source(p.source)
 if not source then p.opaque=false;p.source=nil;p.error=reason;return true end
 local ok,value=pcall(love.graphics.newShader,source)
 p.opaque=ok and value or false;p.source=nil
 p.error=not ok and tostring(value)or nil
 return true
end
function M.native(p)return p and p.native or p end
function M.wrap(shader)
 local p=pairsByShader[shader]
 if not p then return shader end
 p.epoch=p.epoch+1
 if not p.send then
  function p:hasUniform(name)return self.native:hasUniform(name)end
  function p:send(name,...)
   local n=select('#',...);local old=self.values[name];local changed=not old or old.n~=n
   if not changed then for i=1,n do if not same(old[i],select(i,...))then changed=true;break end end end
   if changed or self.sent[name]~=self.epoch then
    self.native:send(name,...);self.sent[name]=self.epoch
   end
   if changed then
    old=old or{};for i=1,math.max(n,old.n or 0)do old[i]=copy(select(i,...),old[i])end
    old.n=n;self.values[name]=old;self.dirty[name]=true
    self.resources[name]=nil
    for i=1,n do if type(old[i])=='userdata'then self.resources[name]=true;break end end
    if M.observe then M.observe(self,name)end
   end
  end
 end
 return p
end
function M.value(p,name,index)
 local row=p and p.values and p.values[name];local value=row and row[1]
 if index then return type(value)=='table'and value[index]or nil end
 return value
end
function M.worldSafe(p)
 return p and p.opaque and M.value(p,'cutaway',4)==0
  and M.value(p,'actorWaterline')==-30000 and M.value(p,'roomMaskSize',3)==0
  and M.value(p,'silphWindow',1)==0
end
function M.shadowSafe(p)return p and p.opaque and M.value(p,'objectOnly')==0 end
local function bindOpaque(p)
 for name in pairs(p.dirty)do
  local row=p.values[name]
  if p.opaque:hasUniform(name)then p.opaque:send(name,unpack(row,1,row.n))end
  p.dirty[name]=nil
 end
 love.graphics.setShader(p.opaque)
end
local function reject(p,reason)
 p.error=tostring(reason)
 local shader=p.opaque;p.opaque=false
 love.graphics.setShader(p.native)
 if shader and shader.release then pcall(shader.release,shader)end
end
function M.bind(p)
 if not(p and p.opaque)then return false end
 local ok,reason=pcall(bindOpaque,p)
 if not ok then reject(p,reason)end
 return ok
end
local function drawMesh(mesh,count)
 if count then love.graphics.drawInstanced(mesh,count)else love.graphics.draw(mesh)end
end
function M.draw(p,mesh,count)
 if not M.bind(p)then return false end
 local ok,reason=pcall(drawMesh,mesh,count)
 if not ok then reject(p,reason);return false end
 love.graphics.setShader(p.native)
 return true
end

function M.drawRanges(p,mesh,ranges)
 if not(p and p.opaque and ranges and mesh.getDrawRange and mesh.setDrawRange)then return false end
 if mesh:getDrawRange()~=nil then return false end
 local ok,reason=pcall(function()
  for _,range in ipairs(ranges)do
   mesh:setDrawRange(range.first,range.count)
   if not(range.opaque and M.draw(p,mesh))then
    love.graphics.setShader(p.native);love.graphics.draw(mesh)
   end
  end
 end)
 mesh:setDrawRange();love.graphics.setShader(p.native)
 if not ok then error(reason,0)end
 return true
end

function M.status(shader)return pairsByShader[shader]end
return M
