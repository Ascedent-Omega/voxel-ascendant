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




 W.setting:setValue(true,game,true)
 local old=assert(loadfile(assert(os.getenv('BASE_PORTAL'))))(V)
 local new=V.require('SilphWindowVisibility');local Map=require('src.world.Map')
 local report={};local totals={0,0};local accepted={0,0};local precise=0
 for floor=1,11 do
  local id='SILPH_CO_'..floor..'F';local def=game.data.maps[id];local map=Map.new(def,game.data.tilesets[def.tileset])
  local profile=H.interiorProfileFor(map);local times={0,0}
  for i=1,100 do
   local eye={16+(i*13)%(def.width*32-32),i%4==0 and 80 or 25,16+(i*19)%240}
   local fns={}
   for _,index in ipairs(i%2==0 and {1,2}or{2,1})do
    local m=index==1 and old or new;local t=os.clock();fns[index]=m.forView(map,profile,eye);times[index]=times[index]+os.clock()-t
   end
   for j=1,20 do
    local x,z=j*83%800-200,j*121%700-200;local b={x,0,z,x+32,64,z+32}
    local a,b=fns[1](b),fns[2](b);-- AABB false positives need not match between differently sized cones.
    if a then accepted[1]=accepted[1]+1 end;if b then accepted[2]=accepted[2]+1 end
   end
   if i%10==0 then
    for _,p in ipairs(old.apertures(map,profile,eye,V.require('Gen1InteriorLayout').panelsFor(map,profile)))do
     local along=(p.from+p.upto)/2;local y=(p.bottom+p.top)/2
     local horizontal=p.edge=='north'or p.edge=='south'
     local x,z=horizontal and along or p.at,horizontal and p.at or along
     x,y,z=eye[1]+(x-eye[1])*2,eye[2]+(y-eye[2])*2,eye[3]+(z-eye[3])*2
     assert(fns[2]({x-.1,y-.1,z-.1,x+.1,y+.1,z+.1}),id..' visible ray rejected')
     precise=precise+1
    end
    U.wait(1)
   end
  end
  report[#report+1]={map=id,beforeCpuMs=times[1]*10,afterCpuMs=times[2]*10}
  totals[1]=totals[1]+times[1];totals[2]=totals[2]+times[2]
  print('PORTAL_CPU',id,times[1]*10,times[2]*10)
 end
 local f=assert(io.open(dir..'/portal-cpu.json','w'));f:write(assert(json.encode({rows=report,totals=totals,accepted=accepted,visibleRays=precise},{indent=true})));f:close()
 assert(totals[2]<totals[1]*.5,'portal CPU regression')
 print('PASS_PORTAL_CPU_ALL_11',totals[1],totals[2],accepted[1],accepted[2]);love.event.quit(0)
end
