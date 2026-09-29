return function(game)
 assert(os.getenv('POKEPORT_IDENTITY')=='vasc-video-polish-qa');love.audio.setVolume(0);io.stdout:setvbuf('no')
 local U=require('tests.drivers.util');local Save=require('src.core.gen2.Save')
 local save=Save.newGame{version='crystal',playerName='LIGHTQA'}
 game.save=save;game:adoptSave(save);game.world.save=save
 require('src.mods.Runtime').emit('save.created',{game=game,save=save});game:continueGame(save)
 local ex=game.mods.exports.VOXEL_ASCENDANT
 if ex.setupCard then ex.setupCard.suspended=true end
 ex.ascendantContent.promptDisabled=true;ex.ascendantContent.onboardingShown=true
 local V;for i=1,100 do local k,v=debug.getupvalue(ex.dexModelPreview.draw,i);if k=='V'then V=v end end;assert(V)
 local options=ex.vascMenuGen2.settingsByKey
 options.voxel3d:setValue(true,game)
 local scene=V.require('VoxelScene');local render=scene.render;local draws,ok=0,0
 scene.render=function(...)
  draws=draws+1;local result=render(...);if result then ok=ok+1 end;return result
 end
 assert(game.world:setMap('NEW_BARK_TOWN',8,8,'down'))
 U.wait(180)
 assert(draws>10 and ok>10,'Gen-2 world failed to draw: '..draws..'/'..ok)
 assert(not V.require('LocalLights').failure,'lighting failed')
 assert(U.shot(game,assert(os.getenv('SHOT_DIR'))..'/gen2-scene.png'))
 print('PASS_GEN2_SCENE',draws,ok);love.event.quit(0)
end
