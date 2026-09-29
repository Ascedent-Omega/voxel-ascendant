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
 local R=ex.lib.require('Voxel3D')
 local step=assert(find(R.prewarmWorldCards,'humanAtlasTexture'),'human preload not installed')
 local decoder=assert(ex.lib.require('HdImageDecode'),'Gen2 decoder facade missing')
 local before=decoder.stats().completed
 local rows={};local g=love.graphics
 local prefix='mods/VOXEL_ASCENDANT/integrated/ascendant_pokemon_overworld/assets/characters/'
 local function digest(texture)
  local w,h=texture:getDimensions();local canvas=g.newCanvas(w,h)
  g.push('all');g.setCanvas(canvas);g.origin();g.setScissor();g.setShader();g.setDepthMode()
  g.clear(0,0,0,0);g.setColor(1,1,1,1);g.setBlendMode('replace','premultiplied');g.draw(texture)
  g.pop();local data=canvas:newImageData();local hash=love.data.encode('string','hex',love.data.hash('sha256',data:getString()))
  data:release();canvas:release();return hash
 end
 for _,name in ipairs{'voxel-demo/red_cards_4x3.png','voxel-npcs/jr-trainer-female-kasc-hd-4x3-walk-sheet-v1.png',
    'voxel-npcs/super-nerd-kasc-hd-4x3-walk-sheet-v1.png','voxel-npcs/team-rocket-grunt-male-kasc-hd-4x3-walk-sheet-v1.png'}do
  local path=prefix..name;local maxMs,total,steps=0,0,0;local texture,owned
  repeat
   local t=love.timer.getTime();texture,owned=step(path,true)
   local ms=(love.timer.getTime()-t)*1000;maxMs=math.max(maxMs,ms);total=total+ms;steps=steps+1
   assert(steps<2000,'worker timeout');if not texture then love.timer.sleep(.001)end
  until texture
  assert(owned,'preload fell back to synchronous Assets image')
  local t=love.timer.getTime();local reference=g.newImage(path);local referenceMs=(love.timer.getTime()-t)*1000
  reference:setFilter('linear','linear',8);texture:setFilter('linear','linear',8)
  local hash=digest(texture);assert(hash==digest(reference),'GPU pixels changed: '..path)
  texture:release();reference:release()
  rows[#rows+1]={path=path,maxStepMs=maxMs,totalMainMs=total,referenceMs=referenceMs,steps=steps,hash=hash}
  print('ATLAS_PAIR',name,referenceMs,maxMs,total)
 end
 assert(decoder.stats().completed-before==#rows,'decoder was not used')
 local f=assert(io.open(assert(os.getenv('SHOT_DIR'))..'/atlas-pairs.json','w'))
 f:write(require('src.link.Json').encode{generation=gen2 and 2 or 1,rows=rows,decoder=decoder.stats()});f:close()
 print('PASS_ATLAS_PIXELS',gen2 and 2 or 1,#rows)
 if gen2 then
  ex.vascMenuGen2.settingsByKey.voxel3d:setValue(true,game)
  local scene=V.require('VoxelScene');local render=scene.render;local draws=0
  scene.render=function(...)local result=render(...);if result then draws=draws+1 end;return result end
  assert(game.world:setMap('NEW_BARK_TOWN',8,8,'down'))
  local U=require('tests.drivers.util');U.wait(180)
  assert(draws>10 and not V.require('LocalLights').failure,'Gen2 scene failed')
  assert(U.shot(game,assert(os.getenv('SHOT_DIR'))..'/scene.png'))
  print('PASS_GEN2_SCENE',draws)
 end
 love.event.quit(0)
end
