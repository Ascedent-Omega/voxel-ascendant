-- Reusable companion canvas must be copied without inherited GPU state.
local M=assert(loadfile('lib/SeviiCanvasCopy.lua'))()
local state={canvas='caller',shader='heat',scissor={4,5,30,20},
  blend='alpha',alpha='alphamultiply',transform='rotated',color={.2,.3,.4,.5}}
local stack={}
local fail=false
local draws=0
local g={}
function g.getCanvas()return state.canvas end
function g.setCanvas(canvas)state.canvas=canvas end
function g.push(kind)
  assert(kind=='all')
  local snapshot={}
  for k,v in pairs(state)do snapshot[k]=v end
  stack[#stack+1]=snapshot
end
function g.pop()state=assert(table.remove(stack))end
function g.origin()state.transform='origin'end
function g.setShader(value)state.shader=value end
function g.setScissor(...)state.scissor=select('#',...)>0 and {...}or nil end
function g.setBlendMode(blend,alpha)state.blend=blend;state.alpha=alpha end
function g.setColor(...)state.color={...}end
function g.clear()assert(state.canvas=='partner')end
function g.draw(source,x,y)
  assert(source=='shared' and x==0 and y==0)
  assert(state.canvas=='partner' and state.shader==nil
    and state.scissor==nil and state.transform=='origin'
    and state.blend=='replace' and state.alpha=='premultiplied')
  draws=draws+1
  if fail then error('simulated GPU error')end
end
local function retained()
  assert(state.canvas=='caller' and state.shader=='heat'
    and state.scissor[1]==4 and state.transform=='rotated'
    and state.blend=='alpha' and state.alpha=='alphamultiply'
    and state.color[1]==.2 and #stack==0)
end
assert(M.copy(g,'shared','partner')=='partner')
retained()
fail=true
local ok,err=pcall(M.copy,g,'shared','partner')
assert(not ok and tostring(err):find('simulated GPU error',1,true))
retained()
assert(draws==2)
print('PASS Sevii partner canvas isolates GPU state and restores on error')
