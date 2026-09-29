-- Explicit optional human-art pack. Only owned, catalogued paths may redirect.
local M={ID='ASCENDANT_HD_CHARACTERS'}
function M.install(mod)
 local files=assert(loadstring(assert(mod:read('lib/HumanDlcAssets.lua'))))()
 local Assets=require('src.render.Assets')
 local function provider()
  local h=mod:find(M.ID)
  local p=h and h.exports and h.exports.humanArt
  return p and p.schema=='ascendant.human-art/v1' and p or nil
 end
 local api={}
 function api.available()return provider()~=nil end
 function api.style(value)
  if value=='cobble' then return value end
  if value=='hd' and api.available()then return value end
  return 'voxel'
 end
 function api.path(path)
  local prefix=mod.path..'/'
  local relative=type(path)=='string' and path:sub(1,#prefix)==prefix and path:sub(#prefix+1)
  if not relative or files[relative]==nil then return path end
  local p=provider()
  if p then return p.path(relative) or path end
  return files[relative] and prefix..files[relative] or path
 end
 function api.has(relative)
  if files[relative]==nil then return true end
  return api.available() or files[relative]~=false
 end
 local read,info=mod.read,mod.info
 function mod:read(relative)
  if files[relative]~=nil then
   local p=provider();if p then return p.read(relative)end
   return files[relative] and read(self,files[relative]) or nil
  end
  return read(self,relative)
 end
 if info then function mod:info(relative)
  if files[relative]~=nil then
   local p=provider();if p then return p.info(relative)end
   return files[relative] and info(self,files[relative]) or nil
  end
  return info(self,relative)
 end end
 local path=mod.assets.path
 mod.assets.path=function(self,relative)return api.path(path(self,relative))end
 local image=mod.assets.image
 mod.assets.image=function(self,relative)
  if files[relative]~=nil then return Assets.image(api.path(mod.path..'/'..relative))end
  return image(self,relative)
 end
 -- One scoped resolver per owned root, shared by field and battle renderers.
 if not Assets._vascHumanDlc then
  Assets._vascHumanDlc={}
  local resolve=Assets.resolve
  Assets.resolve=function(value)
   for _,owner in pairs(Assets._vascHumanDlc)do value=owner.path(value)end
   return resolve(value)
  end
 end
 Assets._vascHumanDlc[mod.path]=api
 mod.exports.humanDlc=api
 return api
end
return M
