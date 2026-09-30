local active,items=true,true
package.loaded['src.render.Assets']={register=function()end}
package.loaded['src.render.Pipelines']={worldPipeline=function()return active and 'voxel'or'vanilla'end}
local profiles=assert(loadfile('lib/Gen1InteriorPanoramas.lua'))()
local V={require=function(n)
 if n=='GateDoors'then return assert(loadfile('lib/GateDoors.lua'))()end
 if n=='Gen1InteriorPanoramas'then return profiles end
 if n=='Gen1GymInteriors'then return assert(loadfile('lib/Gen1GymInteriors.lua'))()end
 if n=='VoxelState'then return{active=function()return active end}end
 if n=='VoxelItems'then return{setting={get=function()return items end}}end
 error(n)
end}
local M=assert(loadfile('lib/Gen1GlassDoors.lua'))(V)
local native,sounds=0,0
local Sound={play=function(_,name)native=native+1;return name,nil,'native'end}
local original=Sound.play;package.loaded['src.core.Sound']=Sound
local OW={startWarpTo=function(self,dest)
 Sound.play({},'Confirm')
 Sound.play({},'Go_Outside')
 if self.fail then error(self.fail)end
 return dest,nil,'done'
end};package.loaded['src.world.OverworldController']=OW
local map={id='VIRIDIAN_POKECENTER',def={tileset='POKECENTER',width=7,height=4}}
local ow=setmetatable({map=map,player={px=40,py=40},doorWarp=true},{__index=OW})
local game={overworld=ow,save={options={sfxVol=7}},stack={top=function()return ow end}}
package.loaded['src.core.Game']=game
local source={stop=function()end,setVolume=function(self,v)self.volume=v end,setPitch=function()end,play=function()sounds=sounds+1 end}
M.source=source
assert(M.interior(map,'LAST_MAP')and M.interior(map,'VIRIDIAN_CITY'))
assert(not M.interior(map,'CELADON_CITY')and not M.interior(map,'VIRIDIAN_POKECENTER_2F'))
map.def.width=8;assert(not M.interior(map,'LAST_MAP'));map.def.width=7
map.def.generation=2;assert(not M.interior(map,'LAST_MAP'));map.def.generation=nil
assert(M.transition({id='VIRIDIAN_CITY',def={tileset='OVERWORLD'}},'VIRIDIAN_POKECENTER'))
assert(not M.transition({id='VIRIDIAN_CITY',def={tileset='OVERWORLD'}},'VIRIDIAN_NICKNAME_HOUSE'))
M.install();local installed=OW.startWarpTo;M.install();assert(OW.startWarpTo==installed)
local a,b,c=ow:startWarpTo('VIRIDIAN_CITY');assert(a=='VIRIDIAN_CITY'and b==nil and c=='done')
assert(native==1 and sounds==1 and Sound.play==original)
M.clock=1;active=false;ow:startWarpTo('VIRIDIAN_CITY');assert(native==3 and sounds==1);active=true
items=false;ow:startWarpTo('VIRIDIAN_CITY');assert(native==5 and sounds==1);items=true
ow.doorWarp=false;ow:startWarpTo('VIRIDIAN_CITY');assert(native==7 and sounds==1);ow.doorWarp=true
ow:startWarpTo('SILPH_CO_ELEVATOR');assert(native==9 and sounds==1)
local fault={};ow.fail=fault;local ok,err=pcall(ow.startWarpTo,ow,'VIRIDIAN_CITY');assert(not ok and err==fault and Sound.play==original);ow.fail=nil
M.clock=2;M.source=nil;M.failed=true;ow:startWarpTo('VIRIDIAN_CITY');assert(native==12,'failed audio must retain native cue');M.source=source
M.clock=3;game.save.options.sfxVol=0;ow:startWarpTo('VIRIDIAN_CITY');assert(native==13,'muted cue must not fall back');game.save.options.sfxVol=7
M.update(1/60,game)
local left={mapId=map.id,edge='south',at=64,center=48,width=32,travel=16,horizontal=true,sign=-1}
local right={};for k,v in pairs(left)do right[k]=v end;right.sign=1
assert(M.offset(left)==0)
for i=1,30 do M.update(1/60,game)end
local lx,lz=M.offset(left);local rx,rz=M.offset(right)
assert(lx==-16 and rx==16 and lz==0 and rz==0,'two leaves must part symmetrically')
local count=sounds;for i=1,60 do M.update(1/60,game);M.offset(left)end;assert(sounds==count,'idle door repeated sound')
ow:startWarpTo('VIRIDIAN_CITY');assert(sounds==count,'already opened door repeated sound during native warp')
ow.player.py=-40;for i=1,30 do M.update(1/60,game)end;assert(M.offset(left)==0,'door did not close')
active=false;M.update(1/60,game);assert(next(M.states)==nil and M.offset(left)==0)
print('PASS glass doors: native warp arity/error/reload, 2D/items/stair/house guards, audio failure/mute, reversible pane motion and no repeated idle sounds')
local P={models={},decorColors={silver=4,silphGlass=7},resolveKind=function(k)return k~='missing'and k end}
local model={frameW=64,frameH=100,depth=64,offsetY=-36}
assert(not M.addExterior(P,model,'house',{dest='REDS_HOUSE_1F'},64,64))
for _,side in ipairs{'south','north','west','east'}do
 assert(M.addExterior(P,model,'shop',{side=side,at=32,width=14,dest='VIRIDIAN_MART'},64,64))
