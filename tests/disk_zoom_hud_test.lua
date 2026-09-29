local function read(path)local f=assert(io.open(path));local s=f:read('*a');f:close();return s end
local function section(s,a,b)local i=assert(s:find(a,1,true));return s:sub(i,assert(s:find(b,i+#a,true))-1)end
local function run(s,env)local f=assert(loadstring(s));setfenv(f,setmetatable(env,{__index=_G}));return f()end
local camera=read('lib/BattleCam.lua')
local remembered
local C={steerable=true,ZOOM_MIN=.45,ZOOM_MAX=3,ZOOM_STEP=1.15,terrariumZoomGoal=1}
run(section(camera,'function BattleCam.stepZoom(', '\n  BattleCam.applyDistanceSetting(false)')..'\nend',
 {BattleCam=C,terrariumProfile={remember=function(z)remembered=z end}})
for _,arena in ipairs{{terarrium=true},{diskCourt=true}}do
 C.terrariumZoomGoal=1
 assert(C.stepZoom(-2,arena));assert(math.abs(remembered-1/1.15^2)<1e-10)
 assert(C.stepZoom(4,arena));assert(math.abs(remembered-1.15^2)<1e-10)
 C.stepZoom(100,arena);assert(remembered==3);assert(not C.stepZoom(1,arena))
 C.stepZoom(-100,arena);assert(remembered==.45)
 C.still=true;assert(not C.stepZoom(1,arena));C.still=false
end
local hud=read('battle_hud_oras.lua');local F={OWNER_ATTACHMENT={player={x=0,y=0},enemy={x=0,y=0}},
 safeInsets=function()return 0,0,0,0 end,ownerAnchorFor=function(shot,side)return shot.actorVisuals[side].head end}
run(section(hud,'function FloatingHud.fixedCourtStatus(', 'FloatingHud.statusAttachmentStates ='),
 {FloatingHud=F,plateSize=function()return 140,40 end,uiScale=function()return 2 end,
 optionChoice=function(_,default)return default end,isAscendantHost=true,
 clamp=function(v,a,b)return math.max(a,math.min(b,v))end})
for _,size in ipairs{{1000,700},{700,1000}}do
 local shot={pw=size[1],ph=size[2],layoutContext={mode='DISCS'},actorVisuals={}}
 local rects={}
 for i=1,30 do
  for _,side in ipairs{'player','enemy'}do
   shot.actorVisuals[side]={head={x=i*31,y=i*15},hull={i*20,i*10,150,200}}
   local r=F.projectOwnerStatusRect(shot,side)
   if rects[side]then for n=1,4 do assert(r[n]==rects[side][n],'orbit/zoom moved '..side)end end
   rects[side]=r
  end
 end
 assert(rects.player[1]+rects.player[3]<rects.enemy[1],'HP plates overlap')
end
assert(not F.fixedCourtStatus({layoutContext={mode='MAP'}}))
print('PASS Terrarium/DISCS identical zoom notches, limits, saved values; fixed HP slots at both aspect ratios')

run(section(hud,'function FloatingHud.statusSlotFromVisual(', 'function FloatingHud.rectanglesHit('),{FloatingHud=F})
local battler,mon={},{}
local visual={battler=battler,mon=mon,head={x=100,y=200,source='stable-pokemon-pose'}}
local shot={pw=1000,ph=700,layoutContext={mode='DISCS'},actorVisuals={player=visual}}
F.ownerAnchorFor=function(s,side)return s.actorVisuals[side].head end
local first=F.statusSlotFromVisual(shot,'player',visual)
visual.head={x=330,y=400,source='stable-pokemon-pose'}
local updated=F.refreshStatusSlot(first,visual,shot,'player')
assert(updated and updated.anchor.x==330)
for i=1,4 do assert(updated.rect[i]==first.rect[i],'receipt refresh moved fixed card')end
print('PASS animated owner receipts refresh without moving fixed HP cards')
local settings={}
local V={require=function(name)
 if name=='TerrariumZoomProfile'then return assert(loadfile('lib/TerrariumZoomProfile.lua'))()end
 assert(name=='ModSetting',name)
 return{new=function(key,label,values,labels,default)
  local s={value=default,get=function(self)return self.value end};settings[key]=s;return s
 end}
end}
local real=assert(loadfile('lib/BattleCam.lua'))(V)
local arena={diskCourt=true,discs=true,trainerOffsets={},cam='disk_court',mid={280,304},player={280,328},enemy={280,280}}
local battle={phase='menu'}
real.viewportW,real.viewportH=1000,700
local outcome,reason=true,nil
real.setScreenSafetyEvaluator(function()return outcome,reason end)
local function tick()for i=1,100 do real.update(.2,arena,battle,0)end end
tick();local home=real.rig(arena,0)
real.dragOrbit(10);tick();local turned=real.rig(arena,0)
assert(real.orbit==1 and real.orbitRange(arena)==math.pi/2)
real.stepZoom(-2,arena);tick();local close=real.rig(arena,0)
assert(math.abs(math.tan(close.fov*.5)/math.tan(turned.fov*.5)-1/1.15^2)<1e-10,'orbit lost optical zoom')
real.dragOrbit(-20);tick();assert(real.orbit==-1)
local before=real.rig(arena,0);battle.phase='moveSelect';tick();local after=real.rig(arena,0)
assert(after.fov==before.fov,'command phase changed zoom')
local fitted=real.fitPortrait(after,1,700,1000,arena)
assert(fitted~=after and fitted.eye~=after.eye,'portrait mutated shared camera')
assert(math.abs(math.tan(fitted.fov*.5)/math.tan(after.fov*.5)-1.4)<1e-10)
outcome,reason=false,'actor-pair-too-close'
assert(real.rig(arena,0).fov==after.fov,'automatic fit undid deliberate zoom')
print('PASS real DISCS rig: full orbit, optical zoom after rotation, menu stability and portrait framing')
