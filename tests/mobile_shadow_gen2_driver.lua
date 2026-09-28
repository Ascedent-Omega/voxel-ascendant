return function(game)
 io.stdout:setvbuf('no')
 assert((os.getenv('POKEPORT_IDENTITY')or''):match('^vasc%-.*%-qa$'))
 love.window.hasFocus=function()return true end;love.window.isVisible=function()return true end
 local out=assert(os.getenv('VASC_SHADOW_OUT'));local U=require('tests.drivers.util')
 local save=require('src.core.gen2.Save').newGame{version='crystal',playerName='SHADOWQA'}
 save.party={require('src.battle.gen2.Mon').new(game.data,'CHIKORITA',12)}
 game.save=save;game:adoptSave(save);game.world.save=save
 require('src.mods.Runtime').emit('save.created',{game=game,save=save});game:continueGame(save)
 local e=assert(game.mods.exports.VOXEL_ASCENDANT)
 if e.setupCard then e.setupCard.suspended=true end
 e.ascendantContent.promptDisabled=true;e.ascendantContent.onboardingShown=true
 local V;for i=1,40 do local k,v=debug.getupvalue(e.dexModelPreview.draw,i);if k=='V'then V=v end end;assert(V)
 e.vascMenuGen2.settingsByKey.voxel3d:setValue(true,game)
 local S,D,G=V.require('ShadowMap'),V.require('DeviceShadows'),V.require('Voxel3D')
 V.require('Quality').shadowSetting:setValue('low',game)
 V.require('Weather').setting:setValue('clear',game)
 V.require('Shadows').setting:setValue(true,game)
 love.window.setMode(960,540,{resizable=true,vsync=0});assert(game.world:setMap('NEW_BARK_TOWN',8,8,'down'))
 for i=1,900 do U.wait(1);if S.active()then break end end
 assert(D.enabled(),'device rejected: '..tostring(D.reason));assert(S.active(),'Gen2 never cast shadows')
 U.wait(80);assert(S.active());assert(U.shot(game,out..'/world-on.png'))
 V.require('Quality').shadowSetting:setValue('off',game);U.wait(30);assert(not S.active())
 assert(U.shot(game,out..'/world-off.png'))
 V.require('Quality').shadowSetting:setValue('low',game)
 love.window.setMode(540,960,{resizable=true,vsync=0});U.wait(35)
 assert(S.active(),'rotation lost Gen2 shadows');assert(U.shot(game,out..'/portrait-on.png'))
 local shaders=os.getenv('VASC_SHADER_OUT')
 if shaders then
  for _,lighting in ipairs({false,true})do for _,gles in ipairs({false,true})do
   local raw=G._shaderSource(nil,false,lighting)
   local vert,frag=love.graphics._shaderCodeToGLSL(gles,raw)
   for ext,code in pairs({vert=vert,frag=frag})do
    local f=assert(io.open(shaders..'/gen2-'..tostring(lighting)..(gles and '-gles' or '-gl')..'.'..ext,'w'));f:write(code);f:close()
   end
  end end
 end
 print('MOBILE_SHADOW_GEN2_PASS' ,D.state,D.resolution,D.flipY)
 love.event.quit()
end
