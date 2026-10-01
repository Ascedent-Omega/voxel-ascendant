return function(game)
 io.stdout:setvbuf('no')
 assert((os.getenv('POKEPORT_IDENTITY')or''):match('^vasc%-.*%-qa$'))
 local out=assert(os.getenv('HABITAT_QA_ROOT'))
 local U=require('tests.drivers.util')
 local Q=dofile(assert(os.getenv('BLAINE_KASC_ROOT'))..'/tests/habitat_playthrough/drivers/common.lua')(game)
 Q.setup();Q.V.setupCard.suspended=true
 game.save.flags.EVENT_OAK_GOT_PARCEL=true;game.save.flags.EVENT_GOT_POKEDEX=true
 game.save.flags.EVENT_BEAT_ROUTE22_RIVAL_1ST_BATTLE=true
 love.window.hasFocus=function()return true end;love.window.isVisible=function()return true end
 love.window.setMode(1100,760,{resizable=true,vsync=0});love.audio.setVolume(0)
 local function find(fn,name,seen)
  if type(fn)~='function'then return end;seen=seen or{};if seen[fn]then return end;seen[fn]=true
  for i=1,200 do local k,v=debug.getupvalue(fn,i);if not k then break end;if k==name then return v end end
  for i=1,200 do local k,v=debug.getupvalue(fn,i);if not k then break end;local x=find(v,name,seen);if x then return x end end
 end
 local V=assert(find(Q.V.lib.require('VoxelScene').render,'V'));local scene=V.require('VoxelScene')
 local function ready(id)
  for i=1,2400 do U.wait(1);local l=V.require('LoadingCompanion').status()
   if i>60 and V.require('VoxelState').ready and not scene.pendingReason and not l.visible and not l.cover then return end
  end
  error('scene not ready '..id..' '..tostring(scene.pendingReason))
 end
 local settings=Q.V.setupCard.new(game).settings
 require('src.render.Pipelines').setLevel('voxel',1)
 local fp=V.require('FirstPerson');local frame=fp.frame;local rigSpec
 fp.frame=function(...)local rig,x,z=frame(...);if rigSpec then rig={eye=rigSpec.eye,focus=rigSpec.focus,fov=.94,up={0,1,0},near=.3,far=10000,curveK=0};V.require('Voxel3D').camera=rig;return rig,rigSpec.focus[1],rigSpec.focus[3]end;return rig,x,z end
 assert(settings.apo_hd_walking_sprites):setValue(true,game)
 assert(settings.apo_human_art_style):setValue('cobble',game)
 assert(settings.voxelCharacterCardEnabled):setValue(true,game)
 V.require('Weather').setting:setValue('clear',game);V.require('DayNight').setting:setValue('day',game)
 rigSpec=nil;require('src.render.Pipelines').setLevel('voxel',1)
 V.require('PokemonModelProvider').setting:setValue('cobblemon',game)


 local Map=require('src.world.Map');local census={};local total=0
 for id,def in pairs(game.data.maps)do
  local ts=game.data.tilesets[def.tileset]
  if ts then
   for _,fig in ipairs(V.require('TileShape').figures(ts.id)or{})do
    if fig.hdActor=='pokecenter_seated_man'then
     local map=Map.new(def,ts);local count=0;local couches=0
     for _,p in ipairs(V.require('VoxelFurniture').find(map))do if p.kind=='center_couch'then couches=couches+1 end end
     for y=0,def.height*4-fig.h do for x=0,def.width*4-fig.w do
      local hit=true
      for i,tile in ipairs(fig.tiles)do
       if map:tileAt(x+(i-1)%fig.w,y+math.floor((i-1)/fig.w))~=tile then hit=false;break end
      end
      if hit then count=count+1 end
     end end
     assert(count==couches,'couch mismatch '..id)
     if count>0 then census[id]=count;total=total+count;print('ACTOR LOCATION',id,count)end
    end
   end
  end
 end
 assert(census.CELADON_HOTEL and total==12,'shared placement census failed')
 print('PASS SHARED TILE-PATTERN LOCATIONS',total)
 local def=game.data.maps.VIRIDIAN_POKECENTER
 local changed=Map.new(def,game.data.tilesets[def.tileset]);local old=changed.tileAt
 changed.tileAt=function(self,x,y)if x==1 and y==10 then return 1 end;return old(self,x,y)end
 for _,p in ipairs(V.require('VoxelFurniture').find(changed))do assert(p.kind~='center_couch','changed couch layout replaced')end
 print('PASS MODIFIED LAYOUT FALLBACK')
 local P=require('src.render.Pipelines');local figures=V.require('HdAuthoredFigures')
 for _,style in ipairs{'hd','voxel','cobble'}do
  settings.apo_human_art_style:setValue(style,game);U.wait(90);assert(figures.style()==style)
  for _,spec in ipairs{{'VIRIDIAN_POKECENTER',6,6},{'CELADON_HOTEL',6,6}}do
   rigSpec=nil;P.setLevel('voxel',1);U.teleport(game,spec[1],spec[2],spec[3],'up');ready(spec[1]);Q.settle()
   local sitter
   for _,f in ipairs(V.require('ChunkMesher').figures(game.overworld.map)or{})do
    if f.hdActor=='pokecenter_seated_man'then sitter=f;local chosen,tex=figures.resolve(f)
     assert(chosen.mesh~=f.mesh and tex and chosen.y==f.y-4.5 and not chosen.solid)
     rigSpec={eye={f.wx+29,19,f.wz+28},focus={f.wx+6,13,f.wz}}
    end
   end
   assert(sitter and sitter.y==8,'authored sitter height/missing');
   local couch;for _,p in ipairs(V.require('VoxelFurniture').find(game.overworld.map))do if p.kind=='center_couch'then couch=p end end
   assert(couch and couch.claimed,'replacement missing');P.setLevel('voxel',6);U.wait(40)
   assert(U.shot(game,out..'/couch-'..style..'-'..spec[1]..'.png'))
   print('PASS ROSTER/VOXEL SPRITE SEATED CENTER',style,spec[1],sitter.wx,sitter.wz,sitter.y)
  end
 end
 settings.apo_hd_walking_sprites:setValue(false,game);U.wait(90);assert(figures.style()=='native')
 for _,f in ipairs(V.require('ChunkMesher').figures(game.overworld.map)or{})do
  if f.hdActor=='pokecenter_seated_man'then assert(figures.resolve(f)==f)end
 end
 assert(U.shot(game,out..'/couch-native-OFF.png'))
 print('PASS NATIVE SITTER WHEN WALKERS OFF')
 settings.apo_hd_walking_sprites:setValue(true,game)
 settings.apo_human_art_style:setValue('voxel',game);U.wait(90);assert(figures.style()=='voxel')
 V.require('VoxelItems').setting:setValue(false,game);rigSpec=nil;P.setLevel('voxel',1);U.teleport(game,'VIRIDIAN_POKECENTER',6,6,'up');ready('furniture-off');Q.settle();
 local sitter;for _,f in ipairs(V.require('ChunkMesher').figures(game.overworld.map)or{})do if f.hdActor=='pokecenter_seated_man'then sitter=f end end
 assert(sitter and sitter.y==8,'OFF lost native sitter');for _,p in ipairs(V.require('VoxelFurniture').find(game.overworld.map))do if p.kind=='center_couch'then assert(not p.claimed,'OFF still claimed')end end
 rigSpec={eye={sitter.wx+29,19,sitter.wz+28},focus={sitter.wx+6,13,sitter.wz}};P.setLevel('voxel',6);U.wait(40);assert(U.shot(game,out..'/couch-furniture-OFF.png'));V.require('VoxelItems').setting:setValue(true,game)
 print('CENTER_COUCH_DONE')
 love.event.quit()
end
