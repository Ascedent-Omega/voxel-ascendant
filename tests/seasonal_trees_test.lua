local W={clock=0,seasonAt=function(t)return t>=100 and 'winter' or 'summer'end}
local S=assert(loadfile('lib/SeasonalTrees.lua'))({require=function(n)assert(n=='Weather');return W end})
local leaf,wood,light=5,6,7
local source={seasonalFoliage=true,leafColors={[leaf]=true},frameW=16,depth=16,boxes={{6,0,6,4,12,4,wood},{1,12,1,14,14,14,leaf}}}
local P={models={oak=source,fir={boxes=source.boxes}},decorColors={walnut=wood,oak=light}}
assert(S.kind(P,'oak','ROUTE_1',2,4)=='oak','summer sheds leaves')
W.clock=100
assert(S.kind(P,'fir','ROUTE_1',2,4)=='fir','conifer sheds')
local shed,kept=0,0
for x=0,30 do for z=0,30 do
 local kind=S.kind(P,'oak','ROUTE_1',x*2,z*2)
 assert(S.kind(P,'oak','ROUTE_1',x*2,z*2)==kind,'selection flickers')
 if kind=='oak'then kept=kept+1 else
  shed=shed+1
  for _,b in ipairs(P.models[kind].boxes)do
   assert(b[7]~=leaf,'leaves retained on bare tree')
   assert(b[1]>=0 and b[3]>=0 and b[1]+b[4]<=16 and b[3]+b[6]<=16,'branches escape blocked footprint')
  end
  assert(not P.models[kind].blossomSource and not P.models[kind].seasonalFoliage)
 end
end end
assert(shed>800 and kept>30 and kept<160,'most deciduous trees must shed, with stable exceptions')
assert(#source.boxes==2 and source.boxes[2][7]==leaf,'source model mutated')
W.clock=0;assert(S.kind(P,'oak','ROUTE_1',2,4)=='oak','spring does not restore leaves')
print('PASS winter forks, stable majority, evergreen conifers, footprint, spring restoration',shed,kept)
