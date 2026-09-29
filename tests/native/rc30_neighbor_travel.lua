return function(game)
 assert(os.getenv('POKEPORT_IDENTITY')=='vasc-video-polish-qa')
 local root=assert(os.getenv('QA_VASC_ROOT'))
 local U=require('tests.drivers.util');local teleport=U.teleport
 local ex=game.mods.exports.VOXEL_ASCENDANT
 local R=ex.lib.require('Voxel3D')
 U.teleport=function(...)
  teleport(...)
  -- The travel fixture installs an overworld directly. Give it a real
  -- covered update phase before walking, using the normal preload lane.
  local cover={isOpaque=true,draw=function()love.graphics.clear(0,0,0,1)end}
  game.stack:push(cover)
  local ready=false
  for i=1,1800 do
   U.wait(1)
   -- Like rc27_model_travel, this synthetic scene has no warp-owned prop
   -- batch receipt. Assert the actual card gate under normal covered updates;
   -- the base travel driver separately waits for terrain readiness.
   if R.worldCardsReady(game.overworld)then ready=true;break end
  end
  assert(ready,'covered neighborhood preparation did not finish')
  while game.stack:top()and game.stack:top()~=game.overworld do game.stack:pop()end
  print('PASS_NEIGHBOR_COVERED_READY')
 end
 local Assets=require('src.render.Assets');local image=Assets.image;local calls={}
 Assets.image=function(path,...)
  local t=love.timer.getTime();local out=image(path,...)
  if tostring(path):find('/characters/',1,true)then
   calls[#calls+1]={path=path,ms=(love.timer.getTime()-t)*1000,
    map=game.overworld and game.overworld.map.id,covered=game.stack:top()~=game.overworld}
  end
  return out
 end
 local quit=love.event.quit;love.event.quit=function(...)
  local f=assert(io.open(assert(os.getenv('SHOT_DIR'))..'/character-loads.json','w'))
  f:write(assert(require('src.link.Json').encode(calls)));f:close()
  U.teleport=teleport;Assets.image=image;return quit(...)
 end
 return assert(loadfile(root..'/tests/native/rc29_model_travel.lua'))()(game)
end
