return function(game)
 assert(os.getenv('POKEPORT_IDENTITY')=='vasc-video-polish-qa')
 love.audio.setVolume(0)
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
 V.require('VoxelGrid').setting:setValue(false,game,true)
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




 local Layout=V.require('Gen1InteriorLayout');local Furniture=V.require('VoxelFurniture')
 W.setting:setValue(true,game,true);P.setLevel('voxel',6)
 local frame=fp.frame;local rigSpec
 fp.frame=function(...)
  local rig,x,z=frame(...)
  if rig and rigSpec then rig.eye=rigSpec.eye;rig.focus=rigSpec.focus;rig.fov=rigSpec.fov or .9;return rig,rigSpec.focus[1],rigSpec.focus[3]end
  return rig,x,z
 end
 local ids={};for n=1,11 do ids[#ids+1]='SILPH_CO_'..n..'F'end
 for _,id in ipairs{'POKEMON_MANSION_1F','POKEMON_MANSION_2F','POKEMON_MANSION_3F','POKEMON_MANSION_B1F','POWER_PLANT',
 'CELADON_MART_1F','CELADON_MART_2F','CELADON_MART_3F','CELADON_MART_4F','CELADON_MART_5F'}do ids[#ids+1]=id end
 local checked=0
 for _,id in ipairs(ids)do
  if not os.getenv('INTERIOR_FILTER')or id:match(os.getenv('INTERIOR_FILTER'))then
  print('BEGIN_ROOM',id)
  checked=checked+1
  local d=game.data.maps[id];local m=require('src.world.Map').new(d,game.data.tilesets[d.tileset])
  local px,py
  for y=2,d.height*2-2 do for x=2,d.width*2-2 do if not px and m:isWalkableCell(x,y)and not m:warpAtCell(x,y)then px,py=x,y end end end
  assert(px);local w,h=d.width*32,d.height*32
  rigSpec={eye={w/2,math.max(w,h)*.92,h*1.08},focus={w/2,0,h*.42},fov=.94}
  U.teleport(game,id,px,py,'up');ready();U.wait(45)
  local profile=H.interiorProfileFor(game.overworld.map);local panels=profile and Layout.panelsFor(game.overworld.map,profile)or{}
  local doors=0
  for i,p in ipairs(panels)do
   for _,o in ipairs(p.openings)do if not o.open then doors=doors+1 end end
   for j=i+1,#panels do local q=panels[j]
    local ph=p.edge=='north'or p.edge=='south';local qh=q.edge=='north'or q.edge=='south'
    assert(not(ph==qh and p.at==q.at and p.from<q.upto and q.from<p.upto),'duplicate wall plane '..id)
   end
  end
  local props={};for _,p in ipairs(Furniture.find(game.overworld.map))do props[p.kind]=(props[p.kind]or 0)+1 end
  if id:match('^POKEMON_MANSION_')then
   local claims={};local count=0
   for _,p in ipairs(Furniture.find(game.overworld.map))do
    if p.kind:match('^mansion_shaft_rail_')then
     assert(p.claimed,'unclaimed shaft rail '..p.kind)
     for dy=0,p.h-1 do for dx=0,p.w-1 do
      local x,y=p.tx+dx,p.ty+dy;local t=m:tileAt(x,y)
      assert(t==64 or t==65 or t==80 or t==81,'rail replaces a native hole or floor')
      claims[y*1000+x]=true;count=count+1
     end end
    end
   end
   local expected=0
   for y=0,d.height*4-1 do for x=0,d.width*4-1 do
    local t=m:tileAt(x,y)
    if t==64 or t==65 or t==80 or t==81 then
     assert(claims[y*1000+x],'unreplaced shaft railing at '..x..','..y);expected=expected+1
    end
   end end
   assert(count==expected);print('SHAFT_RAIL_COVERAGE',id,count)
  end
  print('ROOM',id,#panels,doors,json.encode(props))
  while game.stack:top()~=game.overworld do game.stack:pop()end
  U.wait(1)
  assert(U.shot(game,dir..'/'..id..'-overview.png'))
  -- Inspect below the real ceiling as well: an above-roof screenshot cannot
  -- establish whether partitions or furniture are correct inside this room.
  for i,q in ipairs{{.25,.25},{.75,.25},{.25,.75},{.75,.75}}do
   local bx,by,best
   for cy=2,d.height*2-2 do for cx=2,d.width*2-2 do
    if m:isWalkableCell(cx,cy)and not m:warpAtCell(cx,cy)then
     local score=(cx*16+8-w*q[1])^2+(cy*16+8-h*q[2])^2
     if not best or score<best then bx,by,best=cx,cy,score end
    end
   end end
   local x,z=bx*16+8,by*16+8;local dx,dz=w/2-x,h/2-z
   local length=math.max(1,math.sqrt(dx*dx+dz*dz));dx,dz=dx/length,dz/length
   -- A quadrant can lie immediately beside a partition. Look along its
   -- usable floor rather than filling the entire evidence image with plaster.
   local aimX,aimZ,aimScore=dx,dz,-1
   for angle=0,15 do
    local ax,az=math.cos(angle*math.pi/8),math.sin(angle*math.pi/8)
    local clear=0
    for dist=4,128,4 do
     if not m:isWalkableCell(math.floor((x+ax*dist)/16),math.floor((z+az*dist)/16))then break end
     clear=dist
    end
    local score=clear+(ax*dx+az*dz)*2
    if score>aimScore then aimX,aimZ,aimScore=ax,az,score end
   end
   rigSpec={eye={x,25,z},focus={x+aimX*64,20,z+aimZ*64},fov=1.2}
   print('INTERIOR_VIEW',id,i,bx,by,aimScore)
   U.wait(3);assert(U.shot(game,dir..'/'..id..'-inside-'..i..'.png'))
  end
  if id=='POKEMON_MANSION_2F'then
   rigSpec={eye={208,25,400},focus={248,15,440},fov=1.2}
   U.wait(3);assert(U.shot(game,dir..'/'..id..'-rail-corner.png'))
   local Items=V.require('VoxelItems')
   Items.setting:setValue(false,game);U.wait(45);ready()
   for _,p in ipairs(Furniture.find(game.overworld.map))do
    if p.kind:match('^mansion_shaft_rail_')then assert(not p.claimed,'rail still claimed with objects OFF')end
   end
   assert(U.shot(game,dir..'/'..id..'-rail-off.png'))
   Items.setting:setValue(true,game);U.wait(45);ready()
  end
  if id:match('^SILPH_CO_')then
   for _,warp in ipairs(d.warps)do
    if warp.destMap=='SILPH_CO_ELEVATOR'then
     local x,z=warp.x*16+8,warp.y*16+8
     rigSpec={eye={x-22,25,z+58},focus={x,20,z-3},fov=1.1};U.wait(20)
     assert(U.shot(game,dir..'/'..id..'-lift.png'))
    end
   end
  end
  end
 end
 fp.frame=frame;print('PASS_NATIVE_INTERIOR_AUDIT',checked);love.event.quit()
end
