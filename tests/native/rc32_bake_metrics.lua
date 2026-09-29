-- Package-time bake using the actual native rig. Output stays in SHOT_DIR
-- until its complete roundtrip comparison succeeds.
return function(game)
 assert(os.getenv('POKEPORT_IDENTITY')=='vasc-video-polish-qa');love.audio.setVolume(0);io.stdout:setvbuf('no')
 game:startNewGame{intro=false}
 local root=assert(os.getenv('QA_VASC_ROOT'));local U=require('tests.drivers.util')
 local ex=game.mods.exports.VOXEL_ASCENDANT;ex.setupCard.suspended=true
 ex.ascendantContent.promptDisabled=true;ex.ascendantContent.onboardingShown=true
 local function find(fn,name,seen)
  if type(fn)~='function'then return end;seen=seen or{};if seen[fn]then return end;seen[fn]=true
  for i=1,100 do local k,v=debug.getupvalue(fn,i);if not k then break end;if k==name then return v end end
  for i=1,100 do local k,v=debug.getupvalue(fn,i);if not k then break end;local x=find(v,name,seen);if x then return x end end
 end
 local V=assert(find(ex.lib.require('VoxelScene').render,'V'))
 local J=V.require('ContentJson');local Content=V.require('CobblemonContent');local Pack=V.require('CobblemonPack')
 local Rig=V.require('StadiumRig');local Size=V.require('CobblemonSize')
 local envelope=assert(find(V.require('CobblemonOverworldSize').scale,'envelope'))
 local Metrics=V.require('CobblemonMetrics');local index=assert(J.decode(V.mod:read('assets/cobblemon-prepared/index.json')))
 local seen,keys={},{ }
 for dex,variants in pairs(index.species)do for variant,hash in pairs(variants)do
  if not seen[hash]then seen[hash]={dex=tonumber(dex),variant=variant};keys[#keys+1]=hash end
 end end;table.sort(keys)
 local records,failures,expected={},{},{}
 for i,h in ipairs(keys)do
  local id=seen[h];local model=assert(Content.record(id.dex,id.variant));model._preparedMetrics=nil
  model.crystalDex=id.dex;model.assetProvider=Pack;model.textures={{}}
  local rig=Rig.new(model)
  if rig then
   local battle=Size.prepare(model,rig);local world=envelope{model=model,rig=rig}
   if battle and world then
    local values={battle.height,battle.span,world.height,world.span,world.bodyHeight,world.bodySpan}
    local bytes=love.data.pack('string','<dddddd',unpack(values))
    records[#records+1]=love.data.decode('string','hex',h)..bytes;expected[h]=values
   else failures[#failures+1]=h end
   rig:release()
  else failures[#failures+1]=h end
  if i%32==0 then print('BAKE_METRICS',i,#keys);collectgarbage('collect');U.wait(1)end
 end
 local stamps={};for _,path in ipairs(Metrics.sources)do stamps[#stamps+1]=love.data.hash('sha256',assert(V.mod:read(path)))end
 local body=table.concat(records)
 local blob='CMM1'..love.data.hash('sha256',table.concat(stamps))..love.data.hash('sha256',body)..love.data.pack('string','<I4',#records)..body
 local mod=setmetatable({},{__index=V.mod});function mod:read(path)
  if path=='assets/cobblemon-binary/metrics.bin'then return blob end;return V.mod:read(path)
 end
 local decode=assert(loadfile(root..'/lib/CobblemonMetrics.lua'))(setmetatable({mod=mod},{__index=V}))
 for h,values in pairs(expected)do
  local row=assert(decode.get(h));local actual={row.battleHeight,row.battleSpan,row.height,row.span,row.bodyHeight,row.bodySpan}
  for i=1,6 do assert(actual[i]==values[i],'metrics changed '..h..'/'..i)end
 end
 local output=assert(os.getenv('SHOT_DIR'))
 local f=assert(io.open(output..'/metrics.bin','wb'));f:write(blob);f:close()
 f=assert(io.open(output..'/bake.json','w'));f:write(assert(require('src.link.Json').encode{models=#keys,prepared=#records,failures=failures,bytes=#blob}));f:close()
 print('PASS_BAKED_METRICS',#keys,#records,#failures,#blob);love.event.quit(0)
end
