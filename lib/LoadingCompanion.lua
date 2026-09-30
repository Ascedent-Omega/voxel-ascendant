-- Presentation only: native reveal readiness owns every wait and callback.
-- No model loading, extra render target, input lock or minimum display time.
local V=...
local M={}
local pending,font,registered
local function now()return love.timer.getTime()end
local function voxel()return require('src.render.Pipelines').worldPipeline()=='voxel'end
function M.clear()pending=nil end
function M.probe(map,ready,kind)
 if ready or not voxel()then M.clear();return end
 -- Warp readiness and the renderer's streaming cover can both report the
 -- same cold arrival each frame. They share one wait, not two debounce clocks.
 local arrival=kind=='warp' or kind=='stream'
 local sameArrival=pending and pending.map==map and arrival
  and (pending.kind=='warp' or pending.kind=='stream')
 if not pending or pending.map~=map or (pending.kind~=kind and not sameArrival) then
  local hash=0;for i=1,#(map.id or '')do hash=hash+(map.id or ''):byte(i)end
  pending={map=map,kind=kind,started=now(),species=hash%2==0 and 'pikachu'or 'eevee'}
 end
 if sameArrival and kind=='warp'then pending.kind='warp'end
 pending.touched=now()
end
function M.windows(game)
 if voxel()and game.overworld and V.require('SilphWindows').enabled(game.overworld.map)then
  M.probe(game.overworld.map,false,'windows')
 end
end
function M.update(game)
 if not pending then return end
 if pending.kind=='continue'then
  for _,s in ipairs(game.stack and game.stack.states or{})do if s.vascContinue then return end end
  M.clear();return -- title/reset/error cancelled the cover
 end
 local ow=game.overworld
 if not voxel()or not ow or ow.map~=pending.map then M.clear();return end
 if pending.kind=='windows'then
  local status=V.require('HorizonWall').cacheStatus({map=ow.map,neighbors={}})
  -- Invalidation is synchronous; the existing scene scheduler owns rebuilding.
  if not V.require('SilphWindows').enabled(ow.map)or status.failed
    or (now()-pending.started>0 and status.ready)then M.clear()end
 elseif now()-pending.touched>.25 then M.clear()end -- cancelled/failed-open native transition
end
function M.status()
 if not pending then return {visible=false}end
 return {cover=voxel()and pending.kind=='warp',visible=voxel()and (pending.kind=='continue'or now()-pending.started>=.18),species=pending.species,kind=pending.kind,map=pending.map.id}
end
local function art(g,t,species)
 local function box(x,y,w,h,r,green,b)
  g.setColor(r,green,b,1);g.rectangle('fill',x,y,w,h)
  g.setColor(r*.72,green*.72,b*.72,1);g.rectangle('fill',x+w-2,y+2,2,h)
 end
 -- Small block-built Pokéball; the seam and button rotate with the ball.
 g.push();g.translate(0,10);g.rotate(t*1.6)
 for y=-12,11,3 do local width=math.floor(math.sqrt(144-(y+1.5)^2)/3)*3
  box(-width,y,width*2,3,y<0 and .92 or .91,y<0 and .16 or .94,y<0 and .18 or .97)
 end
 box(-12,-1.5,24,3,.12,.17,.23);box(-4,-4,8,8,.12,.17,.23);box(-2,-2,4,4,1,1,1);g.pop()
 g.push();g.translate(0,3-math.abs(math.sin(t*7))*.8)
 local p=species=='pikachu';local r,b=p and .98 or .61,p and .10 or .25;local green=p and .77 or .38
 -- Profile, ears and tail remain recognisable at a small loading-icon size.
 if p then
  box(-19,-15,5,10,r,green,b);box(-22,-20,9,5,r,green,b);box(-18,-25,5,6,r,green,b)
 else box(-21,-16,12,8,r,green,b);box(-23,-17,5,6,.94,.83,.58)end
 box(-10,-18,15,14,r,green,b);box(-1,-26,14,13,r,green,b)
 box(0,-37,4,13,r,green,b);box(8,-35,4,11,r,green,b)
 box(0,-37,4,4,.18,.12,.10);box(8,-35,4,4,.18,.12,.10)
 if not p then box(-6,-15,13,5,.95,.85,.62)end
 box(9,-22,2,3,.09,.09,.12);box(12,-18,3,2,.13,.10,.09)
 if p then box(6,-17,3,3,.91,.20,.14)end
 local step=math.sin(t*7)*3
 box(-8+step,-5,6,3,r,green,b);box(2-step,-5,6,3,r,green,b)
 g.pop()
end
function M.draw(game)
 local s=M.status();if not s.visible and not s.cover then return end
 local g=love.graphics;local w,h=g.getDimensions()
 if not font then
  font=g.newFont(14)
  if not registered then
   require('src.render.Assets').register(function()if font then font:release();font=nil end;M.clear()end)
   registered=true
  end
 end
 g.push('all')
 local ok,err=pcall(function()
  g.setCanvas();g.origin();g.setShader();g.setScissor();g.setDepthMode();g.setStencilTest();g.setBlendMode('alpha')
  -- The native renderer can re-blit its world canvas after state:draw().
  -- Cover the final composite too, while still warming the scene beneath it.
  -- A validation report above the preparation state must remain readable.
  local top=game and game.stack and game.stack:top()
  local warpCover=s.cover and top and top~=game.overworld
    and type(top.alpha)=='function'and top:alpha()>=1
  if warpCover or (s.kind=='continue'and top and top.vascContinue) then
   g.setColor(.025,.04,.065,1);g.rectangle('fill',0,0,w,h)
  end
  -- Cover a cold arrival immediately; the small indicator still debounces
  -- fast cache hits. Native readiness clears both without a minimum delay.
  if not s.visible then return end
  local scale=math.min(2,math.max(1,w/800));g.translate(w-164*scale,h-54*scale);g.scale(scale)
  g.setColor(.025,.04,.065,.94);g.rectangle('fill',-132,-69,283,105,9,9)
  g.push();g.translate(-88,0);art(g,now()-pending.started,s.species);g.pop()
  g.setFont(font);g.setColor(.93,.96,1,1)
  local text=V.require('SetupLocale').text
  g.print(s.kind=='windows'and text('Loading windows …','Fenster laden …')or s.kind=='continue'and text('Preparing game …','Spiel vorbereiten …')or text('Loading area …','Gebiet laden …'),-47,-24)
  local dots=math.floor((now()-pending.started)*4)%4
  for i=1,3 do g.setColor(.95,.76,.28,i<=dots and 1 or .25);g.rectangle('fill',-45+(i-1)*11,2,5,5)end
 end)
 g.pop();if not ok then error(err)end
end
function M.install(game)
 if game.__vascLoadingCompanion then return end
 local inner=game.draw
 local function after(...)
  local ok=pcall(M.draw,game);if not ok then M.clear()end
  return ...
 end
 game.draw=function(...)return after(inner(...))end
 game.__vascLoadingCompanion=true
end
return M
