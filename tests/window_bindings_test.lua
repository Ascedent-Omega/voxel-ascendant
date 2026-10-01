local V={require=function()error('unexpected dependency')end}
local B=assert(loadfile('lib/Gen1WindowBindings.lua'))(V)
assert(B.root('CELADON_MANSION_3F')=='CELADON_MANSION_1F')
assert(B.root('CINNABAR_LAB_FOSSIL_ROOM')=='CINNABAR_LAB')
assert(not B.options{id='OAKS_LAB'}.edges.north,'lab posters must remain visible')
local function map(id)
 local d={width=12,height=8,tileset='SHIP',borderBlock=12,blocks={}}
 for y=0,7 do for x=0,11 do d.blocks[y*12+x+1]=(x%5<2 and(y<3 or y>=5))and 9 or 12 end end
 return{id=id,def=d}
end
for _,id in ipairs{'SS_ANNE_1F_ROOMS','SS_ANNE_2F_ROOMS'}do
 local m=map(id);local rooms=assert(B.cabins(m));assert(#rooms==6)
 local edge=id=='SS_ANNE_1F_ROOMS'and'south'or'north'
 for _,r in ipairs(rooms)do assert(r.edge==edge and r.east-r.west==64 and r.south-r.north==(edge=='north'and 80 or 96))end
 m.def.blocks[3]=9;assert(not B.cabins(m),'modified cabin footprint accepted')
end
assert(not B.cabins(map('SS_ANNE_B1F_ROOMS')),'below-water cabins received windows')
print('PASS window bindings: floor roots, lab art, six separate cabin rooms, changed-layout and basement guards')
