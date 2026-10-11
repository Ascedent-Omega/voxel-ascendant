-- Actual native TileRenderer draws for every declared source stream/frame and
-- every claimed atlas slot. Source phase schedules have a separate ROM oracle.
return function(game)
 io.stdout:setvbuf('no')
 assert((os.getenv('POKEPORT_IDENTITY')or''):match('^vasc%-sevii%-.*%-qa$'))
 local out=assert(os.getenv('SEVII_QA_OUTPUT'))
 local U=require('tests.drivers.util')
 local Q=dofile(assert(os.getenv('SEVII_KASC_ROOT'))..'/tests/habitat_playthrough/drivers/common.lua')(game)
 Q.setup();game.save.options.colors='redpp';game:applyOptions();Q.V.setupCard.suspended=true
 local R=require('src.render.TileRenderer');local Loader=require('src.world.MapLoader')
 local A=require('src.render.Assets');local J=require('src.link.Json')
 local report={maps={},samples=0,streams=0,claimedSlots=0,animatedMaps=0,
 scope='Native TileRenderer.drawTile GPU output, every stream image and every claimed tile slot; exact decoded RGBA comparison. QA clock changes are restored. No engine file changes and no mobile performance claim.'}
 local function write()local f=assert(io.open(out..'/map-animation-proof.json','wb'));f:write(J.encode(report));f:close()end
 local ci
 for i=1,100 do local k=debug.getupvalue(R.animClock,i);if k=='animFrame'then ci=i;break end end
 assert(ci,'native tile clock accessor changed')
 local saved=R.animClock()
 local function clock(t)debug.setupvalue(R.animClock,ci,t)end
 local ids={};for id in pairs(Q.K.seviiExpedition.maps)do ids[#ids+1]=id end;table.sort(ids)
 for _,id in ipairs(ids)do
  local map=Loader.load(game.data,id);local specs=map.tileset.animatedTiles or{}
  local row={map=id,streams=#specs,samples=0,claimedSlots=0}
  assert(#(map.renderer.anims or{})==#specs,'native missing stream '..id)
  if #specs>0 then
   report.animatedMaps=report.animatedMaps+1
   local cases={}
   for _,spec in ipairs(specs)do
    local tiles=spec.tiles or{spec.tile}
    for _,tile in ipairs(tiles)do
     assert(map.renderer.claimedBy[tile],'native missing claimed tile '..id..' '..tile)
     row.claimedSlots=row.claimedSlots+1
     cases[#cases+1]={tile=tile,tick=0,path=spec.images[spec.sequence[1]]}
    end
    for image,path in ipairs(spec.images)do
     local tick;for i,index in ipairs(spec.sequence)do if index==image then tick=i-1;break end end
     assert(tick,'unreachable image '..id)
     cases[#cases+1]={tile=tiles[1],tick=tick,path=path}
    end
   end
   local width,height=512,math.ceil(#cases/64)*8
   local canvas=love.graphics.newCanvas(width,height,{dpiscale=1,format='rgba8'})
   canvas:setFilter('nearest','nearest')
   local expected=love.image.newImageData(width,height)
   love.graphics.push('all');love.graphics.setCanvas(canvas);love.graphics.setShader()
   love.graphics.origin();love.graphics.clear(0,0,0,0);love.graphics.setColor(1,1,1,1)
   love.graphics.setBlendMode('replace','premultiplied')
   for i,case in ipairs(cases)do
    local x,y=(i-1)%64*8,math.floor((i-1)/64)*8
    clock(case.tick);map.renderer:drawTile(case.tile,x,y)
    local pixels=A.imageData(case.path)
    assert(pixels:getWidth()==8 and pixels:getHeight()==8,'frame dimensions '..case.path)
    local tex=map.renderer.claimedBy[case.tile].textures[map.renderer.claimedBy[case.tile].sequence[case.tick+1]]
    local min,mag=tex:getFilter();assert(min=='nearest'and mag=='nearest','frame filtering '..id)
    expected:paste(pixels,x,y,0,0,8,8)
   end
   love.graphics.pop()
   local actual=canvas:newImageData();assert(actual:getString()==expected:getString(),'native pixel mismatch '..id)
   row.samples=#cases;actual:release();expected:release();canvas:release()
  end
  report.samples=report.samples+row.samples;report.streams=report.streams+row.streams
  report.claimedSlots=report.claimedSlots+row.claimedSlots;report.maps[#report.maps+1]=row
  if #report.maps%20==0 then write();U.wait(1)end
 end
 clock(saved);assert(#ids==266 and report.animatedMaps==135 and report.streams>3000)
 report.completed=true;write()
 print('SEVII_NATIVE_TILE_ANIMATION_PROOF_PASS',#ids,report.animatedMaps,report.streams,report.claimedSlots,report.samples)
 love.event.quit()
end
