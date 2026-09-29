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



 local Layout=V.require('Gen1InteriorLayout');local F=V.require('VoxelFurniture')
 local camera;local oldFrame=fp.frame
 fp.frame=function(me,...)
  if camera then me={px=camera.x-8,py=camera.z-8,gh=0,lift=0}end
  return oldFrame(me,...)
 end
 local maps={};for floor=1,11 do maps[#maps+1]='SILPH_CO_'..floor..'F'end
 for _,id in ipairs{'POKEMON_MANSION_1F','POKEMON_MANSION_2F','POKEMON_MANSION_3F','POKEMON_MANSION_B1F','POWER_PLANT','ROCKET_HIDEOUT_B1F','ROCKET_HIDEOUT_B2F','ROCKET_HIDEOUT_B3F','ROCKET_HIDEOUT_B4F','CELADON_MANSION_1F','CELADON_MANSION_2F','CELADON_MANSION_3F'}do maps[#maps+1]=id end
 local all={}
 -- Check every supported native interior, beyond the photographed families.
 local Map=require('src.world.Map');local profiles=V.require('Gen1InteriorPanoramas').profiles
 local checked=0
 for id,profile in pairs(profiles)do
  local source=assert(game.data.maps[id],id)
  local def={};for k,v in pairs(source)do def[k]=v end
  def.blocks={};for i,v in ipairs(source.blocks)do def.blocks[i]=v end
  local map=Map.new(def,game.data.tilesets[def.tileset])
  for pass=1,2 do
   local panels=Layout.panelsFor(map,profile)
   for i,p in ipairs(panels)do
    assert(p.upto>p.from and p.at==p.at,id..' invalid panel')
    for _,o in ipairs(p.openings)do assert(o.from>=p.from and o.upto<=p.upto and o.height>0 and o.height<profile.shellHeight,id..' invalid opening')end
    for j=1,i-1 do local q=panels[j]
     local horizontal=p.edge=='north'or p.edge=='south';local qHorizontal=q.edge=='north'or q.edge=='south'
     assert(not(horizontal==qHorizontal and p.at==q.at and math.min(p.upto,q.upto)>math.max(p.from,q.from)),id..' duplicate coplanar wall')
    end
   end
   if pass==1 then
    local spec=V.require('Gen1SecurityDoors').specs[id]
    if spec then for _,slot in ipairs(spec[3])do map:setBlock(slot[1],slot[2],spec[4]and 3 or 14)end end
   end
  end
  checked=checked+1
 end
 print('PASS_ALL_PROFILE_LAYOUTS',checked,'closed/open security blocks')
 if os.getenv('QA_LAYOUT_ONLY')then love.event.quit(0);return end
 V.require('AntiAlias').resolution:setValue('balanced',game,true)
 for _,id in ipairs(maps)do
  camera=nil;P.setLevel('voxel',6);U.teleport(game,id,3,4,'up');ready();U.wait(20)
  local map=game.overworld.map;local profile=assert(H.interiorProfileFor(map),id)
  local panels=Layout.panelsFor(map,profile);local w,d=map.def.width*32,map.def.height*32
  local props=F.find(map);local covered={};local count=0
  for _,p in ipairs(props)do if p.claimed then
   for y=p.ty,p.ty+p.h-1 do for x=p.tx,p.tx+p.w-1 do covered[y*w/8+x]=p.kind end end
   if p.kind:find('table')or p.kind:find('desk')then count=count+1 end
  end end
  if id:match('^SILPH_CO_')then
   if map.def.tileset=='FACILITY'then
    for y=0,d/8-1 do for x=0,w/8-1 do
     if map:tileAt(x,y)==53 then assert(covered[y*w/8+x],id..' native table left at '..x..','..y)end
    end end
   end
   local columns=0;for _,p in ipairs(panels)do if p.column then columns=columns+1 end end
   assert(columns==8,id..' missing corner pier face: '..columns)
   for _,a in ipairs(W.apertures(map,profile.shellHeight))do assert(a.from==8 and a.upto==((a.edge=='north'or a.edge=='south')and w-8 or d-8))end
  end
  local tiles={};for y=0,d/8-1 do tiles[y+1]={};for x=0,w/8-1 do tiles[y+1][x+1]=map:tileAt(x,y)end end
  all[id]={panels=panels,tiles=tiles,tables=count}
  -- Photograph every actual capped end from its outward side. Synthetic
  -- positions never become the saved/native player position.
  for _,windows in ipairs{true,false}do
   W.setting:setValue(windows,game);ready();U.wait(8)
   local prefix=id..'-'..(windows and'on'or'off')
   for i,p in ipairs(panels)do if p.endcap then
    local horizontal=p.edge=='north'or p.edge=='south'
    local sign=(p.edge=='north'or p.edge=='west')and 1 or -1
    local along=(p.from+p.upto)/2;local across=p.at+sign*24
    camera={x=horizontal and along or across,z=horizontal and across or along}
    if camera.x>8 and camera.x<w-8 and camera.z>8 and camera.z<d-8 then
     fp.yaw=horizontal and(sign<0 and 0 or math.pi)or(sign<0 and math.pi/2 or -math.pi/2);fp.pitch=0
     U.wait(2);assert(U.shot(game,dir..'/'..prefix..'-cap'..i..'.png'))
    end
   end end
   camera={x=w*.5,z=d*.5};fp.yaw=-math.pi*.75;fp.pitch=0;U.wait(3)
   assert(U.shot(game,dir..'/'..prefix..'-room.png'))
   if id:match('^SILPH_CO_')then
    camera={x=w-40,z=d-40};fp.yaw=math.pi*.25;fp.pitch=0;U.wait(3)
    assert(U.shot(game,dir..'/'..prefix..'-corner.png'))
   end
  end
  camera=nil;W.setting:setValue(true,game);ready()
  P.setLevel('voxel',3);U.wait(25);assert(U.shot(game,dir..'/'..id..'-orbit.png'))
  print('AUDIT_MAP',id,#panels,count)
 end
 local f=assert(io.open(dir..'/layouts.json','w'));f:write(assert(json.encode(all)));f:close()
 print('PASS_ALL_INTERIOR_AUDIT');love.event.quit(0)
end
