local noop=setmetatable({register=function()end},{__call=function()end})
local resolved=0
local P={models={},setting={get=function()return true end},resolveKind=function(k)resolved=resolved+1;return k,'texture'end}
local mods={VoxelItems=P,Voxel3D={},Mat4=assert(loadfile('lib/Mat4.lua'))(),BuildBudget={},
 SeasonalTrees={winter=function()return false end,kind=function(_,kind)return kind end},
 LedgeElevation={map=function()return {at=function()return 7 end}end},Gen1Harbor={kind=function()end,each=function()end}}
package.loaded['src.render.Assets']={register=function()end}
local F=assert(loadfile('lib/VoxelFurniture.lua'))({require=function(n)return mods[n]or noop end})
local glow,visible=.8,true
P.models.house={terrain=true,glassKind='pane',glassVisible=function()return visible end,windowLight=function()return glow end,cutawayKind='cut'}
P.models.cut={terrain=true,glassKind='pane',windowLight=function()return glow end}
P.models.pane={};P.models.tree={};P.models.torch={lightSource={power=1}}
local function prop(kind,x)return{kind=kind,tx=x,ty=2,w=4,h=4,claimed=true}end
local a,b={id='A'},{id='B'}
local props={[a]={prop('house',1),prop('tree',8),prop('torch',10)},[b]={prop('house',5)}}
props[a][3].terrainDecoration=true;props[a][3].decorPlacement={kind='torch',base=13}
F.find=function(map)return props[map]end
local function collect(state,fast)
 local out={};local function draw(_,_,mat,_,extra)
  out[#out+1]={model=extra.lightModel,glow=extra.glow,x=mat[4],y=mat[8],z=mat[12]}
 end
 if fast then F.eachWorldLights(state,draw)else F.eachWorld(state,draw,true)end
 return out
end
local function compare(state)
 F.beginFrame();local expected=collect(state,false)
 local before=resolved;local actual=collect(state,true);assert(resolved==before,'lighting resolves GPU resources')
 assert(#actual==#expected,'count mismatch')
 for i,row in ipairs(expected)do for k,v in pairs(row)do assert(actual[i][k]==v,'descriptor mismatch '..k)end end
 return actual
end
local state={map=a,neighbors={{map=b,ox=32,oy=64},{map=b,ox=32,oy=64}}}
assert(#compare(state)==3)
glow=.25;compare(state)
visible=false;assert(#compare(state)==1)
visible=true;props[a][1].claimed=false;compare(state)
props[a][1].claimed=true;props[b][1].enabled=function()return false end;compare(state)
props[b][1].enabled=nil;state.landmarkCutaway=true;compare(state)
state.landmarkCutaway=nil;state.neighbors[1].ox=128;compare(state)
-- New lighting descriptors never install GPU placeholders in render extras.
for _,list in pairs(props)do for _,p in ipairs(list)do if p.drawExtra then assert(p.drawExtra.mesh~=true)end end end
local sight={map=a,sightFurniture={{mat=mods.Mat4.translate(3,4,5),shade=.9,extra={lightModel=P.models.torch,glow=1}}},neighbors={{map=b}}}
assert(#compare(sight)==1)
print('PASS light descriptors: transforms, elevation, decorations, claims, visibility, live glow, cutaway, duplicate neighbors, sight capture; zero GPU resolves')
