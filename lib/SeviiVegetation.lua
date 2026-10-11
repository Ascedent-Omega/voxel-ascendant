-- Source-wide canopy coverage and seasonal identity. No collision, RNG or
-- encounter changes; a clearing cannot inherit a neighbouring grove's shade.
local V=...
local M={}
local textures={}
local registered
function M.coordinates(id,x,z)
 local p=type(id)=='string'and id:match('^KA_SEVII_')and V.data('sevii_voxel_profiles')[id]
 if p then return p.source,x+p.origin[1]*2,z+p.origin[2]*2 end
 return id,x,z
end
function M.density(p,x,z)
 local row=p.canopyDensity and p.canopyDensity[z+1]
 return row and x>=0 and x<#row and (row:byte(x+1)-33)/90 or 0
end
function M.leavesAt(clock)
 local W=V.require('Weather')
 local t=(clock%W.CLOCK_SECONDS)/W.SEASON_SECONDS
 -- Bare winter forks transmit most daylight; leaf density returns gradually.
 if t>=3 then return .16 end
 if t<.25 then return .16+.84*t/.25 end
 if t>2.75 then return 1-.84*(t-2.75)/.25 end
 return 1
end
function M.clear()
 for _,texture in pairs(textures)do V.require('RasterResources').changing(texture);texture:release()end
 textures={}
end
function M.lighting(map)
 local p=V.require('KascSeviiScenery').profile(map)
 if not(p and p.kind=='canopy'and p.canopyDensity)then return nil end
 local texture=textures[p.source]
 if not texture then
  if not registered then require('src.render.Assets').register(M.clear);registered=true end
  local w,h=unpack(p.canopySize)
  local data=love.image.newImageData(w,h)
  for z=0,h-1 do for x=0,w-1 do local c=M.density(p,x,z);data:setPixel(x,z,c,c,c,1)end end
  local ok,result=pcall(love.graphics.newImage,data);data:release()
  if not ok then return nil end
  texture=V.require('RasterResources').seal(result);texture:setFilter('linear','linear');texture:setWrap('clamp','clamp');textures[p.source]=texture
 end
 local W=V.require('Weather')
 return {texture=texture,area={p.origin[1]*16,p.origin[2]*16,p.canopySize[1]*16,p.canopySize[2]*16},leaves=M.leavesAt(W.clock)}
end
return M
