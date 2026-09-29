local mods={Gen1GymInteriors={profiles={PEWTER_GYM={tileset='GYM',width=5,height=7}}},HorizonWall={gymSkylightTexture=function()return true end}}
local S=assert(loadfile('lib/GymSkylights.lua')){require=function(n)return assert(mods[n])end}
local map={id='PEWTER_GYM',def={tileset='GYM',width=5,height=7}}
local phase,power,moon=0,0,false
local clock={time=function()return phase end,strengthAt=function()return power end,bodyAt=function()return phase,45,moon end}
for _,weather in ipairs{'clear','rain','storm','fog','snow'}do
 for p=0,100 do
  phase=p*3.6;power=p/100;moon=p<50
  local light=S.light(map,clock,weather);local t=S.transmission(map,clock,weather)
  assert(light.lampArea[1]==80 and light.lampArea[2]==7*32*.53,'lamp projection moved with sun')
  assert(light.color[4]+light.lampColor[4]>=.26-1e-10,'night/dusk lost mosaic illumination')
  assert(t[1]>.45 and t[2]>.4 and t[3]>.35,'glass went dark')
 end
end
map.def.generation=2;assert(not S.light(map,clock,'clear'));map.def.generation=nil
local positions={LAVENDER_TOWN={x=1000,y=1000,anchor='kanto'},ROUTE_8={x=400,y=1000,anchor='kanto'}}
local L=assert(loadfile('lib/LavenderFog.lua')){require=function()return{position=function(id)return positions[id]end}end}
local a=L.region{id='LAVENDER_TOWN',def={}};local b=L.region{id='ROUTE_8',def={}}
for x=-150,500 do
 assert(math.abs(L.weight(a,x,150)-L.weight(b,x+600,150))<1e-10,'fog changed across root coordinate seam')
end
assert(L.weight(a,-96,150)==0 and L.weight(a,160,150)==1)
local D=assert(loadfile('lib/Gen1FacadeDetails.lua'))()
local solids,glass={},{}
D.add({wallMaterial='timber',facadeVariant=1},function(...)solids[#solids+1]={...}end,function(...)glass[#glass+1]={...}end,
 {oak=37,walnut=36},{},64,48,40,5,0,0,true,false)
for _,g in ipairs(glass)do
 for _,s in ipairs(solids)do
  if g[3]==0 and s[3]==1 and s[5]==1 then
   local overlapX=math.min(s[1]+s[4],g[1]+g[4])>math.max(s[1],g[1])
   local overlapY=math.min(s[2]+s[5],g[2]+g[5])>math.max(s[2],g[2])
   assert(not(overlapX and overlapY),'timber course crosses back pane')
  end
 end
end
local F=assert(loadfile('lib/WeatherFootsteps.lua')){require=function(n)
 if n=='ModSetting'then return{new=function()return{get=function()return true end}end}end
 return{}
end}
for tileset,kind in pairs{HOUSE='wood',FACILITY='stone',CEMETERY='stone',OVERWORLD='grass',FOREST='grass'}do
 assert(F.surface{map={def={tileset=tileset}},player={cellX=0,cellY=0}}==kind)
end
print('PASS 505 mosaic clock/weather cases, fixed lamp footprint, seamless fog coordinate invariance, timber pane clearance and footstep materials')

local Floors=assert(loadfile('lib/Gen1InteriorFloors.lua')){require=function(n)
 if n=='ModSetting'then return{new=function()return{get=function()return true end}end}end
 if n=='Gen1InteriorPanoramas'then return{profileFor=function()end}end
 if n=='Gen1Rooftops'then return assert(loadfile('lib/Gen1Rooftops.lua'))()end
 return{}
end}
for floor=1,7 do
 local tower={id='POKEMON_TOWER_'..floor..'F',def={tileset='CEMETERY',width=10,height=9}}
 assert(Floors.profile(tower)==54)
 assert(Floors.material(tower,54,1,false)==-182)
 assert(Floors.material(tower,54,34,false)==nil,'healing pad covered')
 assert(Floors.material(tower,54,5,false)==nil,'grave tile covered')
 tower.def.generation=2;assert(Floors.profile(tower)==nil)
 tower.def.generation=1;tower.def.width=11;assert(Floors.profile(tower)==nil)
end
print('PASS native Tower slate, seven floors, healing/grave preservation and foreign layout/generation exclusion')

local Weather=assert(loadfile('lib/Weather.lua')){require=function(n)
 if n=='ModSetting'then return{new=function()return{get=function()return 'clear'end}end}end
 if n=='Gen1Rooftops'then return{matches=function()return false end}end
 if n=='SkyEvents'then return{setRainbowPreview=function()end,forceRainbow=function()end}end
 return{}
end}
local town={id='LAVENDER_TOWN',def={tileset='OVERWORLD'}}
local route={id='ROUTE_8',def={tileset='OVERWORLD'}}
for _,weather in ipairs{'auto','clear','rain','storm','snow','fog','off'}do
 for clock=0,15360,240 do
  assert(Weather.modeAt(town,weather,clock,1)==Weather.modeAt(route,weather,clock,123),'regional sky switches at Lavender seam')
 end
end
assert(Weather.mode(town)=='clear'and Weather.skyState(town)=='clear')
print('PASS Lavender regional weather/sky continuity across 455 clock/weather combinations')

local material=-162
local Steps=assert(loadfile('lib/WeatherFootsteps.lua')){require=function(n)
 if n=='ModSetting'then return{new=function()return{get=function()return true end}end}end
 if n=='Gen1OutdoorScenery'then return{profile=function()return true end,material=function()return material end}end
 return{}
end}
local terrain={map={def={tileset='OVERWORLD'},cellTile=function()return 35 end},player={cellX=2,cellY=3}}
assert(Steps.surface(terrain)=='stone');material=-130;assert(Steps.surface(terrain)=='wood')
material=-159;assert(Steps.surface(terrain)=='grass');material=-173;assert(Steps.surface(terrain)=='stone')
terrain.map.isGrassCell=function()return true end;assert(Steps.surface(terrain)=='grass')
print('PASS surface steps follow paving, piers and lawn materials; tall grass retains ownership')

material=-183
assert(Steps.surface{map={def={tileset='OVERWORLD'},cellTile=function()return 48 end},player={cellX=3,cellY=4}}=='ash')
print('PASS volcanic ash footsteps use dry granular surface')
