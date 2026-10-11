return function(game)
 io.stdout:setvbuf('no')
 assert((os.getenv('POKEPORT_IDENTITY')or''):match('^vasc%-sevii%-.*%-qa$'))
 local out=assert(os.getenv('HABITAT_QA_ROOT'))
 local U=require('tests.drivers.util')
 local Q=dofile(assert(os.getenv('SEVII_KASC_ROOT'))..'/tests/habitat_playthrough/drivers/common.lua')(game)
 Q.setup();game.save.options.colors='redpp';game:applyOptions();Q.V.setupCard.suspended=true
 love.window.hasFocus=function()return true end;love.window.isVisible=function()return true end
 local width,height=1100,760
 if os.getenv('SEVII_NATIVE_4K')=='1'then width,height=3420,2214 end
 love.window.setMode(width,height,{resizable=true,vsync=1});love.audio.setVolume(0)
 local function find(fn,name,seen)
  if type(fn)~='function'then return end;seen=seen or{};if seen[fn]then return end;seen[fn]=true
  for i=1,200 do local k,v=debug.getupvalue(fn,i);if not k then break end;if k==name then return v end end
  for i=1,200 do local k,v=debug.getupvalue(fn,i);if not k then break end;local x=find(v,name,seen);if x then return x end end
 end
 local V=assert(find(Q.V.lib.require('VoxelScene').render,'V'));local M=V.require('KascSeviiScenery');local T=V.require('TileShape');local P=V.require('VoxelItems')
 local liveRims,liveRimMap;local horizon=V.require('HorizonWall');local horizonMeshes=horizon.meshes
 horizon.meshes=function(state,...)
  local rims,ready,failed=horizonMeshes(state,...)
  if ready and rims and state.map==game.overworld.map then liveRims,liveRimMap=rims,state.map end
  return rims,ready,failed
 end
 local visualMode=os.getenv('SEVII_VISUAL_MODE')or'full'
 assert(visualMode=='full'or visualMode=='nature'or visualMode=='basic','unknown Sevii visual mode')
 local function applyMode(mode)
  local enabled=mode~='basic';local scenery=V.require('Gen1OutdoorScenery');local village=V.require('Gen1PalletVillage')
  for _,setting in ipairs{P.setting,scenery.ground,scenery.trees,scenery.stone,village.surrounds,village.lights,V.require('Gen1InteriorFloors').setting,V.require('Gen1Stairs').setting}do setting:setValue(enabled,game)end
  village.buildings:setValue(mode=='full',game)
  V.require('HorizonWall').setting:setValue(enabled and'full'or'off',game)
  V.require('OutdoorHorizon').setting:setValue(mode=='full'and'voxel'or'off',game)
  print('SEVII_VISUAL_MODE',mode)
 end
 local function setCamera(level)
  require('src.render.Pipelines').setLevel('voxel',level);require('src.render.Pipelines').syncOptions(game.save.options);U.wait(3);applyMode(visualMode)
  require('src.render.Pipelines').setLevel('tiltshift',0)
  local stable=0;local serial=V.require('WorldSceneHold').serial()
  for frame=1,3000 do U.wait(1)
   if V.require('WorldSceneHold').serial()>serial+8 and not V.require('VoxelScene').pendingReason and not V.require('LoadingCompanion').status().visible then stable=stable+1 else stable=0 end
   if stable>=45 then return end
  end
  error('camera never presented: '..tostring(V.require('VoxelScene').pendingReason))
 end
 applyMode('full')
 require('src.render.Pipelines').setLevel('tiltshift',0)
 local Loader=require('src.world.MapLoader');local S=assert(Q.K.seviiExpedition)
 local oraclePath=assert(os.getenv('SEVII_SOURCE_ORACLE'),'independent source oracle required')
 local oracleFile=assert(io.open(oraclePath,'r'));local oracle=require('src.link.Json').decode(oracleFile:read('*a'));oracleFile:close()
 for _,case in ipairs(oracle.cases)do
  local id,x,y=S.location(case.source,case.x,case.y);assert(id,case.source)
  local map=Loader.load(game.data,id)
  assert(M.token(map,x*2,y*2)==case.tag,'wrong source object role: '..case.source..' '..case.x..','..case.y..' expected '..case.tag..' got '..tostring(M.token(map,x*2,y*2))..' on '..id..' '..x..','..y)
  if case.material then assert(M.material(map,map:tileAt(x*2,y*2),x*2,y*2)==case.material,'wrong plank material')end
  if case.wallDonor then
   local paint=assert(M.profile(map).nativeWallSource)
   assert(paint.x==x and paint.y==y,'native wall donor is source padding instead of reviewed panel: '..case.source)
  end
 end
 print('SEVII_SOURCE_ORACLE_PASS',#oracle.cases)
 local auditRows={};local inventory={};local missed={};local landscapes={};local palmView;local counts={maps=0,cells=0,props=0,buildings=0,objects=0};local ids={};for id in pairs(S.maps)do ids[#ids+1]=id end;table.sort(ids)
 local function same(a,b)
  if type(a)~=type(b)then return false end;if type(a)~='table'then return a==b end
  for k,v in pairs(a)do if not same(v,b[k])then return false end end
  for k in pairs(b)do if a[k]==nil then return false end end;return true
 end
 local function copy(a)if type(a)~='table'then return a end;local b={};for k,v in pairs(a)do b[k]=copy(v)end;return b end
 for _,id in ipairs(ids)do
  local map=Loader.load(game.data,id);for _,o in ipairs(map.def.objects or{})do inventory[#inventory+1]={map=id,name=o.name,sprite=o.sprite,index=o.index,item=o.item}end;local before=copy(map.def);local profile=assert(M.profile(map),'missing profile '..id)
  local auditRow={map=id,source=profile.source,kind=profile.kind,tileset=map.def.tileset,
   origin=profile.origin,contract=true,cells=map.widthCells*map.heightCells,
   waterCells=0,grassCells=0,subtiles=0,missingTags=0,shapeConflicts=0,
   actors=#(map.def.objects or{}),warps=#(S.links[id]or{}),connections=0,
   battleStyle=V.require('BattleArenaStyle').resolve(map).id,
   visualReview='UNREVIEWED',mobileReview='UNTESTED'}
  for _,connection in pairs(map.def.connections or{})do
   assert(S.maps[connection.map],'missing connection target '..id..' -> '..tostring(connection.map))
   auditRow.connections=auditRow.connections+1
  end
  for _,warp in ipairs(S.links[id]or{})do
   assert(S.maps[warp.map],'missing warp target '..id..' -> '..tostring(warp.map))
  end
  local shapes=T.forMap(map)
  for y=0,map.heightCells-1 do for x=0,map.widthCells-1 do
   if map:isGrassCell(x,y)then assert(not map:isWaterCell(x,y),'native encounter grass became inherited Kanto shore '..id)end
   if map:isGrassCell(x,y)then auditRow.grassCells=auditRow.grassCells+1 end
   if map:isWaterCell(x,y)then auditRow.waterCells=auditRow.waterCells+1 end
   for dy=0,1 do for dx=0,1 do
    local tx,ty=x*2+dx,y*2+dy;local tile=map:tileAt(tx,ty)
    assert(M.token(map,tx,ty,tile)~=nil,'SEVII_MISSING_TILE map='..id..' tile='..tostring(tile)..' at='..tx..','..ty)
    local shape=assert(T.at(map,shapes,tile,tx,ty),'SEVII_MISSING_SHAPE map='..id..' tile='..tostring(tile))
    assert(shape.authored,'unowned shape mapping '..id..' tile='..tostring(tile))
    auditRow.subtiles=auditRow.subtiles+1
    if map:isWaterCell(x,y)then assert(shape.class=='water','water extruded '..id)
    elseif map:isWalkableCell(x,y)or map:warpAtCell(x,y)then assert(shape.flat or shape.class=='ledge','walkable raised '..id)end
   end end
   counts.cells=counts.cells+1
  end end
  local props=M.find(P,map,false);counts.props=counts.props+#props;auditRow.props=#props
  if profile.theme=='mart'then
   local cashier,frontShelf,nearShelf=false,false,false
   for _,prop in ipairs(props)do
    local x,y=(prop.claimTx or prop.tx)/2,(prop.claimTy or prop.ty)/2
    cashier=cashier or prop.kind=='sevii_P_16_48'and x==3 and y==2
    frontShelf=frontShelf or prop.kind=='sevii_MS_48_16'and x==0 and y==4
    nearShelf=nearShelf or prop.kind=='sevii_MS_32_16'and x==1 and y==6
   end
   assert(cashier and frontShelf and nearShelf,'Mart checkout or source shelves missing '..id)
  elseif profile.source=='FourIsland_PokemonDayCare'then
   local counter=0
   for _,prop in ipairs(props)do if prop.kind:match('^sevii_Dc_')then counter=counter+1 end end
   assert(counter==2,'Day Care reception counter is incomplete')
  elseif profile.source:match('^TrainerTower_[1-8]F$')then
   local markers=0
   for _,prop in ipairs(props)do if prop.kind=='sevii_TP_16_16'then markers=markers+1 end end
   assert(markers==18,'Trainer Tower lanes lost their source markers '..id)
  end
  if os.getenv('SEVII_DEBUG_RETAIL')=='1'and profile.source=='TwoIsland_JoyfulGameCorner'then
   for _,prop in ipairs(props)do print('SEVII_RETAIL_PROP',prop.kind,prop.tx/2,prop.ty/2,prop.w/2,prop.h/2)end
  end
  local centerRoom=profile.theme=='center'and profile.source:match('PokemonCenter_1F$')~=nil
  local upperRoom=profile.theme=='center'and profile.source:match('PokemonCenter_2F$')~=nil
  if profile.kind=='room'then
   local expected=#profile.props
   if profile.source=='OneIsland_PokemonCenter_1F'then expected=expected-4 end
   if profile.source=='TwoIsland_JoyfulGameCorner'then expected=8 end
   if profile.theme=='mart'then expected=6 end
   assert(#props>=expected,'room lost its source-footprint voxel objects '..id)
  end
  local region=V.require('SeviiLandscape').region(profile)
  if region then
   local entry=landscapes[region]or{maps=0,palms=0,rocks=0,trees=0,maxRise=0};landscapes[region]=entry;entry.maps=entry.maps+1
   local field=M.elevation(map)
   if field then for yy=0,map.heightCells-1 do for xx=0,map.widthCells-1 do entry.maxRise=math.max(entry.maxRise,field:at(xx,yy))end end end
   for _,prop in ipairs(props)do
    if prop.kind:match('^cinnabar_palm')then
     entry.palms=entry.palms+1;assert(not map:isWalkableCell(prop.tx/2,prop.ty/2),'palm root obstructs walking plot')
     palmView=palmView or{profile.source,profile.origin[1]+prop.tx/2,profile.origin[2]+prop.ty/2+2,'coastal-palm'}
     assert(V.require('SeviiLandscape').nearWater(map,prop.tx/2,prop.ty/2,3),'inland palm')
    elseif prop.kind:find('rock_',1,true)then entry.rocks=entry.rocks+1
    elseif prop.kind:match('^kanto_tree')or prop.kind:match('^sevii_tree')then entry.trees=entry.trees+1 end
   end
  end
  local covered={};for _,p in ipairs(props)do
   local x,y=(p.claimTx or p.tx)/2,(p.claimTy or p.ty)/2
   for yy=y,y+p.h/2-1 do for xx=x,x+p.w/2-1 do covered[yy*map.widthCells+xx]=true end end
  end
  for y=0,map.heightCells-1 do for x=0,map.widthCells-1 do
   local tag=M.token(map,x*2,y*2)
   if tag and tag:match('^[BTFSfnptsbeahrkuqlcAHJNOQZmRzji]$')
      and not(profile.theme=='center'and tag=='u')
      and not map:isWaterCell(x,y)and not M.portalAt(map,x,y)and not covered[y*map.widthCells+x]then
    missed[tag]=(missed[tag]or 0)+1
   end
   if profile.exterior and tag=='D'and not map:isWalkableCell(x,y)and not map:isWaterCell(x,y)and not M.portalAt(map,x,y)then assert(covered[y*map.widthCells+x],'blocked sand-labelled boulder unclaimed')end
  end end
  for _,prop in ipairs(props)do
   local model=assert(P.models[prop.kind],prop.kind)
   assert(model.boxes and #model.boxes>0,'empty model '..prop.kind)
   local x,y=prop.claimTx or prop.tx,prop.claimTy or prop.ty
   assert(x>=0 and y>=0 and x+prop.w<=map.def.width*4 and y+prop.h<=map.def.height*4,'claim crosses fragment '..id)
   for _,b in ipairs(model.boxes)do assert(b[4]>0 and b[5]>0 and b[6]>0,'invalid box')end
   if prop.kind=='sevii_W_128_48'or prop.kind:match('^sevii_P_')
      or prop.kind:match('^sevii_MS_')or prop.kind:match('^sevii_Dc_')
      or prop.kind=='sevii_TP_16_16'
      or upperRoom and prop.kind:match('^sevii_E_')then
    for cy=0,prop.h/2-1 do for cx=0,prop.w/2-1 do
     local px,pz=cx*16+8,cy*16+8
     for _,b in ipairs(model.boxes)do
      if b[2]+b[5]>5 and px>=b[1]and px<b[1]+b[4]
          and pz>=b[3]and pz<b[3]+b[6]then
       assert(not map:isWalkableCell(prop.tx/2+cx,prop.ty/2+cy),
        'service furniture crosses a walkable source cell '..id)
      end
     end
    end end
   end
  end
  for _,o in ipairs(map.def.objects or{})do
   if M.objectStyle(o.name or'',o.sprite)then
    local def=assert(game.data.sprites[o.sprite],o.sprite);local kind=assert(P.kind(def,id..'_obj_'..o.index),'missing live replacement '..o.name)
    local mesh,tex=P.resolveKind(kind);assert(mesh and tex,'missing live mesh '..o.name);counts.objects=counts.objects+1
   end
  end
  auditRow.buildings=#M.find(P,map,true);auditRows[#auditRows+1]=auditRow
  counts.buildings=counts.buildings+auditRow.buildings;counts.maps=counts.maps+1
  assert(same(before,map.def),'presentation changed native definition '..id)
  if counts.maps%30==0 then print('SEVII_PROFILE_AUDIT',counts.maps,counts.props)end
 end
 print('SEVII_COUNTS',counts.maps,counts.buildings,counts.props)
 print('SEVII_LANDSCAPES',require('src.link.Json').encode(landscapes))
 local lf=assert(io.open(out..'/landscapes.json','w'));lf:write(require('src.link.Json').encode(landscapes));lf:close()
 print('SEVII_LIVE_OBJECTS',counts.objects)
 assert(counts.objects>=80,'incomplete live objects');assert(counts.maps==266 and counts.buildings>15,'incomplete region')
 local f=assert(io.open(out..'/audit.json','w'));f:write(require('src.link.Json').encode(counts));f:close()
 local missFile=assert(io.open(out..'/unclaimed.json','w'));missFile:write(require('src.link.Json').encode(missed));missFile:close()
 print('SEVII_UNCLAIMED',require('src.link.Json').encode(missed));assert(next(missed)==nil,'unreplaced static object cells')
 local matrixFile=assert(io.open(out..'/map-audit.json','w'));matrixFile:write(require('src.link.Json').encode(auditRows));matrixFile:close()
 local inventoryFile=assert(io.open(out..'/objects.json','w'));inventoryFile:write(require('src.link.Json').encode(inventory));inventoryFile:close()
 if os.getenv('SEVII_INVENTORY_ONLY')=='1'then love.event.quit();return end
 applyMode(visualMode)
 setCamera(1)
 V.require('DayNight').setting:setValue('day',game);V.require('Weather').setting:setValue('clear',game)
 V.require('CalendarEvents').setting:setValue('off',game)
 if os.getenv('SEVII_BATTLE_ONLY')~='1'then
 local representatives={
  {'OneIsland',12,14,'one-town'},{'TwoIsland',15,8,'two-town'},
  {'ThreeIsland',12,15,'three-town'},{'FourIsland',18,22,'four-town'},
  {'FiveIsland',10,10,'five-town'},{'SixIsland',10,12,'six-town'},
  {'SevenIsland',10,10,'seven-town'},
  {'OneIsland_PokemonCenter_1F',7,8,'center'},
  {'TwoIsland_House',6,6,'home'},
  {'ThreeIsland_BerryForest',14,12,'berry-forest'},
  {'FourIsland_IcefallCave_1F',8,8,'ice-cave'},
  {'FiveIsland_RocketWarehouse',8,7,'warehouse'},
  {'SixIsland_DottedHole_B1F',7,8,'ruins'},
  {'TrainerTower_1F',6,7,'trainer-tower'},
  {'ThreeIsland_Port',12,11,'ferry'},
  {'SevenIsland_TanobyRuins',11,8,'tanoby'},
 }
 if os.getenv('SEVII_QUICK_QUALITY')=='1'then representatives={
  {'OneIsland',12,14,'one-town'},{'TwoIsland_House',6,6,'home'},
  {'OneIsland_PokemonCenter_1F',7,8,'center'},{'FiveIsland_RocketWarehouse',8,7,'warehouse'},
  {'FourIsland',18,22,'four-town'},{'SixIsland',10,12,'six-town'},{'SevenIsland',10,10,'seven-town'}
 }end
 if os.getenv('SEVII_CENTER_ONLY')=='1'then representatives={
  {'OneIsland_House1',5,6,'first-shop'},
  {'OneIsland_PokemonCenter_1F',7,8,'center'},
 }end
 if os.getenv('SEVII_CENTER_ALL')=='1'then representatives={
  {'OneIsland_PokemonCenter_1F',7,8,'center-one'},
  {'TwoIsland_PokemonCenter_1F',7,7,'center-two'},
  {'ThreeIsland_PokemonCenter_1F',7,7,'center-three'},
  {'FourIsland_PokemonCenter_1F',7,7,'center-four'},
  {'FiveIsland_PokemonCenter_1F',7,7,'center-five'},
  {'SixIsland_PokemonCenter_1F',7,7,'center-six'},
  {'SevenIsland_PokemonCenter_1F',7,7,'center-seven'},
 }end
 if os.getenv('SEVII_CENTER_UPSTAIRS')=='1'then representatives={
  {'OneIsland_PokemonCenter_2F',7,7,'center-upper-one'},
  {'TwoIsland_PokemonCenter_2F',7,7,'center-upper-two'},
 }end
 if os.getenv('SEVII_INTERIOR_THEMES')=='1'then representatives={
  {'SevenIsland_Mart',6,6,'mart'},
  {'FiveIsland_ResortGorgeous_House',6,6,'hotel'},
  {'TrainerTower_Lobby',6,6,'tower-lobby'},
  {'FourIsland_PokemonDayCare',6,6,'daycare'},
  {'TwoIsland_JoyfulGameCorner',6,6,'game-corner'},
  {'FiveIsland_RocketWarehouse',8,7,'warehouse'},
  {'FourIsland_LoreleisHouse',6,6,'lorelei-home'},
  {'ThreeIsland_House1',6,6,'three-home'},
 }end
 if os.getenv('SEVII_ALL_INTERIORS')=='1'then
  representatives={}
  for _,id in ipairs(ids)do
   local roomMap=Loader.load(game.data,id)
   local roomProfile=M.profile(roomMap)
   if roomProfile.kind=='room'then
    representatives[#representatives+1]={roomProfile.source,
     math.floor(roomMap.widthCells/2),roomMap.heightCells-3,
     roomProfile.source:lower():gsub('[^%w]+','-'),id}
   end
  end
  assert(#representatives==52,'Sevii room inventory changed')
 end
 if os.getenv('SEVII_KANTO_INTERIORS_ONLY')=='1'then representatives={}end
 if os.getenv('SEVII_RETAIL_QUALITY')=='1'then representatives={
  {'SevenIsland_Mart',6,6,'mart'},
  {'TwoIsland_JoyfulGameCorner',6,6,'game-corner'},
 }end
 if os.getenv('SEVII_GRASS_QUALITY')=='1'then representatives={
  {'ThreeIsland_BerryForest',14,12,'berry-forest'},
  {'SixIsland_PatternBush',36,20,'pattern-bush'},
  {'FiveIsland_Meadow',12,10,'meadow'},
  {'SixIsland',10,12,'six-town'}, {'TwoIsland_House',6,6,'home'}
 }end
 if os.getenv('SEVII_ISLAND_QUALITY')=='1'then representatives={
  {'ThreeIsland_BerryForest',14,12,'berry-forest'},{'SixIsland_PatternBush',36,20,'pattern-bush'},
  {'FiveIsland_Meadow',12,10,'meadow'}, {'OneIsland_KindleRoad',12,30,'volcanic-coast'},
  {'SevenIsland_SevaultCanyon',12,46,'canyon'},{'SevenIsland_SevaultCanyon_Entrance',12,14,'canyon-terraces'},
  {'SixIsland_RuinValley',12,30,'ruin-valley'},{'SevenIsland_TanobyRuins',11,8,'tanoby'},
  {'ThreeIsland_Port',12,11,'ferry'},{'TwoIsland_House',6,6,'home'},
  {'OneIsland_PokemonCenter_1F',7,8,'center'},{'SixIsland',10,12,'six-town'}
 }end
 if os.getenv('SEVII_ISLAND_QUALITY')=='1'then assert(palmView,'no coastal accent in actual map');representatives[#representatives+1]=palmView end
 if os.getenv('SEVII_FEATURE_QUALITY')=='1'then representatives={
  {'MtEmber_Exterior',28,43,'ember-approach'},
  {'MtEmber_Exterior',28,30,'ember-terraces'},
  {'MtEmber_Exterior',29,15,'ember-upper'},
  {'MtEmber_Summit',10,17,'ember-summit'},
  {'FourIsland_IcefallCave_Entrance',14,21,'ice-waterfall'},
  {'FourIsland_IcefallCave_1F',8,8,'ice-thin-floor'},
  {'FourIsland_IcefallCave_B1F',12,8,'ice-basement'},
  {'FourIsland_IcefallCave_Back',12,15,'ice-back'},
  {'TrainerTower_Roof',8,8,'tower-roof'},
  {'FiveIsland_MemorialPillar',12,44,'memorial'},
  {'SevenIsland_TanobyRuins',11,8,'tanoby'},
  {'OneIsland_KindleRoad_EmberSpa',12,20,'ember-spa'},
  {'OneIsland_KindleRoad_EmberSpa',12,8,'ember-spa-falls'},
  {'MtEmber_RubyPath_1F',7,8,'ruby-cave'},
  {'FiveIsland_LostCave_Entrance',6,7,'lost-cave'}
 }end
 if os.getenv('SEVII_WATER_ONLY_QUALITY')=='1'then
  representatives={{'SevenIsland_TrainerTower',60,16,'tower-coast'},
    {'SevenIsland_TrainerTower',84,15,'sea-only-surf'}}
 end
 if os.getenv('SEVII_WAREHOUSE_QUALITY')=='1'then
  representatives={{'FiveIsland_RocketWarehouse',9,4,'warehouse-crates'},
   {'FiveIsland_RocketWarehouse',10,14,'warehouse-puzzle'},
   {'FiveIsland_RocketWarehouse',25,10,'warehouse-machines'}}
 end
 if os.getenv('SEVII_PRIMARY_HOME_QUALITY')=='1'then
  representatives={{'SevenIsland_House_Room1',5,6,'primary-home'},
   {'SevenIsland_House_Room2',5,6,'adjacent-home'},
   {'FiveIsland_ResortGorgeous_House',5,6,'resort-home'},
   {'FourIsland_LoreleisHouse',5,6,'lorelei-home'}}
 end
 if os.getenv('SEVII_CAVE_QUALITY')=='1'then
  representatives={}
  for _,id in ipairs(ids)do
   local map=Loader.load(game.data,id);local p=M.profile(map)
   if p.kind=='cave'then
    local cx,cy=map.widthCells/2,map.heightCells/2;local score=math.huge;local x,y
    for yy=0,map.heightCells-1 do for xx=0,map.widthCells-1 do
     local d=(xx-cx)^2+(yy-cy)^2+(M.portalAt(map,xx,yy)and 1000 or 0)
     if d<score and map:isWalkableCell(xx,yy)then score,x,y=d,xx,yy end
    end end
    if x then representatives[#representatives+1]={p.source,x+p.origin[1],y+p.origin[2],id:lower()}end
   end
  end
 end
 if os.getenv('SEVII_CAVE_RETURN_QUALITY')=='1'then
  representatives={{'FiveIsland_LostCave_Entrance',6,7,'lost-cave'}}
 end
 if os.getenv('SEVII_PARITY_QUALITY')=='1'then
  local W=V.require('Weather');W.setting:setValue('auto',game)
  W.update=function(_,map)W.clock=1440;return 'clear'end
  W.mode=function()return 'clear'end;W.clock=1440
  V.require('DayNight').setting:setValue('day',game)
  -- Every distinct source, rather than a few favourable demonstration maps.
  -- Pick a genuine walkable plot near its source-wide centre, independently
  -- of runtime fragment boundaries; optionally review one category at a time.
  local sources={};local picked={};local category=os.getenv('SEVII_PARITY_KIND')
  local selectedText=os.getenv('SEVII_PARITY_SELECTED');local selected
  if selectedText then selected={};for name in selectedText:gmatch('[^,]+')do selected[name]=true end end
  for _,id in ipairs(ids)do local map=Loader.load(game.data,id);local p=M.profile(map)
   if (not selected or selected[p.source])and(not category or(category=='exterior'and p.exterior)or category==p.kind)then
    local a=sources[p.source]or{width=0,height=0};sources[p.source]=a
    a.width=math.max(a.width,p.origin[1]+map.widthCells)
    a.height=math.max(a.height,p.origin[2]+map.heightCells)
   end
  end
  for _,id in ipairs(ids)do local map=Loader.load(game.data,id);local p=M.profile(map);local a=sources[p.source]
   if a then for yy=0,map.heightCells-1 do for xx=0,map.widthCells-1 do
    if map:isWalkableCell(xx,yy)and not M.portalAt(map,xx,yy)then
     local sx,sy=xx+p.origin[1],yy+p.origin[2]
     local score=(sx-a.width/2)^2+(sy-a.height/2)^2
     if not a.score or score<a.score then a.score=score;a.x=sx;a.y=sy end
    end
   end end end
  end
  local names={};for name in pairs(sources)do names[#names+1]=name end;table.sort(names)
  representatives={}
  for _,name in ipairs(names)do local a=sources[name];assert(a.x,'no reviewable source '..name)
   representatives[#representatives+1]={name,a.x,a.y,'source-'..name}
   picked[#picked+1]={source=name,x=a.x,y=a.y,width=a.width,height=a.height}
  end
  local f=assert(io.open(out..'/review-sources.json','w'));f:write(require('src.link.Json').encode(picked));f:close()
  print('SEVII_PARITY_SOURCE_COUNT',#representatives,category or'all')
 end
 if os.getenv('SEVII_SEASON_QUALITY')=='1'then
  representatives={{'ThreeIsland_BerryForest',12,10,'berry-forest'},
    {'SixIsland_PatternBush',12,10,'pattern-bush'}}
  local W=V.require('Weather');W.setting:setValue('auto',game)
  local seasonClock=480
  W.update=function(_,map)W.clock=seasonClock;return 'clear'end
  W.mode=function()return 'clear'end
  W.setClock=function(t)seasonClock=t;W.clock=t end
  V.require('DayNight').setting:setValue('day',game)
  V.require('LocalLights').setting:setValue(true,game)
 end
 local caveEyes={}
 local roomEyes={}
 for _,r in ipairs(representatives)do
  local id,x,y=r[5],r[2],r[3]
  if not id then id,x,y=S.location(r[1],r[2],r[3])end
  assert(id,r[1])
  local m=Loader.load(game.data,id)
  if r[4]~='sea-only-surf'and not m:isWalkableCell(x,y)then
   local best=math.huge;local bx,by=x,y
   for yy=2,m.heightCells-3 do for xx=2,m.widthCells-3 do
    local dist=(xx-x)^2+(yy-y)^2
    if dist<best and m:isWalkableCell(xx,yy)and not m:warpAtCell(xx,yy)then best,bx,by=dist,xx,yy end
   end end;x,y=bx,by
  end
  local serial=V.require('WorldSceneHold').serial()
  U.teleport(game,id,x,y,'down');Q.settle()
  if r[4]=='sea-only-surf'then assert(game.overworld.map:isWaterCell(x,y),'water-only fixture on land');game.overworld.player.surfing=true end
  local ready=false;local stable=0
  for frame=1,3000 do
   U.wait(1)
   if frame>20 and V.require('WorldSceneHold').serial()>serial+8 and not V.require('VoxelScene').pendingReason and not V.require('LoadingCompanion').status().visible then stable=stable+1 else stable=0 end
   if stable>=45 then ready=true;break end
  end
  if not ready then
   -- Passive failure receipts: querying these never warms the failed scene.
   local C=V.require('ChunkMesher');local J=require('src.link.Json')
   local N=V.require('VisibleNeighborhood').apply(game.overworld)
   local list={{map=N.map}};for _,n in ipairs(N.neighbors or{})do list[#list+1]=n end
   for i,n in ipairs(list)do
    print('SEVII_PRESENT_CACHE',n.map.id,not not C.ready(n.map,i~=1),
     C.auxReady(n.map),V.require('TerrainAtlas').prepared(n.map),not not C.building(n.map,i~=1))
   end
   print('SEVII_PRESENT_PLAN',J.encode(V.require('VoxelScene').planStatus()),
    J.encode(V.require('HorizonWall').cacheStatus(N)),C.pending())
   print('SEVII_PRESENT_FAILURE',id,V.require('VoxelScene').pendingReason,V.require('WorldSceneHold').serial(),serial)
   U.shot(game,out..'/failure.png')
  end
  assert(ready,'world never presented '..id);U.wait(15)
  if os.getenv('SEVII_CENTER_ONLY')=='1'or os.getenv('SEVII_CENTER_ALL')=='1'then
   local times={}
   for sample=1,120 do
    local start=love.timer.getTime();U.wait(1)
    times[#times+1]=(love.timer.getTime()-start)*1000
   end
   table.sort(times)
   local sum=0;for _,ms in ipairs(times)do sum=sum+ms end
   local vw,vh=V.require('Voxel3D').size()
   print('SEVII_FRAME_MS',r[4],width,height,'mean',sum/#times,
    'p95',times[math.ceil(#times*.95)],'scale',V.require('FrameBudget').scale,
    'render',vw,vh)
  end
  if os.getenv('SEVII_PARITY_QUALITY')=='1'or os.getenv('SEVII_SEASON_QUALITY')=='1'or os.getenv('SEVII_WATER_ONLY_QUALITY')=='1'then
   local scene=V.require('VoxelScene');local ring=false
   for frame=1,3000 do
    if scene.resumeNeighborhoodReady(game.overworld)then ring=true;break end
    U.wait(1)
   end
   local receipt=scene.planStatus();print('SEVII_REVIEW_RING',id,ring,require('src.link.Json').encode(receipt))
   if not ring then
    local C=V.require('ChunkMesher');local A=V.require('TerrainAtlas');local H=V.require('HorizonWall')
    for _,nb in ipairs(V.require('VisibleNeighborhood').apply(game.overworld).neighbors or{})do
     local ids={};for _,v in ipairs(receipt.active and receipt.active.ids or{})do ids[v]=true end;ids[nb.map.id]=true
     local list={};for _,n in ipairs(game.overworld.neighbors or{})do if ids[n.map.id]then list[#list+1]=n end end
     local status=H.cacheStatus({map=game.overworld.map,neighbors=list,worldMaps=game.overworld.worldMaps})
     print('SEVII_RING_MISSING',nb.map.id,not not C.ready(nb.map,true),C.auxReady(nb.map),A.prepared(nb.map),C.building(nb.map,true),C.pending(),require('src.link.Json').encode(status))
    end
    assert(U.shot(game,out..'/ring-failure-'..r[4]..'.png'))
   end
   assert(ring,'published neighbourhood incomplete '..id)
  end
  local current=game.overworld.map;local cave=M.profile(current)
  if r[4]=='sea-only-surf'then
   local C=V.require('ChunkMesher');local opaque=assert(C.ready(current,true))
   assert(opaque.__voxelMeshBundle and opaque.waterOnly and not opaque.base and #opaque.instances==0,'pure sea invents opaque ground')
   assert(game.overworld.player.surfing,'surf state lost on sea-only map')
   assert(C.auxReady(current),'water pass not published')
   local body,water=C.pair(current,true)
   assert(body==opaque and water and water~=body,'water-only cache pair not atomic')
   print('SEVII_WATER_ONLY_BUNDLE',current.id,'empty-opaque','separate-water','surfing')
  end
  if cave.kind=='cave'then
   local geometry=assert(V.require('SeviiCaveEnclosure').geometry({map=current,ox=0,oy=0},nil,nil,nil,visualMode=='basic'))
   local walls,roof=false,false
   assert(liveRimMap==current,'no live cavern rim receipt '..id)
   for _,rim in ipairs(liveRims or{})do
    if rim.class==(visualMode=='basic'and'native_sevii_cave'or'cave_'..cave.cave)then
     assert(rim.unmaskedRoom,'floor mask clips high cave wall '..id)
     walls=walls or rim.kind=='wall';roof=roof or rim.kind=='ground'
    end
    roof=roof or rim.class=='interior_ceiling'and rim.kind=='ground'
   end
   assert(#geometry.ceilingVertices>0,'missing cavern ceiling '..id)
   if geometry.caveBoundaryPanels>0 then assert(walls,'cavern boundary absent from live mesh '..id)end
   assert(roof,'cavern ceiling absent from live mesh '..id)
   print('SEVII_CAVE_ENCLOSURE',id,geometry.caveBoundaryPanels,#geometry.ceilingVertices/4)
  end
  if os.getenv('SEVII_GRASS_QUALITY')=='1'and(r[4]=='berry-forest'or r[4]=='pattern-bush'or r[4]=='meadow')then
   local map=game.overworld.map;local pixels=require('src.render.Assets').imageData(map.tileset.image)
   local shapes=T.forMap(map);local structures={shapeAt={},tileAt={}}
   local grassCells,expectedTufts=0,0
   for yy=0,map.heightCells-1 do for xx=0,map.widthCells-1 do
    if map:isGrassCell(xx,yy)then grassCells=grassCells+1
     for dy=0,1 do for dx=0,1 do local tx,ty=xx*2+dx,yy*2+dy;local key=(ty+64)*4096+tx+64
      structures.tileAt[key]=map:tileAt(tx,ty);structures.shapeAt[key]=T.at(map,shapes,structures.tileAt[key],tx,ty)
      if M.token(map,tx,ty)=='g'and not M.portalAt(map,xx,yy)and not map:isWaterCell(xx,yy)then expectedTufts=expectedTufts+1 end
      assert(not map:isWaterCell(xx,yy),'imported grass mislabeled as Kanto shore')
     end end
    end
   end end
   V.require('Structures').buildGrass(structures,map,0,map.def.width*4-1,0,map.def.height*4-1,pixels)
   local placements=0;local mask=assert(V.require('SeviiNativeVoxel').grassMask(map))
   for _,group in ipairs(structures.grassGroups)do
    placements=placements+#group.placements/2;assert(#group.quads>0,'missing grass blades')
    for _,q in ipairs(group.quads)do for _,uv in ipairs(q.uv)do
     local px,py=math.floor(uv[1]*map.tileset.imageWidth),math.floor(uv[2]*map.tileset.imageHeight)
     assert(mask(pixels:getPixel(px,py)),'standing grass samples background floor')
    end end
   end
   assert(grassCells>0 and placements==expectedTufts,'grass density/ownership changed '..grassCells..' cells '..placements..' tufts')
   local recolored=V.require('Gen1OutdoorScenery').grassGroups(map,structures.grassGroups)
   if visualMode=='full'then
    local canonical=assert(V.require('Structures').kantoGrassTemplate())
    local total=0
    for _,group in ipairs(recolored)do total=total+#group.placements/2;assert(#group.quads==#canonical,'Sevii grass differs from Kanto mesh')
     for i,q in ipairs(group.quads)do assert(q.uv[1][1]==-166,'Kanto blade material missing')
      local coastal=q[2][1]~=canonical[i][2][1]or q[2][2]~=canonical[i][2][2]
      for n=1,4 do
       local v=canonical[i][n]
       assert(q[n][1]==(coastal and 4+(v[1]-4)*.94 or v[1]),'Kanto blade width changed beyond coastal variant')
       assert(q[n][2]==(coastal and v[2]*.92 or v[2]),'Kanto blade height changed beyond coastal variant')
       assert(q[n][3]==v[3],'Kanto blade depth changed')
      end
     end
    end
    assert(total==placements,'coastal variant changed encounter density')
   else assert(recolored==structures.grassGroups,'overhaul OFF recolored original grass')end
   print('SEVII_GRASS_MESH_PASS',r[4],grassCells,placements,visualMode)
  end
  local visible=V.require('VoxelFurniture').find(game.overworld.map);local enabled=0;for _,p in ipairs(visible)do if p.claimed then enabled=enabled+1 end end
  local activeProfile=M.profile(game.overworld.map)
  local activeCenter=activeProfile.theme=='center'and activeProfile.source:match('PokemonCenter_1F$')~=nil
  local upperCenter=activeProfile.theme=='center'and activeProfile.source:match('PokemonCenter_2F$')~=nil
  if activeProfile.kind=='room'then
   for _,actor in ipairs(game.overworld.npcs or{})do
    assert(not actor.wildsAmbientPokemon,'ambient Wilds Pokemon spawned in an authored Sevii room '..r[4])
   end
   for _,actor in ipairs(game.overworld.entities or{})do
    assert(not actor.wildsAmbientPokemon,'ambient Wilds entity spawned in an authored Sevii room '..r[4])
   end
  end
  if activeCenter or upperCenter then
   local guests=0
   for _,actor in ipairs(game.overworld.npcs or{})do
    if actor.def and actor.def.name and actor.def.name:match(
       activeCenter and'^KA_SEVII_CENTER_VISITOR_'or'^KA_SEVII_UPPER_VISITOR_')then guests=guests+1 end
   end
   assert(guests==(upperCenter and 2 or activeProfile.source=='OneIsland_PokemonCenter_1F'and 5 or 4),
    'Sevii Center guests missing '..r[4])
  end
  if activeProfile.kind=='room'and visualMode~='basic'then
   assert(enabled>=(activeProfile.theme=='mart'and 6
       or activeProfile.source=='TwoIsland_JoyfulGameCorner'and 8
       or #activeProfile.props-(activeProfile.source=='OneIsland_PokemonCenter_1F'and 4 or 0)),
    'room presented without its voxel objects '..r[4])
  end
  if visualMode=='basic'then
   assert(enabled==0,'disabled replacement still claims source art '..r[4])
   local H=V.require('HorizonWall');local room=M.room(game.overworld.map)
   if room then
    assert(H.hasInteriorShell(game.overworld.map) and H.interiorProfileFor(game.overworld.map).nativeSourceWalls,'normal voxel room has no source-art enclosure')
    assert(H.setting:get()=='off','native room changed overhaul preference')
   else assert(not H.hasInteriorShell(game.overworld.map),'outdoor room shell')end
   local native=assert(V.require('Structures').peek(game.overworld.map),'native analysis missing')
   for _,stamp in ipairs(native.buildingStamps or{})do assert(#stamp.quads>0,'empty native-art model')end
   if r[4]=='home'then assert(#native.buildingStamps>=11,'wall claims flattened original devices/plants')end
   if r[4]=='one-town'or r[4]=='home'then assert(native.buildingStamps and #native.buildingStamps>=3,'source art was not dimensionalized')end
  elseif visualMode=='nature'then
   for _,p in ipairs(visible)do if P.models[p.kind].glassKind then assert(not p.claimed,'disabled building still claimed')end end
  end
  if r[4]=='berry-forest'and visualMode~='basic'then assert(enabled>20,'forest lost voxel props')end
  if visualMode=='full'and(r[4]=='home'or r[4]=='center')then
   local house=V.require('HouseWindows').describe(game.overworld.map)
   print('SEVII_WINDOWS',r[4],house and house.source,house and #house.panes)
   assert(house and #house.panes>0,'Sevii windows missing '..r[4])
   local panels=V.require('Gen1InteriorLayout').panelsFor(game.overworld.map,M.room(game.overworld.map));local doors=0
   for _,panel in ipairs(panels)do doors=doors+#panel.openings end
   assert(doors>0,'Sevii entrance missing from room shell')
  end
  print('SEVII_PRESENTED_PROPS',r[4],enabled);assert(U.shot(game,out..'/'..r[4]..'.png'));print('SEVII_VOXEL_SHOT',r[4],id)
  if os.getenv('SEVII_PARITY_REFERENCE_2D')=='1'then
   local mapId,cellX,cellY=game.overworld.map.id,game.overworld.player.cellX,game.overworld.player.cellY
   require('src.render.Pipelines').setLevel('voxel',0)
   require('src.render.Pipelines').syncOptions(game.save.options);U.wait(60)
   assert(U.shot(game,out..'/'..r[4]..'-2d.png'))
   assert(game.overworld.map.id==mapId and game.overworld.player.cellX==cellX
     and game.overworld.player.cellY==cellY,'2D reference moved its coordinate')
   print('SEVII_2D_REFERENCE',r[4],id,cellX,cellY)
   setCamera(1);U.wait(60)
  end
  if os.getenv('SEVII_SEASON_QUALITY')=='1'then
   local W=V.require('Weather');local B=V.require('SpringBlossom');local G=V.require('Voxel3D')
   for _,season in ipairs{{480,'spring'},{1440,'summer'},{2400,'autumn'},{3360,'winter'},{480,'spring-return'}}do
    W.setClock(season[1]);U.wait(180)
    for frame=1,3000 do
     if not V.require('VoxelScene').pendingReason and not V.require('LoadingCompanion').status().visible then break end
     U.wait(1)
    end
    U.wait(60)
    assert(U.shot(game,out..'/'..r[4]..'-'..season[2]..'.png'))
    local foliage,bare=0,0
    for _,prop in ipairs(visible)do if prop.claimed and P.models[prop.kind].seasonalFoliage then
     local kind=V.require('SeasonalTrees').kind(P,prop.kind,game.overworld.map.id,prop.tx,prop.ty)
     if P.models[kind].seasonalFoliage then foliage=foliage+1 else bare=bare+1 end
    end end
    if visualMode=='full'then
     assert(foliage+bare>20,'no seasonal Sevii trees')
     if season[2]=='winter'then assert(bare>foliage,'winter crowns did not shed')else assert(bare==0,'leaves failed to return')end
     if season[2]:match('spring')then assert(B.count>0,'Sevii blossom petals missing')end
    end
    local sky=V.require('LocalLights').current().sky
    assert(sky and sky.canopy==2 and sky.forest,'source forest lighting absent')
    print('SEVII_SEASON_PASS',r[4],season[2],foliage,bare,B.count,sky.forest.leaves,G._seasonUniform and G._seasonUniform[2])
   end
  end
  local caveEye=os.getenv('SEVII_CAVE_EYE_QUALITY')=='1'and cave.kind=='cave'
    and(os.getenv('SEVII_CAVE_QUALITY')~='1'or not caveEyes[cave.cave]or cave.source=='FourIsland_IcefallCave_1F')
  if caveEye then caveEyes[cave.cave]=true end
  local roomEye=os.getenv('SEVII_PARITY_QUALITY')=='1'and cave.kind=='room'and not roomEyes[cave.theme]
    or os.getenv('SEVII_PRIMARY_HOME_QUALITY')=='1'
  if roomEye then roomEyes[cave.theme]=true end
  if r[4]=='home'or r[4]=='warehouse'or caveEye or roomEye then
   if r[4]=='home'then game.overworld.player.facing='up';setCamera(6);V.require('FirstPerson').yaw=math.pi;U.wait(90);assert(U.shot(game,out..'/home-first-person.png'))end
   game.overworld.player.facing='up';setCamera(7);V.require('FirstPerson').yaw=math.pi;U.wait(90)
   assert(U.shot(game,out..'/'..r[4]..'-eye.png'));setCamera(1);U.wait(60)
  end
 end
 if os.getenv('SEVII_CENTER_ONLY')=='1'or os.getenv('SEVII_CENTER_ALL')=='1'
    or os.getenv('SEVII_CENTER_UPSTAIRS')=='1'or os.getenv('SEVII_INTERIOR_THEMES')=='1'
    or os.getenv('SEVII_RETAIL_QUALITY')=='1'or os.getenv('SEVII_ALL_INTERIORS')=='1'then
  if os.getenv('SEVII_CENTER_CAMERAS')=='1'then
   for _,camera in ipairs{{6,'first-person'},{7,'third-person'}}do
    setCamera(camera[1]);U.wait(90)
    assert(not V.require('VoxelScene').pendingReason,'Center camera failed '..camera[2])
    assert(U.shot(game,out..'/center-'..camera[2]..'.png'))
    print('SEVII_CENTER_CAMERA_PASS',camera[2],game.overworld.map.id)
   end
  end
  print('SEVII_CENTER_ONLY_PASS',visualMode);love.event.quit();return
 end
 if os.getenv('SEVII_WATER_ONLY_QUALITY')=='1'then print('SEVII_WATER_ONLY_QUALITY_PASS',visualMode);love.event.quit();return end
 if os.getenv('SEVII_WAREHOUSE_QUALITY')=='1'then print('SEVII_WAREHOUSE_QUALITY_PASS',visualMode);love.event.quit();return end
 if os.getenv('SEVII_PRIMARY_HOME_QUALITY')=='1'then print('SEVII_PRIMARY_HOME_QUALITY_PASS',visualMode);love.event.quit();return end
 if os.getenv('SEVII_SEASON_QUALITY')=='1'then print('SEVII_SEASON_QUALITY_PASS',visualMode);love.event.quit();return end
 if os.getenv('SEVII_PARITY_QUALITY')=='1'
     or os.getenv('SEVII_KANTO_INTERIORS_ONLY')=='1'then
  local references=os.getenv('SEVII_KANTO_INTERIORS_ONLY')=='1'and{
   {'REDS_HOUSE_1F',3,5},{'VIRIDIAN_POKECENTER',5,5},
   {'VIRIDIAN_MART',5,5},{'GAME_CORNER',8,9},
  }or{
   {'PALLET_TOWN',6,8},{'VIRIDIAN_CITY',10,10},{'CERULEAN_CITY',12,12},
   {'CINNABAR_ISLAND',9,8},{'ROUTE_1',6,10},{'ROUTE_12',10,20},
   {'ROUTE_20',10,10},{'ROUTE_23',10,20},{'VIRIDIAN_FOREST',10,12},
   {'REDS_HOUSE_1F',3,5},{'VERMILION_TRADE_HOUSE',3,5},
   {'VIRIDIAN_POKECENTER',5,5},{'GAME_CORNER',8,9},
   {'SEAFOAM_ISLANDS_1F',8,8},{'MT_MOON_1F',10,10},{'ROCK_TUNNEL_1F',10,10},
  }
  for _,r in ipairs(references)do
   local map=Loader.load(game.data,r[1]);local bx,by,best=nil,nil,math.huge
   for y=0,map.heightCells-1 do for x=0,map.widthCells-1 do
    local score=(x-r[2])^2+(y-r[3])^2
    if score<best and map:isWalkableCell(x,y)and not map:warpAtCell(x,y)then best,bx,by=score,x,y end
   end end
   assert(bx,'no Kanto reference plot '..r[1]);U.teleport(game,r[1],bx,by,'down');Q.settle();setCamera(1);U.wait(45)
   assert(not M.profile(game.overworld.map),'Sevii rules leak into Kanto '..r[1])
   assert(U.shot(game,out..'/kanto-'..r[1]..'.png'))
   if not map.def.outdoor then
    game.overworld.player.facing='up';setCamera(7);V.require('FirstPerson').yaw=math.pi;U.wait(60)
    assert(U.shot(game,out..'/kanto-'..r[1]..'-eye.png'));setCamera(1)
   end
   print('SEVII_PARITY_KANTO_REFERENCE',r[1],bx,by)
  end
  print('SEVII_PARITY_QUALITY_PASS',#representatives,#references,visualMode)
  love.event.quit();return
 end
 if os.getenv('SEVII_GRASS_QUALITY')=='1'then
  local map=Loader.load(game.data,'ROUTE_1');local gx,gy
  for yy=2,map.heightCells-3 do for xx=2,map.widthCells-3 do
   if not gx and map:isGrassCell(xx,yy)and map:isWalkableCell(xx,yy)then gx,gy=xx,yy end
  end end
  assert(gx,'Kanto comparison grass absent');U.teleport(game,'ROUTE_1',gx,gy,'down');Q.settle();setCamera(1);U.wait(120)
  assert(not V.require('SeviiNativeVoxel').grassMask(game.overworld.map),'Sevii mask leaked into Kanto')
  assert(U.shot(game,out..'/kanto-grass-reference.png'));print('KANTO_GRASS_REFERENCE_PASS',visualMode)
 end
 for _,lane in ipairs{11,12,13}do
  local id,x,y=S.location('OneIsland',lane,17);U.teleport(game,id,x,y,'up');Q.settle();U.wait(120)
  for wait=1,1800 do if not V.require('WorldSceneHold').loading(game.overworld)then break end;U.wait(1)end
  if V.require('WorldSceneHold').loading(game.overworld)then
   print('SEVII_BRIDGE_PRESENT_FAILURE',V.require('VoxelScene').pendingReason,
    V.require('WorldSceneHold').serial(),V.require('ChunkMesher').pending(),
    require('src.link.Json').encode(V.require('VoxelScene').planStatus()))
   U.shot(game,out..'/bridge-failure.png')
  end
  assert(not V.require('WorldSceneHold').loading(game.overworld),'bridge scene did not become ready')
  local map=game.overworld.map;local elevation=V.require('LedgeElevation').map(map)
  local _,tx,ty=S.location('OneIsland',lane,15)
  local furniture=V.require('VoxelFurniture')
  local south=elevation:at(tx,ty+1);local north=elevation:at(tx,ty-1)
  assert(north-south==(visualMode=='basic'and 0 or 6),'bridge landing height mismatch')
  if visualMode~='basic'then
   assert(furniture.actorSupportAt(map,tx*16,ty*16-7.999)==north,'north stair endpoint mismatch')
   assert(furniture.actorSupportAt(map,tx*16,ty*16+7.999)==south,'south stair endpoint mismatch')
  end
  Q.walkTo(x,y-3)
  assert(game.overworld.map.id==id and game.overworld.player.cellX==x and game.overworld.player.cellY==y-3,'bridge lane not traversable')
 end
 local bid,bx,by=S.location('OneIsland',12,16);U.teleport(game,bid,bx,by,'up');Q.settle();U.wait(120)
 setCamera(7);U.wait(90);assert(U.shot(game,out..'/bridge-eye.png'))
 setCamera(1);U.wait(60);assert(U.shot(game,out..'/bridge.png'))
 print('SEVII_BRIDGE_THREE_LANES_AND_ENDPOINTS_PASS')
 if visualMode=='basic'then
  local function waitRebuild()
   U.wait(15);local stable=0
   for frame=1,3000 do U.wait(1)
    if not V.require('VoxelScene').pendingReason and not V.require('WorldSceneHold').loading(game.overworld)then stable=stable+1 else stable=0 end
    if stable>=45 then return end
   end;error('mode switch did not present')
  end
  applyMode('full');waitRebuild()
  local n=0;for _,o in ipairs(V.require('VoxelFurniture').find(game.overworld.map))do if o.claimed then n=n+1 end end
  assert(n>0,'overhaul toggle did not restore models')
  applyMode('basic');waitRebuild()
  for _,o in ipairs(V.require('VoxelFurniture').find(game.overworld.map))do assert(not o.claimed,'overhaul model survived OFF')end
  require('src.render.Pipelines').setLevel('voxel',0);require('src.render.Pipelines').syncOptions(game.save.options)
  for frame=1,600 do U.wait(1);if not V.require('VoxelState').active()then break end end
  assert(not V.require('VoxelState').active(),'2D return stayed voxel')
  setCamera(1);waitRebuild();assert(V.require('VoxelState').active(),'native voxel return failed')
  assert(U.shot(game,out..'/bridge-after-toggle.png'))
  print('SEVII_NORMAL_FULL_NORMAL_2D_ROUNDTRIP_PASS')
 end

 if os.getenv('SEVII_QUICK_QUALITY')=='1'then print('SEVII_QUICK_QUALITY_PASS',visualMode);love.event.quit();return end
 local id,x,y=S.location('OneIsland',12,14);U.teleport(game,id,x,y,'down');Q.settle()
 for _,mode in ipairs{{6,'first-person'},{7,'third-person'}}do
  setCamera(mode[1]);U.wait(150)
  for frame=1,3000 do if not V.require('VoxelScene').pendingReason and not V.require('LoadingCompanion').status().visible then break end;U.wait(1)end
  assert(not V.require('VoxelScene').pendingReason,V.require('VoxelScene').pendingReason);assert(U.shot(game,out..'/'..mode[2]..'.png'))
 end
 V.require('DayNight').setting:setValue('night',game);U.wait(150);assert(U.shot(game,out..'/night.png'))
 love.window.setMode(540,960,{resizable=true,vsync=1});require('src.core.TouchControls'):setPreview(true)
 U.wait(150);assert(U.shot(game,out..'/portrait.png'))
 love.window.setMode(1100,760,{resizable=true,vsync=1});require('src.core.TouchControls'):setPreview(false)
 V.require('DayNight').setting:setValue('day',game)
 end
 local B,BS=V.require('OverworldBattle'),V.require('BattleScene');local renders=0;local render=BS.render
 BS.render=function(...)local im=render(...);if im then renders=renders+1 else local st,ar=...;local terrain,_,_,_,plan=V.require('VoxelScene').prefetch(st);print('SEVII_BATTLE_DECLINE',BS.lastDeclineReason,V.require('VoxelScene').pendingReason,ar.map==st.map,st.map.id,ar.map.id,terrain~=nil,plan~=nil,#(st.neighbors or{}),plan and #(plan.state.neighbors or{}))end;return im end
 B.setting:setValue(true,game)
 local function battleReady()
  for i=1,2000 do local t=game.stack:top()
   if t.enemy and t.phase=='menu'and not t.current and not t.sendingOut and not t.enemySendingOut then return t end
   U.wait(1);if i%18==0 then U.tap(game,'a')end
  end
  local t=game.stack:top();print('SEVII_BATTLE_START_FAILURE',t.phase,t.current,t.sendingOut,t.enemySendingOut,t.enemy~=nil)
  U.shot(game,out..'/battle-start-failure.png');error('Sevii battle did not start')
 end
 local battles={{'ThreeIsland_BerryForest',14,12,'forest-map-battle',false},{'OneIsland_TreasureBeach',10,12,'sea-map-battle',true}}
 if os.getenv('SEVII_CAVE_BATTLE_QUALITY')=='1'then
  battles[#battles+1]={'FourIsland_IcefallCave_1F',8,8,'ice-map-battle',false}
  battles[#battles+1]={'MtEmber_RubyPath_1F',7,8,'ruby-map-battle',false}
 end
 if os.getenv('SEVII_BATTLE_CASE')then
  local picked={};for _,area in ipairs(battles)do if area[4]==os.getenv('SEVII_BATTLE_CASE')then picked[#picked+1]=area end end
  assert(#picked==1,'unknown battle case');battles=picked
 end
 for _,area in ipairs(battles)do
  local mid,xx,yy=S.location(area[1],area[2],area[3]);local map=Loader.load(game.data,mid)
  if area[5]then xx=nil;for cy=3,map.heightCells-4 do for cx=3,map.widthCells-4 do if not xx and map:isWaterCell(cx,cy)then xx,yy=cx,cy end end end;assert(xx)end
  local sceneSerial=V.require('WorldSceneHold').serial()
  U.teleport(game,mid,xx,yy,'down');Q.settle();game.overworld.player.surfing=area[5];U.wait(180)
  local ready=false;local stable=0
  for frame=1,3000 do U.wait(1)
   if not V.require('VoxelScene').pendingReason and not V.require('WorldSceneHold').loading(game.overworld)and V.require('WorldSceneHold').serial()>sceneSerial+8 then stable=stable+1 else stable=0 end
   if stable>=45 then ready=true;break end
  end
  assert(ready,'battle source scene did not present: '..tostring(V.require('VoxelScene').pendingReason))
  for _,mon in ipairs(game.save.party)do mon.hp=mon.stats.hp;mon.status=nil end
  local battle=require('src.battle.BattleState').newWild(game,area[5]and'TENTACRUEL'or'PIDGEOT',60)
  game.overworld:pushBattle(battle);assert(battleReady()==battle);local before=renders;U.wait(90)
  local arena=assert(B.arena());print('SEVII_BATTLE_STAGE',area[4],arena.presentationMode,arena.map.id,arena.fallbackReason);assert(arena.presentationMode=='MAP'and M.profile(arena.map),'Sevii MAP fallback')
  assert(renders>before+10,'Sevii battle renderer stalled');assert(U.shot(game,out..'/'..area[4]..'.png'))
  print('SEVII_MAP_BATTLE_PASS',area[4],arena.map.id,renders-before)
  B.finish();while game.stack:top()~=game.overworld do game.stack:pop()end
 end
 if os.getenv('SEVII_BATTLE_ONLY')~='1'then print('SEVII_CAMERA_PORTRAIT_NIGHT_PASS')end
 print('SEVII_FULL_VOXEL_AUDIT_PASS',counts.maps,counts.cells,counts.props,counts.buildings)
 love.event.quit()
end
