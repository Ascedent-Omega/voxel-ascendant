return function(game)
 assert(os.getenv('POKEPORT_IDENTITY')=='vasc-video-polish-qa');love.audio.setVolume(0);io.stdout:setvbuf('no')
 love.window.hasFocus=function()return true end;love.window.isVisible=function()return true end
 local U=require('tests.drivers.util');local Save=require('src.core.gen2.Save')
 local save=Save.newGame{version='crystal',playerName='WATERQA'}
 game.save=save;game:adoptSave(save);game.world.save=save
 require('src.mods.Runtime').emit('save.created',{game=game,save=save});game:continueGame(save)
 local ex=game.mods.exports.VOXEL_ASCENDANT
 if ex.setupCard then ex.setupCard.suspended=true end
 ex.ascendantContent.promptDisabled=true;ex.ascendantContent.onboardingShown=true
 local V;for i=1,100 do local k,v=debug.getupvalue(ex.dexModelPreview.draw,i);if k=='V'then V=v end end;assert(V)
 ex.vascMenuGen2.settingsByKey.voxel3d:setValue(true,game)
 ex.vascMenuGen2.settingsByKey.cameraMode:setValue('third',game)
 local P=require('src.render.Pipelines');P.setLevel('voxel',6)
 love.window.setMode(1710,958,{resizable=true,vsync=0})
 local scene,G=V.require('VoxelScene'),V.require('Voxel3D')
 local original,render,mirror=scene.drawWater,scene.render,G.beginWater
 local sample;local optimized=false
 G.beginWater=function(paint,texture)
  local wrapped=paint and function(...)
   if sample then sample.casts=sample.casts+1 end
   return paint(...)
  end
  return mirror(wrapped,optimized and texture or nil)
 end
 scene.drawWater=function(draws,cast)
  local t=love.timer.getTime();local result=original(draws,cast)
  if sample then sample.waterCalls=sample.waterCalls+1;sample.waterMs=sample.waterMs+(love.timer.getTime()-t)*1000 end
  return result
 end
 scene.render=function(...)
  local t=love.timer.getTime();local r=render(...)
  if sample then sample.sceneMs=sample.sceneMs+(love.timer.getTime()-t)*1000;sample.draws=sample.draws+1 end
  return r
 end
 assert(game.world:setMap('CHERRYGROVE_CITY',25,6,'down'))
 U.wait(240)
 print('CAMERA_LEVEL',V.require('VoxelState').level);assert(V.require('VoxelState').level==7,'not third person')
 local fp=V.require('FirstPerson');local rows={}
 for _,mode in ipairs{'sky','full'}do
  V.require('Water').setting:setValue(mode,game);U.wait(15)
  for _,enabled in ipairs{false,true,false,true}do
   optimized=enabled;sample={mode=mode,optimized=enabled,casts=0,waterCalls=0,waterMs=0,sceneMs=0,draws=0}
   local t=love.timer.getTime()
   for i=1,240 do fp.yaw=i/240*math.pi*2;fp.pitch=-.08;U.wait(1)end
   sample.elapsed=love.timer.getTime()-t;rows[#rows+1]=sample
   print('WATER_RESULT',assert(require('src.link.Json').encode(sample)));sample=nil
  end
 end
 assert(U.shot(game,assert(os.getenv('SHOT_DIR'))..'/gen2-water.png'))
 local f=assert(io.open(assert(os.getenv('SHOT_DIR'))..'/results.json','w'));f:write(require('src.link.Json').encode(rows));f:close()
 assert(rows[1].casts>0 and rows[2].casts==0 and rows[4].casts==0,'SKY still paints scene reflection')
 assert(rows[5].casts>0 and rows[6].casts==rows[5].casts,'FULL changed')
 print('PASS_GEN2_WATER');love.event.quit(0)
end
