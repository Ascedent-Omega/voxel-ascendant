local enabled=true
local mods={VoxelState={active=function()return enabled end}}
local V={require=function(n)return assert(mods[n],n)end}
local T=assert(loadfile('lib/SilphTeleport.lua'))(V)
local function player()return{cellX=4,cellY=5,facing='down',spinning=true}end
local ow={map={id='SILPH_CO_2F',warpPadOrHoleAt=function()return 'pad'end},player=player(),arriveWarp='teleport'}
assert(T.eligible(ow,'SILPH_CO_11F'))
for _,id in ipairs{'SILPH_CO_1F','SILPH_CO_ELEVATOR','SAFFRON_GYM','ROUTE_1','SILPH_CO_12F'}do assert(not T.eligible(ow,id),id)end
ow.map.warpPadOrHoleAt=function()return 'hole'end;assert(not T.eligible(ow,'SILPH_CO_3F'))
ow.map.warpPadOrHoleAt=function()return 'pad'end
enabled=false;assert(not T.eligible(ow,'SILPH_CO_3F'));enabled=true
ow.arriveWarp=nil;assert(not T.eligible(ow,'SILPH_CO_3F'));ow.arriveWarp='teleport'
local drawn,mid,done,popped=0,0,0,0
package.loaded['src.render.Pipelines']={worldRevealReady=function()return true end}
local Transition=require('src.render.Transition')
local top
local game={overworld=ow,renderer={worldActive=true},stack={top=function()return top end,pop=function()popped=popped+1 end}}
local destination={id='SILPH_CO_3F',warpPadOrHoleAt=ow.map.warpPadOrHoleAt}
ow.startWarpTo=function(self,id,x,y,facing,callback,opts)
 assert(id=='SILPH_CO_3F' and x==7 and y==8 and facing=='left' and opts.keepMusic==true)
 self.transitioning=true
 top=Transition.new(game,function()
  mid=mid+1;self.map=destination;self.player=player();self.player.spinFrames=48;self.player.spinDrop=true
  self.warpEntryCell={x=x,y=y}
 end,function()self.transitioning=false;done=done+1;callback()end)
 return 'preserved',nil,17
end
assert(T.install(game));assert(T.install(game))
local callback=0
local a,b,c=ow:startWarpTo('SILPH_CO_3F',7,8,'left',function()callback=callback+1 end,{keepMusic=true})
assert(a=='preserved' and b==nil and c==17)
assert(top.frames==78 and not ow.player.spinning and T.current(ow))
for tick=0,77 do
 assert(T.amount(top)>=0 and T.amount(top)<=1)
 top:draw();assert(game.renderer.worldFadeAlpha==T.alpha(top));assert(top.t==tick and top.frames==78)
 if tick<=66 then assert(game.renderer.worldFadeAlpha==0,'fade hides dissolution')end
 top:update(1/60)
