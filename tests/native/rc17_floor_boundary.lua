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
   if V.require('VoxelState').ready and active and active.rootId==game.overworld.map.id and not Chunk.hasPriorityWork()and H.cacheStatus{map=game.overworld.map,neighbors={}}.ready then return end
   U.wait(1)
  end
  error('readiness timeout '..game.overworld.map.id)
 end
 P.setLevel('voxel',7);LL.setting:setValue(true,game,true)
 V.require('PerformanceOverlay').enabled:setValue(false,game,true)



 local maps={};for n=1,11 do maps[#maps+1]='SILPH_CO_'..n..'F'end
 for n=1,5 do maps[#maps+1]='CELADON_MART_'..n..'F'end
 local fp=V.require('FirstPerson');local camera
 local oldFrame=fp.frame
 fp.frame=function(me,...)
  if camera then me={px=camera.x-8,py=camera.z-8,gh=0,lift=0}end
  return oldFrame(me,...)
 end
 for _,id in ipairs(maps)do
  camera=nil;P.setLevel('voxel',6);U.teleport(game,id,3,4,'up');ready();U.wait(10)
  local map=game.overworld.map;local S=V.require('Structures').forMap(map)
  local mask=assert(S.interiorFloorTiles,id..' missing clipped floor')
  local beforeBlocks=table.concat(map.def.blocks,',')
  S.interiorFloorTiles=nil;local before=Chunk.geometry(map,true)
  S.interiorFloorTiles=mask;local after=Chunk.geometry(map,true)
  local function key(x,z)return(z/8+64)*4096+x/8+64 end
  local function overhang(vertices)
   local count=0
   for i=1,#vertices,4 do
    local a,b,c,d=vertices[i],vertices[i+1],vertices[i+2],vertices[i+3]
    if a and b and c and d and a[2]==0 and b[2]==0 and c[2]==0 and d[2]==0
     and b[1]-a[1]==8 and c[3]-b[3]==8 and d[1]==a[1]and d[3]==c[3]
     and a[1]%8==0 and a[3]%8==0 and not mask[key(a[1],a[3])]then count=count+1 end
   end
   return count
  end
  local old,new=overhang(before),overhang(after)
  assert(old>0,id..' failed to reproduce old overhang');assert(new==0,id..' floor still outside walls '..new)
  assert(#after<#before,id..' excess floor still emitted')
  for _,w in ipairs(map.def.warps or{})do if map:isWalkableCell(w.x,w.y)then
   for dy=0,1 do for dx=0,1 do assert(mask[key(w.x*16+dx*8,w.y*16+dy*8)],id..' warp floor removed')end end
  end end
  assert(table.concat(map.def.blocks,',')==beforeBlocks)
  print('FLOOR_PASS',id,old,new,#before-#after)
  local b=V.require('Gen1RoomBounds').forMap(map)
  camera={x=b.west+24,z=b.south-24};fp.yaw=-math.pi*.75;fp.pitch=.85;U.wait(5)
  assert(U.shot(game,dir..'/'..id..'-floor.png'))
  P.setLevel('voxel',3);U.wait(10);assert(U.shot(game,dir..'/'..id..'-orbit.png'))
 end
 print('PASS_FLOOR_OVERHANG',#maps);love.event.quit(0)
end
