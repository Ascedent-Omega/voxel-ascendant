local host=assert(os.getenv('QA_GAME_HOST'))..'/'
local maps=dofile(host..'red/data/generated/maps.lua')
local gyms=assert(loadfile('lib/Gen1GymInteriors.lua'))()
local rooms=assert(loadfile('lib/Gen1InteriorPanoramas.lua'))()
local V={};local modules={Gen1GymInteriors=gyms,Gen1InteriorPanoramas=rooms,
 GateDoors=assert(loadfile('lib/GateDoors.lua'))()}
V.require=function(n)return assert(modules[n],n)end
local doors=assert(loadfile('lib/Gen1GlassDoors.lua'))(V);modules.Gen1GlassDoors=doors
local geometry=assert(loadfile('lib/Gen1GymDoors.lua'))(V)
package.loaded['src.core.Game']={data={maps=maps}}
doors.configure(package.loaded['src.core.Game'].data)
local count=0
for id in pairs(gyms.profiles)do
 local map={id=id,def=maps[id]};local p=assert(gyms.exitDoor(map),id)
 assert(doors.interior(map,p.city)and doors.interior(map,'LAST_MAP'),'interior not registered '..id)
 assert(doors.transition({id=p.city,def=maps[p.city]},id),'exterior not registered '..id)
 local groups=assert(geometry.geometry(map,32))
 assert(#groups==4 and groups[2].doorView==doors.outViewKey(map,p.warp))
 assert(groups[3].family=='room_glass_door'and groups[4].family=='room_glass_door')
 assert(groups[3].slidingDoor.sign==-1 and groups[4].slidingDoor.sign==1)
 assert(groups[3].slidingDoor.travel==16 and groups[4].slidingDoor.travel==16)
 local frame=groups[1];local near,far=false,false
 for _,v in ipairs(frame.vertices)do
  if v[3]==p.at-.5 then near=true end;if v[3]==p.at+32 then far=true end
 end
 assert(near and far,'door frame does not reach enclosure')
 for _,g in ipairs(groups)do assert(g.family~='room_door','wooden legacy exit remained')end
 for _,w in ipairs(map.def.warps)do
  if w.destMap~=p.city and w.destMap~='LAST_MAP'then assert(not doors.interior(map,w.destMap),'puzzle pad became sliding door')end
 end
 local altered={id=id,def={}}
 for k,v in pairs(map.def)do altered.def[k]=v end
 altered.def.generation=2;assert(not gyms.exitDoor(altered))
 altered.def.generation=nil;altered.def.width=map.def.width+1;assert(not gyms.exitDoor(altered))
 count=count+1
end
assert(count==9)
assert(not geometry.geometry({id='KA_BLAINE_VOLCANO_GYM',def={tileset='KA_BLAINE_VOLCANO_ARENA',width=24,height=18}},32))
print('PASS all eight native gyms plus dojo, reciprocal glass, joined frames, paired retained leaves, puzzle/Gen2/modified-map/volcano guards')

local styles=assert(loadfile('lib/Gen1DoorStyles.lua'))()
for _,id in ipairs{'VIRIDIAN_NICKNAME_HOUSE','VIRIDIAN_SCHOOL_HOUSE','REDS_HOUSE_1F','BLUES_HOUSE','OAKS_LAB','CELADON_HOTEL','MUSEUM_1F','GAME_CORNER','BILLS_HOUSE','WARDENS_HOUSE'}do
 local map={id=id,def=maps[id]};assert(not doors.entrances[id],id..' was given sliding doors')
 assert(doors.wooden(map,'LAST_MAP'),id..' should use a single wooden leaf')
 local boxes={};local colors={};for name in pairs(styles.colors)do colors[name]=name end
 styles.exterior({decorColors=colors},function(...)boxes[#boxes+1]={...}end,id,14,20)
 assert(boxes[1][7]==styles.variant(id),'outside colour does not match room identity')
 assert(styles.material(id)=='room_wood_door:'..boxes[1][7],'inside colour differs')
 assert(#boxes==7,'single slab/two panels/one handle expected')
end
for _,id in ipairs{'BIKE_SHOP','SILPH_CO_1F','CELADON_MART_1F','INDIGO_PLATEAU_LOBBY','VIRIDIAN_MART','VIRIDIAN_POKECENTER','ROUTE_7_GATE'}do
 assert(doors.entrances[id],id..' must retain sliding glass')
end
assert(styles.variant('VIRIDIAN_NICKNAME_HOUSE')~=styles.variant('VIRIDIAN_SCHOOL_HOUSE'),'house colours are identical')
print('PASS explicit public-building glass scope, ordinary houses single wood and shared inside/outside colours')

for _,id in ipairs{'VIRIDIAN_FOREST_NORTH_GATE','VIRIDIAN_FOREST_SOUTH_GATE'}do
 assert(doors.interior({id=id,def=maps[id]},'VIRIDIAN_FOREST'),'forest gate inside mismatch')
 assert(doors.transition({id='VIRIDIAN_FOREST',def=maps.VIRIDIAN_FOREST},id),'forest gate outside mismatch')
end
assert(maps.CINNABAR_GYM.objects[1].name=='CINNABARGYM_BLAINE'and not maps.KA_BLAINE_VOLCANO_GYM,'VASC changed native Blaine without KASC')
print('PASS forest-facing gate leaves and native Blaine preserved without KASC')
