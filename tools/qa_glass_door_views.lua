-- Run with the native host's POKEPORT_DRIVER seam and a disposable
-- POKEPORT_IDENTITY. VASC_DOOR_ASSETS is the absolute output directory.
-- Captures static destination views; never runs during ordinary gameplay.
return function(game)
 local dir=assert(os.getenv('VASC_DOOR_ASSETS'))
 local U=require('tests.drivers.util')
 love.audio.setVolume(0)
 io.stdout:setvbuf('no')
 love.window.hasFocus=function()return true end
 love.window.isVisible=function()return true end
 love.keyboard.isDown=function()return false end
 love.joystick.getJoysticks=function()return{}end
 love.window.setMode(640,480,{vsync=0})
 game:startNewGame{intro=false}
 local e=assert(game.mods.exports.VOXEL_ASCENDANT)
 e.setupCard.suspended=true
 e.ascendantContent.promptDisabled=true
 e.ascendantContent.onboardingShown=true
 game.save.flags.EVENT_FOLLOWED_OAK_INTO_LAB=true
 game.save.flags.EVENT_GOT_STARTER=true
 U.teleport(game,'PALLET_TOWN',8,9,'down')
 require('src.render.Pipelines').setLevel('voxel',6)
 U.wait(60)
 -- QA runs in the native driver, outside the mod sandbox.
 local function find(fn,name,seen)
  if type(fn)~='function'then return end
  seen=seen or{};if seen[fn]then return end;seen[fn]=true
  for i=1,100 do
   local k,v=debug.getupvalue(fn,i);if not k then break end
   if k==name then return v end
  end
  for i=1,100 do
   local k,v=debug.getupvalue(fn,i);if not k then break end
   local value=find(v,name,seen);if value then return value end
  end
 end
 local V=assert(find(e.lib.require('VoxelScene').render,'V'))
 local scene=V.require('VoxelScene')
 local function ready(label)
  for n=1,2400 do
   if n>60 and V.require('VoxelState').ready and not scene.pendingReason then return end
   U.wait(1)
  end
  error('Doorway capture timeout: '..label..' '..tostring(scene.pendingReason))
 end
 V.require('Weather').setting:setValue('clear',game,true)
 V.require('DayNight').setting:setValue('day',game,true)
 local F=V.require('FirstPerson');local D=V.require('Gen1GlassDoors');D.configure(game.data)
 local render,args=scene.render
 scene.render=function(...)args={...};return render(...)end
 local loader=require('src.world.MapLoader')
 local rows={};local captured=0
 for id,city in pairs(D.entrances)do
  if not os.getenv('VASC_DOOR_GYMS_ONLY')or V.require('Gen1GymInteriors').profiles[id]then rows[#rows+1]={id=id,city=city}end
 end
 table.sort(rows,function(a,b)return a.city<b.city or a.city==b.city and a.id<b.id end)
 local function capture(id,x,y,facing,key)
  if os.getenv('VASC_DOOR_ONLY_MISSING')then local f=io.open(dir..'/'..key..'.png','rb');if f then f:close();return end end
  U.teleport(game,id,x,y,facing);ready(id)
  F.yaw=({down=0,up=math.pi,left=-math.pi/2,right=math.pi/2})[facing];F.pitch=.06
  game.overworld.entities={};U.wait(30)
  local state=args[1];state.entities={}
  for _,nb in ipairs(state.neighbors or{})do nb.entities={}end
  local canvas=assert(render(unpack(args)));local data=canvas:newImageData()
  local out=assert(io.open(dir..'/'..key..'.png','wb'))
  out:write(data:encode('png'):getString());out:close();data:release()
  print('CAPTURE',key,id,x,y,canvas:getDimensions());captured=captured+1
 end
 local directions={north={0,-1,'up','down'},south={0,1,'down','up'},west={-1,0,'left','right'},east={1,0,'right','left'}}
 local function edgeFor(room,w)
  local gym=V.require('Gen1GymInteriors').exitDoor(room)
  if gym and w.y==room.def.height*2-1 and w.x*16>=gym.from and w.x*16<gym.upto then return 'south'end
  local p=assert(V.require('Gen1InteriorPanoramas').profileFor(room))
  for _,panel in ipairs(V.require('Gen1InteriorLayout').panelsFor(room,p))do
   local horizontal=panel.edge=='north'or panel.edge=='south'
   local along=(horizontal and w.x or w.y)*16
   local across=(horizontal and w.y or w.x)*16
   local row=panel.at-((panel.edge=='south'or panel.edge=='east')and 16 or 0)
   if across==row and along>=panel.from and along<panel.upto and not panel.column and not panel.endcap then
    for _,door in ipairs(panel.openings)do
     if door.material=='room_glass_door'and along>=door.from and along<door.upto then return panel.edge end
    end
   end
  end
  print('SKIP non-door warp',room.id,w.x,w.y);return nil
 end
 for _,row in ipairs(rows)do
  local room=loader.load(game.data,row.id)
  for _,w in ipairs(room.def.warps)do if D.interior(room,w.destMap)then
   local cityId=w.destMap=='LAST_MAP'and row.city or w.destMap
   local rules=require('src.world.FieldDefaults').field(game.data,'lastMapRewrites')
   if w.destMap=='LAST_MAP'and rules and rules[row.id]then
    cityId=require('src.world.OverworldController').rewrittenLastMap(rules[row.id],w.x,w.y)or cityId
   end
   local city=assert(game.data.maps[cityId],cityId)
   local back=assert(city.warps[w.destWarp],row.id..':'..tostring(w.destWarp))
   assert(back.destMap==row.id,'reciprocal native door mismatch: '..row.id..' '..cityId)
   local dir=directions[edgeFor(room,w)]
   if dir then capture(cityId,back.x+dir[1],back.y+dir[2],dir[3],D.outViewKey(room,w))end
  end end
  local seen={}
  for cityId,city in pairs(game.data.maps)do if city.tileset=='OVERWORLD'or cityId=='INDIGO_PLATEAU'and city.tileset=='PLATEAU'or cityId=='VIRIDIAN_FOREST'and city.tileset=='FOREST'then
   for _,back in ipairs(city.warps or{})do if back.destMap==row.id and D.transition({id=cityId,def=city},row.id)then
    local key=D.inViewKey(row.id,back.destWarp)
    if not seen[key]then
     local w=assert(room.def.warps[back.destWarp],key)
     local dir=directions[edgeFor(room,w)]
     if dir then capture(row.id,w.x-dir[1],w.y-dir[2],dir[4],key);seen[key]=true end
    end
   end end
  end end
 end
 print('PASS captured native doorway views',captured)
 love.event.quit()
end
