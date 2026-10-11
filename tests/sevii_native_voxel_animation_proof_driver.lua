return function(game)
 io.stdout:setvbuf('no');assert((os.getenv('POKEPORT_IDENTITY')or''):match('^vasc%-sevii%-.*%-qa$'))
 local out=assert(os.getenv('SEVII_QA_OUTPUT'));local U=require('tests.drivers.util')
 local Q=dofile(assert(os.getenv('SEVII_KASC_ROOT'))..'/tests/habitat_playthrough/drivers/common.lua')(game)
 Q.setup();game.save.options.colors='redpp';game:applyOptions();Q.V.setupCard.suspended=true
 local function find(fn,name,seen)
  if type(fn)~='function'then return end;seen=seen or{};if seen[fn]then return end;seen[fn]=true
  for i=1,200 do local k,v=debug.getupvalue(fn,i);if not k then break end;if k==name then return v end end
  for i=1,200 do local k,v=debug.getupvalue(fn,i);if not k then break end;local r=find(v,name,seen);if r then return r end end
 end
 local V=assert(find(Q.V.lib.require('VoxelScene').render,'V'));local Source=V.require('SeviiMapAnimations')
 local R=require('src.render.TileRenderer');local Loader=require('src.world.MapLoader');local A=require('src.render.Assets')
 local report={maps={},surfaceStreams=0,foregroundStreams=0,foregroundCells=0,canvasComparisons=0,
 scope='All source animation GPU atlases at native ticks 0/17/33/79/127/639 versus decoded native frame data. Foreground meshes checked against exact source cell identities, immutable textures and clock sequences. Native world screenshots are a separate visual check; no Android execution.'}
 local function write()local f=assert(io.open(out..'/map-animation-voxel-proof.json','wb'));f:write(require('src.link.Json').encode(report));f:close()end
 local ci;for i=1,100 do local k=debug.getupvalue(R.animClock,i);if k=='animFrame'then ci=i;break end end
 local saved=R.animClock();local function clock(t)debug.setupvalue(R.animClock,assert(ci),t)end
 local ids={};for id in pairs(Q.K.seviiExpedition.maps)do ids[#ids+1]=id end;table.sort(ids)
 for _,id in ipairs(ids)do
  local map=Loader.load(game.data,id)
  if Source.active(map)then
   assert(Source.prepare(map));local e=assert(Source.receipt(map));local row={map=id,surface=#e.surface,foreground=#e.foreground,cells=0,vertices=0}
   for _,s in ipairs(e.foreground)do
    row.cells=row.cells+#s.placements;row.vertices=row.vertices+s.vertices
    assert(#s.placements==0 or s.mesh,'foreground missing source mesh '..id)
    for _,image in ipairs(s.textures)do local w,h=image:getDimensions();local min,mag=image:getFilter()
     assert(w==16 and h==16 and min=='nearest'and mag=='nearest','native foreground frame '..id)
    end
   end
   for _,tick in ipairs{0,17,33,79,127,639}do
    clock(tick);Source.update(map)
    for _,s in ipairs(e.foreground)do assert(s.frame==s.sequence[tick%#s.sequence+1],'foreground clock '..id)end
    if #e.surface>0 or #e.background>0 then
     local expected=love.image.newImageData(map.tileset.imageWidth,map.tileset.imageHeight)
     expected:paste(A.imageData(map.tileset.image),0,0)
     for _,g in ipairs(map.tileset.kaSeviiTileAnimations.groups)do
      if g.kind=='steam'then
       local tile=g.tiles[1];expected:paste(A.imageData(g.background),tile%64*8,math.floor(tile/64)*8,0,0,16,16)
      end
     end
     for _,spec in ipairs(map.tileset.animatedTiles)do
      local surface=false;for _,k in ipairs(spec.kaSeviiAnimationKinds)do if k=='water'or k=='sand'then surface=true end end
      if surface then
       local image=A.imageData(spec.images[spec.sequence[tick%#spec.sequence+1]])
       for _,tile in ipairs(spec.tiles or{spec.tile})do expected:paste(image,tile%64*8,math.floor(tile/64)*8,0,0,8,8)end
      end
     end
     local canvas=Source.atlas(map);local actual=canvas:newImageData()
     assert(actual:getString()==expected:getString(),'native source atlas mismatch '..id..' '..tick)
     actual:release();expected:release();report.canvasComparisons=report.canvasComparisons+1
    end
   end
   local front,back=e.canvases[1],e.canvases[2];local paints=e.paints
   Source.update(map);Source.update(map)
   assert(e.paints==paints and e.canvases[1]==front and e.canvases[2]==back,'stationary clock changed resources '..id)
   if id=='KA_SEVII_TREASURE'or id=='KA_SEVII_FOUR'or id=='KA_SEVII_ONE_ISLAND_KINDLE_ROAD_EMBER_SPA'then
    local old={};local names={'newCanvas','newImage','newMesh','newSpriteBatch'}
    for _,name in ipairs(names)do old[name]=love.graphics[name];love.graphics[name]=function()error('animation allocated GPU resource '..id..' '..name)end end
    local imageData=love.image.newImageData;love.image.newImageData=function()error('animation allocated pixel buffer '..id)end
    collectgarbage('collect');local memory=collectgarbage('count')
    for tick=0,639 do clock(tick);Source.update(map)end
    collectgarbage('collect');row.cycleRetainedLuaKiB=collectgarbage('count')-memory
    for _,name in ipairs(names)do love.graphics[name]=old[name]end;love.image.newImageData=imageData
    assert(e.canvases[1]==front and e.canvases[2]==back,'cycle replaced native buffers '..id)
    row.fullCycleWithoutResourceAllocation=true
   end
   local residency=V.require('WorldResidency')
   assert(e.ownedBytes==#e.canvases*map.tileset.imageWidth*map.tileset.imageHeight*8+row.vertices*80,'source ownership estimate '..id)
   residency.reset();residency.record(id,{});residency.keep({[id]=true})
   assert(residency.last.estimatedTerrainBytes==math.max(64*1024,e.ownedBytes),'source allocation not counted '..id)
   Source.setLive();assert(Source.receipt(map)==e,'live animation evicted '..id)
   local borrowed=e.surface[1]and e.surface[1].textures[1]or e.foreground[1]and e.foreground[1].textures[1]
   row.ownedBytes=e.ownedBytes;residency.reset();Source.setLive()
   assert(not Source.receipt(map)and Source.ownedBytes(id)==0,'source resources retained after eviction '..id)
   for _,canvas in ipairs(e.canvases)do assert(not pcall(canvas.getDimensions,canvas),'evicted canvas not released '..id)end
   for _,s in ipairs(e.foreground)do if s.mesh then assert(not pcall(s.mesh.getVertexCount,s.mesh),'evicted mesh not released '..id)end end
   if borrowed then assert(pcall(borrowed.getDimensions,borrowed),'borrowed native image released '..id)end
   row.resourceEvictionPassed=true
   row.paints=e.paints;report.surfaceStreams=report.surfaceStreams+row.surface
   report.foregroundStreams=report.foregroundStreams+row.foreground;report.foregroundCells=report.foregroundCells+row.cells
   report.maps[#report.maps+1]=row;Source.invalidate()
   if #report.maps%10==0 then write();print('SEVII_VOXEL_ANIMATION_MAPS',#report.maps);U.wait(1)end
  end
 end
 clock(saved);assert(#report.maps==135);report.completed=true;write()
 print('SEVII_VOXEL_MAP_ANIMATION_PROOF_PASS',#report.maps,report.surfaceStreams,report.foregroundStreams,report.foregroundCells,report.canvasComparisons)
 love.event.quit()
end
