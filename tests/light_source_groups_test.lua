-- Boundary/ownership contract for the optimized facade grouping hot path.
local G=assert(loadfile('lib/LocalLightGrid.lua'))({})
local a={lo={0,0,0},hi={1,1,1}}
local b={lo={0,0,0},hi={1,1,1}}
local function light(x,owner,normal,kind,power)
 return {x=x,y=0,z=0,owner=owner,normal=normal or {0,0,1},kind=kind or 'window',radius=10,power=power or 1}
end
local torch=light(-1,a,nil,'torch')
local unowned=light(-1,{})
local sources={light(-1,a),light(-31,a,nil,nil,2),light(0,a),light(-1,b),
 light(-1,a,{0,0,-1}),light(-1,a,{.5,0,.5}),torch,unowned}
local out=G.sources(sources)
assert(#out==7 and out[1].count==2 and out[1].x==-16 and out[1].radius==25 and out[1].power==2)
assert(out[2].x==0 and out[2].owner==a,'crossed a world-cell boundary')
assert(out[3].owner==b,'merged distinct buildings with equal bounds')
assert(out[4].normal[3]==-1 and out[5].normal[1]==.5,'merged facade normals')
assert(out[6]==torch and out[7]==unowned,'changed ungrouped source identity')
assert(sources[1].x==-1 and sources[2].x==-31,'mutated input panes')
print('PASS facade grouping: signed cells, radius, power, owners, normals, non-window identity and immutable inputs')
