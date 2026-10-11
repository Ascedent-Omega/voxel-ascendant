local on=true
local N=assert(loadfile('lib/VisibleNeighborhood.lua')){require=function(n)
 assert(n=='ModSetting');return{new=function()return{get=function()return on end}end}
end}
local function map(id,source,x,y)
 return{id=id,def={width=12,height=5,outdoor=true,kaOwner='kasc.sevii-expedition/v1',kaSeviiSource=source,
  connections={},kaSeviiSourceOrigin={x,y}}}
end
local current=map('center','TwoIsland',24,10)
current.def.connections={north={map='north'},south={map='south'},west={map='west'},east={map='east'}}
local state={map=current,neighbors={}}
for _,a in ipairs{{'north',0,-160},{'south',0,160},{'west',-384,0},{'east',384,0},
 {'nw',-384,-160},{'ne',384,-160},{'sw',-384,160},{'se',384,160},
 {'distant',768,0},{'different-source',-384,-160}}do
 state.neighbors[#state.neighbors+1]={map=map(a[1],a[1]=='different-source'and'CapeBrink'or'TwoIsland',0,0),ox=a[2],oy=a[3]}
end
local view=N.apply(state);assert(#view.neighbors==8,'visible source has a missing diagonal body')
local ids=N.requiredIds(view)
for _,id in ipairs{'north','south','west','east','nw','ne','sw','se'}do assert(ids[id],'corner not required for reveal '..id)end
assert(not ids.distant and not ids['different-source'],'unrelated two-hop route made required')
assert(#state.neighbors==10,'native discovery state mutated')
current.def.kaOwner=nil
assert(#N.apply(state).neighbors==4,'Kanto desktop ring changed')
current.def.kaOwner='kasc.sevii-expedition/v1';current.def.outdoor=false
assert(#N.apply(state).neighbors==4,'indoor/cave ring changed')
on=false;assert(N.apply(state)==state,'PC MAP RING OFF preference lost')
print('PASS Sevii outdoor neighborhood: eight touching source bodies, required corners, no distant/foreign routes, unchanged Kanto/interior ring and discovery state')
