local M=assert(loadfile('lib/SeviiDoubleVisual.lua'))({})
local layout={map='KA_SEVII_TREASURE',center={x=13,y=22},camera='wide',
  player={{x=12,y=24},{x=14,y=24}},
  enemy={{x=12,y=20},{x=14,y=20}}}
local map={id=layout.map,widthCells=40,heightCells=40,
  def={kaOwner='kasc.sevii-expedition/v1'},
  isWalkableCell=function()return true end}
local state={map=map}
local battle={doubleBattle=true,seviiDoubleArena=layout,
  player={},player2={},enemy={},enemy2={},
  sides={{battlers={}},{battlers={}}}}
battle.sides[1].battlers={battle.player,battle.player2}
battle.sides[2].battlers={battle.enemy,battle.enemy2}
assert(M.layoutFor(state,battle)==layout)
local physical=assert(M.mapArena(map,layout))
assert(physical.doubleBattle and physical.presentationMode=='MAP')
assert(physical.playerSlots[1][1]==12*16+8)
assert(physical.playerSlots[2][1]==14*16+8)
assert(physical.enemySlots[1][2]==20*16+8)
local portable={player={0,48},enemy={0,0},mid={0,24},cam='disk_court'}
assert(M.attach(portable,layout)==portable)
assert(portable.player[1]==0 and portable.player[2]==48)
assert(portable.enemy[1]==0 and portable.enemy[2]==0)
assert(portable.playerSlots[1][1]==-16 and portable.playerSlots[2][1]==16)
assert(portable.enemySlots[1][2]==0 and portable.enemySlots[2][2]==0)
assert(portable.cam=='disk_court','portable camera changed')
battle.sides[1].battlers[2]=nil
assert(not M.layoutFor(state,battle),'missing second native battler accepted')
battle.sides[1].battlers[2]=battle.player2
layout.enemy[2]={x=12,y=20}
assert(not M.layoutFor(state,battle),'duplicate foot accepted')
layout.enemy[2]={x=14,y=20}
layout.enemy[2]={x=99,y=20}
assert(not M.layoutFor(state,battle),'out-of-bounds foot accepted')
layout.enemy[2]={x=14,y=20}
map.def.kaOwner='foreign'
assert(not M.layoutFor(state,battle),'foreign map accepted')
map.def.kaOwner='kasc.sevii-expedition/v1'
layout.map='KA_SEVII_KINDLE';map.id=layout.map
map.isGrassCell=function(_,x,y)return x==13 and y==22 end
assert(not M.layoutFor(state,battle),'grass in the camera apron accepted')
map.isGrassCell=nil
layout.map='KA_SEVII_TREASURE';map.id=layout.map
battle.doubleBattle=false
assert(not M.layoutFor(state,battle),'ordinary single accepted')
local textures={player={},player2={},enemy={},enemy2={}}
local visuals={}
for index,slot in ipairs{'player','player2','enemy','enemy2'}do
  visuals[slot]={hull={index*30,10,20,20},battler=battle[slot]}
end
for _,slot in ipairs{'player','player2','enemy','enemy2'}do
  battle[slot].mon={hp=10}
end
battle.phase='menu'
assert(M.frameReady(visuals,textures,160,144,battle))
textures.enemy2=nil
assert(not M.frameReady(visuals,textures,160,144,battle),
  'missing active partner accepted')
textures.enemy2={}
visuals.enemy2.hull={30,10,20,20}
assert(not M.frameReady(visuals,textures,160,144,battle),
  'overlapping partner accepted')
visuals.enemy2.hull={120,10,20,20}
visuals.enemy2.hull[1]=150
assert(not M.frameReady(visuals,textures,160,144,battle))
print('PASS exact Sevii four-actor stage receipt and single/foreign exclusion')
