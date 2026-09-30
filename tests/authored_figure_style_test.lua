local style,walking='voxel',true
local reads=0
package.loaded['src.render.Assets']={image=function()
 reads=reads+1;return{setFilter=function()end}
end}
local renderer={pushQuad=function()end,newMesh=function()return{release=function()end}end}
local V={mod={path='pack',options={get=function(_,key)
 if key=='apo_human_art_style'then return style end
end},exports={humanDlc={style=function(s)return s end},overworldPokemon={walkingSprites={enabled=function()return walking end}}}},
 require=function(key)assert(key=='Voxel3D');return renderer end}
local M=assert(loadfile('lib/HdAuthoredFigures.lua'))(V)
local figure={hdActor='pokecenter_seated_man',mesh={},wx=10,wz=20,y=6,w=12}
for _,mode in ipairs{'voxel','cobble','native'}do
 style=mode
 assert(not M.enabled(),'HD authored actor leaked into '..mode)
 assert(M.resolve(figure)==figure)
end
assert(reads==0,'pixel styles allocated an HD texture')
style='hd';assert(M.enabled())
local chosen,texture=M.resolve(figure)
assert(chosen~=figure and texture and chosen.hdActor==figure.hdActor)
walking=false;assert(not M.enabled() and M.resolve(figure)==figure)
M.invalidate()
print('PASS seated authored figure respects HD/VOXEL/COBBLE/native style and walking toggle')
