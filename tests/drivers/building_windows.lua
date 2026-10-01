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


 local Map=require('src.world.Map');local H=V.require('HouseWindows');local profiles=V.require('Gen1InteriorPanoramas').profiles
 local W=V.require('SilphWindows');local B=V.require('Gen1WindowBindings');local WC=V.require('WindowImageCache')
 V.require('Gen1PalletVillage').buildings:setValue(true,game);W.setting:setValue(true,game)
 for _,id in ipairs{'ROUTE_5_GATE','VIRIDIAN_FOREST_NORTH_GATE'}do
 local d=game.data.maps[id];local m=Map.new(d,game.data.tilesets[d.tileset]);assert(not H.describe(m),'guardhouse must retain flat windows')
 local l=assert(V.require('InteriorLights').layout(m));assert(#l.portals>0,'flat guardhouse windows have no light')
end
 local connected=0;local panes=0
 for id,def in pairs(game.data.maps)do
  local map=Map.new(def,game.data.tilesets[def.tileset]);local h=H.describe(map)
  if h then connected=connected+1;panes=panes+#h.panes
   assert(#h.panes>0 and h.source and game.data.maps[h.source],'invalid source '..id)
   if h.rooms then for _,r in ipairs(h.rooms)do
    local found=false;for _,p in ipairs(h.panes)do if p.edge==r.edge and p.at==r[r.edge]and p.from>=r.west and p.upto<=r.east then found=true end end
    assert(found,'cabin has no real window '..id..' '..r.west..' '..r.north)
   end end
  end
 end
 for n=1,7 do local id='POKEMON_TOWER_'..n..'F';local d=game.data.maps[id]
  assert(not H.describe(Map.new(d,game.data.tilesets[d.tileset]))and not profiles[id],'Tower must stay closed')
 end
 for _,id in ipairs{'SS_ANNE_B1F','SS_ANNE_B1F_ROOMS','POKEMON_MANSION_B1F','ROCKET_HIDEOUT_B1F'}do
  local d=game.data.maps[id];assert(not H.describe(Map.new(d,game.data.tilesets[d.tileset])),'basement received windows '..id)
 end
 print('PASS_WINDOW_CENSUS',connected,panes,'seven Tower floors closed')
 local specs={{'CELADON_HOTEL'}, {'CELADON_DINER'}, {'MUSEUM_2F'}, {'CELADON_MANSION_3F'},
 {'CELADON_MANSION_ROOF_HOUSE'}, {'POKEMON_MANSION_3F'}, 
 {'INDIGO_PLATEAU_LOBBY'}, {'SAFARI_ZONE_SECRET_HOUSE'}, {'CINNABAR_LAB_TRADE_ROOM'},
 {'CINNABAR_LAB_METRONOME_ROOM'}, {'CINNABAR_LAB_FOSSIL_ROOM'}, {'OAKS_LAB'},
 {'SS_ANNE_1F'}, {'SS_ANNE_2F'}, {'SS_ANNE_3F'}, {'SS_ANNE_KITCHEN'}, {'SS_ANNE_CAPTAINS_ROOM'},
 {'SS_ANNE_1F_ROOMS'}, {'SS_ANNE_2F_ROOMS'}, {'POWER_PLANT'}}
 local P=require('src.render.Pipelines');local results={};local Json=require('src.link.Json')
 for _,s in ipairs(specs)do
  local id=s[1];local d=game.data.maps[id];local map=Map.new(d,game.data.tilesets[d.tileset]);local h=assert(H.describe(map),id)
  local px,py
  for y=0,d.height*2-1 do for x=0,d.width*2-1 do if not px and map:isWalkableCell(x,y)then px,py=x,y end end end
  assert(px,id..' has no floor');rigSpec=nil;P.setLevel('voxel',1)
  local before=WC.hits;U.teleport(game,id,px,py,'down');ready(id);Q.settle()
  if os.getenv('EXPECT_WINDOW_CACHE')=='1'then assert(WC.hits>before,'packaged view not used: '..id..' '..tostring(WC.last and WC.last.reason))end
  assert(U.shot(game,out..'/'..id..'-room.png'))
  local p=h.panes[1];local horizontal=p.edge=='north'or p.edge=='south';local a=(p.from+p.upto)/2
  local side=(p.edge=='north'or p.edge=='west')and -1 or 1
  local target=horizontal and{a,21,p.at}or{p.at,21,a}
  local eye=horizontal and{a,21,p.at-side*36}or{p.at-side*36,21,a}
  if h.rooms then local r=h.rooms[1];eye={(r.west+r.east)/2,21,(r.north+r.south)/2}end
  rigSpec={eye=eye,focus=target};P.setLevel('voxel',6);U.wait(30)
  assert(U.shot(game,out..'/'..id..'-window.png'))
  results[#results+1]={map=id,source=h.source,panes=#h.panes,cache=WC.last and WC.last.status,kind=WC.last and WC.last.reason}
  print('PASS_WINDOW_RENDER',id,#h.panes,WC.last and WC.last.status)
 end
 -- Prove the same real-windows toggle restores solid wall panels.
 W.setting:setValue(false,game);rigSpec=nil;P.setLevel('voxel',1)
 U.teleport(game,'CELADON_HOTEL',4,4,'up');ready('windows-off');assert(not W.enabled(game.overworld.map))
 assert(U.shot(game,out..'/CELADON_HOTEL-windows-OFF.png'));W.setting:setValue(true,game)
 local f=assert(io.open(out..'/native-window-results.json','w'));f:write(Json.encode({connected=connected,panes=panes,tower='closed',rows=results}));f:close()
 print('WINDOWS_NATIVE_DONE');love.event.quit()
end
