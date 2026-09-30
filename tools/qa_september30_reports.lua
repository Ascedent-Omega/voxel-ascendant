return function(game)
 game.mods.exports.kanto_ascendant.crystalAnimation.refreshDownloadedAssets()
 love.audio.setVolume(0);io.stdout:setvbuf('no');love.window.hasFocus=function()return true end;love.window.isVisible=function()return true end
 love.keyboard.isDown=function()return false end;love.joystick.getJoysticks=function()return{}end
 love.window.setMode(960,640,{vsync=0})
 local U=require('tests.drivers.util');game:startNewGame{intro=false}
 local e=assert(game.mods.exports.VOXEL_ASCENDANT);assert(not game.mods.exports.ASCENDANT_COBBLE_CHARACTERS,'test must run without separate Card')
 e.setupCard.suspended=true;e.ascendantContent.promptDisabled=true;e.ascendantContent.onboardingShown=true
 game.save.flags.EVENT_FOLLOWED_OAK_INTO_LAB=true;game.save.flags.EVENT_GOT_STARTER=true
 U.teleport(game,'PALLET_TOWN',8,9,'down');require('src.render.Pipelines').setLevel('voxel',7);U.wait(60)
 local function find(fn,name,seen)
 if type(fn)~='function'then return end;seen=seen or{};if seen[fn]then return end;seen[fn]=true
 for i=1,100 do local k,v=debug.getupvalue(fn,i);if not k then break end;if k==name then return v end end
 for i=1,100 do local k,v=debug.getupvalue(fn,i);if not k then break end;local x=find(v,name,seen);if x then return x end end end
 local V=assert(find(e.lib.require('VoxelScene').render,'V'));local scene=V.require('VoxelScene')
 local function ready(label)
  for n=1,2400 do if n>60 and V.require('VoxelState').ready and not scene.pendingReason then print('READY',label,n);return end;if n%180==0 then if n==540 then U.shot(game,'/Users/maarten/Documents/Recompile/artifacts/performance-t6-t27-20260929/transitions/wait.png')end;local h=V.require('HorizonWall').cacheStatus(V.require('VisibleNeighborhood').apply(game.overworld));print('WAIT',label,n,game.stack:top()==game.overworld,V.require('VoxelState').ready,require('src.render.Pipelines').worldPipeline(),require('src.render.Pipelines').level('voxel'),game.stack:top().screenId,scene.pendingReason,h.ready,h.failed,V.require('ChunkMesher').pending())end;U.wait(1)end
  error('TIMEOUT '..label..' '..tostring(scene.pendingReason))
 end


 V.require('Weather').setting:setValue('clear',game,true);V.require('DayNight').setting:setValue('day',game,true)



 local dir=assert(os.getenv('VASC_PERF_DIR'));local F=V.require('FirstPerson');F.lookBy=function()end
 if not os.getenv('VASC_QA_TERRARIUM') then
 V.require('LedgeElevation').setting:setValue('world',game,true)
 U.teleport(game,'VIRIDIAN_CITY',24,26,'up');ready('Viridian WORLD')
 F.yaw=math.pi;F.pitch=.35;U.wait(120);U.shot(game,dir..'/viridian-world.png')
 U.teleport(game,'VIRIDIAN_POKECENTER',3,4,'up');ready('Center')
 local figs=V.require('ChunkMesher').figures(game.overworld.map)
 assert(#figs>0,'missing seated figure')
 local f=figs[1];print('FIGURE',f.wx,f.wz,f.y,f.w,V.require('HdAuthoredFigures').enabled())
 assert(not V.require('HdAuthoredFigures').enabled(),'default voxel got HD')
 local matrix=assert(find(scene.render,'figureMatrix'))
 local first
 for i,yaw in ipairs{math.pi,math.pi-.5,math.pi+.5}do
  F.yaw=yaw;F.pitch=.15*i
  local m=matrix(f,0,0)
  if first then for k,v in pairs(first)do assert(m[k]==v,'seated actor rotated with camera')end else first=m end
 end
 U.teleport(game,'VIRIDIAN_POKECENTER',math.floor((f.wx+f.w/2)/16),math.floor(f.wz/16)+3,'up');ready('Center seat')
 F.yaw=math.pi;F.pitch=.3;U.wait(90);U.shot(game,dir..'/center-seat-front.png')
 F.yaw=math.pi-.5;U.wait(30);U.shot(game,dir..'/center-seat-oblique.png')
 print('PASS fixed couch transform across three yaw/pitch pairs')
 end
 local C=V.require('BattleSpriteControl');C.styleSetting:setValue('crystal',game,true)
 local renderer=V.require('OverworldBattle');renderer.setting:setValue(os.getenv('VASC_QA_TERRARIUM') and 'terarrium' or renderer.FLAT_B,game,true)
 local owner=find(game.mods.exports.kanto_ascendant.crystalAnimation.presentationAnimation,'mod')
 local get=owner.options.get
 owner.options.get=function(self,key)if key=='pokemon_sprite_style'then return'classic'end;return get(self,key)end
 U.teleport(game,'ROUTE_5',10,5,'down');ready('Route 5 arrival')
 game.save.party={require('src.pokemon.Pokemon').new(game.data,'GOROCHU',45)}
 local k=game.mods.exports.kanto_ascendant
 print('KASC',k~=nil,'GOROCHU',game.data.pokemon.GOROCHU.dex)
 local BS=require('src.battle.BattleState')
 for attempt=1,(os.getenv('VASC_QA_TERRARIUM') and 1 or 3) do
  local b=BS.newWild(game,'STARMIE',30);game.overworld:pushBattle(b)
  for n=1,2000 do U.wait(1);if game.stack:top()==b and b.phase=='menu'and renderer.shot()then break end;if n%12==0 then U.tap(game,'a')end end
  assert(game.stack:top()==b and renderer.shot(),'battle never reached staged menu')
  local k=game.mods.exports.kanto_ascendant.crystalAnimation
  local art=assert(k.presentationAnimation('GOROCHU',b.player.mon,'front','battle',{data=game.data,forceStyle=true}))
  print('GOROCHU ART',art.path,art.variant,art.image~=nil)
  assert(art.variant=='normal' and art.image,'Gorochu Crystal did not load coloured art')
  assert(C.imageFor(b,'player','front','crystal'),'Gorochu Crystal has no front')
  if attempt==1 then U.shot(game,dir..(os.getenv('VASC_QA_TERRARIUM') and '/gorochu-terrarium.png' or '/gorochu-crystal.png'))end
  b.result='run';b.evolutionsChecked=true;b:finish()
  for n=1,1200 do U.wait(1);if game.stack:top()==game.overworld then break end;if n%12==0 then U.tap(game,'a')end end
  ready('Route 5 return '..attempt);assert(game.stack:top()==game.overworld)
  U.wait(120);U.shot(game,dir..'/route5-return-'..attempt..'.png')
  print('PASS battle-to-Route5 return',attempt)
 end
 print('PASS native screenshot triage');love.event.quit()
end
