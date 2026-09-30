-- A navigation ghost must run before grass; opaque actors must run after it.
-- This executes the scene's cast pass with renderer dependencies recorded.
local root='./'
local calls,glass,seams,room={},false,false,nil
local function mark(name)calls[#calls+1]=name end
local noop=function()end
love={graphics={setColor=function(r,g,b,a)assert(r==1 and g==1 and b==1 and a==1)end}}
local waterLevel,readable=2,true
local depth={depthReadable=function()return readable end,
 roomVisibility=function(v)room=v end,
 glass=function(v)glass=v end,seams=function(v)seams=v end,
 beginGhost=function()mark('ghost-start')end,endGhost=function()mark('ghost-end')end,
 waterline=noop,
}
local hide=false
local modules={
 ScenePrefetchCache=assert(loadfile("lib/ScenePrefetchCache.lua"))(),
 Voxel3D=depth,CanvasPresentation={OS='OS X'},Water={level=function()return waterLevel end},
 VoxelState={isFirstPerson=function()return false end},
 FirstPerson={hidePlayer=function()return hide end},
 PropVisibility={forView=function()return function()return true end end},
 VoxelFurniture={draw=function()mark('furniture')end,drawOpaque=function()assert(not glass and not seams);mark('opaque')end,drawDetails=function()mark('details')end},
 Gen1OverworldStadium={draw=function(p)
  assert(not glass and not seams and room==nil,'actors retain actor shading and unclipped rooms')
  mark(p.isPlayer and 'player' or 'npc');return true
 end},
}
package.preload['src.render.PaletteFX']=function()return {}end
package.preload['src.world.Map']=function()return {}end
local scene=assert(loadfile(root..'lib/VoxelScene.lua')){require=function(n)
 if not modules[n]then modules[n]={}end;return modules[n]
end}
local draw=scene._drawCast
for i=1,100 do
 local name=debug.getupvalue(draw,i);if not name then break end
 if name=='drawGhost'then debug.setupvalue(draw,i,function()mark('ghost')end)end
 if name=='billboardPull'then debug.setupvalue(draw,i,function()return 1 end)end
 if name=='eachFigure'then debug.setupvalue(draw,i,function()mark('figures')end)end
end
local state={map={},currentRoom={}}
local posed={{isPlayer=true},{isPlayer=false}}
local function grass()
 assert(glass and seams and room==state.currentRoom,'grass retains terrain shading and room mask')
 mark('grass')
end
draw(state,posed,noop,{},grass)
assert(table.concat(calls,',')=='furniture,ghost-start,ghost,ghost-end,grass,player,npc,figures')
assert(glass and seams,'terrain shading restored after actors')
calls={};draw(state,posed,noop,nil,nil)
assert(table.concat(calls,',')=='furniture,player,npc,figures','reflections/desktop must not acquire a grass or ghost pass')
hide=true;calls={};draw(state,posed,noop,{},grass)
assert(table.concat(calls,',')=='furniture,grass,npc,figures','first-person hides player/ghost, not grass or NPCs')

local function find(fn,name,seen)
 if type(fn)~='function'then return end;seen=seen or{};if seen[fn]then return end;seen[fn]=true
 for i=1,100 do local k,v=debug.getupvalue(fn,i);if not k then break end;if k==name then return v end end
 for i=1,100 do local k,v=debug.getupvalue(fn,i);if not k then break end;local got=find(v,name,seen);if got then return got end end
end
local prepare=assert(find(scene.render,'prepareOpaqueFurniture'))
hide=false;calls={}
assert(prepare(state,{{}}));assert(room==state.currentRoom and glass and seams)
draw(state,posed,noop,nil,nil,true)
draw(state,posed,noop,{},grass,true)
assert(table.concat(calls,',')=='opaque,details,player,npc,figures,details,ghost-start,ghost,ghost-end,grass,player,npc,figures',table.concat(calls,','))
for _,level in ipairs{0,1}do waterLevel=level;calls={};assert(not prepare(state,{{}}));assert(#calls==0)end
waterLevel=2;readable=false;calls={};assert(not prepare(state,{{}}));assert(#calls==0)
readable=true;assert(not prepare(state,{}));assert(#calls==0)
print('PASS solid scenery once; reflection/visible decorations, actor/ghost/grass ordering; SKY/OFF/depthless/dry bypass')
