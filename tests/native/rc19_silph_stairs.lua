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
 Stairs.setting:setValue(true,game);W.setting:setValue(true,game)




 P.setLevel('voxel',6)
 local driveZ=0;local oldMove,oldWorld=fp.moveVector,fp.moveWorld
 fp.moveVector=function()return 0,driveZ end;fp.moveWorld=function(x,z)return x,z end
 local total=0
 for n=1,11 do
  local id='SILPH_CO_'..n..'F';local d=game.data.maps[id]
  local map=Map.new(d,game.data.tilesets[d.tileset]);local original=table.concat(d.blocks,',')
  local S=Structures.forMap(map);assert(table.concat(d.blocks,',')==original,'geometry mutated native layout')
  for _,warp in ipairs(d.warps)do
   local shaft=Stairs.silphShaft(map,warp)
   if shaft then
    total=total+1;local parts={};local minimum,maximum=0,0
    for _,q in ipairs(S.objectQuads)do if q.stairCellX==warp.x and q.stairCellY==warp.y then
     parts[q.stairPart]=(parts[q.stairPart]or 0)+1
     assert(q.stairEntrance=='south')
     for _,v in ipairs(q)do
      assert(v[1]>=shaft.from and v[1]<=shaft.upto and v[3]>=shaft.back and v[3]<=shaft.mouth,'shaft footprint')
      minimum=math.min(minimum,v[2]);maximum=math.max(maximum,v[2])
     end
    end end
    assert(parts.tread==16 and parts['shaft-roof']==1,'missing full flight '..id)
    assert(shaft.down and minimum==-52 or not shaft.down and maximum==80,'not full-storey')
    local profile=V.require('Gen1InteriorPanoramas').profiles[id]
    local aperture=false
    for _,p in ipairs(V.require('Gen1InteriorLayout').panelsFor(map,profile))do
     if p.edge=='north'and p.at==0 then for _,o in ipairs(p.openings)do
      if o.stair and o.from<=shaft.from and o.upto>=shaft.upto and o.height==50 then aperture=true end
     end end
    end
    assert(aperture,'narrow/low stair portal '..id)
    for _,a in ipairs(W.apertures(map,50))do
     assert(a.edge~='north'or a.upto<=shaft.from or a.from>=shaft.upto,'glass across shaft')
    end
    U.teleport(game,id,warp.x,1,'up');ready();U.wait(40)
    fp.yaw=math.pi;fp.pitch=shaft.down and .65 or .10;U.wait(35)
    assert(U.shot(game,dir..'/'..id..(shaft.down and '-down' or '-up')..'.png'))
    driveZ=-1
    local frames=0
    while game.overworld.map.id==id and frames<240 do U.wait(1);frames=frames+1 end
    driveZ=0
    assert(game.overworld.map.id==warp.destMap,'stair transition failed '..id)
    ready();U.wait(5)
    print('PASS_SILPH_SHAFT',id,warp.x,shaft.down and 'down'or'up',warp.destMap,frames)
   end
  end

 end
 fp.moveVector=oldMove;fp.moveWorld=oldWorld;assert(total==20);print('PASS_ALL_SILPH_SHAFTS',total);love.event.quit()
end
