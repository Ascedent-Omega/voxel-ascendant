-- Presentation for Gen 1 Silph pads. The engine still resolves the warp,
-- owns the state-stack input lock, loads the map and releases the entry cell.
local V = ...
local T = { FRAMES = 78, DISSOLVE = 66, FADE = 12 }
local KEY = '__vascSilphTeleport'
local INSTALL = '__vascSilphTeleportInstall'
local unpack = unpack or table.unpack
local function pack(...) return {n=select('#', ...), ...} end
local function clamp(v) return math.max(0, math.min(1, v)) end
local function floorMap(id)
  local floor = type(id)=='string' and tonumber(id:match('^SILPH_CO_(%d+)F$'))
  return floor and floor>=2 and floor<=11 or false
end
function T.eligible(ow, destination)
  return ow and ow.player and ow.arriveWarp=='teleport'
    and floorMap(ow.map and ow.map.id) and floorMap(destination)
    and ow.map.warpPadOrHoleAt
    and ow.map:warpPadOrHoleAt(ow.player.cellX, ow.player.cellY)=='pad'
    and V.require('VoxelState').active()==true
end
function T.amount(transition)
  if transition.phase=='out' then return clamp(transition.t/T.DISSOLVE) end
  return 1-clamp((transition.t-T.FADE)/T.DISSOLVE)
end
function T.alpha(transition)
  if transition.phase=='out' then return clamp((transition.t-T.DISSOLVE)/T.FADE) end
  return 1-clamp(transition.t/T.FADE)
end
local function release(fx)
  if fx.mesh then fx.mesh:release(); fx.mesh=nil end
  fx.vertices=nil;fx.pieces=nil;fx.amount=nil;fx.failed=nil
  fx.texture=nil;fx.model=nil;fx.sunModel=nil
end
function T.clear(ow)
  local fx=ow and rawget(ow,KEY)
  if fx then release(fx); ow[KEY]=nil end
end
function T.current(ow)
  local fx=ow and rawget(ow,KEY)
  if not fx then return nil end
  -- Save reload, interrupted transition or renderer switch cannot leave a
  -- hidden player behind. A covering state may temporarily sit above it.
  if fx.game.overworld~=ow or not ow.transitioning
      or ow.map~=fx.map or not V.require('VoxelState').active() then
    T.clear(ow); return nil
  end
  return fx
end
local function stopSpin(player)
  player.spinning=false
  player.spinFrames=nil; player.spinDrop=nil; player.spinRise=nil
  player.spinHolds=nil;player.spinStep=nil;player.spinHold=nil
  player.spinRiseFrom=nil;player.spinDropSteps=nil;player.spinImageIndex=nil
end
function T.decorate(ow, game, transition, facing)
  if not (transition and transition.phase=='out' and transition.t==0
      and type(transition.onMidpoint)=='function'
      and type(transition.draw)=='function') then return false end
  T.clear(ow)
  local fx={game=game,map=ow.map,transition=transition,facing=facing}
  ow[KEY]=fx
  stopSpin(ow.player)
  transition.frames=T.FRAMES
  if transition.framesIn~=nil then transition.framesIn=T.FRAMES end
  local midpoint,done,draw=transition.onMidpoint,transition.onDone,transition.draw
  transition.onMidpoint=function(...)
    local result=pack(midpoint(...))
    release(fx)
    fx.map=ow.map
    stopSpin(ow.player)
    return unpack(result,1,result.n)
  end
  transition.onDone=function(...)
    T.clear(ow)
    if ow.spinArrive then ow.player.inputLocked=false end
    if ow.delaySfx and ow.delaySfx.key=='Teleport_Enter2' then ow.delaySfx.frames=1 end
    if done then return done(...) end
  end
  -- Older hosts lack the reveal gate in Transition:update. Keep the cold
  -- destination black until the same pipeline readiness contract is met.
  local update=transition.update
  transition.update=function(self,...)
    local ready=require('src.render.Pipelines').worldRevealReady
    if self.phase=='in' and self.t==0 and ready and not ready(game) then return end
    return update(self,...)
  end
  -- Delegate full-canvas/letterbox handling to the engine.
  transition.draw=function(self,...)
    local t,frames,framesIn=self.t,self.frames,self.framesIn
    local alpha=T.alpha(self)
    self.frames=1; if framesIn~=nil then self.framesIn=1 end
    self.t=self.phase=='out' and alpha or 1-alpha
    local result=pack(pcall(draw,self,...))
    self.t,self.frames,self.framesIn=t,frames,framesIn
    if not result[1] then error(result[2],0) end
    return unpack(result,2,result.n)
  end
  return true
