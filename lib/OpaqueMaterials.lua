-- Proofs for immutable mesh/texture pairs. Unknown data keeps alpha testing.
-- No GPU readbacks or vertex walks are allowed in the draw path.
local platform=love and love.system and love.system.getOS and love.system.getOS()
local supported=platform~='iOS'and platform~='Android'
local M={enabled=true,opaqueDraws=0,alphaDraws=0,rangeDraws=0}
local PAGE_QUADS=256
local textures=setmetatable({},{__mode='k'})
local meshes=setmetatable({},{__mode='k'})
function M.texture(image,data)
 if not supported then return image end
 if not(image and data and data.getPixel)then return image end
 local w,h=data:getDimensions();local unsafe={};local cols=math.ceil(w/8)
 for y=0,h-1 do for x=0,w-1 do
  local _,_,_,a=data:getPixel(x,y)
  if a<.5 then unsafe[math.floor(y/8)*cols+math.floor(x/8)]=true end
 end end
 textures[image]={w=w,h=h,cols=cols,unsafe=unsafe,solid=next(unsafe)==nil}
 return image
end
function M.collector(w,h)
 if not supported then return nil end
 if not(w and h)then return nil end
 return {w=w,h=h,cols=math.ceil(w/8),tiles={},pages={},quads=0}
end
function M.quad(c,u0,v0,u1,v1)
 if not c then return end
 c.quads=c.quads+1
 local page=math.floor((c.quads-1)/PAGE_QUADS)+1
 local tiles=c.pages[page]
 if not tiles then tiles={};c.pages[page]=tiles end
 if u0 < -128.5 and u1 < -128.5 then return end
 if u0<0 or v0<0 or u1>1 or v1>1 then c.unknown=true;tiles.unknown=true;return end
 local x0=math.min(c.w-1,math.max(0,math.floor(u0*c.w-0.0001)));local x1=math.min(c.w-1,math.floor(u1*c.w+0.0001))
 local y0=math.min(c.h-1,math.max(0,math.floor(v0*c.h-0.0001)));local y1=math.min(c.h-1,math.floor(v1*c.h+0.0001))
 for y=math.floor(y0/8),math.floor(y1/8)do for x=math.floor(x0/8),math.floor(x1/8)do
  local key=y*c.cols+x;c.tiles[key]=true;tiles[key]=true
 end end
end
function M.remember(mesh,c)if mesh then meshes[mesh]=c end;return mesh end
function M.allowed(mesh,texture)
 if not supported or not M.enabled then return false end
 local c,t=meshes[mesh],textures[texture]
 if not t then return false end
 if not t.solid and (not c or c.unknown or c.w~=t.w or c.h~=t.h)then return false end
 if texture.getWrap then local a,b=texture:getWrap();if a=='clampzero'or b=='clampzero'then return false end end
 if texture.getFilter then local a,b=texture:getFilter();if a~='nearest'or b~='nearest'then return false end end
 if t.solid then return true end
 for tile in pairs(t.unsafe)do if c.tiles[tile]then return false end end
 return true
end
-- Contiguous index ranges preserve the original primitive order, including
-- coplanar overlaps. Mixed textures need not force opaque terrain through
-- alpha testing. Limit fragmentation; highly interleaved geometry stays one
-- normal draw rather than trading fragment work for hundreds of submissions.
function M.ranges(mesh,texture)
 if not supported or not M.enabled then return nil end
 local c,t=meshes[mesh],textures[texture]
 if not(c and t and type(c.quads)=='number'and type(c.pages)=='table'
     and c.quads>PAGE_QUADS and c.w==t.w and c.h==t.h)then return nil end
 if texture.getWrap then local a,b=texture:getWrap();if a=='clampzero'or b=='clampzero'then return nil end end
 if texture.getFilter then local a,b=texture:getFilter();if a~='nearest'or b~='nearest'then return nil end end
 c.rangeCache=c.rangeCache or setmetatable({},{__mode='k'})
 local cached=c.rangeCache[texture]
 if cached and cached.texture==t then return cached.ranges or nil end
 local ranges={};local hasOpaque=false
 for i,tiles in ipairs(c.pages)do
  local opaque=not tiles.unknown
  if opaque then for tile in pairs(t.unsafe)do if tiles[tile]then opaque=false;break end end end
  hasOpaque=hasOpaque or opaque
  local first=(i-1)*PAGE_QUADS*6+1
  local count=math.min(PAGE_QUADS,c.quads-(i-1)*PAGE_QUADS)*6
  local previous=ranges[#ranges]
  if previous and previous.opaque==opaque then previous.count=previous.count+count
  else ranges[#ranges+1]={first=first,count=count,opaque=opaque}end
  if #ranges>8 then ranges=nil;break end
 end
 if not hasOpaque then ranges=nil end
 c.rangeCache[texture]={texture=t,ranges=ranges or false}
 return ranges
end
function M.known(mesh)return meshes[mesh]end
return M
