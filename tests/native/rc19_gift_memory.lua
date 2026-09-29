return function(game)
 assert(os.getenv('POKEPORT_IDENTITY')=='vasc-video-polish-qa')
 love.audio.setVolume(0);io.stdout:setvbuf('no')
 local ex=assert(game.mods.exports.kanto_ascendant)
 local dir='mods/kanto_ascendant/'
 local options={species=ex.backendGiftSpecies67,catalog=ex.backendNationalCatalog67,
  mega=ex.backendMegaForms67,megaMetadata=love.filesystem.load(dir..'backend_mega_catalog_67_data.lua')(),
  gigantamax=ex.backendGigantamaxForms67,gigantamaxMetadata=love.filesystem.load(dir..'backend_gigantamax_catalog_67_data.lua')()}
 local optimized=ex.backendGiftProfiles67
 collectgarbage('collect');local before=collectgarbage('count')
 local started=love.timer.getTime()
 local reference=assert(loadfile(assert(os.getenv('QA_GIFT_REFERENCE'))))()(options)
 local referenceSeconds=love.timer.getTime()-started
 collectgarbage('collect');local referenceKB=collectgarbage('count')-before
 local function equal(a,b,path)
  assert(type(a)==type(b),path..' type')
  if type(a)~='table'then assert(a==b,path..' value');return end
  for k,v in pairs(a)do equal(v,b[k],path..'.'..tostring(k))end
  for k in pairs(b)do assert(a[k]~=nil,path..' extra '..tostring(k))end
 end
 equal(reference,optimized,'profiles')
 local function count(root)
  local seen,n={},0
  local function walk(t)
   if type(t)~='table'or seen[t]then return end;seen[t]=true;n=n+1
   for k,v in pairs(t)do walk(k);walk(v)end
  end
  walk(root);return n
 end
 local oldCount,newCount=count(reference),count(optimized)
 local tick=love.timer.getTime()
 local rebuilt=assert(love.filesystem.load(dir..'backend_gift_profiles_67.lua'))()(options)
 local optimizedSeconds=love.timer.getTime()-tick
 equal(reference,rebuilt,'rebuilt')
 rebuilt=nil
 print('GIFT_BUILD_SECONDS',referenceSeconds,optimizedSeconds)

 assert(newCount<oldCount*.15,'insufficient history compaction')
 print('GIFT_EXACT_EQUIVALENCE',#optimized.profiles,'oldTables',oldCount,'newTables',newCount,'referenceKB',referenceKB)
 reference=nil;collectgarbage('collect')
 game:startNewGame{intro=false}
 local profile=optimized.profiles[1]
 local delivered=assert(ex.eventArchive.profileForGame(game,profile))
 assert(delivered.moves~=profile.moves,'delivery aliases catalog moves')
 local epoch=assert(delivered.distributionEpoch)
 local original=profile.generationMoves[epoch].moves[1]
 delivered.moves[1]='TEST_MUTATION'
 assert(profile.generationMoves[epoch].moves[1]==original,'delivery changed immutable catalog')
 assert(profile.generationMoveRevisions[34][epoch].moves[1]==original,'delivery changed historical receipt')
 print('PASS_GIFT_MEMORY');love.event.quit(0)
end
