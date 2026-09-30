local function load(path,V)return assert(loadfile(path))(V)end
local settings={}
local Setting={new=function(key,_,values,_,default)
 local s={value=default or values[1]};function s:get()return self.value end
 settings[key]=s;return s
end}
local AA=load('lib/AntiAlias.lua',{require=function(n)
 if n=='ModSetting'then return Setting end
 if n=='CanvasPresentation'then return{OS='Linux'}end
 if n=='FrameBudget'then return{scale=.75}end
 error(n)
end})
local original=love
love={graphics={getSystemLimits=function()return{texturesize=8192}end}}
settings.aa.value=4
for _,case in ipairs{{'scale50',480,320},{'scale75',720,480},{'native',1920,1280}}do
 settings.sceneResolution.value=case[1];local w,h=AA.expand(960,640)
 assert(w==case[2]and h==case[3],'manual render scale/AA contract')
end
-- Empty maps touch no render state. Legacy providers stay live; versioned
-- providers cache until their revision changes, and built-in in-place edits show.
local matrices,draws,states={},0,0
package.loaded['src.render.Assets']={register=function()end,image=function()
 return {getDimensions=function()return 8,8 end}
end}
local M=load('lib/Mat4.lua')
local V={require=function(n)
 if n=='Mat4' then return M end
 if n=='Voxel3D'then return{newMesh=function()return{}end,pushQuad=function()end,
 glass=function()states=states+1 end,seams=function()states=states+1 end,
 draw=function(_,_,m)draws=draws+1;matrices[#matrices+1]={m[4],m[8],m[12]}end}end
 error(n)
end}
local D=load('lib/WallDecals.lua',V);local map={def={}}
for i=1,200 do assert(D.draw(map)==0)end;assert(states==0)
local record={image='test',cellX=1,cellY=2,face='east',offsetX=3}
map.def.wallDecals={record};assert(D.draw(map)==1);assert(matrices[#matrices][1]==16 and matrices[#matrices][3]==35)
record.cellX=4;assert(D.draw(map)==1);assert(matrices[#matrices][1]==64)
local calls=0;D.register('live',function()calls=calls+1;return{}end)
D.draw(map);D.draw(map);assert(calls==2,'legacy provider frozen')
D.unregister('live');local versioned={revision=1,records=function()calls=calls+1;return{}end}
D.register('versioned',versioned);D.draw(map);D.draw(map);assert(calls==3)
versioned.revision=2;D.draw(map);assert(calls==4);D.invalidate(map);D.draw(map);assert(calls==5)
D.unregister('versioned');map.def.wallDecals=nil;local before=states;assert(D.draw(map)==0 and states==before)
love=original
print('PASS fixed 50/75 percent resolution, AA exclusion, empty decal early-out, live/revision providers and in-place decal edits')
