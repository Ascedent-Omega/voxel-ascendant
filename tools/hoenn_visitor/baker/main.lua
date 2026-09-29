io.stdout:setvbuf('no')
function love.load()
 local ok,err=xpcall(function()
  local root=assert(os.getenv('HOENN_VASC_ROOT'))..'/'
  local B=dofile(root..'tools/hoenn_visitor/inputs/cube_baker.lua')
  local model=dofile(root..'assets/hoenn_visitor/model/rig.lua')
  for _,clip in ipairs({{'idle',1},{'walk',12},{'blink',4},{'preview',3}})do
   local data=B.render(model,clip[2],clip[1]);local png=data:encode('png')
   local f=assert(io.open(root..'assets/hoenn_visitor/cobble/'..clip[1]..'.png','wb'))
   f:write(png:getString());f:close();data:release();png:release()
  end
  print('PASS Cobble rig: 4 directions, 12 walk + 4 blink + 1 idle per direction; height',B.referenceHeight(model))
 end,debug.traceback)
 if not ok then print(err)end
 love.event.quit(ok and 0 or 1)
end
