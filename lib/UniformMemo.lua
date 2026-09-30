-- Module-owned shader uniforms only. Compare numeric contents so callers
-- may safely reuse/mutate scratch vectors and matrices between draws.
local M={}
function M.new()
 local shaders=setmetatable({},{__mode="k"})
 local C={}
 function C.clear()shaders=setmetatable({},{__mode="k"})end
 function C.send(sh,name,value,layout)
  local slots=shaders[sh]
  if not slots then slots={};shaders[sh]=slots end
  local held=slots[name]
  local vector=type(value)=="table"
  local same=held and held.layout==layout and held.vector==vector
  if same then
   if vector then
    same=held.count==#value
    if same then for i=1,#value do if held.value[i]~=value[i]then same=false;break end end end
   else same=held.value==value end
  end
  if same then return true,false end
  local ok
  if layout then ok=pcall(sh.send,sh,name,layout,value)
  else ok=pcall(sh.send,sh,name,value)end
  if not ok then return false,false end
  held=held or{};slots[name]=held
  if vector then
   if not held.vector then held.value={}end
   for i=1,math.max(#value,held.count or 0)do held.value[i]=value[i]end
   held.count=#value
  else held.value=value;held.count=nil end
  held.vector,held.layout=vector,layout
  return true,true
 end
 return C
end
return M
