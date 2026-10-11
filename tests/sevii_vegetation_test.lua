local profiles=assert(loadfile('data/sevii_voxel_profiles.lua'))()
local W={clock=0,CLOCK_SECONDS=15360,SEASON_SECONDS=960,seasonAt=function(t)
 return ({'spring','summer','autumn','winter'})[1+math.floor(t/960)%4]
end}
local modules={Weather=W,ModSetting={new=function()return{get=function()return true end}end},
 Gen1NuggetBridge={register=function()end},CinnabarPalms={register=function()end}}
local V={data=function()return profiles end,require=function(n)return modules[n]or{register=function()end}end}
local vegetation=assert(loadfile('lib/SeviiVegetation.lua'))(V);modules.SeviiVegetation=vegetation
local L=assert(loadfile('lib/SeviiLandscape.lua'))()
package.preload['src.render.Assets']=function()return{}end
local f=assert(io.open('lib/VoxelItems.lua'));local text=f:read('*a');f:close()
local P=assert(loadstring(text:sub(1,assert(text:find('P.palette = palette',1,true))-1)..'P.palette=palette;return P'))(V)
assert(loadfile('lib/Gen1OutdoorScenery.lua'))(V).register(P,{patterns={}})
L.register(P)
local S=assert(loadfile('lib/SeasonalTrees.lua'))(V)
local B=assert(loadfile('lib/SpringBlossom.lua'))(V)
local tones,shapes={},{}
for tone=1,3 do for _,variant in ipairs{1,2,4,5}do
 local kind='sevii_tree_'..tone..'_'..variant;local m=assert(P.models[kind])
 local source=P.models['kanto_tree_1_'..variant]
 assert(m.seasonalFoliage and m.blossomSource==source.blossomSource,'seasonal metadata lost')
 assert(#m.boxes==#source.boxes and m.depth==16,'Kanto silhouette changed')
 local signature={}
 for i,b in ipairs(m.boxes)do
  for j=1,6 do assert(b[j]==source.boxes[i][j],'shape/footprint changed')end
  if source.leafColors[source.boxes[i][7]]then
   assert(m.leafColors[b[7]],'winter cannot remove recoloured foliage')
   signature[#signature+1]=b[7]
  else assert(b[7]==source.boxes[i][7],'trunk/bark recoloured')end
 end
 tones[table.concat(signature,':')]=true;shapes[variant]=true
 W.clock=3360
 local bare=S.kind(P,kind,'ThreeIsland_BerryForest',24,20)
 assert(bare~=kind and not P.models[bare].seasonalFoliage)
 for _,b in ipairs(P.models[bare].boxes)do assert(not m.leafColors[b[7]],'winter leaf colour retained')end
 W.clock=480;assert(S.kind(P,kind,'ThreeIsland_BerryForest',24,20)==kind,'spring restoration failed')
end end
local n=0;for _ in pairs(tones)do n=n+1 end;assert(n>=9,'crowns still share one palette')
local sources={};local forests=0
for id,p in pairs(profiles)do if p.kind=='canopy'then
 forests=forests+1;assert(p.canopySize and #p.canopyDensity==p.canopySize[2])
 local old=sources[p.source]
 if old then
  assert(table.concat(old.canopyDensity)==table.concat(p.canopyDensity),'canopy jumps at source fragment')
 else sources[p.source]=p end
 local source,x,z=vegetation.coordinates(id,6,8)
 assert(source==p.source and x==6+p.origin[1]*2 and z==8+p.origin[2]*2)
 assert(S.sheds(source,x,z)==S.sheds(p.source,x,z))
 assert(B.selected(id,6,8)==B.selected(source,x,z),'blossom selection jumps at source fragment')
 local low,high=1,0
 for y,row in ipairs(p.canopyDensity)do
  assert(#row==p.canopySize[1])
  for x=0,#row-1 do local d=vegetation.density(p,x,y-1);assert(d>=0 and d<=1)
   low,high=math.min(low,d),math.max(high,d)
  end
 end
 assert(high==1 and low<.3,'clearings inherit full canopy shade')
end end
assert(forests>2 and sources.ThreeIsland_BerryForest and sources.SixIsland_PatternBush)
assert(vegetation.leavesAt(1440)==1 and vegetation.leavesAt(3360)<.2)
assert(vegetation.leavesAt(480)==1 and vegetation.leavesAt(15360)==vegetation.leavesAt(0))
print('PASS Sevii vegetation: three crown palettes, four original Kanto silhouettes, bark/footprint isolation, all source canopy fields, clearing light, stable fragment blossoms, winter shedding and spring return')
