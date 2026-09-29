-- Actual desktop volume shader: distant air follows the bent ground, not a
-- flat box at y=0. Also verify scene-depth occlusion and curve OFF.
local root=assert(arg[1]);local world={curveX=0,curveZ=0,curveK=.0002}
local modules={Voxel3D=world,LocalLights={active=function()return false end},Sky={clock=7}}
local M=assert(loadfile(root..'/lib/IndoorMist.lua')){require=function(n)return assert(modules[n],n)end}
M.profile=function()return{height=48,density=.04,color={1,1,1},region={-200,800,200,1200}}end
local g=love.graphics;local target=g.newCanvas(128,240,{dpiscale=1,format='rgba16f'})
local data=love.image.newImageData(1,1);data:setPixel(0,0,1,1,1,1);local depth=g.newImage(data);data:release()
-- x: -128..128, y: -360..120, z: 700..1300.
local vp={1/128,0,0,0, 0,1/240,0,.5, 0,0,1/300,-10/3, 0,0,0,1}
local map={id='MIST_TEST',def={width=4,height=4}}
local function render(k)
 world.curveK=k;g.setCanvas(target);g.clear(0,0,0,1);g.setCanvas()
 assert(M.draw(map,false,target,depth,vp));assert(M.last.samples==12)
 return target:newImageData()
end
local function sample(im,y)
 -- LÖVE canvas render targets invert projected NDC Y on desktop.
 -- Resolve that convention once from the known flat fog band.
 return im:getPixel(64,y)
end
local flat=render(0);local sumLo,sumHi=0,0
for y=24,55 do sumLo=sumLo+sample(flat,y)end
for y=184,215 do sumHi=sumHi+sample(flat,y)end
local flipped=sumLo>sumHi
local function row(worldY)
 local ndc=worldY/240+.5
 return math.max(0,math.min(239,math.floor((flipped and (1-ndc)or(1+ndc))*120)))
end
local floatingRow=row(24);assert(sample(flat,floatingRow)>.05,'flat control did not render')
local bent=render(.0002);assert(sample(bent,floatingRow)<.001,'distant fog still floats at unbent height')
local attached=0;for y=-240,-130,4 do if sample(bent,row(y))>.02 then attached=attached+1 end end
assert(attached>15,'curved mist vanished instead of following the ground')
-- An opaque depth in front of the region must stop all fog along that ray.
local d=love.image.newImageData(1,1);d:setPixel(0,0,.1,.1,.1,1);depth:release();depth=g.newImage(d);d:release()
local hidden=render(.0002)
for y=0,239 do assert(sample(hidden,y)<.001,'fog rendered in front of an occluding surface')end
flat:release();bent:release();hidden:release();target:release();depth:release();M.invalidate()
print('PASS curved desktop mist: no floating far band; ground-following air; depth occlusion; flat control; twelve samples',attached)
