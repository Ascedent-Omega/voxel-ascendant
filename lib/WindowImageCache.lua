-- Packaged skyless views at each room's floor height. Domestic apertures use
-- complete bitmaps; public glass keeps near geometry. No runtime capture.
local V=...
local M={REVISION=2,FACE_SIZE=768,BITMAP_REVISION=1,BITMAP_SIZE=512,hits=0,misses=0,bitmapHits=0}
-- Small domestic apertures tolerate a fixed capture point. Wide public glass
-- fronts and moving elevators retain near geometry and its parallax.
function M.bitmapEligible(map)
 if map and tostring(map.id):match('^SS_ANNE_')then return false end
 local profile=map and V.require('Gen1InteriorPanoramas').profiles[map.id]
 local theme=profile and profile.theme
 return theme=='home' or theme=='traditional_home' or theme=='coastal_home' or theme=='daycare'
end
function M.key(entry)
 return entry.map.id..'-'..V.require('Gen1LavenderTower').setting:get()
end
function M.configuration()
 local outdoor=V.require('Gen1OutdoorScenery')
 return table.concat({tostring(outdoor.ground:get()),tostring(outdoor.trees:get()),
  tostring(V.require('Gen1PalletVillage').buildings:get()),
  tostring(V.require('VoxelItems').setting:get()),tostring(V.require('CinnabarVolcano').setting:get()),'facades-20261001'},':')
end
local function record(entry,status,reason,meta)
 M.last={map=entry.map.id,status=status,reason=reason,path=meta and meta.path}
 local d=V.mod and V.mod._vascMobileDiagnostic
 if d and type(d.checkpoint)=='function' then
  pcall(d.checkpoint,'window-cache-'..status,{caller='WindowImageCache.load',
   map=entry.map.id,context='world',reason=reason,source=meta and meta.path})
 end
end
function M.load(entry,defs,yieldStep)
 -- The lift changes elevation continuously and keeps its live moving view.
 if V.require('SilphElevator').matches(entry.map)then return end
 local key=M.key(entry);local game=require('src.core.Game');defs=defs or game.data.maps
 local C=V.require('RooftopCache');local selected
 -- Derivatives are shipped on disk: even the first phone launch only decodes
 -- them. A missing/stale derivative falls back to the validated hybrid cache.
 if M.bitmapEligible(entry.map) then
  local flatOK,flatIndex=pcall(V.data,'window_bitmap_cache')
  for _,suffix in ipairs{'','-rb','-yellow'}do
   local meta=flatOK and flatIndex and flatIndex[key..suffix]
   if meta and meta.revision==M.BITMAP_REVISION and meta.size==M.BITMAP_SIZE
    and meta.near==0 and meta.width==entry.w and meta.depth==entry.h
    and meta.configuration==M.configuration()
    and C.signature(defs,meta.maps,game.data.tilesets)==meta.signature then
    local near,parts=C.loadMeta(entry,meta,yieldStep,{size=M.BITMAP_SIZE,eyeY=40,class='silph_exterior',expectedNear=0})
    if near and #near==0 then
     M.hits=M.hits+1;M.bitmapHits=M.bitmapHits+1;record(entry,'hit','bitmap',meta)
     return near,parts
    end
   end
  end
 end
 local ok,index=pcall(V.data,'window_cache')
 for _,suffix in ipairs{'','-rb','-yellow'}do
  local meta=ok and index and index[key..suffix]
  if meta and meta.revision==M.REVISION and meta.size==M.FACE_SIZE
   and meta.width==entry.w and meta.depth==entry.h and meta.configuration==M.configuration()
   and C.signature(defs,meta.maps,game.data.tilesets)==meta.signature then selected=meta;break end
 end
 if not selected then M.misses=M.misses+1;record(entry,'miss','no-matching-source-or-settings');return end
 local near,parts=C.loadMeta(entry,selected,yieldStep,{size=M.FACE_SIZE,eyeY=40,class='silph_exterior'})
 if not near then M.misses=M.misses+1;record(entry,'miss','asset-decode-failed',selected);return end
 M.hits=M.hits+1;record(entry,'hit','hybrid',selected)
 return near,parts
end
return M
