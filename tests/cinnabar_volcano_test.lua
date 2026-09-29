-- Geometry contracts: clear native surf corridor, bounded silhouettes, one world anchor,
-- emissive flowing surface, and a reversible preference with no 2D hook.
local mode='connected'
local modules={ModSetting={new=function(_,_,values,labels,default)
 assert(default=='connected');return{get=function()return mode end}
end},WorldPlacement={position=function(id)
 return ({CINNABAR_ISLAND={x=100,y=900,anchor='kanto'},CELADON_CITY={x=500,y=100,anchor='kanto'},OTHER={x=0,y=0,anchor='other'}})[id]
end},Voxel3D={FACE_CORNERS={{{0,0,0},{1,0,0},{1,1,0},{0,1,0}},{{0,0,1},{0,1,1},{1,1,1},{1,0,1}},{{0,1,0},{1,1,0},{1,1,1},{0,1,1}},{{0,0,0},{0,0,1},{1,0,1},{1,0,0}},{{0,0,0},{0,1,0},{0,1,1},{0,0,1}},{{1,0,0},{1,0,1},{1,1,1},{1,1,0}}},newMesh=function(v,i)return{vertices=v,indices=i}end}}
local function noop()end
love={image={newImageData=function()return{setPixel=noop,release=noop}end},graphics={newImage=function()return{setFilter=noop,release=noop}end}}
package.loaded['src.render.Assets']={register=noop}
local M=assert(loadfile('lib/CinnabarVolcano.lua')){require=function(name)return assert(modules[name],name)end}
assert(M.active());assert(M.draw2D==nil and M.install==nil,'Vanilla must stay untouched')
local coast=false
M.geometry(function(x,y,z,w,h,d,c)
 assert(w>0 and h>0 and d>0 and M.colors[c]);assert(x+w<=-48,'scenery covers native surf corridor');if c=='ash' then coast=true end
end)
assert(coast,'volcanic coast absent')
local x,z=M.position('CELADON_CITY',{});assert(x==-400 and z==800)
assert(M.position('OTHER',{})==nil,'cross-world landmark')
local root={{map={id='CINNABAR_ISLAND'},ox=16,oy=32}}
local count=0;M.world(root,{},function()count=count+1 end);assert(count>0)
mode='classic';M.world(root,{},function()error('connected landmark emitted in classic mode')end)
mode='connected'
local meshes=M.meshes(16,32,-100);assert(#meshes==2 and meshes[2].magma and not meshes[1].magma)
for _,rim in ipairs(meshes)do
 assert(#rim.mesh.vertices<40000,'unbounded mesh budget')
 for _,v in ipairs(rim.mesh.vertices)do
  for k=1,3 do assert(v[k]==v[k]and math.abs(v[k])<10000,'invalid coordinate')end
  assert(v[1]>=rim.bounds[1]and v[1]<=rim.bounds[4]and v[2]>=rim.bounds[2]and v[2]<=rim.bounds[5]
   and v[3]>=rim.bounds[3]and v[3]<=rim.bounds[6],'culling bounds clip the volcano')
 end
end
-- Lava ribbons have short contiguous edges along the slope, never the old
-- repeated 30px vertical/horizontal box pairs.
local lava=meshes[2].mesh.vertices
local ribbons=0
for i=1,#lava,4 do
 local a,b=lava[i],lava[i+1]
 if a[2]<480 and b[2]<480 then
  local d=math.sqrt((a[1]-b[1])^2+(a[2]-b[2])^2+(a[3]-b[3])^2)
  assert(d<25,'discontinuous lava segment');ribbons=ribbons+1
 end
end
assert(ribbons>100)
print('PASS clear native surf corridor and varied ash coast, anchored distant view, default/rollback, bounded meshes, continuous magma and untouched Vanilla')
