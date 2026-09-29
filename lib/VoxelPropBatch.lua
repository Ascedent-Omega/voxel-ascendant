-- Batch translated opaque props after Blickfrei has selected visible props.
-- Original meshes are never modified: shadows, other maps and fallback draws
-- continue to own their normal templates. Unsupported drivers draw normally.
local V=...
local G=V.require('Voxel3D')
local B={}
-- One immutable template clone and instance stream per source mesh/pass.
-- World registries retain visited maps: a map-keyed cache otherwise clones
-- the same tree/building geometry at every seam and keeps all copies alive.
local cache=setmetatable({},{__mode='k'})
local scratch={}
local disabled=false
local warmJob,warmMap,warmReceipt,discovery
local frameBudget,frameAttempted
function B.beginFrame(covered)
  frameBudget=covered and .003 or .0005
  frameAttempted=false
end
B.preparedTemplates=0
local function release(group)
  if group.mesh then group.mesh:release()end
  if group.source then group.source:release()end
  group.mesh,group.source=nil,nil
end
function B.clear()
  for _,passes in pairs(cache)do for _,group in pairs(passes)do release(group)end end
  cache=setmetatable({},{__mode='k'});scratch={};disabled=false;warmJob,warmMap,warmReceipt=nil,nil,nil
  frameBudget,frameAttempted=nil,nil
  discovery=nil
end
local function translated(m)
  return m and m[1]==1 and m[2]==0 and m[3]==0
    and m[5]==0 and m[6]==1 and m[7]==0
    and m[9]==0 and m[10]==0 and m[11]==1
    and m[13]==0 and m[14]==0 and m[15]==0 and m[16]==1
