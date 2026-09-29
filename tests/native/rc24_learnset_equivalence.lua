return function(game)
 assert(os.getenv('POKEPORT_IDENTITY')=='vasc-video-polish-qa');love.audio.setVolume(0)
 local U=require('tests.drivers.util');game:startNewGame{intro=false}
 local live=assert(game.mods.exports.kanto_ascendant.backendLiveLearnsets67)
 local opts
 for i=1,100 do local n,v=debug.getupvalue(live.apply,i);if not n then break end;if n=='opts'then opts=v end end
 assert(opts)
 local baseline=assert(loadfile(assert(os.getenv('QA_LEARNSET_BASELINE'))))()(opts)
 local function copy(t)
  if type(t)~='table'then return t end
  local r={};for k,v in pairs(t)do r[k]=copy(v)end;return r
 end
 local function same(a,b,path)
  assert(type(a)==type(b),'type '..path)
  if type(a)~='table'then assert(a==b,'value '..path);return end
  for k,v in pairs(a)do same(v,b[k],path..'.'..tostring(k))end
  for k in pairs(b)do assert(a[k]~=nil,'extra '..path..'.'..tostring(k))end
 end
 local function snapshot()
  local out={eggs=copy(opts.eggMoves),pokemon={}}
  for id in pairs(opts.species.bySpecies)do
   local d=game.data.pokemon[id]
   if d then out.pokemon[id]={level1Moves=copy(d.level1Moves),learnset=copy(d.learnset),tmhm=copy(d.tmhm)}end
  end
  return out
 end
 local originalEdition=opts.edition;local cases=0;local count=0
 for _ in pairs(opts.species.bySpecies)do count=count+1 end
 for _,edition in ipairs{'red','yellow'}do
  opts.edition=function()return edition end
  for era=1,7 do
   local before,audit=baseline.apply(game,era);local expected=snapshot();local auditCopy=copy(audit)
   local after,current=live.apply(game,era)
   assert(before==after);same(auditCopy,current,'audit');same(expected,snapshot(),'projection')
   cases=cases+1;U.wait(1)
  end
 end
 -- Live-registry filtering must not become a stale move-availability cache.
 local missing={}
 for i,id in ipairs{'TACKLE','TOXIC','SURF','REST','PROTECT'}do missing[id]=game.data.moves[id];game.data.moves[id]=nil end
 baseline.apply(game,6);local expected=snapshot();live.apply(game,6);same(expected,snapshot(),'missing moves')
 for id,row in pairs(missing)do game.data.moves[id]=row end
 opts.edition=originalEdition
 local timings={reference={},optimized={}}
 for i=1,7 do
  local t=love.timer.getTime();baseline.apply(game,1);timings.reference[i]=(love.timer.getTime()-t)*1000
  t=love.timer.getTime();live.apply(game,1);timings.optimized[i]=(love.timer.getTime()-t)*1000;U.wait(1)
 end
 print('PASS_LEARNSET_EQUIVALENCE',cases,'profiles',count,'species keys; missing moves; audit and egg registry identical')
 local f=assert(io.open(assert(os.getenv('SHOT_DIR'))..'/timings.json','w'));f:write(assert(require('src.link.Json').encode(timings)));f:close()
 love.event.quit(0)
end
