return function(game)
 io.stdout:setvbuf('no')
 assert((os.getenv('POKEPORT_IDENTITY')or''):match('^vasc%-.*%-qa$'))
 local out=assert(os.getenv('VASC_SHADOW_OUT'));local U=require('tests.drivers.util')
 love.window.hasFocus=function()return true end;love.window.isVisible=function()return true end
 game:startNewGame{intro=false}
 local e=assert(game.mods.exports.VOXEL_ASCENDANT)
 e.setupCard.suspended=true;e.ascendantContent.promptDisabled=true;e.ascendantContent.onboardingShown=true
 local function find(fn,name,seen)
  if type(fn)~='function'then return end;seen=seen or{};if seen[fn]then return end;seen[fn]=true
  for i=1,200 do local k,v=debug.getupvalue(fn,i);if not k then break end;if k==name then return v end end
  for i=1,200 do local k,v=debug.getupvalue(fn,i);if not k then break end;local x=find(v,name,seen);if x then return x end end
 end
 local V=assert(find(e.lib.require('VoxelScene').render,'V'))
 local function module(n)return V.require(n)end
 local S,D,G=module('ShadowMap'),module('DeviceShadows'),module('Voxel3D')
 module('Weather').setting:setValue('clear',game)
 module('Shadows').setting:setValue(true,game)
 require('src.render.Pipelines').setLevel('voxel',3)
 game.save.flags.EVENT_FOLLOWED_OAK_INTO_LAB=true;game.save.flags.EVENT_GOT_STARTER=true;game.save.repelSteps=999999
 U.teleport(game,'PALLET_TOWN',5,8,'down')
 love.window.setMode(960,540,{resizable=true,vsync=0})
 for i=1,600 do U.wait(1);if D.enabled() and S.active()then break end end
 assert(D.enabled(),'device rejected: '..tostring(D.reason));assert(S.active(),'shadow map never rendered')
 U.wait(15);assert(U.shot(game,out..'/world-on.png'))
 module('Shadows').setting:setValue(false,game);U.wait(6)
 assert(not G.shadowsActive(),'OFF kept map active');assert(U.shot(game,out..'/world-off.png'))
 module('Shadows').setting:setValue(true,game);U.wait(15);assert(G.shadowsActive(),'ON failed to restore')
 love.window.setMode(540,960,{resizable=true,vsync=0});U.wait(30)
 assert(G.shadowsActive(),'rotation lost shadows');assert(U.shot(game,out..'/portrait-on.png'))
 print('MOBILE_SHADOW_WORLD_PASS',D.state,D.resolution,D.flipY)
 love.event.quit()
end
