-- Shared decoder failures release every allocated GPU object; face cropping
-- preserves the exact capture direction without changing the existing roofs.
local allocated,released=0,0
local failAt
local function resource()
 allocated=allocated+1
 return{release=function()released=released+1 end,setFilter=function()end,setWrap=function()end,getWidth=function()return 16 end,getHeight=function()return 16 end}
end
local requests=0
love={graphics={newImage=function()
 requests=requests+1;if requests==failAt then error('decode failed')end;return resource()
end}}
local mods={Voxel3D={newMesh=function()return resource()end},VoxelItems={palette={1}}}
local C=assert(loadfile('lib/RooftopCache.lua')){path='test',require=function(n)return assert(mods[n])end,mod={read=function()return'near'end}}
C.unpack=function()return{}end
local entry={w=480,h=288};local face=C.faces[1]
local full=C.faceGeometry(entry,face)
assert(full[1][1]==240+2048 and full[1][2]==2088)
local cropped=C.faceGeometry(entry,face,nil,{x=192,y=192,w=384,h=384},{size=768,eyeY=40})
assert(cropped[1][2]==1064 and cropped[1][3]==144-1024)
local meta={path='windows',files={['east-land']={x=0,y=0,w=768,h=768},['west-land']={x=0,y=0,w=768,h=768}}}
for n=1,4 do
 allocated,released,requests=0,0,0;failAt=n
 assert(not C.loadMeta(entry,meta,nil,{size=768,class='silph_exterior'}))
 assert(allocated==released,'GPU object leaked on failed decode '..n)
end
allocated,released,requests=0,0,0;failAt=nil
local near,parts=C.loadMeta(entry,meta,nil,{size=768,class='silph_exterior'})
assert(near and #parts==2)
for _,p in ipairs(parts)do
 assert(p.class=='silph_exterior'and p.bakedWindow and p.ownsTexture and p.bounds)
 p.mesh:release();p.texture:release();p.materialMask:release()
end
assert(allocated==released)
print('PASS window/roof decoder: cube projection, cropped faces, ownership, partial decode cleanup')
allocated,released,requests=0,0,0
C.unpack=function()return{{1}}end
assert(not C.loadMeta(entry,meta,nil,{expectedNear=0}))
assert(allocated==0,'unexpected near data must fail before allocating GPU resources')
print('PASS bitmap near-count guard before GPU allocation')
