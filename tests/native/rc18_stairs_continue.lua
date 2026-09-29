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
   if V.require('VoxelState').ready and active and active.rootId==game.overworld.map.id and not Chunk.hasPriorityWork()then return end
   U.wait(1)
  end
  error('readiness timeout '..game.overworld.map.id)
 end
 P.setLevel('voxel',7);LL.setting:setValue(true,game,true)
 V.require('PerformanceOverlay').enabled:setValue(false,game,true)




 local Map=require('src.world.Map');local Stairs=V.require('Gen1Stairs');local Structures=V.require('Structures')
 Stairs.setting:setValue(true,game);W.setting:setValue(true,game)
 local count,flights=0,0
 for id,profile in pairs(V.require('Gen1InteriorPanoramas').profiles)do
  local def=game.data.maps[id];local map=Map.new(def,game.data.tilesets[def.tileset]);local original=table.concat(def.blocks,',')
  local S=Structures.forMap(map);local parts=0
  for _,q in ipairs(S.objectQuads or{})do if q.stairPart then
   parts=parts+1
   for j=1,4 do assert(q[j][1]==q[j][1] and q[j][2]==q[j][2] and q[j][3]==q[j][3],id)end
  end end
  assert(table.concat(def.blocks,',')==original,id..' mutated native map')
  if parts>0 then flights=flights+1;print('STAIR_MODEL',id,parts)end
  count=count+1;if count%12==0 then U.wait(1)end
 end
 print('PASS_ALL_NATIVE_STAIR_PROFILES',count,flights)
 P.setLevel('voxel',6);P.setLevel('tiltshift',0);V.require('AntiAlias').resolution:setValue('balanced',game,true)
 love.window.setMode(1000,700,{vsync=1})
 for _,id in ipairs{'SILPH_CO_1F','SILPH_CO_6F','SILPH_CO_11F','CELADON_MART_2F','REDS_HOUSE_1F','POKEMON_MANSION_1F'}do
  local d=game.data.maps[id];assert(d,id)
  local map=Map.new(d,game.data.tilesets[d.tileset]);local S=Structures.forMap(map);local q
  for _,face in ipairs(S.objectQuads)do if face.stairPart=='landing' then q=face;break end end
  assert(q,id..' no modern stair')
  local x,z=0,0;for j=1,4 do x=x+q[j][1]/4;z=z+q[j][3]/4 end
  local delta=({south={0,1},west={-1,0},north={0,-1},east={1,0}})[q.stairEntrance]
  local cx,cy=math.floor(x/16)+delta[1],math.floor(z/16)+delta[2]
  assert(map:isWalkableCell(cx,cy),id..' blocked approach')
  U.teleport(game,id,cx,cy,'up');ready();U.wait(45)
  local room=V.require('CurrentRoom').prepare(game.overworld)
  assert(not room or not room.mesh,id..' synthetic curtain closes native stair opening')
  fp.yaw=({south=math.pi,north=0,west=math.pi/2,east=-math.pi/2})[q.stairEntrance];fp.pitch=.85
  U.wait(3);assert(U.shot(game,dir..'/'..id..'-stairs.png'))
  fp.pitch=.15;U.wait(3);assert(U.shot(game,dir..'/'..id..'-headroom.png'))
  print('PASS_STAIR_SCENE',id,q.stairEntrance)
 end
 -- Exercise the actual title callback, using only this isolated QA identity.
 U.teleport(game,'SILPH_CO_6F',17,5,'down');ready();U.wait(3)
 game.save.player.map='SILPH_CO_6F';game.save.player.x=17;game.save.player.y=5
 assert(require('src.core.SaveData').save(game.save,game.modStatus.loaded))
 game:returnToTitle();U.wait(3)
 H.invalidate();Chunk.invalidate('SILPH_CO_6F')
 local title=game.stack:top();assert(type(title.onContinue)=='function');title.onContinue()
 local cover=game.stack:top();assert(cover.vascContinue and not cover.drawn)
 U.wait(1);assert(U.shot(game,dir..'/continue-loading.png'))
 local start=love.timer.getTime();local frames=0
 while game.stack:top()~=game.overworld and frames<2400 do U.wait(1);frames=frames+1 end
 assert(game.stack:top()==game.overworld,'Continue preparation stuck')
 assert(game.overworld.map.id=='SILPH_CO_6F','Continue changed saved destination')
 assert(Scene.readyForReveal(game.overworld),'Continue released incomplete scene')
 assert(not V.require('LoadingCompanion').status().visible)
 assert(U.shot(game,dir..'/continue-ready.png'))
 print('PASS_NATIVE_CONTINUE',frames,love.timer.getTime()-start,game.overworld.map.id)
 love.event.quit(0)
end
