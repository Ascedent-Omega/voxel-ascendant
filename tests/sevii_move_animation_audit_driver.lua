-- Read-only native coverage inventory; no animation alias is installed here.
return function(game)
 io.stdout:setvbuf('no')
 local U=require('tests.drivers.util')
 local Q=dofile(assert(os.getenv('SEVII_KASC_ROOT'))..'/tests/habitat_playthrough/drivers/common.lua')(game)
 Q.setup();Q.V.setupCard.suspended=true
 love.window.hasFocus=function()return true end;love.window.isVisible=function()return true end
 local K=Q.K;local S=K.seviiExpedition
 assert(K.beyondKanto.activate(game,{decision='qa-animation-coverage-fixture'}))
 U.teleport(game,S.ONE,12,14,'down');Q.settle();K.generationRules.resolve(game);S.install(game)
 local Pokemon=require('src.pokemon.Pokemon');local rows={};local count=0
 game.save.party={Pokemon.new(game.data,'MEWTWO',100)}
 local function inspect(id,level,context)
  local mon=Pokemon.new(game.data,id,level)
  for _,slot in ipairs(mon.moves or{})do
   local move=assert(game.data.moves[slot.id],slot.id)
   local row=rows[slot.id]
   if not row then row={id=slot.id,type=move.type,category=move.category,effect=move.effect,
    animationPresent=game.data.battle_anims.moveAnims[slot.id]~=nil,examples={}};rows[slot.id]=row end
   if #row.examples<5 then row.examples[#row.examples+1]={species=id,level=level,context=context}end
  end
 end
 for _,pool in ipairs(S.habitats.plan.pools)do for _,row in ipairs(pool.species)do
  local id=assert(S.habitats.resolve(game,row));inspect(id,row.level,pool.map);for level=1,100 do inspect(id,level,'level-range '..pool.map)end;count=count+1
 end end
 for _,trainer in ipairs(S.trainers.allRows)do
  for _,row in ipairs(assert(S.trainers.team(game,trainer)))do inspect(row.species,row.level,trainer.id)end
 end
 -- Include authored optional encounters and their level-scaled move sets.
 local optional={}
 for id,row in pairs(S.specialEncounters.rows)do
  local species=assert(K.backendGiftSpecies67.byKey['dex:'..row.dex]);optional[species]='special '..id
 end
 optional[assert(K.backendGiftSpecies67.byKey['dex:485'])]='Heatran mystery'
 for _,id in ipairs{'GROUDON','KYOGRE','RAYQUAZA','LATIAS','LATIOS','JIRACHI','GIRATINA','RAIKOU','ENTEI','SUICUNE','HO_OH','LUGIA','ARTICUNO','ZAPDOS','MOLTRES','MEWTWO'}do
  if game.data.pokemon[id]then optional[id]='authored legend/roamer' end
 end
 local optionalCount=0
 for species,context in pairs(optional)do optionalCount=optionalCount+1;for level=1,100 do inspect(species,level,context)end end
 local list,missing={},{}
 for _,r in pairs(rows)do list[#list+1]=r;if not r.animationPresent then missing[#missing+1]=r end end
 table.sort(list,function(a,b)return a.id<b.id end);table.sort(missing,function(a,b)return a.id<b.id end)
 local out=assert(os.getenv('HABITAT_QA_ROOT'));local f=assert(io.open(out..'/move-animation-coverage.json','w'))
 f:write(require('src.link.Json').encode({species=count,optionalSpecies=optionalCount,moves=list,missing=missing,
  scope='Actual constructor moves for every ordinary habitat at every level 1..100 and every registered trainer team scaled to level 100, plus authored optional legends/roamers at levels 1..100 in the normal expanded Sevii profile.'}));f:close()
 print('SEVII_MOVE_ANIMATION_AUDIT',count,#list,#missing)
 love.event.quit()
end
