return function(game)
 assert(os.getenv('POKEPORT_IDENTITY')=='vasc-video-polish-qa');love.audio.setVolume(0)
 io.stdout:setvbuf('no')
 local gen2=os.getenv('POKEPORT_GAME')=='gold'or os.getenv('POKEPORT_GAME')=='crystal'
 if gen2 then
  local Save=require('src.core.gen2.Save');local save=Save.newGame{version='crystal',playerName='MODELQA'}
  game.save=save;game:adoptSave(save);game.world.save=save
  require('src.mods.Runtime').emit('save.created',{game=game,save=save});game:continueGame(save)
 else game:startNewGame{intro=false}end
 local ex=game.mods.exports.VOXEL_ASCENDANT
 if ex.setupCard then ex.setupCard.suspended=true end
 ex.ascendantContent.promptDisabled=true;ex.ascendantContent.onboardingShown=true
 local function find(fn,name,seen)
  if type(fn)~='function'then return end;seen=seen or{};if seen[fn]then return end;seen[fn]=true
  for i=1,100 do local k,v=debug.getupvalue(fn,i);if not k then break end;if k==name then return v end end
  for i=1,100 do local k,v=debug.getupvalue(fn,i);if not k then break end;local x=find(v,name,seen);if x then return x end end
 end
 local V=assert(find(gen2 and ex.dexModelPreview.draw or ex.lib.require('VoxelScene').render,'V'))
 if not gen2 then V.require('Gen1PalletVillage').buildings:setValue(true,game,true)end
 local root=assert(os.getenv('QA_VASC_ROOT'));local baseline=assert(os.getenv('QA_CONTENT_BASELINE'))
 local phase,reads,fail={},{old={},new={}},nil
 local mod=setmetatable({},{__index=V.mod})
 function mod:read(path)
  local r=reads[phase];if r then r[path]=(r[path]or 0)+1 end
  if path:match('^assets/cobblemon%-binary/')then
   if fail=='missing'then return nil end
   if fail=='corrupt'then return 'broken' end
   if fail=='throw'then error('test read failed')end
  end
  return V.mod:read(path)
 end
 local ctx=setmetatable({mod=mod},{__index=V})
 local oldContext=setmetatable({require=function(n)if n=='CobblemonBinary'then return assert(loadfile(assert(os.getenv('QA_BINARY_BASELINE'))))()end;return V.require(n)end},{__index=ctx})
 local old=assert(loadfile(baseline))(oldContext)
 local current=assert(loadfile(root..'/lib/CobblemonContent.lua'))(ctx)
 local providers={}
 for name,content in pairs{old=old,new=current}do
  local c=setmetatable({require=function(n)if n=='CobblemonContent'then return content end;return V.require(n)end},{__index=ctx})
  providers[name]=assert(loadfile(name=='old'and assert(os.getenv('QA_PACK_BASELINE'))or root..'/lib/CobblemonPack.lua'))(c)
 end
 local decoder=assert(loadfile(root..'/lib/CobblemonBinary.lua'))()
 local body='a'..love.data.pack('string','<I4',3)..'nna'..love.data.pack('string','<I4',0)
 local blob='CMB1'..love.data.pack('string','<I4',#body)..string.rep('\0',32)..love.data.compress('string','zlib',body)
 local tree,charge=decoder.decode(blob,string.rep('0',64),{})
 assert(tree and charge==528,'shared null accounting')
 local Mon=V.require('StadiumMon');local Size=not gen2 and V.require('CobblemonOverworldSize')
 local function signature(mon)
  local out={string.format('%.17g',mon.scale)}
  for _,part in ipairs(mon.rig.parts)do
   for _,row in ipairs(part.rows)do for _,n in ipairs(row)do out[#out+1]=string.format('%.17g',n)end end
   if part.texture then
    local texture=part.texture;local canvas=love.graphics.newCanvas(texture:getWidth(),texture:getHeight())
    love.graphics.push('all');love.graphics.setCanvas(canvas);love.graphics.origin();love.graphics.setShader();love.graphics.setColor(1,1,1,1)
    love.graphics.setBlendMode('replace','premultiplied');love.graphics.clear(0,0,0,0);love.graphics.draw(texture);love.graphics.pop()
    local data=canvas:newImageData();out[#out+1]=love.data.hash('sha256',data:getString());data:release();canvas:release()
   end
  end
  return love.data.hash('sha256',table.concat(out,','))
 end
 local rows,sigs={},{}
 for i,dex in ipairs{16,19,25,52,72,81,92,133,143,150,151,249}do
  for _,name in ipairs(i%2==0 and {'new','old'}or{'old','new'})do
   phase=name;collectgarbage('collect');local mon=Mon.new('overworld',providers[name]);local t=love.timer.getTime()
   assert(mon:setSpecies(dex,true));assert(mon.model._preparedMetrics,'prepared metrics inactive');mon.scale=Size and assert(Size.scale(mon,dex))or 1;mon:matrix(0,0,0,0,1);mon.time=.375;assert(mon:pose());assert(mon:upload())
   rows[#rows+1]={mode=name,dex=dex,ms=(love.timer.getTime()-t)*1000}
   local s=signature(mon)..':'..tostring(mon.model._residencyBytes);if sigs[dex]then assert(s==sigs[dex],'pose/scale/pixels changed '..dex)else sigs[dex]=s end
   mon:release()
  end
 end
 phase=nil
 for _,fault in ipairs{'missing','corrupt','throw'}do
  fail=fault;assert(current.record(25,'normal'),'record fallback '..fault)
  local fallback=assert(loadfile(root..'/lib/CobblemonContent.lua'))(ctx)
  assert(fallback.record(25,'normal'),'manifest fallback '..fault)
 end
 fail=nil
 local counts={oldJson=0,newJson=0,binary=0}
 for name,r in pairs(reads)do for path,n in pairs(r)do
  if path:match('^assets/cobblemon%-prepared/models/')then counts[name..'Json']=counts[name..'Json']+n end
  if path:match('^assets/cobblemon%-binary/.*%.bin$')then counts.binary=counts.binary+n end
 end end
 assert(counts.oldJson==0 and counts.newJson==0 and counts.binary==24,'binary path not active')
 local f=assert(io.open(assert(os.getenv('SHOT_DIR'))..'/render.json','w'));f:write(assert(require('src.link.Json').encode{rows=rows,counts=counts,generation=gen2 and 2 or 1}));f:close()
 print('PASS_ACCOUNTING_RENDER',gen2 and 2 or 1,counts.oldJson,counts.newJson,counts.binary);love.event.quit(0)
end