end
assert(mid==1 and top.phase=='in' and top.t==0 and not ow.player.spinning and not ow.player.spinFrames)
assert(ow.warpEntryCell.x==7 and ow.warpEntryCell.y==8)
assert(T.current(ow).map==destination)
package.loaded['src.render.Pipelines'].worldRevealReady=function()return false end
for i=1,30 do top:update(1/60);top:draw();assert(top.t==0 and T.amount(top)==1 and game.renderer.worldFadeAlpha==1)end
package.loaded['src.render.Pipelines'].worldRevealReady=function()return true end
for i=1,78 do top:update(1/60)end
assert(done==1 and callback==1 and popped==1 and not ow.transitioning and not T.current(ow))
print('PASS native transition: pad scope, callbacks, entry lock, cold reveal, completion, reinstallation')
local allocated,released,updates=0,0,0
mods.Voxel3D={pushQuad=function(indices,n)local b=n*4;for _,i in ipairs{1,2,3,1,3,4}do indices[#indices+1]=b+i end end,
 newMesh=function(vertices,indices)
  allocated=allocated+1
  for _,index in ipairs(indices)do assert(index>=1 and index<=#vertices,'invalid mesh index')end
  return{setVertices=function(_,v)updates=updates+1 end,release=function()released=released+1 end}
 end}
local points={{0,0,0,0,1,1},{16,0,0,1,1,1},{16,16,0,1,0,1},{0,16,0,0,0,1}}
local source={getVertexCount=function()return 4 end,getVertex=function(_,i)return unpack(points[i])end,getVertexMap=function()return{1,2,3,1,3,4}end}
for _,hero in ipairs{'red','blue','green'}do
 local fx={transition={phase='out',t=0}}
 local texture={hero=hero};assert(T.present(fx,source,texture,{},{}));assert(fx.texture==texture)
 assert(#fx.vertices<=65532 and #fx.pieces>200)
 for _,piece in ipairs(fx.pieces)do for _,r in ipairs(piece.vertices)do
  local v=fx.vertices[r.index];for i=1,6 do assert(math.abs(v[i]-r.base[i])<1e-7,'intact shape or UV changed')end
 end end
 local oldAlloc=allocated
 for i=1,66 do fx.transition.t=i;assert(T.present(fx,source,texture,{},{}))end
 assert(allocated==oldAlloc,'per-frame allocation')
 for _,piece in ipairs(fx.pieces)do local first=fx.vertices[piece.vertices[1].index]
  for _,r in ipairs(piece.vertices)do local v=fx.vertices[r.index];for i=1,3 do assert(math.abs(v[i]-first[i])<1e-7,'remaining body at full dissolve')end end
 end
 fx.transition.phase='in';fx.transition.t=78;T.animate(fx)
 for _,piece in ipairs(fx.pieces)do for _,r in ipairs(piece.vertices)do local v=fx.vertices[r.index]
  for i=1,6 do assert(math.abs(v[i]-r.base[i])<1e-7,'reconstruction mismatch')end
 end end
 ow.__vascSilphTeleport=fx;T.clear(ow)
end
assert(allocated==3 and released==3)
print('PASS 3 hero textures: original UV/shape, 400+ cube shards, complete dissolve/reassembly, bounded allocation/release')
for _,name in ipairs{'lib/SilphTeleport.lua','lib/VoxelScene.lua','lib/Voxel3D.lua','main_gen1.lua'}do assert(loadfile(name))end
-- Current engines resolve the destination once, then defer startWarpTo in
-- teleportOut.go. Taking that continuation must keep the exact warp args.
local staged={player=player(),map={id='SILPH_CO_2F',warpPadOrHoleAt=function()return 'pad'end}}
local stagedGame={overworld=staged,stack={top=function()return top end}}
local stages=0
staged.startWarpTo=function(self,id)
 stages=stages+1;assert(id=='SILPH_CO_3F');self.transitioning=true
 top={phase='out',t=0,frames=24,framesIn=24,
  onMidpoint=function()self.player.spinFrames=30;self.player.spinDrop=true;self.spinArrive=true;self.player.inputLocked=true end,
  onDone=function()self.transitioning=false end,draw=function(t)assert(t.frames==1 and t.framesIn==1)end}
end
staged.takeWarp=function(self,w)
 self.arriveWarp='teleport';self.player.inputLocked=true
 self.teleportOut={go=function()self:startWarpTo(w.destMap)end}
end
T.install(stagedGame);staged:takeWarp{destMap='SILPH_CO_3F'}
assert(stages==1 and not staged.teleportOut and not staged.player.inputLocked and top.framesIn==78)
top:draw();assert(top.frames==78 and top.framesIn==78)
top.onMidpoint();assert(not staged.player.spinFrames)
top.onDone();assert(not staged.player.inputLocked and not T.current(staged))
-- Repeated teleport and a hard map reload release the one retained GPU mesh.
staged:takeWarp{destMap='SILPH_CO_3F'}
local fx=assert(T.current(staged));T.present(fx,source,{},nil,nil)
staged.map={id='SILPH_CO_4F'}
assert(not T.current(staged) and released==4)
print('PASS staged engine: resolved continuation once, separate in timing, native input release, interrupted-map cleanup')
