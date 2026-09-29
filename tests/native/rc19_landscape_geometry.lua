return function(game)
 assert(os.getenv('POKEPORT_IDENTITY')=='vasc-video-polish-qa')
 love.audio.setVolume(0)
 local ex=assert(game.mods.exports.VOXEL_ASCENDANT)
 local function find(fn,name,seen)
  if type(fn)~='function'then return end;seen=seen or{};if seen[fn]then return end;seen[fn]=true
  for i=1,100 do local k,v=debug.getupvalue(fn,i);if not k then break end;if k==name then return v end end
  for i=1,100 do local k,v=debug.getupvalue(fn,i);if not k then break end;local got=find(v,name,seen);if got then return got end end
 end
 local V=assert(find(ex.lib.require('VoxelScene').render,'V'))
 local H=V.require('HorizonWall');local build=assert(find(H.geometry,'geometryFor'))
 local oldBuild
 if os.getenv('QA_HORIZON_REFERENCE')then
  local file=assert(io.open(os.getenv('QA_HORIZON_REFERENCE')));local source=file:read('*a');file:close()
  local proxy={require=function(name)
   if name=='ModSetting'then return{new=function()return H.setting end}end
   return V.require(name)
  end}
  oldBuild=assert(find(assert(loadstring(source))(proxy).geometry,'geometryFor'))
 end
 local elevation=V.require('LedgeElevation');local original=elevation.waterBase;local scans=0
 elevation.waterBase=function(...)scans=scans+1;return original(...)end
 local Map=require('src.world.Map')
 for _,id in ipairs{'SAFFRON_CITY','ROUTE_6','PALLET_TOWN','ROUTE_21','CINNABAR_ISLAND','VERMILION_CITY'}do
  local def=assert(game.data.maps[id]);local map=Map.new(def,game.data.tilesets[def.tileset])
  local e={map=map,ox=0,oy=0,w=def.width*32,h=def.height*32}
  e.x0,e.z0,e.x1,e.z1=0,0,e.w,e.h
  local reference=(oldBuild or build)(e,1,{e},nil,{},{},{},game.data.maps,true)
  scans=0;local yields=0;local result
  local co=coroutine.create(function()
   result=build(e,1,{e},function()yields=yields+1;coroutine.yield()end,{},{},{},game.data.maps,true)
  end)
  repeat local ok,err=coroutine.resume(co);assert(ok,err)until coroutine.status(co)=='dead'
  assert(result.seaQuads==reference.seaQuads and yields>0)
  for _,name in ipairs{'seaVertices','seaIndices'}do
   assert(#result[name]==#reference[name])
   for i,v in ipairs(reference[name])do
    if type(v)=='table'then for k,n in ipairs(v)do assert(result[name][i][k]==n,id..' changed sea vertex')end
    else assert(result[name][i]==v,id..' changed sea index')end
   end
  end
  assert(scans==(result.seaQuads>0 and 1 or 0),'unused or repeated water-height scan')
  print('PASS_LANDSCAPE_GEOMETRY',id,'waterQuads',result.seaQuads,'yields',yields,'waterScans',scans)
 end
 elevation.waterBase=original
 -- Verify the packed native upload after constructor changes as well.
 assert(love.filesystem.load('mods/VOXEL_ASCENDANT/tests/native/rc19_scenery_upload.lua'))()(game)
end
