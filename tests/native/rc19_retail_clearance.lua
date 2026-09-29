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



 local Items=V.require('VoxelItems');local Furniture=V.require('VoxelFurniture')
 P.setLevel('voxel',6)
 local driveX,driveZ=0,0;local move=fp.moveVector
 fp.moveVector=function()return -driveX,driveZ end
 for floor=1,5 do
  local id='CELADON_MART_'..floor..'F';U.teleport(game,id,5,5,'down');ready();U.wait(50)
  local map=game.overworld.map;local checked,walked=0,0
  local tested={}
  for _,p in ipairs(Furniture.find(map))do if p.kind:match('^retail_')and p.kind~='retail_checkout'then
   local m=assert(Items.models[p.kind]);local loX,loZ,hiX,hiZ=math.huge,math.huge,-math.huge,-math.huge
   for _,b in ipairs(m.boxes)do
    for i=1,6 do assert(b[i]==math.floor(b[i]),'fractional shelf voxel')end
    loX=math.min(loX,b[1]);loZ=math.min(loZ,b[3]);hiX=math.max(hiX,b[1]+b[4]);hiZ=math.max(hiZ,b[3]+b[6])
   end
   assert(hiX-loX<=20 and hiZ-loZ<=16,'rack still too wide')
   local cx,cy=p.tx/2,p.ty/2
   for y=cy-1,cy+2 do for x=cx-1,cx+2 do
    if map:inBounds(x,y)and map:isWalkableCell(x,y)then
     local nearestX=math.max(p.tx*8+loX,math.min(x*16+8,p.tx*8+hiX))
     local nearestZ=math.max(p.ty*8+loZ,math.min(y*16+8,p.ty*8+hiZ))
     assert((nearestX-(x*16+8))^2+(nearestZ-(y*16+8))^2>5.5^2,'shelf blocks native aisle')
    end
   end end
   checked=checked+1
   for _,a in ipairs{{cx-1,cy,0,1},{cx+2,cy,0,1},{cx,cy-1,1,0},{cx,cy+2,1,0}}do
    local x,y,dx,dz=unpack(a);local key=table.concat(a,':')
    if not tested[key]and map:inBounds(x,y)and map:inBounds(x+dx,y+dz)
     and map:isWalkableCell(x,y)and map:isWalkableCell(x+dx,y+dz)
     and not map:warpAtCell(x,y)and not map:warpAtCell(x+dx,y+dz)
     and not game.overworld:npcAtCell(x,y)and not game.overworld:npcAtCell(x+dx,y+dz)then
      tested[key]=true
      U.teleport(game,id,x,y,'down');ready();U.wait(2);fp.yaw=0
      local px,pz=game.overworld.player.px,game.overworld.player.py
      driveX,driveZ=dx,dz;U.wait(20);driveX,driveZ=0,0
      local progress=(game.overworld.player.px-px)*dx+(game.overworld.player.py-pz)*dz
      assert(progress>=12,'aisle walk blocked '..id..' '..key..' distance '..progress)
      walked=walked+1
    end
   end
  end end
  if floor>1 then assert(checked>0 and walked>0,'missing shelf audit '..id)end
  U.teleport(game,id,5,5,'down');ready();fp.yaw=math.pi/2;fp.pitch=.1;U.wait(3)
  U.shot(game,dir..'/'..id..'-slender.png')
  print('PASS_RETAIL_CLEARANCE',id,checked,walked)
 end
 fp.moveVector=move;print('PASS_RETAIL_WALK');love.event.quit()
end
