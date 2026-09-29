return function(game)
 assert(os.getenv('POKEPORT_IDENTITY')=='vasc-video-polish-qa');love.audio.setVolume(0)
 local U=require('tests.drivers.util');game:startNewGame{intro=false}
 local ex=game.mods.exports.VOXEL_ASCENDANT;ex.setupCard.suspended=true
 ex.ascendantContent.promptDisabled=true;ex.ascendantContent.onboardingShown=true
 local function find(fn,name,seen)
  if type(fn)~='function'then return end;seen=seen or{};if seen[fn]then return end;seen[fn]=true
  for i=1,100 do local k,v=debug.getupvalue(fn,i);if not k then break end;if k==name then return v end end
  for i=1,100 do local k,v=debug.getupvalue(fn,i);if not k then break end;local x=find(v,name,seen);if x then return x end end
 end
 local V=assert(find(ex.lib.require('VoxelScene').render,'V'))
 V.require('Gen1PalletVillage').buildings:setValue(true,game,true)
 ex.voxelCharacterCard.setting:setValue(true,game);assert(ex.voxelCharacterCard.select('voxel',game))
 local R=V.require('Voxel3D');assert(R.prewarmWorldCards)
 local walking=assert(ex.overworldPokemon.walkingSprites)
 local scenery=walking.scenerySprite
 if os.getenv('QA_CURRENT_ONLY')=='1'then walking.scenerySprite=nil end
 game.save.flags.EVENT_FOLLOWED_OAK_INTO_LAB=true;game.save.flags.EVENT_GOT_STARTER=true
 while game.stack:top()do game.stack:pop()end
 love.window.setMode(1710,958,{resizable=true,vsync=0})
 require('src.render.Pipelines').setLevel('voxel',6)
 game.stack:push(require('src.world.OverworldController'),os.getenv('QA_CARD_MAP')or'ROUTE_16',14,11,'right')
 local world=V.require('VisibleNeighborhood').apply(game.overworld)
 local Assets=require('src.render.Assets');local image=Assets.image
 local phase='preparing';local calls={preparing={},after={}};local steps,maxStep=0,0
 Assets.image=function(path,...)
  local t=love.timer.getTime();local out=image(path,...)
  calls[phase][#calls[phase]+1]={path=tostring(path),ms=(love.timer.getTime()-t)*1000}
  return out
 end
 -- No draw/update between these calls: unrelated rendering cannot warm the
 -- cache behind the fixture's back. Each call remains the production one-step
 -- preparation API. This fixture's aggregate loop is not a load-time benchmark.
 local positions={}
 for _,e in ipairs(world.entities or{})do positions[e]={e.px,e.py,e.sprite}end
 for _,g in ipairs(world.ghosts or{})do positions[g.npc]={g.npc.px,g.npc.py,g.npc.sprite}end
 local t=love.timer.getTime()
 while not R.worldCardsReady(world)and steps<2000 do
  local st=love.timer.getTime();assert(R.prewarmWorldCards(world),'pending cards made no progress')
  maxStep=math.max(maxStep,(love.timer.getTime()-st)*1000);steps=steps+1
 end
 assert(R.worldCardsReady(world),'preparation never finished')
 local preparingMs=(love.timer.getTime()-t)*1000
 walking.scenerySprite=scenery
 phase='after';local checked=0;local identities={}
 local resident={};for _,nb in ipairs(world.neighbors or{})do resident[nb.map]=true end
 for _,g in ipairs(world.ghosts or{})do
  if resident[g.map]then
   local sprite=scenery(g.map.id,g.npc.def,g.npc.sprite)
   if sprite and sprite.def.ascendantAtlasImage then
    checked=checked+1;identities[#identities+1]={map=g.map.id,id=g.npc.id,atlas=sprite.def.ascendantAtlasImage}
    assert(sprite:resolveImage(),'missing prepared image')
   end
  end
 end
 for e,p in pairs(positions)do assert(e.px==p[1]and e.py==p[2]and e.sprite==p[3],'prewarm changed entity')end
 assert(checked>1,'no future human appearances exercised')
 if os.getenv('QA_CURRENT_ONLY')~='1'then assert(#calls.after==0,'texture loads remained after ready')end
 if os.getenv('QA_CURRENT_ONLY')~='1'then
  local n=#calls.after
  for i=1,30 do assert(R.worldCardsReady(world))end
  assert(#calls.after==n,'readiness loaded images')
  calls.validation={};phase='validation'
  local clone={};for k,v in pairs(world)do clone[k]=v end
  clone.map=setmetatable({},{__index=world.map})
  clone.ghosts={};for _,g in ipairs(world.ghosts or{})do clone.ghosts[#clone.ghosts+1]=g end
  local other={id='QA_UNCONNECTED'}
  clone.neighbors={};for _,nb in ipairs(world.neighbors or{})do clone.neighbors[#clone.neighbors+1]=nb end
  clone.neighbors[#clone.neighbors+1]={map=other}
  clone.ghosts[#clone.ghosts+1]={map=other,npc={def={},sprite={def={}}}}
  local attempts,unrelated=0,false
  walking.scenerySprite=function(mapId,...)
   if mapId=='QA_UNCONNECTED'then unrelated=true end
   attempts=attempts+1;error('QA optional preview failure')
  end
  assert(not R.worldCardsReady(clone),'new map reused stale receipt')
  assert(#calls.validation==0,'cold readiness performed IO')
  for i=1,200 do if R.worldCardsReady(clone)then break end;assert(R.prewarmWorldCards(clone))end
  assert(R.worldCardsReady(clone)and attempts>0,'optional failure blocked readiness')
  assert(not unrelated,'prepared unrelated map')
  walking.scenerySprite=scenery
  assert(not R.worldCardsReady(world),'return reused failed foreign map receipt')
  for i=1,200 do if R.worldCardsReady(world)then break end;assert(R.prewarmWorldCards(world))end
  assert(R.worldCardsReady(world),'return preparation did not recover')
 end
 local ghostAudit={}
 for _,g in ipairs(world.ghosts or{})do local d=g.npc.sprite and g.npc.sprite.def or{};ghostAudit[#ghostAudit+1]={map=g.map and g.map.id,id=d.id,image=d.image,atlas=d.ascendantAtlasImage}end
 local result={ghostAudit=ghostAudit,mode=os.getenv('QA_CURRENT_ONLY')=='1'and'current-only-reference'or'resident-neighbors',steps=steps,maxStepMs=maxStep,
 totalMs=preparingMs,identities=identities,checked=checked,entities=#(world.entities or{}),ghosts=#(world.ghosts or{}),neighbors=#(world.neighbors or{}),calls=calls}
 local f=assert(io.open(assert(os.getenv('SHOT_DIR'))..'/cards.json','w'));f:write(assert(require('src.link.Json').encode(result)));f:close()
 print('PASS_NEIGHBOR_CARDS',result.mode,steps,checked,#calls.after)
 Assets.image=image;walking.scenerySprite=scenery;love.event.quit(0)
end
