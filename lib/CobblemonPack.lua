local V=...;local Content=V.require('CobblemonContent');local Geometry=V.require('CobblemonGeometry')
local M={}
local function failure(dex,reason)
 local ok,d=pcall(V.require,'Diagnostics')
 if ok and d.write then pcall(d.write,'battle-sprite-unavailable',{requested='cobblemon',actual='sprite',
  reason=tostring(dex)..': '..tostring(reason),caller='CobblemonPack'})end
end
local models=setmetatable({},{__mode='v'})
-- Keep a small return cache across map/battle actor teardown. Weak references
-- alone let GC discard the decoded geometry and its size measurements between
-- two visits. This lease never owns/release()s a live actor's GPU resources.
-- The estimate deliberately overcounts table slots and shared strings; it is
-- an allowance, not a claim to measure physical RAM on the device.
local LIMIT,MAX_MODELS=12*1024*1024,16
local retained,used,serial={},0,0
local hits,misses,evictions=0,0,0
local function estimate(value,seen)
 local kind=type(value)
 if kind=='string'then return #value+24 end
 if kind~='table'or seen[value]then return 0 end
 seen[value]=true
 local bytes=128
 for k,v in pairs(value)do bytes=bytes+48+estimate(k,seen)+estimate(v,seen)end
 return bytes
end
local function trim()
 local count=0;for _ in pairs(retained)do count=count+1 end
 while used>LIMIT or count>MAX_MODELS do
  local oldest,key
  for k,row in pairs(retained)do if not oldest or row.used<oldest then oldest,key=row.used,k end end
  if not key then break end
  used=used-retained[key].bytes;retained[key]=nil;count=count-1;evictions=evictions+1
 end
end
local function retain(key,model,bytes)
 serial=serial+1
 local row=retained[key]
 if row then row.used=serial;return end
 if not bytes or bytes>LIMIT then return end
 retained[key]={model=model,bytes=bytes,used=serial};used=used+bytes;trim()
end
function M.residency()
 local count=0;for _ in pairs(retained)do count=count+1 end
 return {models=count,estimatedBytes=used,budget=LIMIT,maxModels=MAX_MODELS,hits=hits,misses=misses,evictions=evictions}
end
-- An actor may ask again every frame while using its sprite fallback. Retry
-- a failed model only after content activation changes the available data.
local failed,failedEpoch={},nil
function M.variant(mon)
 if type(mon)~='table'then return 'normal'end
 if mon._ascMegaForm or mon.ascMegaForm then return nil end
 local identity=Content.catalog.runtime and Content.catalog.runtime[mon.species]
 if Content.catalog.runtime and mon.species and not identity then return nil end
 if mon.form and (not identity or identity.variantPrefix=='') then return nil end
 local female=mon.gender=='female' or mon.gender=='F' or mon.gender=='f'
 local shiny=mon.shiny==true or mon.isShiny==true or mon._shiny==true
 if V.require then local ok,helper=pcall(V.require,'Gen2CrystalFronts');if ok and helper.isShiny then local yes,value=pcall(helper.isShiny,mon);shiny=shiny or yes and value==true end end
 local variant=(female and 'female' or '')..(shiny and (female and '_shiny' or 'shiny')or (female and '' or 'normal'))
 return (identity and identity.variantPrefix or '')..variant
end
local function national(dex,mon)
 local identity=type(mon)=='table' and Content.catalog.runtime and Content.catalog.runtime[mon.species]
 return identity and identity.dex or dex
end
function M.dex(mon)return national(nil,mon)end
function M.available(dex,mon)local variant=M.variant(mon);return variant~=nil and Content.available(national(dex,mon),variant)end
function M.load(dex,mon,checkpoint)
 dex=national(dex,mon)
 local epoch=Content.epoch or 0
 if failedEpoch~=epoch then failed,failedEpoch={},epoch;retained,used={},0 end
 local variant=M.variant(mon)
 local key=tostring(epoch)..':'..tostring(dex)..':'..tostring(variant)
 if failed[key]then return nil end
 if not variant or not Content.available(dex,variant)then failed[key]=true;failure(dex,'variant-unavailable/'..tostring(variant));return nil end
 local model=models[key];if model then
  hits=hits+1;retain(key,model,model._residencyBytes);return model
 end
 misses=misses+1
 model=Content.record(dex,variant,checkpoint);if not model then failed[key]=true;failure(dex,'prepared-model-missing-or-invalid/'..variant);return nil end
 -- Measure before attaching the provider/cache graph. Allow room for the
 -- derived bind/size metadata; texture bytes are charged when uploaded.
 local bytes=model._decodedResidencyBytes
 if type(bytes)=='number'and bytes>=0 and bytes<math.huge then
  -- Metrics are attached after decoding. Preserve the previous conservative
  -- charge for that field; the decoder's bookkeeping field is not model data.
  if model._preparedMetrics then bytes=bytes+48+#'_preparedMetrics'+24+estimate(model._preparedMetrics,{})end
 else bytes=estimate(model,{})end
 model._residencyBytes=bytes+16384
 model.crystalDex=dex
 model.assetProvider=M;model.textures={{}};models[key]=model;retain(key,model,model._residencyBytes);return model
