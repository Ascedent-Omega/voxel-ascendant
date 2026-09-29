return function(game)
 assert(os.getenv('POKEPORT_IDENTITY')=='vasc-video-polish-qa');love.audio.setVolume(0)
 if os.getenv('QA_DISABLE_JIT')=='1'and jit then jit.off();jit.flush()end
 io.stdout:setvbuf('no')
 game:startNewGame{intro=false}
 local ex=game.mods.exports.VOXEL_ASCENDANT;ex.setupCard.suspended=true
 ex.ascendantContent.promptDisabled=true;ex.ascendantContent.onboardingShown=true
 local function find(fn,name,seen)
  if type(fn)~='function'then return end;seen=seen or{};if seen[fn]then return end;seen[fn]=true
  for i=1,100 do local k,v=debug.getupvalue(fn,i);if not k then break end;if k==name then return v end end
  for i=1,100 do local k,v=debug.getupvalue(fn,i);if not k then break end;local x=find(v,name,seen);if x then return x end end
 end
 local V=assert(find(ex.lib.require('VoxelScene').render,'V'))
 V.require('Gen1PalletVillage').buildings:setValue(true,game,true)
 local old=assert(loadfile(assert(os.getenv('QA_PACK_BASELINE'))))(V)
 local new=V.require('CobblemonPack');local Mon=V.require('StadiumMon')
 local Size=V.require('CobblemonOverworldSize');local Content=V.require('CobblemonContent')
 local reads={old=0,new=0};local phase
 local record=Content.record;Content.record=function(...)
  if phase then reads[phase]=reads[phase]+1 end;return record(...)
 end
 local rows,signatures={},{}
 local function signature(mon)
  local out={string.format('%.17g',mon.scale)}
  for _,part in ipairs(mon.rig.parts)do
   for _,row in ipairs(part.rows)do for _,n in ipairs(row)do out[#out+1]=string.format('%.17g',n)end end
   if part.texture then
    local texture=part.texture
    local canvas=love.graphics.newCanvas(texture:getWidth(),texture:getHeight())
    love.graphics.push('all');love.graphics.setCanvas(canvas);love.graphics.origin()
    love.graphics.setShader();love.graphics.setColor(1,1,1,1)
    love.graphics.setBlendMode('replace','premultiplied');love.graphics.clear(0,0,0,0)
    love.graphics.draw(texture);love.graphics.pop()
    local data=canvas:newImageData();out[#out+1]=love.data.hash('sha256',data:getString())
    data:release();canvas:release()
   end
  end
  return love.data.hash('sha256',table.concat(out,','))
 end
 local species={16,19,25,52,72,81,92,133}
 for round=1,3 do
  for _,name in ipairs(round%2==1 and {'old','new'}or{'new','old'})do
   phase=name;collectgarbage('collect');local before=collectgarbage('count')
   local total=0
   for _,dex in ipairs(species)do
    local mon=Mon.new('overworld',name=='old'and old or new)
    local t=love.timer.getTime()
    assert(mon:setSpecies(dex,true));mon.scale=assert(Size.scale(mon,dex))
    mon:matrix(0,0,0,0,1);mon.time=.375;assert(mon:pose());assert(mon:upload())
    local ms=(love.timer.getTime()-t)*1000;total=total+ms
    local sig=signature(mon)
    if signatures[dex]then assert(sig==signatures[dex],'model/pose changed '..dex)else signatures[dex]=sig end
    rows[#rows+1]={round=round,mode=name,dex=dex,ms=ms}
    mon:release();mon=nil
   end
   collectgarbage('collect')
   print('MODEL_RESIDENCY',round,name,total,reads[name],collectgarbage('count')-before)
  end
 end
 phase=nil;Content.record=record
 local status=new.residency();assert(status.estimatedBytes<=status.budget and status.models<=status.maxModels)
 assert(reads.new<reads.old,'retention did not prevent repeat decoding')
 local f=assert(io.open(assert(os.getenv('SHOT_DIR'))..'/models.json','w'))
 f:write(assert(require('src.link.Json').encode({rows=rows,reads=reads,residency=status,voxelBuildings=true})));f:close()
 print('PASS_MODEL_RESIDENCY');love.event.quit(0)
end
