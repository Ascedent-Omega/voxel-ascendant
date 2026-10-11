local recipes=dofile('data/sevii_voxel_profiles.lua')
local file=assert(io.open('tests/evidence/sevii-source-map-types-20261008/original-map-header-types.json','r'))
local rows=require('src.link.Json').decode(file:read('*a'));file:close();local headers={}
for _,row in ipairs(rows)do headers[row.source]=row end
local modules={};local V={data=function()return recipes end,require=function(n)return assert(modules[n],n)end}
modules.KascSeviiScenery=assert(loadfile('lib/KascSeviiScenery.lua'))(V)
modules.SeviiArenaBindings=assert(loadfile('lib/SeviiArenaBindings.lua'))(V)
local Style=assert(loadfile('lib/BattleArenaStyle.lua'))(V)
local counts={};local n=0
for id,p in pairs(recipes)do
 local ts={id='KA_SEVII_TILES_'..id:sub(10),trueColor=true,imageWidth=p.atlas[1],imageHeight=p.atlas[2],blocks={},sourceCellCollision={}}
 for b=1,#p.blocks do
  local block,collision={},{};local codes={X='WALL',G='FLOOR',W='WATER',g='GRASS'}
  for y=0,3 do for x=0,3 do block[#block+1]=math.floor((b-1)/16)*256+(b-1)%16*4+y*64+x end end
  for q=1,4 do collision[q]=codes[p.collision[b]:sub(q,q)]end;ts.blocks[b]=block;ts.sourceCellCollision[b]=collision
 end
 local m={id=id,tileset=ts,def={kaOwner='kasc.sevii-expedition/v1',tileset=ts.id,kaSeviiSource=p.source,kaSeviiSourceOrigin=p.origin,width=p.size[1],height=p.size[2],outdoor=p.outdoor}}
 local h=assert(headers[p.source]);assert(p.sourceMapType==h.type,'source header changed '..id)
 local expected=({[1]='city',[3]='grass',[4]='cave',[8]='interior'})[h.type]
 if p.kind=='canopy'then expected=Style.resolve({id='VIRIDIAN_FOREST',def={}}).id
 elseif p.kind=='mountain'and p.exterior then expected=Style.resolve({id='ROUTE_3',def={}}).id
 elseif p.source=='OneIsland_TreasureBeach'then expected=Style.resolve({id='ROUTE_19',def={}}).id end
 assert(Style.resolve(m).id==expected,'non-Kanto style '..id)
 counts[expected]=(counts[expected]or 0)+1;n=n+1
 if h.type==1 then
  local saved=p.sourceMapType;p.sourceMapType=nil
  local ok,err=pcall(modules.SeviiArenaBindings.styleFor,m);assert(not ok and err:find(id,1,true),'missing type silently accepted')
  p.sourceMapType=saved
 end
 m.def.kaOwner='foreign';assert(not modules.SeviiArenaBindings.styleFor(m),'foreign owner accepted')
end
assert(n==266 and counts.city and counts.grass and counts.moon_approach)
for id,expected in pairs{PALLET_TOWN='city',VIRIDIAN_FOREST='forest',ROUTE_1='grass',ROUTE_19='coast',REDS_HOUSE_1F='interior',MT_MOON_1F='cave',ROUTE_3='moon_approach'}do
 assert(Style.resolve({id=id,def={tileset=id:match('ROUTE')and'OVERWORLD'or'INTERIOR'}}).id==expected,'Kanto family changed '..id)
end
print('PASS source map types: 266 header identities, Kanto family reuse, missing metadata rejection, foreign/Kanto exclusion')
