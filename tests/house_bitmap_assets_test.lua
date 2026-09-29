local source=assert(loadfile('data/window_cache.lua'))()
local index=assert(loadfile('data/window_bitmap_cache.lua'))()
local function read(path)local f=assert(io.open(path,'rb'),path);local b=f:read('*a');f:close();return b end
local function be(b,p)return b:byte(p)*16777216+b:byte(p+1)*65536+b:byte(p+2)*256+b:byte(p+3)end
local count,bytes=0,0
for key,m in pairs(index)do
 count=count+1;local old=assert(source[key])
 assert(not key:match('^SILPH_CO_')and not key:match('^CELADON_MART_')and not key:find('GATE')and not key:find('POKECENTER'))
 assert(m.revision==1 and m.size==512 and m.near==0 and m.sourceNear==old.near)
 assert(m.signature==old.signature and m.configuration==old.configuration and m.width==old.width and m.depth==old.depth)
 assert(table.concat(m.maps,',')==table.concat(old.maps,','),'different source maps')
 local raw=read(m.path..'/near.bin');assert(raw=='RWB2\0\0\0\0','bitmap keeps near geometry');bytes=bytes+#raw
 for name,crop in pairs(m.files)do
  assert(crop.x>=0 and crop.y>=0 and crop.w>0 and crop.h>0 and crop.x+crop.w<=512 and crop.y+crop.h<=512)
  local png=read(m.path..'/'..name..'.png');assert(png:sub(1,8)=='\137PNG\r\n\26\n')
  assert(be(png,17)==crop.w and be(png,21)==crop.h);bytes=bytes+#png
  if name:match('%-land$')then local mask=assert(m.files[name:gsub('%-land$','-materials')]);for _,k in ipairs{'x','y','w','h'}do assert(crop[k]==mask[k])end end
 end
end
assert(count>=120,'incomplete house/style/source coverage')
for _,id in ipairs{'REDS_HOUSE_1F','REDS_HOUSE_2F','BLUES_HOUSE','VERMILION_TRADE_HOUSE'}do
 for _,style in ipairs{'stone','wood'}do for _,suffix in ipairs{'','-rb'}do assert(index[id..'-'..style..suffix])end end
end
local yellow=0;for key in pairs(index)do if key:match('%-yellow$')then yellow=yellow+1 end end
assert(yellow==58,'incomplete Yellow domestic bitmaps')
print('PASS house bitmap assets: '..count..' captures, zero near boxes, source/config guards, '..bytes..' bytes')
