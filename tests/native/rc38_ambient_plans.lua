return function(game)
 assert(os.getenv('POKEPORT_IDENTITY')=='vasc-video-polish-qa');love.audio.setVolume(0);io.stdout:setvbuf('no')
 game:startNewGame{intro=false}
 local ex=game.mods.exports.VOXEL_ASCENDANT;ex.setupCard.suspended=true
 ex.ascendantContent.promptDisabled=true;ex.ascendantContent.onboardingShown=true
 local iw=assert(game.mods.exports.kanto_ascendant.internalWilds)
 local E=iw.exports;local A=E.lib.require('ambient_pokemon');local Config=E.lib.require('config')
 assert(Config.townPokemonEnabled(iw.proxy),'QA town option disabled')
 local manager=A.new(iw.proxy,{seed=290928,render=E.render})
 local searches=0;local original=manager.findSpawnCell
 function manager:findSpawnCell(...)searches=searches+1;return original(self,...)end
 local function signature()
  local a={};for n in pairs(manager.active)do a[#a+1]=n.ambientSpecies..':'..n.cellX..','..n.cellY..':'..n.ambientBehavior end
  table.sort(a);return table.concat(a,'|')
 end
 local rows={};local movingChecks=0
 for _,id in ipairs{'PALLET_TOWN','VIRIDIAN_CITY','PEWTER_CITY','CERULEAN_CITY','VERMILION_CITY','LAVENDER_TOWN','CELADON_CITY','SAFFRON_CITY','FUCHSIA_CITY','CINNABAR_ISLAND'}do
  local map=require('src.world.MapLoader').load(game.data,id)
  local ow={map=map,npcs={},entities={}}
  -- Authored NPCs participate in collision; keep real map furniture/warps.
  for _,obj in ipairs(map.def.objects or{})do
   if obj.sprite and game.data.sprites[obj.sprite]then
    local npc=require('src.world.NPC').new(game.data,id,obj);ow.npcs[#ow.npcs+1]=npc;ow.entities[#ow.entities+1]=npc
   end
  end
  for y=2,map.heightCells-3 do
   for x=2,map.widthCells-3 do
    if not ow.player and map:isWalkableCell(x,y)and not(map.isWaterCell and map:isWaterCell(x,y))then ow.player={cellX=x,cellY=y}end
   end
  end
  assert(ow.player);manager.activeMapId=nil
  local t=love.timer.getTime();local n=manager:spawnForMap(game,ow);local cold=(love.timer.getTime()-t)*1000
  assert(n>=1 and n<=2,id..' no safe ambient positions')
  local first=signature();local before=searches;local warm=0
  for i=1,10 do
   manager:clearAll(ow);manager.activeMapId=nil
   for j=1,i*10 do love.math.random()end
   t=love.timer.getTime();assert(manager:spawnForMap(game,ow)==n);warm=warm+(love.timer.getTime()-t)*1000
   assert(signature()==first,id..' rerolled');assert(searches==before,id..' searched cached cells')
   for npc in pairs(manager.active)do assert(A.isSafeSpawnCell(ow,map,npc.cellX,npc.cellY,npc),id..' unsafe placement')end
  end
  -- Exercise the real wandering wrapper; every attempted move must keep space.
  for tick=1,2000 do
   for npc in pairs(manager.active)do
    npc:update(map,ow.entities)
    if npc.moving then
     movingChecks=movingChecks+1
     assert(A.isSafeSpawnCell(ow,map,npc.targetX,npc.targetY,npc),id..' unsafe wander target')
    end
   end
  end
  rows[#rows+1]={map=id,count=n,signature=first,coldMs=cold,warmMeanMs=warm/10}
  manager:clearAll(ow);print('AMBIENT_PLAN',id,n,cold,warm/10)
 end
 assert(movingChecks>0,'no real wandering exercised')
 local f=assert(io.open(assert(os.getenv('SHOT_DIR'))..'/plans.json','w'));f:write(require('src.link.Json').encode(rows));f:close()
 print('PASS_AMBIENT_PLANS',#rows,'cities, 100 returns, 20000 wander ticks',movingChecks,'moving checks');love.event.quit(0)
end