end
function T.install(game)
  local ow=game and game.overworld
  if not (ow and type(ow.startWarpTo)=='function') then return false end
  local prior=rawget(ow,INSTALL)
  if prior then prior.api=T; prior.game=game; return true end
  local state={api=T,game=game,original=ow.startWarpTo,takeWarp=ow.takeWarp}
  ow[INSTALL]=state
  ow.startWarpTo=function(self,mapId,...)
    local eligible=state.api.eligible(self,mapId)
    local facing=self.player and self.player.facing
    local result=pack(state.original(self,mapId,...))
    if eligible then
      state.api.decorate(self,state.game,state.game.stack:top(),facing)
    end
    return unpack(result,1,result.n)
  end
  if type(state.takeWarp)=='function' then
    ow.takeWarp=function(self,warp,...)
      local result=pack(state.takeWarp(self,warp,...))
      -- New engines stage a rising spin before startWarpTo. Reuse its
      -- resolved continuation (including follower spawn), replacing only
      -- that presentation lead-in. Older engines already pushed the fade.
      local departure=self.teleportOut
      if departure and type(departure.go)=='function'
          and state.api.eligible(self,warp and warp.destMap) then
        self.teleportOut=nil
        stopSpin(self.player)
        self.player.inputLocked=false
        self.playerHidden=false
        departure.go()
      end
      return unpack(result,1,result.n)
    end
  end
  return true
end

-- Deterministic fragmented sprite: one bounded reusable mesh, no image readback,
-- no baked hero palette, no random-number consumption from gameplay.
local GRID=20
local function noise(i,s) return ((i*73+s*151)%997)/997 end
function T.fragment(col,row,amount)
  local i=row*GRID+col
  -- Head/right shoulder go first, then an irregular front crosses the body.
  local delay=.34*(row/(GRID-1))+.10*(1-col/(GRID-1))+.08*noise(i,1)
  local q=clamp((amount-delay)/.48)
  local drift=q*q
  local size=1-clamp((q-.55)/.45)
  return (10+8*noise(i,2))*drift+math.sin(q*6+noise(i,3)*6)*q*2,
    (9+13*noise(i,4))*drift,
    (noise(i,5)-.5)*12*drift, size, q*(noise(i,6)-.5)*5, q
