local V={}
local B=assert(loadfile('lib/BlaineVolcano.lua'))(V)
local mods={BlaineVolcano=B,VoxelBattleStage={arena=function(map)return{map=map,mid={0,0}}end}}
V.require=function(n)return assert(mods[n],n)end
local H=assert(loadfile('lib/TerarriumHost.lua'))(V)
local seen
H.service={setup=function(map)seen=map;return{actors={player={-10,0,0},enemy={10,0,0}}}end}
local map={id='KA_BLAINE_VOLCANO_GYM',def={generation=1,kaOwner='kasc.blaine-volcano-route/v1',tileset='KA_BLAINE_VOLCANO_ARENA',width=24,height=18,
 kaArenaGeometry={kind='suspended-over-lava',version=2,platform={x=16,y=10,width=18,height=12},bridge={x=24,y=22,width=2,height=8}}}}
assert(H.stage(map).map==map and seen.id=='CINNABAR_GYM','new route did not use Blaine court')
assert(map.id=='KA_BLAINE_VOLCANO_GYM','actual battle identity mutated')
map.def.kaOwner=nil;H.stage(map);assert(seen==map,'foreign map changed')
map.id='PEWTER_GYM';H.stage(map);assert(seen==map,'other gym changed')
print('PASS exact Blaine presentation alias and unchanged battle/map ownership')
