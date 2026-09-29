local modules={Mat4=assert(loadfile('lib/Mat4.lua'))(),Voxel3D={},DayNight={},CompactBackgroundAssets={},
 BattleArena={at=function()return{player={280,328},enemy={280,280},mid={280,304}}end},
 BattleBillboard={yawToward=function()return 0 end,matrix=function(...)return{...}end}}
local calls={}
modules.Voxel3D.seams=function()end;modules.Voxel3D.glass=function()end
modules.Voxel3D.draw=function(_,_,matrix)calls[#calls+1]=matrix end
local views={}
local api={schema='ascendant.battle-heroes/v1',preparePresentation=function(_,side,view)
 views[#views+1]={side,view};return true end}
local V={require=function(k)return assert(modules[k],k)end,
 mod={find=function()end,exports={battleHeroes=api}}}
local stage=assert(loadfile('lib/VoxelBattleStage.lua'))(V)
local bridge=assert(loadfile('lib/BattleHeroesBridge.lua'))(V)
local arena=stage.arena({});assert(arena.diskCourt and arena.cam=='disk_court')
assert(not stage.arena({},'arena').diskCourt,'other stages must keep their placement')
stage.mesh=function()return{}end;stage.textureFor=function()return{}end
stage.draw(arena,0);assert(#calls==2)
for _,m in ipairs(calls)do assert(m[1]==18 and m[11]==18,'trainer space enlarged a Pokemon disk')end
local casts={};stage.cast({draw=function(_,_,m)casts[#casts+1]=m end},arena,0)
for i,m in ipairs(casts)do for j,v in ipairs(m)do assert(v==calls[i][j],'shadow disk size differs')end end
local tex={battleHeroes={player={canvas={},width=16,height=18},enemy={canvas={},width=12,height=18}}}
local layout={player={280,0,328},enemy={280,0,280},actorScale={player=3,enemy=.5}}
local positions
for _,eye in ipairs{{400,80,304},{280,80,500},{280,80,100}}do
 local cards={};bridge.append(cards,tex,layout,eye,nil,arena)
 assert(#cards==2);local feet={cards[1].shadowFoot,cards[2].shadowFoot}
 if positions then for i,p in ipairs(feet)do for j,v in ipairs(p)do assert(v==positions[i][j],'trainer followed camera')end end end
 positions=feet
 local distances={}
 for i,side in ipairs{'player','enemy'}do
  local p=layout[side];local foot=feet[i]
  assert((foot[3]-p[3])*(side=='player' and 1 or -1)>18,'trainer not behind own disk')
  distances[i]=(foot[1]-p[1])^2+(foot[3]-p[3])^2
 end
 assert(distances[1]==distances[2],'trainer spacing depends on species scale')
end
for _,side in ipairs{'player','enemy'}do for _,view in ipairs{'side','front','back'}do
 assert(bridge.prepare({},side,arena,view));assert(views[#views][2]==view)
end end
print('PASS original disk/shadow dimensions; symmetric trainers behind disks; camera/species-independent spacing; directional preparation')
local pads={{side='playerHero',shadowFoot={292,0,356}},{side='enemyHero',shadowFoot={268,0,252}}}
calls={};stage.draw(arena,0,pads);assert(#calls==4)
assert(calls[1][1]==18 and calls[2][1]==18,'main disks resized for trainer pads')
for i=3,4 do assert(calls[i][1]==6 and calls[i][11]==6);assert(calls[i][4]==pads[i-2].shadowFoot[1] and calls[i][12]==pads[i-2].shadowFoot[3])end
casts={};stage.cast({draw=function(_,_,m)casts[#casts+1]=m end},arena,0,pads)
for i,m in ipairs(casts)do for j,v in ipairs(m)do assert(v==calls[i][j])end end
calls={};stage.draw(arena,0,{pads[1]});assert(#calls==3,'wild encounter added an absent trainer pad')
print('PASS small trainer disks match foot/shadow positions; wild encounters omit absent enemy pad')
