-- Separate entry/exit fixtures supplement the continuous story playthrough.
-- Starts each probe beside an incoming edge in a COPY of our completed QA save.
return function(game)
 io.stdout:setvbuf('no')
 local out=assert(os.getenv('SEVII_QA_OUTPUT'));local root=assert(os.getenv('SEVII_KASC_ROOT'))
 local U=require('tests.drivers.util');local Q=dofile(root..'/tests/habitat_playthrough/drivers/common.lua')(game)
 local Save=require('src.core.SaveData');game:restoreSave(assert(Save.load('red')))
 local S=assert(game.mods.exports.kanto_ascendant.seviiExpedition);assert(S.state().expeditionComplete==true,'completed own QA checkpoint required')
 require('src.world.OverworldController').rollEncounter=function()return nil end
 local Map=require('src.world.Map');local maps={};local ids={};local incoming={};local results={}
 local camera=tonumber(os.getenv('SEVII_COMPONENT_CAMERA')or'0')
 local function view()local p=require('src.render.Pipelines');p.setLevel('voxel',camera);p.setLevel('tiltshift',0);p.syncOptions(game.save.options)end
 local dirs={{'up',0,-1,'north'},{'down',0,1,'south'},{'left',-1,0,'west'},{'right',1,0,'east'}}
 local function usable(m,x,y)return m:inBounds(x,y)and(m:isWalkableCell(x,y)or m:isWaterCell(x,y))end
 for id,def in pairs(S.maps)do ids[#ids+1]=id;maps[id]=Map.new(def,game.data.tilesets[def.tileset]);incoming[id]={}end;table.sort(ids)
 for id,m in pairs(maps)do
  for _,w in ipairs(S.links[id])do if incoming[w.map]then
   for _,d in ipairs(dirs)do local x,y=w.x-d[2],w.y-d[3]
    if usable(m,x,y)and not m:warpAtCell(x,y)then
     incoming[w.map][#incoming[w.map]+1]={source=id,x=x,y=y,dir=d[1],target=w.map,toX=w.toX,toY=w.toY,kind='door'}
    end
   end
  end end
  for _,d in ipairs(dirs)do local c=m:connection(d[4]);local dest=c and maps[c.map]
   if dest then
    local length=d[2]==0 and m.widthCells or m.heightCells
    for cell=0,length-1 do
     local sx,sy,tx,ty
     if d[1]=='up'then sx,sy,tx,ty=cell,0,cell-c.offset*2,dest.heightCells-1
     elseif d[1]=='down'then sx,sy,tx,ty=cell,m.heightCells-1,cell-c.offset*2,0
     elseif d[1]=='left'then sx,sy,tx,ty=0,cell,dest.widthCells-1,cell-c.offset*2
     else sx,sy,tx,ty=m.widthCells-1,cell,0,cell-c.offset*2 end
     if usable(m,sx,sy)and usable(dest,tx,ty)then incoming[c.map][#incoming[c.map]+1]={source=id,x=sx,y=sy,dir=d[1],target=c.map,toX=tx,toY=ty,kind='seam'};break end
    end
   end
  end
 end
 local function probe(edge)
  U.teleport(game,edge.source,edge.x,edge.y,edge.dir);Q.settle();view();U.wait(3)
  local ow=game.overworld;ow.player.surfing=ow.map:isWaterCell(edge.x,edge.y)and not ow.map:isWalkableCell(edge.x,edge.y)
  for _=1,240 do
   if ow.map.id==edge.target and not ow.transitioning and not ow.player.moving then break end
   if game.stack:top()==ow then U.hold(game,edge.dir,1)else Q.settle()end
  end
  Q.settle();assert(ow.map.id==edge.target,'incoming edge reached '..ow.map.id)
  assert(ow.player.cellX==edge.toX and ow.player.cellY==edge.toY,'incoming coordinates differ')
  Q.extraWarpAt=function(m,x,y)for _,w in ipairs(S.links[m.id]or{})do if w.x==x and w.y==y then return true end end;return false end
  local exit
  -- A fragment may contain disconnected plots. Its first door is not
  -- necessarily reachable from this incoming edge. Use a real reachable
  -- authored door, otherwise prove the reciprocal seam return below.
  for _,w in ipairs(S.links[edge.target])do if w.map==edge.source
   and Q.reachable(ow.player.cellX,ow.player.cellY,w.x,w.y)then exit=w;break end end
  if not exit then for _,w in ipairs(S.links[edge.target])do if w.map~=edge.target
   and Q.reachable(ow.player.cellX,ow.player.cellY,w.x,w.y)then exit=w;break end end end
  if exit then
   Q.walkTo(exit.x,exit.y,exit.map);Q.settle();assert(ow.map.id==exit.map,'authored door exit did not arrive');edge.exitMap=exit.map
  elseif edge.kind=='seam'then
   local reverse=({up='down',down='up',left='right',right='left'})[edge.dir]
   for _=1,120 do if ow.map.id==edge.source and not ow.transitioning then break end;U.hold(game,reverse,1)end
   Q.settle();assert(ow.map.id==edge.source,'seam exit did not return')
  else error('no authored return edge')end
 end
 local selected=os.getenv('SEVII_MAP_ENTRY_SELECTED')
 if selected then local wanted={};for id in selected:gmatch('[^,]+')do wanted[id]=true end;local filtered={};for _,id in ipairs(ids)do if wanted[id]then filtered[#filtered+1]=id end end;ids=filtered end
 for i,id in ipairs(ids)do
  local row={map=id,source=S.maps[id].kaSeviiSource,attempts={}}
  if #incoming[id]==0 then row.status='no walkable incoming edge; scenery-only or needs separate puzzle route'
  else
   for index,edge in ipairs(incoming[id])do
    if index>8 then break end
    local ok,why=pcall(probe,edge);row.attempts[#row.attempts+1]={edge=edge,passed=ok,error=not ok and tostring(why)or nil}
    if ok then row.status='PASS physical entry and exit';break end
   end
   row.status=row.status or'OPEN native entry fixture could not complete'
  end
  results[#results+1]=row;local f=assert(io.open(out..'/map-entries.json','w'));f:write(require('src.link.Json').encode(results));f:close()
  print('SEVII_NATIVE_MAP_ENTRY',i,id,row.status)
 end
 local pass,open,scenery=0,0,0;for _,r in ipairs(results)do if r.status:match('^PASS')then pass=pass+1 elseif r.status:match('^OPEN')then open=open+1 else scenery=scenery+1 end end
 print('SEVII_NATIVE_MAP_ENTRY_SUMMARY',pass,open,scenery);love.event.quit(open==0 and 0 or 1)
end
