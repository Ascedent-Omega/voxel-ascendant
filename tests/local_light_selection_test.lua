local M=assert(loadfile('lib/LocalLightGrid.lua'))({})
local sources={}
for i=1,96 do sources[i]={x=(i%12)*19-70,y=i%9,z=math.floor(i/12)*17-60,radius=55+i%5*12,power=i%7*.25}end
for _,limit in ipairs{2,4}do
 local layout=M.layout(sources,limit)
 for z=0,layout.nz-1 do for x=0,layout.nx-1 do
  local left,top=layout.x+x*M.CELL,layout.z+z*M.CELL
  local expected={}
  for id,l in ipairs(sources)do
   local dx=l.x-math.max(left,math.min(left+M.CELL,l.x))
   local dz=l.z-math.max(top,math.min(top+M.CELL,l.z))
   if dx*dx+dz*dz<=l.radius*l.radius then expected[#expected+1]=id end
  end
  if #expected>limit then
   local function score(id)
    local l=sources[id];local d=((l.x-left-M.CELL/2)^2+(l.z-top-M.CELL/2)^2)/(l.radius*l.radius)
    return l.power*math.max(0,1-d)^2/(1+3*d)
   end
   table.sort(expected,function(a,b)local aa,bb=score(a),score(b);return aa==bb and a<b or aa>bb end)
   for i=#expected,limit+1,-1 do expected[i]=nil end
  end
  local actual=layout.cells[z*layout.nx+x+1]or{}
  assert(#actual==#expected,'changed overlap count')
  for i,id in ipairs(expected)do assert(actual[i]==id,'changed strongest-light selection/tie ordering')end
 end end
end
print('PASS bounded light selection: full-sort reference across dense overlap, distances, zero/equal powers and mobile/desktop budgets')
