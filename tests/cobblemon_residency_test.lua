local reads=0
local content={catalog={},epoch=0,available=function()return true end,
 record=function(dex,variant)
  reads=reads+1
  return {texture='base',identity=dex..':'..variant,payload=dex==999 and string.rep('x',13*1024*1024)or''}
 end,read=function()return 'image' end}
local releases=0
local function image()
 return {getWidth=function()return 2048 end,getHeight=function()return 2048 end,
 setFilter=function()end,release=function()releases=releases+1 end}
end
love={image={newImageData=image},graphics={newImage=image}}
local modules={CobblemonContent=content,CobblemonGeometry={},Diagnostics={write=function()end},
 EngineCompat={fs=function()return {newFileData=function()return {release=function()end}end}end}}
local function make()return assert(loadfile('lib/CobblemonPack.lua'))({require=function(n)return assert(modules[n],n)end})end
local p=make()
for dex=1,16 do assert(p.load(dex))end
collectgarbage('collect');local n=reads
for dex=1,16 do assert(p.load(dex))end
assert(reads==n,'GC discarded retained models')
-- Touch 1; admitting 17 must evict 2 rather than the most recent 1.
assert(p.load(1));assert(p.load(17));collectgarbage('collect');n=reads
assert(p.load(1));assert(reads==n);assert(p.load(2));assert(reads==n+1,'LRU did not evict oldest')
assert(p.residency().models==16 and p.residency().estimatedBytes<=p.residency().budget)
-- Eviction drops the cache reference only, never an actor's live model.
local live=p.load(3)
for dex=30,50 do p.load(dex)end
collectgarbage('collect');n=reads
assert(p.load(3)==live and reads==n)
local normal=p.load(4);local shiny=p.load(4,{shiny=true})
assert(normal~=shiny and normal.identity~=shiny.identity,'variants aliased')
content.epoch=1;assert(p.load(4)~=normal,'content activation reused stale data')
assert(normal.identity=='4:normal','invalidated live model was changed')
assert(p.residency().models==1,'old epoch retained')
local giant=p.load(999);assert(giant and p.residency().models==1,'oversized model retained')
giant=nil;collectgarbage('collect');n=reads;p.load(999);assert(reads==n+1)
-- A texture can push a model beyond the allowance. Charge it and evict the
-- lease, but do not release the image which the caller/rig still references.
local only=make();local textured=only.load(1);local before=releases
local tex=assert(only.image(textured,1));assert(releases==before+1,'temporary ImageData not released')
assert(only.residency().models==0 and only.residency().estimatedBytes==0)
assert(only.image(textured,1)==tex and releases==before+1,'cache eviction freed active texture')
print('PASS bounded model residency, GC reuse, LRU, live eviction, variants, epoch, oversize and texture accounting')
