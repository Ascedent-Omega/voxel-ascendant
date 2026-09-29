local config=true;local lift=false;local good=true;local width=480
local released=0;local loads=0;local sig='match';local meta={revision=2,size=768,width=480,depth=288,configuration='true:true:true:true:connected',maps={'CITY'},signature='match'}
local index={['SILPH_CO_1F-stone']=meta}
local yes={get=function()return config end}
local modules={Gen1InteriorPanoramas={profiles={}},Gen1LavenderTower={setting={get=function()return'stone'end}},
 Gen1OutdoorScenery={ground=yes,trees=yes},Gen1PalletVillage={buildings=yes},VoxelItems={setting=yes},
 CinnabarVolcano={setting={get=function()return'connected'end}},SilphElevator={matches=function()return lift end},
 RooftopCache={signature=function()return sig end,loadMeta=function(e,m,y,o)
  loads=loads+1;assert(o.class=='silph_exterior'and o.size==768 and o.eyeY==40)
  if good then return {},{{bakedWindow=true}}end
  return nil,"missing texture"
 end}}
package.preload['src.core.Game']=function()return{data={maps={},tilesets={}}}end
local W=assert(loadfile('lib/WindowImageCache.lua')){require=function(k)return assert(modules[k],k)end,data=function()return index end}
local entry={map={id='SILPH_CO_1F'},w=480,h=288}
assert(W.load(entry));assert(loads==1)
-- Stale source, settings, wrong floor/dimensions, missing assets, and the lift
-- all fall back before rendering an incorrect photograph.
sig='changed';assert(not W.load(entry));assert(loads==1);sig='match'
config=false;assert(not W.load(entry));config=true
entry.w=416;assert(not W.load(entry));entry.w=480
entry.map.id='SILPH_CO_2F';assert(not W.load(entry));entry.map.id='SILPH_CO_1F'
lift=true;assert(not W.load(entry));lift=false
meta.revision=0;assert(not W.load(entry));meta.revision=2
index['SILPH_CO_1F-stone']=nil;index['SILPH_CO_1F-stone-rb']=meta
assert(W.load(entry),'native map alternative ignored')
good=false;local near,parts=W.load(entry);assert(not near and not parts,'broken image cache must fall back without an error string as geometry')
print('PASS window cache: floor/source/settings guards, alternative maps, lift and failed-asset fallback')
-- Domestic rooms prefer complete bitmaps; public glass never loses parallax.
local flat={revision=1,size=512,width=480,depth=288,near=0,configuration=meta.configuration,maps={'CITY'},signature='match'}
local profiles=modules.Gen1InteriorPanoramas.profiles
profiles.HOME={theme='home'};profiles.CENTER={theme='center'};profiles.STORE={theme='mart'}
local flats={['HOME-stone']=flat};index['HOME-stone']=meta
local errors=false;local decodedSize
modules.RooftopCache.loadMeta=function(e,m,y,o)
 decodedSize=o.size
 if m==flat then assert(o.expectedNear==0);if errors then return nil end;return{},{ {bakedWindow=true} }end
 return{{1}},{{bakedWindow=true}}
end
local B=assert(loadfile('lib/WindowImageCache.lua')){require=function(k)return assert(modules[k],k)end,
 data=function(n)return n=='window_bitmap_cache'and flats or index end}
entry.map.id='HOME'
assert(B.load(entry)and decodedSize==512 and B.bitmapHits==1)
errors=true;assert(B.load(entry)and decodedSize==768,'bad bitmap must recover through hybrid');errors=false
flat.near=1;assert(B.load(entry)and decodedSize==768,'bitmap cannot carry old near geometry');flat.near=0
flat.signature='stale';assert(B.load(entry)and decodedSize==768);flat.signature='match'
assert(not B.bitmapEligible({id='CENTER'})and not B.bitmapEligible({id='STORE'})and not B.bitmapEligible({id='SILPH_CO_1F'}))
flats['HOME-stone']=nil;flats['HOME-stone-rb']=flat
assert(B.load(entry)and decodedSize==512,'bitmap native-source variant ignored')
print('PASS domestic bitmap preference, stale/missing/corrupt fallback, no near meshes, public glass preserved')

-- Version selection must skip Red entries with a different world fingerprint.
entry.map.id='SILPH_CO_1F';good=true;sig='yellow';decodedSize=nil
meta.signature='red';index['SILPH_CO_1F-stone']=meta
local yellow={};for k,v in pairs(meta)do yellow[k]=v end;yellow.signature='yellow';yellow.path='yellow'
index['SILPH_CO_1F-stone-yellow']=yellow
modules.RooftopCache.loadMeta=function(e,m)assert(m==yellow,'wrong version capture selected');return {},{}end
assert(W.load(entry),'Yellow capture not selected');assert(W.last.path=='yellow'and W.last.status=='hit')
sig='custom-map';assert(not W.load(entry),'custom world must not borrow stale capture')
assert(W.last.status=='miss','cache rejection missing from diagnostics')
print('PASS Yellow cache selection and custom-world rejection')
