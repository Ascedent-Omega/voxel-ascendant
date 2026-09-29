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




 local A=V.require('RetailAisles');local Items=V.require('VoxelItems')
 P.setLevel('voxel',7)
 local targetX,targetZ;local move=fp.moveVector;local worldMove=fp.moveWorld
 fp.moveWorld=function(mx,mz)return -mx,mz end
 fp.moveVector=function()
  if not targetX then return 0,0 end
  local p=game.overworld.player
  local function step(v)return math.max(-1,math.min(1,v))end
  return -step(targetX-p.px),step(targetZ-p.py)
 end
 local function walkTo(x,y)
  targetX,targetZ=x*16,y*16
  for i=1,240 do
   local p=game.overworld.player
   if math.abs(p.px-targetX)<.01 and math.abs(p.py-targetZ)<.01 then break end
   U.wait(1)
  end
  targetX,targetZ=nil,nil
  local p=game.overworld.player
  assert(math.abs(p.px-x*16)<.01 and math.abs(p.py-y*16)<.01,
   'walk blocked '..game.overworld.map.id..' target '..x..','..y..' actual '..(p.px/16)..','..(p.py/16))
 end
 local total=0
 for floor=2,5 do
  local id='CELADON_MART_'..floor..'F';U.teleport(game,id,5,5,'down');ready();U.wait(40)
  local ow=game.overworld;local map=ow.map;local targets={}
  local function open(x,y)return map:inBounds(x,y)and (map:isWalkableCell(x,y)or A.permission(ow,x,y))and not map:warpAtCell(x,y)and not ow:npcAtCell(x,y)end
  for y=0,7 do for x=0,19 do
   if not map:isWalkableCell(x,y)and A.permission(ow,x,y)then targets[#targets+1]={x,y}end
  end end
  assert(floor==3 and #targets==0 or floor~=3 and #targets>0,'unexpected public/staff aisle classification '..id)
  local function pathTo(tx,ty)
   local start=ow.player.cellY*20+ow.player.cellX;local goal=ty*20+tx
   local queue,parent={start},{[start]=start};local head=1
   while head<=#queue and not parent[goal]do
    local k=queue[head];head=head+1;local x,y=k%20,math.floor(k/20)
    for _,d in ipairs{{0,-1},{-1,0},{1,0},{0,1}}do local nx,ny=x+d[1],y+d[2];local nk=ny*20+nx
     if not parent[nk]and open(nx,ny)then parent[nk]=k;queue[#queue+1]=nk end
    end
   end
   if not parent[goal]then
    for y=0,7 do local row={};for x=0,19 do row[#row+1]=ow:npcAtCell(x,y)and'N'or A.permission(ow,x,y)and'f'or map:isWalkableCell(x,y)and'.'or'#'end;print('PATH_GRID',y,table.concat(row))end
    print('PATH_START',ow.player.cellX,ow.player.cellY)
   end
   assert(parent[goal],'window aisle unreachable '..id..' '..tx..','..ty)
   local path={};local k=goal;while k~=start do table.insert(path,1,{k%20,math.floor(k/20)});k=parent[k]end
   return path
  end
  for _,target in ipairs(targets)do
   for _,cell in ipairs(pathTo(unpack(target)))do
    fp.yaw=0
    assert(math.abs(cell[1]-ow.player.cellX)+math.abs(cell[2]-ow.player.cellY)==1,'non-adjacent walking step')
    walkTo(cell[1],cell[2])
    assert(ow.player.cellX==cell[1]and ow.player.cellY==cell[2],
     'window aisle walk blocked '..id..' '..cell[1]..','..cell[2]..' actual '..ow.player.cellX..','..ow.player.cellY)
   end
   assert(not map:isWalkableCell(ow.player.cellX,ow.player.cellY),'test skipped new aisle')
   assert(Scene.groundAt(map,ow.player.cellX,ow.player.cellY)==0,'aisle retained native rack elevation')
   total=total+1
  end
  print('PASS_WINDOW_AISLE_WALK',id,#targets)
  P.setLevel('voxel',6);fp.yaw=-math.pi/2;fp.pitch=.06;U.wait(40)
  U.shot(game,dir..'/'..id..'-window-aisle.png');P.setLevel('voxel',7)
 end
 -- Walk the reported window-side passage end to end, in both cameras.
 -- Checking isolated released cells alone does not prove a continuous aisle.
 U.teleport(game,'CELADON_MART_5F',16,5,'right');ready();U.wait(4)
 local ow=game.overworld
 fp.yaw=0;walkTo(19,5)
 assert(ow.player.cellX==19 and ow.player.cellY==5,'cannot enter window-side aisle')
 for _,level in ipairs{6,7}do
  P.setLevel('voxel',level);fp.yaw=math.pi;fp.pitch=.18;U.wait(30)
  walkTo(19,2)
  assert(ow.player.cellX==19 and ow.player.cellY==2,'window aisle blocked northbound')
  fp.yaw=0;U.wait(30)
  U.shot(game,dir..'/5F-window-passage-'..level..'.png')
  walkTo(19,7)
  assert(ow.player.cellX==19 and ow.player.cellY==7,'window aisle blocked southbound')
  walkTo(19,5)
  assert(ow.player.cellX==19 and ow.player.cellY==5,'cannot return through window aisle')
  print('PASS_WINDOW_AISLE_CONTINUOUS',level,19,2,7)
 end
 -- Enter the previously blocked back row of the reported fifth floor.
 U.teleport(game,'CELADON_MART_5F',9,7,'right');ready();U.wait(4);fp.yaw=0
 walkTo(11,7)
 local ow=game.overworld
 assert(not ow.map:isWalkableCell(ow.player.cellX,ow.player.cellY)and A.permission(ow,ow.player.cellX,ow.player.cellY),'did not enter released shelf footprint')
 P.setLevel('voxel',0);U.wait(4)
 assert(require('src.render.Pipelines').worldPipeline()~='voxel')
 assert(ow.map:isWalkableCell(ow.player.cellX,ow.player.cellY),'vanilla switch trapped player')
 print('PASS_WINDOW_AISLE_VANILLA_RETURN',ow.player.cellX,ow.player.cellY)
 P.setLevel('voxel',7);U.teleport(game,'CELADON_MART_5F',9,7,'right');ready();U.wait(4);fp.yaw=0
 walkTo(11,7)
 assert(A.permission(ow,ow.player.cellX,ow.player.cellY));Items.setting:setValue(false,game,true);U.wait(4)
 assert(ow.map:isWalkableCell(ow.player.cellX,ow.player.cellY),'items OFF trapped player')
 Items.setting:setValue(true,game,true)
 print('PASS_WINDOW_AISLE_ITEMS_OFF_RETURN')
 fp.moveVector=move;fp.moveWorld=worldMove;print('PASS_WINDOW_AISLES',total);love.event.quit()
end
