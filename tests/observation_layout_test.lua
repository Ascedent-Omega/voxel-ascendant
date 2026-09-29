local active=true
local Map={isWalkableCell=function(_,x,y)return not(x==6 and y==2)end,signAtCell=function(_,x,y)if x==6 and y==2 then return{text='TEXT_ROUTE12GATE2F_RIGHT_BINOCULARS'}end end}
local calls=0;local fail=false
local OW={showMapText=function(self,text)calls=calls+1;assert(self.player.facing=='up');if fail then error('native failure')end;return text end}
package.loaded['src.world.Map']=Map;package.loaded['src.world.OverworldController']=OW
local V={require=function(n)if n=='Gen1Rooftops'then return{gate=function()return true end}elseif n=='VoxelState'then return{active=function()return active end}else return{setting={get=function()return true end}}end end}
local L=assert(loadfile('lib/ObservationLayout.lua'))(V);L.install();L.install()
local map=setmetatable({id='ROUTE_12_GATE_2F'},{__index=Map})
assert(map:isWalkableCell(6,2));assert(not map:isWalkableCell(2,6));assert(not map:signAtCell(6,2));assert(map:signAtCell(2,6))
local ow=setmetatable({map=map,player={cellX=2,cellY=5,facing='down'}},{__index=OW})
assert(ow:showMapText('TEXT_ROUTE12GATE2F_RIGHT_BINOCULARS'));assert(calls==1 and ow.player.facing=='down')
fail=true;assert(not pcall(ow.showMapText,ow,'TEXT_ROUTE12GATE2F_RIGHT_BINOCULARS'));assert(ow.player.facing=='down')
active=false;assert(not map:isWalkableCell(6,2));assert(map:signAtCell(6,2));assert(not map:signAtCell(2,6))
print('PASS observation layout: sign, collision, voxel-only, idempotence and facing restoration on native error')
