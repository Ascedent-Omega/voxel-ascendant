-- Water has its own renderer and cache slot. A successfully built sea map
-- can therefore have no opaque faces; that is different from a failed build.
local M={}
function M.complete(opaque,water)
 if opaque or not water then return opaque end
 -- An empty render bundle keeps the established terrain readiness contract
 -- without inventing ground or drawing the water in the opaque pass.
 local bundle={__voxelMeshBundle=true,waterOnly=true,instances={},released=false}
 function bundle:release()self.released=true end
 return bundle
end
return M
