local active=true
package.loaded['src.render.Pipelines']={worldPipeline=function()return active and 'voxel'or'vanilla'end}
local roofs=assert(loadfile('lib/Gen1Rooftops.lua'))()
local original=function(def)return def.tileset=='OVERWORLD'end
local Map={isOutside=original};package.loaded['src.world.Map']=Map
local party={update=function(self)
 if self.fail then error(self.fail)end
 return self.badge and Map.isOutside(self.game.overworld.map.def),nil,'native'
end};package.loaded['src.ui.PartyMenu']=party
local API={canFly=function(self)return self.knows and Map.isOutside(self.game.overworld.map.def)end}
package.loaded['src.world.WorldAPI']=API
local policy;local field={registerMapPolicyProvider=function(_,fn)assert(not policy);policy=fn;return true end}
local modules={VoxelState={active=function()return active end},Gen1Rooftops=roofs,
 KantoAscendantCompat={fieldTech=function()return field end}}
local M=assert(loadfile('lib/RooftopFly.lua')){require=function(n)return assert(modules[n],n)end}
local game={overworld={},input={wasPressed=function(_,k)return k=='a'end}}
M.install(game);local wrapper=party.update;M.install(game);assert(wrapper==party.update)
local menu=setmetatable({game=game,submenu=true,subItems={{action='fly'}},subIndex=1,badge=true},{__index=party})
local api=setmetatable({game=game,knows=true},{__index=API})
for _,id in ipairs{'CELADON_MART_ROOF','ROUTE_11_GATE_2F','ROUTE_12_GATE_2F','ROUTE_15_GATE_2F','ROUTE_16_GATE_2F','ROUTE_18_GATE_2F'}do
 game.overworld.map={id=id,def={tileset=id=='CELADON_MART_ROOF'and'LOBBY'or'GATE',width=id=='CELADON_MART_ROOF'and 10 or 4,height=4}}
 local allowed,none,tag=menu:update();assert(allowed and none==nil and tag=='native')
 assert(api:canFly());assert(policy(game,'FLY').allowFlyInside);assert(not policy(game,'TELEPORT'))
 assert(Map.isOutside==original and not Map.isOutside(game.overworld.map.def),'global classification leaked')
 menu.badge=false;assert(not menu:update());menu.badge=true
 api.knows=false;assert(not api:canFly());api.knows=true
 active=false;assert(not menu:update()and not api:canFly()and not policy(game,'FLY'));active=true
 game.overworld.map.def.generation=2;assert(not menu:update());game.overworld.map.def.generation=nil
 game.overworld.map.def.width=99;assert(not menu:update())
end
 game.overworld.map={id='CELADON_MART_5F',def={tileset='LOBBY',width=10,height=4}}
assert(not menu:update()and not api:canFly())
game.overworld.map.id='CELADON_MART_ROOF'
menu.subItems[1].action='teleport';assert(not menu:update());menu.subItems[1].action='fly'
local fault={};menu.fail=fault;local ok,err=pcall(menu.update,menu);assert(not ok and err==fault and Map.isOutside==original)
print('PASS rooftop FLY: native badge/party guards, six terraces, 2D/Gen2/interior rejection, narrow scope, errors, arity, reload and Field Kit policy')
