local C=assert(loadfile('lib/TerrainCompletion.lua'))()
local releases=0
local water={release=function()releases=releases+1 end}
assert(C.complete(nil,nil)==nil and C.complete(false,false)==false,'failed/empty dry map marked ready')
local opaque={};assert(C.complete(opaque,water)==opaque,'opaque terrain replaced')
for _,missing in ipairs{false,{}}do
 local body=C.complete(missing==false and false or nil,water)
 assert(body.__voxelMeshBundle and body.waterOnly and not body.base and #body.instances==0)
 local draws=0
 -- Both world and shadow consumers draw only a bundle's base and instances.
 if body.base then draws=draws+1 end
 for _,group in ipairs(body.instances)do draws=draws+1 end
 assert(draws==0,'sea surface duplicated in the opaque pass')
 body:release();body:release();assert(body.released and releases==0,'opaque slot released separately owned water')
end
print('PASS water-only terrain: successful sea-map completion, zero opaque draws, separate water ownership, dry failure retained and idempotent release')
