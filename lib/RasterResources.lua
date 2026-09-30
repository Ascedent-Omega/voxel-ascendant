-- Only renderer-owned resources with an explicit upload revision may be cached.
local R={}
local versions=setmetatable({},{__mode='k'})
local dependencies=setmetatable({},{__mode='k'})
function R.seal(resource)
 if resource then versions[resource]=versions[resource]or 0 end
 return resource
end
-- Invoke BEFORE changing/releasing storage that a postponed draw may reference.
function R.changing(resource)
 if R.barrier then R.barrier()end
 if resource then versions[resource]=(versions[resource]or 0)+1 end
 return resource
end
function R.depend(resource,source)
 R.changing(resource);dependencies[resource]=source
end
function R.revision(resource)
 if not resource then return 0,nil,0 end
 local source=dependencies[resource]
 local sourceRev=0;if source then sourceRev=versions[source]end
 return versions[resource],source,sourceRev
end
return R
