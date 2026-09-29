return function(game)
 assert(os.getenv('POKEPORT_IDENTITY')=='vasc-video-polish-qa');love.audio.setVolume(0)
 local U=require('tests.drivers.util');game:startNewGame{intro=false}
 local rules=game.mods.exports.kanto_ascendant.generationRules
 local f=assert(io.open(assert(os.getenv('QA_RULES_BASELINE'))));local source=f:read('*a');f:close()
 local body=assert(source:match('(  function G.syncData.-)  function G.shouldUseEpoch'))
 body=body:gsub('function G.syncData','return function',1)
 local env={};for i=1,100 do local n,v=debug.getupvalue(rules.syncData,i);if not n then break end;env[n]=v end
 setmetatable(env,{__index=getfenv(rules.syncData)})
 local chunk=assert(loadstring(body));setfenv(chunk,env);local baseline=chunk()
 local function copy(t)
  if type(t)~='table'then return t end;local r={};for k,v in pairs(t)do r[k]=copy(v)end;return r
 end
 local function same(a,b,path)
  assert(type(a)==type(b),'type '..path)
  if type(a)~='table'then assert(a==b,'value '..path);return end
  for k,v in pairs(a)do same(v,b[k],path..'.'..tostring(k))end
  for k in pairs(b)do assert(a[k]~=nil,'extra '..path..'.'..tostring(k))end
 end
 local function snapshot()
  local s={pokemon={},moves={},chart=copy(game.data.type_chart),party=copy(game.save.party),boxes=copy(game.save.boxes)}
  for id,d in pairs(game.data.pokemon)do if type(d)=='table'then
   s.pokemon[id]={types=copy(d.types),level1Moves=copy(d.level1Moves),learnset=copy(d.learnset),tmhm=copy(d.tmhm)}
  end end
  for id,d in pairs(game.data.moves)do if type(d)=='table'then
   s.moves[id]={type=d.type,category=d.category,power=d.power,accuracy=d.accuracy,pp=d.pp,priority=d.priority}
  end end
  return s
 end
 local cases=0
 for _,active in ipairs{1,2,3,4,5,6,7,6,3,1}do
  local profile={activeEpoch=active,extensionsEnabled=true,mode='gen'..active}
  local ok,why=baseline(game,profile);local expected=snapshot()
  local done,actual=rules.syncData(game,profile)
  assert(ok==done);same(expected,snapshot(),'era'..active);cases=cases+1;U.wait(1)
 end
 -- OFF projection and a changed move introduction must be re-evaluated.
 local original=game.data.moves.TACKLE.originEpoch
 game.data.moves.TACKLE.originEpoch=7
 for _,profile in ipairs{{activeEpoch=1,extensionsEnabled=false,mode='off'},{activeEpoch=1,extensionsEnabled=true,mode='gen1'}}do
  local ok=baseline(game,profile);local expected=snapshot();assert(rules.syncData(game,profile)==ok)
  same(expected,snapshot(),'changed registry');cases=cases+1;U.wait(1)
 end
 game.data.moves.TACKLE.originEpoch=original
 baseline(game,{activeEpoch=1,extensionsEnabled=true,mode='gen1'});local expected=snapshot()
 rules.syncData(game,{activeEpoch=1,extensionsEnabled=true,mode='gen1'});same(expected,snapshot(),'restored registry')
 print('PASS_GENERATION_EQUIVALENCE',cases+1,'profiles, up/down/OFF/live move epoch; types, moves, learnsets, matchups and owned save surfaces identical')
 love.event.quit(0)
end
