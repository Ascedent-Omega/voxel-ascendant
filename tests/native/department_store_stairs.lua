return function(game)
 assert(os.getenv('POKEPORT_IDENTITY')=='vasc-video-polish-qa')
 io.stdout:setvbuf('no');love.window.hasFocus=function()return true end;love.window.isVisible=function()return true end
 local U=require('tests.drivers.util');game:startNewGame{intro=false}
 if not game.mods.exports.VOXEL_ASCENDANT then for k,v in pairs(game.mods:status())do print('STATUS',k);if type(v)=='table'then for _,r in pairs(v)do if type(r)=='table'then for a,b in pairs(r)do print(a,b)end else print(r)end end end end end
 local ex=assert(game.mods.exports.VOXEL_ASCENDANT);ex.setupCard.suspended=true;ex.ascendantContent.promptDisabled=true;ex.ascendantContent.onboardingShown=true
 local function find(fn,name,seen)
  if type(fn)~='function'then return end;seen=seen or{};if seen[fn]then return end;seen[fn]=true
  for i=1,100 do local k,v=debug.getupvalue(fn,i);if not k then break end;if k==name then return v end end
  for i=1,100 do local k,v=debug.getupvalue(fn,i);if not k then break end;local got=find(v,name,seen);if got then return got end end
 end
 local raw=game.update;game.update=function(self,dt)return require('src.mods.Runtime').call('core.update',raw,self,dt)end
 local V=assert(find(ex.lib.require('VoxelScene').render,'V'));local P=require('src.render.Pipelines');local H=V.require('HorizonWall');local fp=V.require('FirstPerson')
 V.require('CalendarEvents').setting:setValue('off',game);V.require('Weather').setting:setValue('clear',game);V.require('DayNight').setting:setValue('day',game,true)
 game.save.flags.EVENT_FOLLOWED_OAK_INTO_LAB=true;game.save.flags.EVENT_GOT_STARTER=true
 love.window.setMode(1280,800,{vsync=1});P.setLevel('tiltshift',0);P.setLevel('voxel',1)
 local out=assert(os.getenv('VASC_STAIR_OUTPUT'))..'/evidence/';local label=os.getenv('STAIR_LABEL')or 'overhaul-before'
 local function ready()
  for i=1,3000 do local s=H.cacheStatus(game.overworld);assert(not s.failed);if s.ready then U.wait(30);return end;U.wait(1)end;error('timeout')
 end

 local stairs=V.require('Gen1Stairs');local cells=V.require('Gen1StairCells')
 local total=0
 for _,id in ipairs({'CELADON_MART_1F','CELADON_MART_2F','CELADON_MART_3F','CELADON_MART_4F','CELADON_MART_5F','CELADON_MART_ROOF'})do
  U.teleport(game,id,14,3,'up');ready()
  local map=game.overworld.map;local structure=V.require('Structures').forMap(map);local nosings=0;for _,q in ipairs(structure.objectQuads)do if q.storeStair=='nosing'then nosings=nosings+1 end end
  assert(nosings==(id=='CELADON_MART_ROOF'and 0 or id=='CELADON_MART_1F'and 5 or 10),'scene geometry '..id..' '..nosings)
  print('SCENE_GEOMETRY_PASS',id,nosings)
  local warps={};local originalBlocks=table.concat(map.def.blocks,',')
  for _,w in ipairs(map.def.warps)do if cells.classForWarp(map,w) then warps[#warps+1]=w end end
  assert(#warps==((id=='CELADON_MART_1F' or id=='CELADON_MART_ROOF')and 1 or 2))
  for _,w in ipairs(warps)do
   U.teleport(game,id,w.x,w.y+1,'up');ready()
   local m=game.overworld.map
   P.setLevel('voxel',6);fp.yaw=math.pi;fp.pitch=.5;ready();U.wait(60)
   assert(U.shot(game,out..id..'-'..w.x..'-entry.png'))
   P.setLevel('voxel',1);U.wait(3)
   local q={objectQuads={}};local class=cells.classForWarp(m,w)
   assert(stairs.buildStore(q,m,w.x,w.y,{class=class}));assert(#q.objectQuads<125,'mesh budget '..#q.objectQuads)
   assert(table.concat(m.def.blocks,',')==originalBlocks,'blocks modified')
   for i=1,180 do
    if game.overworld.map.id~=id then break end
    U.hold(game,'up',1)
   end
   game.input.state.up=false
   if game.overworld.map.id~=w.destMap then local ow=game.overworld;print('FAILED_STATE',ow.player.cellX,ow.player.cellY,ow.player.moving,game.stack:top()==ow);for k,v in pairs(ow)do if type(v)=='boolean'or type(v)=='number'or type(v)=='string'then print('OW',k,v)end end;assert(U.shot(game,out..'warp-failure.png'))end
   assert(game.overworld.map.id==w.destMap,'warp failed '..id..' -> '..w.destMap..' got '..game.overworld.map.id)
   U.wait(150);total=total+1;print('WARP_PASS',id,w.x,w.y,w.destMap)
  end
 end
 assert(total==10);print('NATIVE_STAIRS_PASS',total);love.event.quit()
end