end
-- Capture the final renderer mesh, after wardrobe, rig and voxel look have
-- resolved. All faces use their original UVs. Subdivide broad planar cards
-- into small closed shards; existing voxel faces already have small cells.
function T.capture(fx, source)
  local indices=source:getVertexMap()
  if not indices or #indices%6~=0 then return false end
  local points={};local lo,hi=math.huge,-math.huge
  local zlo,zhi=math.huge,-math.huge
  for i=1,source:getVertexCount() do
    local v={source:getVertex(i)};points[i]=v
    lo=math.min(lo,v[2]);hi=math.max(hi,v[2])
    zlo=math.min(zlo,v[3]);zhi=math.max(zhi,v[3])
  end
  if hi<=lo or #indices>96000 then return false end
  local pieces,verts,map={},{},{}
  local v3=V.require('Voxel3D')
  local planar=zhi-zlo<.6
  local unit=math.max(.65,(hi-lo)/22)
  local function mix(a,b,c,d,u,v)
    local out={}
    for k=1,6 do out[k]=(a[k]*(1-u)+b[k]*u)*(1-v)+(d[k]*(1-u)+c[k]*u)*v end
    return out
  end
  local function quad(piece,a,b,c,d,depth)
    v3.pushQuad(map,#verts/4)
    for _,p in ipairs{a,b,c,d} do
      verts[#verts+1]={unpack(p)}
      piece.vertices[#piece.vertices+1]={index=#verts,base=p,depth=depth or 0}
    end
  end
  for n=1,#indices,6 do
    local a,b,c,d=points[indices[n]],points[indices[n+1]],points[indices[n+2]],points[indices[n+5]]
    -- The engine and human rig use indexed quads (including shared vertices).
    if indices[n]~=indices[n+3] or indices[n+2]~=indices[n+4] then return false end
    local nx=planar and math.max(1,math.ceil(math.abs(b[1]-a[1])/unit)) or 1
    local ny=planar and math.max(1,math.ceil(math.abs(d[2]-a[2])/unit)) or 1
    for y=0,ny-1 do for x=0,nx-1 do
      local aa=mix(a,b,c,d,x/nx,y/ny);local bb=mix(a,b,c,d,(x+1)/nx,y/ny)
      local cc=mix(a,b,c,d,(x+1)/nx,(y+1)/ny);local dd=mix(a,b,c,d,x/nx,(y+1)/ny)
      local center=mix(a,b,c,d,(x+.5)/nx,(y+.5)/ny)
      local piece={x=center[1],y=center[2],z=center[3],vertices={},
        col=math.floor(center[1]/unit)%GRID,row=clamp((hi-center[2])/(hi-lo))*(GRID-1)}
      pieces[#pieces+1]=piece
      quad(piece,aa,bb,cc,dd)
      if planar then
        local function edge(p)
          local v={unpack(p)};v[4],v[5],v[6]=center[4],center[5],p[6]*.78;return v
        end
        -- Back stays textured; edges sample the same real clothing texel.
        quad(piece,bb,aa,dd,cc,-unit)
        for _,pair in ipairs{{aa,bb},{bb,cc},{cc,dd},{dd,aa}} do
          local u,v=edge(pair[1]),edge(pair[2])
          quad(piece,u,v,v,u)
          local count=#piece.vertices
          piece.vertices[count-1].depth=-unit;piece.vertices[count].depth=-unit
        end
      end
    end end
  end
  if #verts>65532 then return false end
  fx.mesh=v3.newMesh(verts,map)
  if not fx.mesh then return false end
  fx.pieces,fx.vertices=pieces,verts
  return true
end
function T.animate(fx)
  if not fx.mesh then return nil end
  local amount=T.amount(fx.transition)
  if fx.amount==amount then return fx.mesh end
  for _,piece in ipairs(fx.pieces) do
    local dx,dy,dz,size,angle,q=T.fragment(piece.col,piece.row,amount)
    local c,s=math.cos(angle),math.sin(angle)
    for _,record in ipairs(piece.vertices) do
      local v=record.base;local x,y=(v[1]-piece.x)*size,(v[2]-piece.y)*size
      local out=fx.vertices[record.index]
      out[1]=piece.x+x*c-y*s+dx
      out[2]=piece.y+x*s+y*c+dy
      out[3]=piece.z+(v[3]-piece.z+record.depth*math.min(1,q*8))*size+dz
    end
  end
  fx.mesh:setVertices(fx.vertices);fx.amount=amount
  return fx.mesh
end
function T.present(fx,mesh,texture,model,sunModel)
  if not fx.mesh and not fx.failed then
    local ok,built=pcall(T.capture,fx,mesh)
    if not ok or not built then fx.failed=true;return nil end
  end
  fx.texture,fx.model,fx.sunModel=texture,model,sunModel
  return T.animate(fx)
end
return T
