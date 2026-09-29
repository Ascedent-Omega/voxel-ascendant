local f=assert(io.open('battle_hud_oras.lua'));local source=f:read('*a');f:close()
local a=assert(source:find('function FloatingHud.statusLatchFrameSafe(',1,true))
local b=assert(source:find('function FloatingHud.searchOwnerStatus(',a,true))
local F={safeInsets=function()return 0,0,0,0 end,rectanglesHit=function(a,b,p)
 return a[1]<b[1]+b[3]+p and a[1]+a[3]>b[1]-p and a[2]<b[2]+b[4]+p and a[2]+a[4]>b[2]-p end}
local chunk=assert(loadstring(source:sub(a,b-1)));setfenv(chunk,setmetatable({FloatingHud=F},{__index=_G}));chunk()
local shot={pw=1000,ph=700,actorVisuals={player={hull={300,300,60,80}},enemy={hull={600,300,60,80}},playerHero={hull={100,300,50,80}},enemyHero={hull={800,300,50,80}}}}
for _,hero in ipairs{'playerHero','enemyHero'} do
 local slots={player={rect={shot.actorVisuals[hero].hull[1],280,120,60}}}
 local safe,reason=F.statusLatchFrameSafe(shot,slots,{})
 assert(not safe and reason=='player-status-over-'..hero..'-actor')
 slots.player.rect={300,100,120,60};assert(F.statusLatchFrameSafe(shot,slots,{}))
end
print('PASS status receipt rejects both trainer silhouettes and accepts clear placement')