end
function M.sample(model,index,frame,wrap)return Geometry.sample(model,index,frame,wrap)end
function M.image(model,index)
 if index~=1 then return nil end
 local slot=model.textures[1];if slot.image~=nil then return slot.image or nil end
 local owned={}
 local function own(object)owned[object]=true;return object end
 local function release(object)
  if owned[object]then owned[object]=nil;if object.release then pcall(object.release,object)end end
 end
 local ok,img=pcall(function()
  local fs=V.require('EngineCompat').fs()
  local function data(path)
   local bytes=assert(Content.read(path),'Cobblemon texture missing')
   local fd=own((fs.newFileData or love.filesystem.newFileData)(bytes,'cobblemon.png'))
   local image=own(love.image.newImageData(fd));release(fd)
   assert(image:getWidth()<=4096 and image:getHeight()<=4096,'texture size');return image
  end
  local base=data(model.texture)
  for _,path in ipairs(model.layers or {})do
   local layer=data(path)
   if layer:getWidth()==base:getWidth() and layer:getHeight()==base:getHeight()then
    base:mapPixel(function(x,y,r,g,b,a)
     local R,G,B,A=layer:getPixel(x,y);local out=A+a*(1-A)
     if out==0 then return 0,0,0,0 end
     return (R*A+r*a*(1-A))/out,(G*A+g*a*(1-A))/out,(B*A+b*a*(1-A))/out,out
    end)
   end
   release(layer)
  end
  local image=own(love.graphics.newImage(base));release(base);image:setFilter('nearest','nearest');return image
 end)
 if ok then owned[img]=nil end -- The model owns only the completed GPU image.
 for object in pairs(owned)do release(object)end
 if not ok then failure(model.crystalDex,'texture-upload: '..tostring(img))end
 slot.image=ok and img or false
 if ok and img.getWidth and img.getHeight then
  local bytes=img:getWidth()*img:getHeight()*8
  model._residencyBytes=(model._residencyBytes or LIMIT)+bytes
  for _,row in pairs(retained)do
   if row.model==model then row.bytes=row.bytes+bytes;used=used+bytes;break end
  end
  trim()
 end
 return slot.image or nil
end
-- Actual destination actors, not speculative encounter pools, own these
-- leases. Changing the destination drops all leases; weak keys also drop
-- removed actors within the current map. This avoids
-- warming several models only to evict the first before the reveal; active
-- rigs will subsequently share these exact records and GPU textures.
local preparedActors=setmetatable({}, {__mode='k'})
local preparedMap,prepareJob
local function actorRequest(entity)
 if type(entity)~='table' or entity.ascendantPokemonModelSource~='cobblemon'
     or entity.pokemonModel==false or entity.stadiumModel==false then return end
 local dex=tonumber(entity.ascendantPokemonModelDex)
 if not dex or dex<1 or dex>1026 or dex~=math.floor(dex)then return end
 local appearance=entity.ascendantPokemonModelAppearance
 return dex,appearance,tostring(Content.epoch or 0)..':'..tostring(national(dex,appearance))..':'..tostring(M.variant(appearance))
end
function M.entitiesReady(world)
 for _,entity in ipairs(world and world.entities or {})do
  local _,_,key=actorRequest(entity)
  local row=key and preparedMap==world.map and preparedActors[entity]
  if key and (not row or row.key~=key)then return false end
 end
 return true
end
function M.prewarmEntities(world)
 local map=world and world.map
 if map~=preparedMap then
  preparedMap=map;preparedActors=setmetatable({}, {__mode='k'});prepareJob=nil
 end
 for _,entity in ipairs(world and world.entities or {})do
  local dex,appearance,key=actorRequest(entity)
  local row=key and preparedActors[entity]
  if key and (not row or row.key~=key)then
   -- Only this prewarm lane is cooperative. Direct battle/provider loads
   -- keep their synchronous API. Do not expose a half-decoded model or mark
   -- the actor ready until both its model and texture have completed.
   if not prepareJob or prepareJob.entity~=entity or prepareJob.key~=key then
    local job={entity=entity,key=key};prepareJob=job
    job.co=coroutine.create(function()
     local function checkpoint()
      if job.deadline and love.timer.getTime()>=job.deadline then coroutine.yield()end
     end
     local ok,model=pcall(M.load,dex,appearance,checkpoint)
     checkpoint()
     if ok and model then pcall(M.image,model,1)end
     job.model=ok and model or false
    end)
   end
   local job=prepareJob
   job.deadline=love and love.timer and love.timer.getTime and (love.timer.getTime()+.0015) or nil
   local ok,err=coroutine.resume(job.co)
   if not ok or coroutine.status(job.co)=='dead'then
    -- Optional content/GPU failures are terminal for this actor/appearance.
    preparedActors[entity]={key=key,model=ok and job.model or false}
    prepareJob=nil
    if not ok then failure(dex,'prewarm: '..tostring(err))end
   end
   return true
  end
 end
 prepareJob=nil -- removed/disabled actors must not retain unfinished models
 return false
end
return M
