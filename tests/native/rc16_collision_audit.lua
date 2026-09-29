return function(game)
 assert(os.getenv('POKEPORT_IDENTITY')=='vasc-video-polish-qa');io.stdout:setvbuf('no')
 game:startNewGame{intro=false}
 local function find(fn,name,seen)
  if type(fn)~='function'then return end;seen=seen or{};if seen[fn]then return end;seen[fn]=true
  for i=1,100 do local k,v=debug.getupvalue(fn,i);if not k then break end;if k==name then return v end end
  for i=1,100 do local k,v=debug.getupvalue(fn,i);if not k then break end;local got=find(v,name,seen);if got then return got end end
 end
 local ex=game.mods.exports.VOXEL_ASCENDANT
 local V=assert(find(ex.lib.require('VoxelScene').render,'V'));local Map=require('src.world.Map')
 local Bounds=V.require('Gen1RoomBounds');local L=V.require('Gen1InteriorLayout');local Stairs=V.require('Gen1Stairs')
 Stairs.setting:setValue(true,game)
 local maps,stairs,turned,portal=0,0,0,0
 local deltas={south={0,1},west={-1,0},north={0,-1},east={1,0}}
 for id,profile in pairs(V.require('Gen1InteriorPanoramas').profiles)do
  local d=game.data.maps[id];local m=Map.new(d,game.data.tilesets[d.tileset]);local before=table.concat(d.blocks,',')
  local panels=L.panelsFor(m,profile);local b=Bounds.forMap(m);maps=maps+1
  local warps={};for _,w in ipairs(d.warps or{})do warps[w.y*d.width*2+w.x]=true end
  -- Reclaimed wall strips contain no ordinary native walkable cell.
  for y=0,d.height*2-1 do for x=0,d.width*2-1 do
   if not warps[y*d.width*2+x]and m:isWalkableCell(x,y)then
    assert(x*16>=b.west and (x+1)*16<=b.east and y*16>=b.north and (y+1)*16<=b.south,id..' wall consumes walkable cell')
   end
  end end
  for _,w in ipairs(d.warps or{})do
   local class=V.require('Gen1StairCells').classForWarp(m,w)
   local spec=V.data('voxel_heights').tilesets[d.tileset]
   if not class then for name,ids in pairs(spec or{})do if type(name)=='string'and name:match('^stair')and type(ids)=='table'then
    for _,tile in ipairs(ids)do if m:tileAt(w.x*2,w.y*2)==tile then class=name end end
   end end end
   if class then
    local default=(class=='stair_e'or class=='stair_down_w')and 'west'or 'east'
    local store=Stairs.storeFlight(m,w.x,w.y,{class=class});if store then default='south'end
    local side=Stairs.entrance(m,w.x,w.y,default);local any=false
    for _,delta in pairs(deltas)do local x,y=w.x+delta[1],w.y+delta[2]
     if x>=0 and y>=0 and x<d.width*2 and y<d.height*2 and m:isWalkableCell(x,y)then any=true end
    end
    if any then local v=deltas[side];assert(m:isWalkableCell(w.x+v[1],w.y+v[2]),id..' stair faces blocked approach')end
    stairs=stairs+1;if side~=default then turned=turned+1 end
    print('STAIR',id,w.x,w.y,class,default,side)
   end
   -- No wall crosses the centre of an actual walkable warp cell.
   if m:isWalkableCell(w.x,w.y)then for _,p in ipairs(panels)do
    local horizontal=p.edge=='north'or p.edge=='south'
    local across=(horizontal and w.y or w.x)*16;local along=(horizontal and w.x or w.y)*16+8
    assert(not(p.at>across and p.at<across+16 and along>p.from and along<p.upto),id..' panel crosses warp')
   end end
  end
  assert(table.concat(d.blocks,',')==before,id..' native blocks changed')
 end
 print('PASS_NATIVE_BOUNDARIES_AND_STAIRS',maps,stairs,turned)
 love.event.quit()
end
