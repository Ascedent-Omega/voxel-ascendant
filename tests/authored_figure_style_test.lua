local style,walking,time='voxel',true,0
local reads,meshes,released=0,0,0
local paths={}
package.loaded['src.render.Assets']={image=function(path)
 reads=reads+1;paths[#paths+1]=path;return{setFilter=function()end}
end}
love={timer={getTime=function()return time end}}
local renderer={pushQuad=function()end,newMesh=function(rows)
 meshes=meshes+1;return{rows=rows,release=function()released=released+1 end}
end}
local V={mod={path='pack',options={get=function(_,key)
 if key=='apo_human_art_style'then return style end
end},exports={humanDlc={style=function(s)return s end},overworldPokemon={walkingSprites={enabled=function()return walking end}}}},
 require=function(key)assert(key=='Voxel3D');return renderer end}
local M=assert(loadfile('lib/HdAuthoredFigures.lua'))(V)
local figure={hdActor='pokecenter_seated_man',mesh={},wx=10,wz=20,y=8,w=12}
walking=false
for _,mode in ipairs{'voxel','cobble','hd','native'}do
 style=mode;assert(M.style()=='native'and not M.enabled());assert(M.resolve(figure)==figure)
end
assert(reads==0 and meshes==0,'OFF allocated artwork')
walking=true
local textures={}
for _,mode in ipairs{'voxel','cobble','hd'}do
 style=mode;assert(M.style()==mode and M.enabled())
 local chosen,texture=M.resolve(figure)
 assert(chosen~=figure and texture and chosen.y==3.5 and chosen.hdActor==figure.hdActor)
 assert(math.abs(chosen.wx+chosen.w/2-16)<.0001 and chosen.wz==20,'bench anchor changed')
 assert(chosen.mesh.rows[3][2]==20,'seated height changed')
 assert(not textures[texture],'presentation reused wrong texture');textures[texture]=true
 local again=M.resolve(figure);assert(again.mesh==chosen.mesh)
end
assert(reads==3 and meshes==6)
assert(paths[1]:match('voxel%-v1')and paths[2]:match('cobble/sitting')and paths[3]:match('hd%-v1'))
style='cobble';local open=M.resolve(figure);time=2.8;local closed=M.resolve(figure)
assert(open.mesh~=closed.mesh and open.wx==closed.wx and open.y==closed.y,'blink moved sitter')
style='native';assert(M.resolve(figure)==figure)
M.invalidate();assert(released==6)
walking=false;M.resolve(figure);assert(reads==3)
walking=true;style='cobble';package.loaded['src.render.Assets'].image=function()reads=reads+1;error('missing')end
assert(M.resolve(figure)==figure);assert(M.resolve(figure)==figure);assert(reads==4,'failed artwork retried every frame')
M.invalidate()
print('PASS authored sitter: separate Voxel/HD/Cobble sprites, fixed seat, cached blink, OFF and failure fallback')
