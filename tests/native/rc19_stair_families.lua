return function(game)
 assert(os.getenv('POKEPORT_IDENTITY')=='vasc-video-polish-qa')
 io.stdout:setvbuf('no');love.window.hasFocus=function()return true end;love.window.isVisible=function()return true end
 local U=require('tests.drivers.util');game:startNewGame{intro=false}
 local ex=game.mods.exports.VOXEL_ASCENDANT;assert(not os.getenv('EXPECTED_VASC_VERSION')or ex.packageVersion==os.getenv('EXPECTED_VASC_VERSION'),'wrong packed version');ex.setupCard.suspended=true
 ex.ascendantContent.promptDisabled=true;ex.ascendantContent.onboardingShown=true
 local function find(fn,name,seen)
  if type(fn)~='function'then return end;seen=seen or{};if seen[fn]then return end;seen[fn]=true
  for i=1,100 do local k,v=debug.getupvalue(fn,i);if not k then break end;if k==name then return v end end
  for i=1,100 do local k,v=debug.getupvalue(fn,i);if not k then break end;local got=find(v,name,seen);if got then return got end end
 end
 local rawUpdate=game.update;game.update=function(self,dt)return require('src.mods.Runtime').call('core.update',rawUpdate,self,dt)end
 local V=assert(find(ex.lib.require('VoxelScene').render,'V'));local P=require('src.render.Pipelines')
 V.require('PokemonModelProvider').setting:setValue('cobblemon',game)
 local dir=assert(os.getenv('SHOT_DIR'));local fp=V.require('FirstPerson')
 game.save.flags.EVENT_FOLLOWED_OAK_INTO_LAB=true;game.save.flags.EVENT_GOT_STARTER=true
 game.save.flags.EVENT_BEAT_BROCK=true;game.save.flags.EVENT_BEAT_PEWTER_GYM_TRAINER_0=true
 V.require('CalendarEvents').setting:setValue('halloween',game)
 V.require('Weather').setting:setValue('clear',game)
 V.require('DayNight').setting:setValue('night',game,true)
 love.window.setMode(1200,800,{resizable=true,vsync=0})
 local Screens=require('src.ui.Screens')
 local menu=Screens.push(game,'VascSettings',{section='pokemon'})
 for _,r in ipairs(menu.items)do
  if r.settingKey=='apo_pokemon_model_source'or r.settingKey=='apo_follower_sprite_source'or r.settingKey=='modernDexSpriteSource'then
   local owner=find(r.descriptor.step,'self_');if owner then owner:setValue('cobblemon',game,true);print('SET',r.settingKey,owner:get())end
  end
 end
 game.stack:pop()

 ex.voxelCharacterCard.setting:setValue(true,game);assert(ex.voxelCharacterCard.select('voxel',game))
 V.require('CalendarEvents').setting:setValue('off',game)
 V.require('DayNight').setting:setValue('day',game,true)


 P.setLevel('tiltshift',0);P.setLevel('voxel',1)




 local H=V.require('HorizonWall');local W=V.require('SilphWindows');local LL=V.require('LocalLights');local Scene=V.require('VoxelScene')
 local Chunk=V.require('ChunkMesher');local Neighborhood=V.require('VisibleNeighborhood')
 local json=require('src.link.Json')
 local function clean(v,seen)
  if type(v)=='function'or type(v)=='userdata'or type(v)=='thread'then return nil end
  if type(v)~='table'then return v end
  seen=seen or{};if seen[v]then return nil end;seen[v]=true
  local out={};for k,x in pairs(v)do if type(k)=='string'or type(k)=='number'then out[k]=clean(x,seen)end end;seen[v]=nil;return out
 end
 local renderedStats;local rawDraw=love.draw
 love.draw=function(...)rawDraw(...);renderedStats=love.graphics.getStats()end
 local rows={};local config={};local started=love.timer.getTime()
 local function emit(row)
  rows[#rows+1]=row
  print('RESULT_JSON '..assert(json.encode(row)))
  local f=assert(io.open(dir..'/results.json','w'));f:write(assert(json.encode({config=config,rows=rows},{indent=true})));f:close()
 end
 local function ready()
  for i=1,1000 do
   local plan=Scene.planStatus();local active=plan and plan.active
   if V.require('VoxelState').ready and active and active.rootId==game.overworld.map.id and not Chunk.hasPriorityWork()then return end
   U.wait(1)
  end
  error('readiness timeout '..game.overworld.map.id)
 end
 P.setLevel('voxel',7);LL.setting:setValue(true,game,true)
 V.require('PerformanceOverlay').enabled:setValue(false,game,true)




 local Map=require('src.world.Map');local Stairs=V.require('Gen1Stairs');local Structures=V.require('Structures')
 Stairs.setting:setValue(true,game);W.setting:setValue(true,game);P.setLevel('voxel',6)
 local delta={south={0,1},west={-1,0},north={0,-1},east={1,0}}
 local yaw={south=math.pi,west=math.pi/2,north=0,east=-math.pi/2}
 local facing={south='up',west='right',north='down',east='left'}
 local ids={};for id in pairs(game.data.maps)do ids[#ids+1]=id end;table.sort(ids)
 local total,families=0,{}
 for _,id in ipairs(ids)do
  local d=game.data.maps[id];local map=Map.new(d,game.data.tilesets[d.tileset])
  local original=table.concat(d.blocks,',')
  for _,warp in ipairs(d.warps or{})do
   local class=Stairs.classForWarp(map,warp)
   if class then
    local spec={class=class,art='stair',h=16};local S={objectQuads={}}
    assert(Stairs.buildStore(S,map,warp.x,warp.y,spec)or Stairs.buildGeneral(S,map,warp.x,warp.y,spec),'no model '..id)
    local side=S.objectQuads[1].stairEntrance;local v=assert(delta[side]);local ax,ay=warp.x+v[1],warp.y+v[2]
    -- The preferred entrance must be a real native floor, even on edge pins.
    assert(ax>=0 and ay>=0 and ax<d.width*2 and ay<d.height*2 and map:isWalkableCell(ax,ay),'blocked approach '..id)
    for _,q in ipairs(S.objectQuads)do
     assert(q.stairEntrance==side)
     -- No railing/post crosses the middle eight pixels of the entry edge.
     if q.stairPart=='rail'or q.stairPart=='post'then
      local lo,hi=math.huge,-math.huge;local near=false
      for _,p in ipairs(q)do
       local x,z=p[1]-warp.x*16,p[3]-warp.y*16
       local across=(side=='south'or side=='north')and x or z
       lo,hi=math.min(lo,across),math.max(hi,across)
       if side=='south'and z>=14 or side=='north'and z<=2 or side=='west'and x<=2 or side=='east'and x>=14 then near=true end
      end
      assert(not near or hi<=4 or lo>=12,'rail blocks entrance '..id)
     end
    end
    total=total+1;families[d.tileset]=(families[d.tileset]or 0)+1
   end
  end
  assert(table.concat(d.blocks,',')==original,'mutated native map '..id)
 end
 print('PASS_ALL_NATIVE_STAIR_GEOMETRY',total,assert(json.encode(families)))
 local driveX,driveZ=0,0;local oldMove,oldWorld=fp.moveVector,fp.moveWorld
 fp.moveVector=function()return driveX,driveZ end;fp.moveWorld=function(x,z)return x,z end
 local cases={
 {'REDS_HOUSE_1F',7,1},{'REDS_HOUSE_2F',7,1},
 {'CELADON_MANSION_1F',2,1},{'CELADON_MANSION_2F',4,1},{'CELADON_MANSION_3F',4,1},
 {'MUSEUM_1F',7,7},{'MUSEUM_2F',7,7},
 {'POKEMON_TOWER_1F',18,9},{'POKEMON_TOWER_2F',18,9},
 {'POKEMON_MANSION_1F',5,10},{'POKEMON_MANSION_2F',5,10},
 {'ROCKET_HIDEOUT_B1F',23,2},{'ROCKET_HIDEOUT_B1F',21,2},
 {'SS_ANNE_1F',2,6},{'SS_ANNE_1F',37,15},{'SS_ANNE_3F',19,3},{'SS_ANNE_CAPTAINS_ROOM',0,7},
 {'ROUTE_11_GATE_1F',6,8},{'ROUTE_11_GATE_2F',7,7},
 {'ROUTE_12_GATE_1F',8,6},{'ROUTE_12_GATE_2F',7,7},
 {'UNDERGROUND_PATH_ROUTE_5',4,4},{'UNDERGROUND_PATH_NORTH_SOUTH',5,4},{'UNDERGROUND_PATH_WEST_EAST',2,5},
 {'MT_MOON_1F',5,5},{'MT_MOON_B1F',5,5},{'MT_MOON_B1F',17,11},
 {'CERULEAN_CAVE_1F',0,6},{'CERULEAN_CAVE_2F',29,1},
 }
 local completed=0
 for _,c in ipairs(cases)do
  local id,x,y=unpack(c);print('BEGIN_NATIVE_STAIR',id,x,y)
  local d=assert(game.data.maps[id],id);local map=Map.new(d,game.data.tilesets[d.tileset]);local warp
  for _,w in ipairs(d.warps)do if w.x==x and w.y==y then warp=w;break end end
  assert(warp,'no warp '..id);local class=assert(Stairs.classForWarp(map,warp));local down=class:find('down')~=nil
  local flight=Stairs.storeFlight(map,x,y,{class=class,art='stair',h=16})or Stairs.flight(map,x,y,{class=class,art='stair',h=16})
  local side=Stairs.entrance(map,x,y,flight.preferred or 'south');local v=delta[side]
  U.teleport(game,id,x+v[1],y+v[2],facing[side]);ready();U.wait(35)
  local actual=Structures.forMap(game.overworld.map);local parts={}
  for _,q in ipairs(actual.objectQuads)do if q.stairCellX==x and q.stairCellY==y then
   parts[q.stairPart]=(parts[q.stairPart]or 0)+1;assert(q.stairEntrance==side)
  end end
  assert(parts.tread,'native stair geometry replaced/absent '..id)
  fp.yaw=yaw[side];fp.pitch=down and .65 or .20;U.wait(20)
  assert(U.shot(game,dir..'/'..id..'-'..x..'-'..y..'.png'))
  driveX,driveZ=-v[1],-v[2];local frames=0
  while game.overworld.map.id==id and frames<240 do U.wait(1);frames=frames+1 end
  driveX,driveZ=0,0
  assert(game.overworld.map.id==warp.destMap,'failed transition '..id..' -> '..tostring(game.overworld.map.id))
  ready();U.wait(5);completed=completed+1
  print('PASS_NATIVE_STAIR',id,x,y,side,warp.destMap,frames)
 end
 fp.moveVector,fp.moveWorld=oldMove,oldWorld
 print('PASS_ALL_STAIR_FAMILIES',total,completed);love.event.quit()
end