end
local function prepare(group,entries)
  local rows,changed=group.rows or {},#entries~=group.count
  for i,p in ipairs(entries)do
    local m=p[3];local row=rows[i]
    if not row then row={};rows[i]=row;changed=true end
    if row[1]~=m[4]or row[2]~=m[8]or row[3]~=m[12]then
      row[1],row[2],row[3]=m[4],m[8],m[12];changed=true
    end
  end
  if not group.mesh then
    local original=entries[1][1];local vertices={}
    for i=1,original:getVertexCount()do vertices[i]={original:getVertex(i)}end
    group.mesh=assert(G.newMesh(vertices,original:getVertexMap()))
  end
  if not group.source or #entries>group.capacity then
    local capacity=1;while capacity<#entries do capacity=capacity*2 end
    local source=love.graphics.newMesh({{'InstanceOffset','float',3}},capacity,'points','dynamic')
    local ok,err=pcall(group.mesh.attachAttribute,group.mesh,'InstanceOffset',source,'perinstance')
    if not ok then source:release();error(err)end
    if group.source then group.source:release()end
    group.source,group.capacity=source,capacity;changed=true
  end
  if changed then group.source:setVertices(rows,1,#entries)end
  group.rows,group.count=rows,#entries
  group.bundle=group.bundle or {__voxelMeshBundle=true,instances={{}}}
  group.bundle.instances[1].mesh=group.mesh
  group.bundle.instances[1].count=#entries
  return group.bundle
end
-- Prepare the complete arrival view, before frustum filtering. Looking in a
-- new direction must not clone a building/tree template in the first draw.
function B.prepared(map)return disabled or warmMap==map end
function B.prewarm(state,each,seconds,receipt)
  if disabled or not G.canInstance or not G.canInstance()then warmMap=state.map;return true end
  -- Prefetch is queried by both update and draw. They share one preparation
  -- allowance; a second query must not repeat discovery or resume the job.
  if frameBudget then
    if frameAttempted then return B.prepared(state.map)end
    frameAttempted=true;seconds=math.min(seconds or .002,frameBudget)
  end
  local deadline=love.timer.getTime()+(seconds or .002)
  -- Lazily validate only once per frame, and never on non-instanced drivers.
  if type(receipt)=='function'then receipt=receipt(state)end
  if receipt and warmMap==state.map and warmReceipt==receipt then return true end
  local counts,colorOnly
  if receipt and discovery and discovery.map==state.map
      and discovery.receipt==receipt and discovery.each==each then
    counts,colorOnly=discovery.counts,discovery.colorOnly
  else
    counts,colorOnly={},{}
    local function add(mesh,blossom)
      if not mesh then return end
      local kinds=counts[mesh];if not kinds then kinds={};counts[mesh]=kinds end
      local suffix=blossom and '-blossom' or '';kinds[suffix]=(kinds[suffix]or 0)+1
    end
    each(state,function(mesh,tex,mat,shade,extra)
      if not translated(mat)then return end
      if extra and extra.mesh and extra.tex then add(mesh);add(extra.mesh);add(extra.winterMesh)
      elseif not extra or extra.batchWindow or extra.frost or extra.seasonalFoliage then add(mesh,extra and extra.blossomSource)end
    end)
    local items=V.require('VoxelItems')
    if items.distant then
      local lows={}
      for mesh,kinds in pairs(counts)do local low=items.distant(mesh);if low then lows[#lows+1]={low,kinds}end end
      for _,p in ipairs(lows)do colorOnly[p[1]]=not counts[p[1]];local kinds=counts[p[1]]or{};counts[p[1]]=kinds;for suffix,count in pairs(p[2])do kinds[suffix]=(kinds[suffix]or 0)+count end end
    end
    -- A yielded upload does not change an immutable furniture snapshot.
    -- Recount only after that snapshot changes, not on every upload slice.
    discovery=receipt and {map=state.map,receipt=receipt,each=each,counts=counts,colorOnly=colorOnly}or nil
  end
  if warmJob and not counts[warmJob.original]then warmJob=nil end
  local function pump()
    if not warmJob then return true end
    local budget=V.require('BuildBudget')
    budget.begin(warmJob.co,math.max(0,deadline-love.timer.getTime()))
    local ok,err=coroutine.resume(warmJob.co)
    budget.finish()
    if not ok then
      release(warmJob.group);B.lastError=tostring(err);disabled=true;warmJob=nil;return true
    end
    if coroutine.status(warmJob.co)=='dead'then warmJob=nil;B.preparedTemplates=B.preparedTemplates+1;return true end
    return false
  end
  while warmJob do
    if pump()then break end
    if love.timer.getTime()>=deadline then warmMap=nil;return false end
  end
  for original,kinds in pairs(counts)do for suffix,count in pairs(kinds)do if count>1 then
    local passes=cache[original];if not passes then passes={};cache[original]=passes end
    for _,basePass in ipairs{'color','shadow'}do
      if basePass~='shadow' or not colorOnly[original]then
      local pass=basePass..suffix
      local group=passes[pass];if not group then group={};passes[pass]=group end
      if not group.mesh or not group.source or group.capacity<count then
        warmMap=nil
        local originalMesh,entry=original,group
        warmJob={original=original,group=group}
        warmJob.co=coroutine.create(function()
          if not entry.mesh then
            local vertices={}
            for i=1,originalMesh:getVertexCount()do
              vertices[i]={originalMesh:getVertex(i)}
              if i%256==0 then coroutine.yield()end
            end
            -- A normal draw may have prepared the same group while loading.
            if not entry.mesh then
              local upload=#vertices>=16384 and V.require('PagedPropUpload')
              if upload and upload.available()then entry.mesh=assert(upload.create(G.FORMAT,vertices,originalMesh:getVertexMap()))
              else entry.mesh=assert(G.newMesh(vertices,originalMesh:getVertexMap()))end
            end
          end
          if not entry.source or entry.capacity<count then
            local capacity=1;while capacity<count do capacity=capacity*2 end
            local source=love.graphics.newMesh({{'InstanceOffset','float',3}},capacity,'points','dynamic')
            local attached,err=pcall(entry.mesh.attachAttribute,entry.mesh,'InstanceOffset',source,'perinstance')
            if not attached then source:release();error(err)end
            if entry.source then entry.source:release()end
            entry.source,entry.capacity,entry.count=source,capacity,nil
          end
        end)
        repeat
          if pump()then break end
        until love.timer.getTime()>=deadline
        if warmJob or love.timer.getTime()>=deadline then return false end
      end
      end
    end
  end end end
  warmMap,warmReceipt=state.map,receipt;discovery=nil;return true
end
function B.draw(state,each,draw,pass)
  -- Keep immutable prop snapshots intact; burial changes with buildup/thaw,
  -- and applies to both colour and shadow consumers, including fallback draws.
  if V.require('DeepSnow').buriesFlowers(state.map) then
    local original=draw
    draw=function(mesh,tex,mat,shade,extra)
      if extra and extra.snowBuried then return true end
      return original(mesh,tex,mat,shade,extra)
    end
  end
  if disabled or not state.map or not G.canInstance or not G.canInstance()then return each(state,draw)end
  -- Staging is consumed synchronously and contains no map-specific result.
  -- Keep one workspace per pass, not per visited map: the world registry
  -- retains those map keys, so a weak map table still grows across a journey.
  -- Steady scenery otherwise allocates two tables per prop every frame.
  pass=pass or 'color'
  -- MAP battles draw the same immutable templates as the overworld. Reuse
  -- their GPU clones/streams rather than copying every vertex at send-out.
  -- Each draw consumes its offsets before the next caller streams new ones;
  -- colour and shadow still require independent buffers. Keep staging and
  -- pass-specific filtering separate below.
  local cachePass=pass=='battle-color' and 'color'
    or pass=='battle-shadow' and 'shadow' or pass
  local s=scratch[pass]
  if not s then s={byMesh={},byBlossom={},order={},groups={},entries={}};scratch[pass]=s end
  local byMesh,order=s.byMesh,s.order
  for k in pairs(byMesh)do byMesh[k]=nil end
  for k in pairs(s.byBlossom)do s.byBlossom[k]=nil end
  for i=#order,1,-1 do order[i]=nil end
  local entryCount,groupCount=0,0
  local function newGroup(p)
    groupCount=groupCount+1
    local group=s.groups[groupCount]
    if not group then group={};s.groups[groupCount]=group end
    for i=#group,1,-1 do group[i]=nil end
    if p then group[1]=p end
    order[#order+1]=group;return group
  end
  local function add(mesh,tex,mat,shade,extra,windowGlow,windowColor)
    entryCount=entryCount+1
    local p=s.entries[entryCount]
    if not p then p={};s.entries[entryCount]=p end
    if windowGlow~=nil then
      p.window=p.window or {batchWindow=true};p.window.glow=windowGlow;p.window.glowColor=windowColor;extra=p.window
    end
    p[1],p[2],p[3],p[4],p[5]=mesh,tex,mat,shade,extra
    if (extra and not extra.batchWindow and not extra.frost and not extra.seasonalFoliage)or not translated(mat)then newGroup(p);return end
    -- The same tree mesh may carry either green or cherry crowns. Keep both
    -- instance groups batched, rather than issuing one draw per cherry tree.
    local paletteGroups=extra and extra.blossomSource and s.byBlossom or byMesh
    local group=paletteGroups[mesh]
    if not group then group=newGroup();paletteGroups[mesh]=group end
    -- A template normally uses one palette and shade. Never merge a caller
    -- that explicitly overrides either property.
    if #group>0 and (group[1][2]~=tex or group[1][4]~=shade
      or ((group[1][5]and group[1][5].seasonalFoliage)~=(extra and extra.seasonalFoliage))
      or ((group[1][5]and group[1][5].frost)~=(extra and extra.frost))
      or ((group[1][5]and group[1][5].glow)~=(extra and extra.glow))
      or ((group[1][5]and group[1][5].glowColor)~=(extra and extra.glowColor)))then newGroup(p)
    else group[#group+1]=p end
  end
  each(state,function(mesh,tex,mat,shade,extra)
    if extra and extra.winterMesh and extra.mesh and extra.tex and pass~='shadow'
        and G.weatherKind==2 and (G.weatherAmount or 0)>.2 then
      add(extra.winterMesh,extra.winterTex,mat,shade,nil)
    end
    -- Window geometry uses an opaque palette, not alpha compositing. Split
    -- the two passes so repeated buildings can instance both their body and
    -- their lit panes. Emission differences remain separate groups.
    if extra and extra.mesh and extra.tex then
      add(mesh,tex,mat,shade,nil)
      add(extra.mesh,extra.tex,mat,shade,nil,extra.glow or 0,extra.glowColor)
    else add(mesh,tex,mat,shade,extra)end
  end)
  -- Reuse empty table capacity, but do not pin resources from a larger old
  -- scene in slots that this frame no longer uses.
  for i=entryCount+1,s.entryCount or 0 do
    local p=s.entries[i]
    for j=1,5 do p[j]=nil end
    if p.window then p.window.glowColor=nil end
  end
  for i=groupCount+1,s.groupCount or 0 do
    local group=s.groups[i];for j=#group,1,-1 do group[j]=nil end
  end
  s.entryCount,s.groupCount=entryCount,groupCount
  -- Eye and sun see different instance sets. Sharing their streaming buffer
  -- overwrote it twice per frame, even with an entirely stationary camera.
  -- Every draw is consumed before the next map's offsets are streamed.
  -- Sharing across maps is safe; eye and sun still get independent streams.
  for _,entries in ipairs(order)do
    local batched=false
    if #entries>1 and not disabled then
      local original=entries[1][1]
      local passes=cache[original];if not passes then passes={};cache[original]=passes end
      local palettePass=entries[1][5] and entries[1][5].blossomSource
        and cachePass..'-blossom' or cachePass
      local group=passes[palettePass]
      if not group then group={};passes[palettePass]=group end
      local cold=not group.mesh or not group.source or (group.capacity or 0)<#entries
      if cold and frameBudget and not pass:match('^battle')then
        -- Render the exact originals until update has staged this group.
        -- Never clone a whole template or resize streams during world draw.
        warmMap=nil
      else
      local ok,bundle=pcall(prepare,group,entries)
      if ok then
        local rendered,result=pcall(draw,bundle,entries[1][2],nil,entries[1][4],entries[1][5])
        batched=rendered and result~=false
        if not batched then B.lastError=tostring(result)end
      else B.lastError=tostring(bundle)end
      if not batched then release(group);passes[palettePass]=nil;disabled=true end
      end
    end
    if not batched then for _,p in ipairs(entries)do draw(unpack(p))end end
  end
end
require('src.render.Assets').register(B.clear)
return B