end
assert(#model.slidingDoors==8 and M.prepareExterior(P,model))
for i,leaf in ipairs(model.slidingDoors)do
 assert(leaf.horizontal==(i<=4));assert(leaf.sign==(i%2==1 and -1 or 1))
 local boxes=P.models[leaf.kind].boxes;assert(#boxes==2 and #P.models[leaf.glassKind].boxes==4)
 for _,b in ipairs(boxes)do assert(b[4]>0 and b[5]>0 and b[6]>0)end
end
model.slidingDoors[1].kind='missing';assert(not M.prepareExterior(P,model),'partial geometry should retain native facade')
print('PASS exterior four bearings, modern-building scope, paired leaves and atomic resource preparation')
local allocated,uploads,draws=0,0,0
local resources={};local paths={};local uploaded
package.loaded['src.render.Assets']={register=function(fn)resources[#resources+1]=fn end}
local previewV={path='testmod',require=function(n)
 if n=='GateDoors'then return assert(loadfile('lib/GateDoors.lua'))()end
 if n=='CompactBackgroundAssets'then return {newImage=function(path)
  paths[#paths+1]=path;allocated=allocated+1
  return {setFilter=function()end,setWrap=function()end,release=function()allocated=allocated-1 end}
 end}end
 if n=='Voxel3D'then return {newMesh=function(vertices,indices)
  uploads=uploads+1;uploaded=vertices
  return {release=function()uploads=uploads-1 end}
 end}end
 if n=='DayNight'then return{tint=function()return {.3,.4,.5}end}end
 error(n)
end}
local Views=assert(loadfile('lib/Gen1GlassDoors.lua'))(previewV)
local building={frameW=64,frameH=100,depth=64,offsetY=-36}
Views.addExterior(P,building,'preview',{side='south',at=32,width=14,dest='VIRIDIAN_MART'},64,64)
assert(Views.prepareExterior(P,building));assert(allocated==1 and uploads==1)
assert(paths[1]=='testmod/assets/doors/VIRIDIAN_MART-in.png')
assert(uploaded[1][4]>0 and uploaded[2][4]<1,'narrow door stretched the 4:3 picture')
Views.prepareExterior(P,building);assert(allocated==1 and uploads==1,'static view was rebuilt')
local tint,cleared
Views.drawView({drawTint=function(t)tint=t or tint;cleared=t==nil end,draw=function()draws=draws+1 end},{},{},{},true)
assert(draws==1 and tint[1]==.3 and cleared,'outdoor picture tint leaked')
for _,cleanup in ipairs(resources)do cleanup()end
assert(allocated==0 and uploads==0,'preview resources leaked on unload')
print('PASS doorway views: exact destination asset, cropped narrow aperture, retained texture/mesh, day tint restoration and resource cleanup')

local maps={
 VIRIDIAN_CITY={tileset='OVERWORLD',warps={{destMap='VIRIDIAN_NICKNAME_HOUSE'},{destMap='VIRIDIAN_SCHOOL_HOUSE'}}},
 PALLET_TOWN={tileset='OVERWORLD',warps={{destMap='REDS_HOUSE_1F'}}},
 ROUTE_7={tileset='OVERWORLD',warps={{destMap='ROUTE_7_GATE'}}},
 SAFFRON_CITY={tileset='OVERWORLD',warps={{destMap='ROUTE_7_GATE'}}},
 CELADON_MART_ROOF={tileset='OVERWORLD',warps={{destMap='CELADON_MART_5F'}}},
}
for _,id in ipairs{'VIRIDIAN_NICKNAME_HOUSE','VIRIDIAN_SCHOOL_HOUSE','REDS_HOUSE_1F','ROUTE_7_GATE','CELADON_MART_5F'}do
 local p=assert(profiles.profiles[id],id);maps[id]={tileset=p.tileset,width=p.width,height=p.height}
end
game.data={maps=maps};M.configure(game.data)
assert(not M.interior({id='VIRIDIAN_NICKNAME_HOUSE',def=maps.VIRIDIAN_NICKNAME_HOUSE},'LAST_MAP'))
assert(M.wooden({id='VIRIDIAN_NICKNAME_HOUSE',def=maps.VIRIDIAN_NICKNAME_HOUSE},'LAST_MAP'))
assert(M.wooden({id='REDS_HOUSE_1F',def=maps.REDS_HOUSE_1F},'LAST_MAP'))
assert(not M.interior({id='REDS_HOUSE_1F',def=maps.REDS_HOUSE_1F},'LAST_MAP'))
local gate={id='ROUTE_7_GATE',def=maps.ROUTE_7_GATE}
assert(M.interior(gate,'ROUTE_7')and M.interior(gate,'SAFFRON_CITY'))
assert(not M.entrances.CELADON_MART_5F,'roof stair was treated as a glass facade')
assert(M.outViewKey(gate,{destMap='ROUTE_7',destWarp=1})~=M.outViewKey(gate,{destMap='SAFFRON_CITY',destWarp=1}))
assert(M.inViewKey('ROUTE_7_GATE',1)~=M.inViewKey('ROUTE_7_GATE',3))
local buildings=assert(loadfile('lib/Gen1KantoBuildings.lua')){require=function(n)
 if n=='GateDoors'then return assert(loadfile('lib/GateDoors.lua'))()end
 if n=='Gen1PalletVillage'then return{}end;error(n)
end}
local ds=buildings.doors({def={tileset='OVERWORLD',warps={{x=3,y=3,destMap='ROUTE_7_GATE',destWarp=1},{x=4,y=3,destMap='ROUTE_7_GATE',destWarp=2}}}},0,0,16,8)
assert(#ds==1 and ds[1].width==30 and ds[1].at==64 and ds[1].destWarp==1,'paired gate cells must be one double door')
M.map=map;M.states={};assert(not M.viewVisible(left));M.states[left.stateKey].amount=.5;assert(M.viewVisible(left))
print('PASS Viridian and Pallet single wood, reciprocal gate sides, roof exclusion, distinct pictures, joined gate doors and occluded-preview suppression')

assert(M.outViewKey({id='ROUTE_22_GATE'},{destMap='LAST_MAP',destWarp=1,y=0})~=M.outViewKey({id='ROUTE_22_GATE'},{destMap='LAST_MAP',destWarp=1,y=7}),'Route 22 last-map pictures collided')
