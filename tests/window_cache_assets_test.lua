local index=assert(loadfile('data/window_cache.lua'))()
local count=0;local maxNear=0;local bytes=0
local function read(path)local f=assert(io.open(path,'rb'),path);local b=f:read('*a');f:close();return b end
local function le(b,p)return b:byte(p)+b:byte(p+1)*256+b:byte(p+2)*65536+b:byte(p+3)*16777216 end
local function be(b,p)return b:byte(p)*16777216+b:byte(p+1)*65536+b:byte(p+2)*256+b:byte(p+3)end
for key,m in pairs(index)do
 count=count+1
 assert(m.revision==2 and m.size==768 and m.width>0 and m.depth>0 and #m.signature==64)
 local raw=read(m.path..'/near.bin');assert(raw:sub(1,4)=='RWB2')
 local near=le(raw,5);assert(#raw==8+32*near and near==m.near and near<=12000)
 maxNear=math.max(maxNear,near);bytes=bytes+#raw
 assert(#m.maps>0 and m.configuration)
 local coast=false
 for _,id in ipairs(m.maps)do if id=='CINNABAR_ISLAND'then coast=true end end
 if key:match('^SAFARI_ZONE_')and not key:match('^SAFARI_ZONE_GATE')then
  for _,id in ipairs(m.maps)do assert(id:match('^SAFARI_ZONE_'),'Safari hut view escaped its native connected area')end
 else assert(coast,'captured horizon ends before Cinnabar: '..key)end
 for _,id in ipairs(m.maps)do assert(not id:match('^SILPH_CO_'),'native interior door state must not invalidate the exterior photograph')end
 for name,crop in pairs(m.files)do
  assert(crop.x>=0 and crop.y>=0 and crop.w>0 and crop.h>0 and crop.x+crop.w<=768 and crop.y+crop.h<=768)
  local png=read(m.path..'/'..name..'.png');assert(png:sub(1,8)=='\137PNG\r\n\26\n')
  assert(be(png,17)==crop.w and be(png,21)==crop.h,'wrong crop '..key..'/'..name)
  bytes=bytes+#png
  if name:match('%-land$')then
   local mask=m.files[name:gsub('%-land$','-materials')];assert(mask and mask.x==crop.x and mask.y==crop.y and mask.w==crop.w and mask.h==crop.h)
  end
 end
end
assert(count>=82,'missing room/style captures')
for floor=1,5 do for _,style in ipairs{'stone','wood'}do
 assert(index['CELADON_MART_'..floor..'F-'..style],'missing department floor '..floor)
end end
local yellow=0;for key in pairs(index)do if key:match('%-yellow$')then yellow=yellow+1 end end
assert(yellow>=128,'incomplete Yellow room/style coverage')
for _,id in ipairs{'CELADON_HOTEL','CELADON_DINER','MUSEUM_2F','CELADON_MANSION_3F','INDIGO_PLATEAU_LOBBY','POKEMON_MANSION_3F','SS_ANNE_1F_ROOMS','SS_ANNE_2F_ROOMS','CINNABAR_LAB_FOSSIL_ROOM','CELADON_MANSION_ROOF_HOUSE'}do
 for _,style in ipairs{'stone','wood'}do for _,suffix in ipairs{'','-rb','-yellow'}do assert(index[id..'-'..style..suffix],'missing expanded building view: '..id..style..suffix)end end
end
for key in pairs(index)do assert(not key:match('^POKEMON_TOWER_'),'Lavender Tower must remain closed')end
for i=1,11 do for _,style in ipairs{'stone','wood'}do
 assert(index['SILPH_CO_'..i..'F-'..style..'-yellow'],'missing Yellow Silph floor '..i)
 assert(index['SILPH_CO_'..i..'F-'..style]or index['SILPH_CO_'..i..'F-'..style..'-rb'])
end end
print('PASS packaged window images: '..count..' captures, max '..maxNear..' near boxes, '..bytes..' bytes')
