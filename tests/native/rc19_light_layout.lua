return function(game)
 assert(os.getenv('POKEPORT_IDENTITY')=='vasc-video-polish-qa');love.audio.setVolume(0)
 local file=assert(io.open(assert(os.getenv('QA_LAYOUT_REFERENCE'))));local source=file:read('*a');file:close()
 local old=assert(loadstring(source))({})
 local new=assert(love.filesystem.load('mods/VOXEL_ASCENDANT/lib/LocalLightGrid.lua'))({})
 local sources={}
 for i=1,512 do sources[i]={x=(i%32)*19-70,y=i%9,z=math.floor(i/32)*17-60,radius=55+i%5*12,power=i%7*.25}end
 for _,limit in ipairs{2,4}do
  local before,after=old.layout(sources,limit),new.layout(sources,limit)
  for _,key in ipairs{'x','z','nx','nz','stride'}do assert(before[key]==after[key],key)end
  for id,cell in pairs(before.cells)do
   local actual=assert(after.cells[id]);assert(#cell==#actual)
   for i,n in ipairs(cell)do assert(n==actual[i],'different source selection')end
  end
  for id in pairs(after.cells)do assert(before.cells[id])end
  local function bench(m)
   for i=1,8 do m.layout(sources,limit)end
   collectgarbage('collect');local t=love.timer.getTime()
   for i=1,30 do m.layout(sources,limit)end
   return (love.timer.getTime()-t)*1000/30
  end
  print('PASS_LIGHT_LAYOUT_NATIVE',limit,'beforeMs',bench(old),'afterMs',bench(new))
 end
 love.event.quit()
end
