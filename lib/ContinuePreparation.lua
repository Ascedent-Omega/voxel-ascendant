-- Continue uses the normal scene scheduler. The cover owns input only until
-- the destination has been prepared AND drawn, so first-use GPU work happens
-- behind the loading image. Save restoration still runs exactly once.
local V=...
local M={}
local marker='__vascContinuePreparation'
local active=setmetatable({},{__mode='v'})
local function opaqueCover(state)
 local cover=active[1]
 local top=cover and cover.game.stack:top()
 local visible=top==cover
 if cover and top and top.ascendantStartup then
  -- The shared intro is opaque and ticks this native preparation owner.
  for _,s in ipairs(cover.game.stack.states)do if s==cover then visible=true;break end end
 end
 if cover and visible and cover.stage=='scene'
     and cover.map==state.map and cover.drawn and cover:alpha()==1 then return cover end
end
-- Once the arrival has actually been presented, only optional region work
-- remains. Reuse that canvas behind the opaque loader instead of drawing
-- the same invisible scene hundreds of times. No extra framebuffer copy.
function M.cachedScene(state,w,h,vw,vh)
 local cover=opaqueCover(state);local frame=cover and cover.frame
 if not frame or not cover.region then return end
 if frame.w~=w or frame.h~=h or frame.vw~=vw or frame.vh~=vh
     or not V.require('VoxelScene').readyForReveal(state)then
  cover.frame=nil;return
 end
 cover.cachedFrames=(cover.cachedFrames or 0)+1
 return frame.canvas
end
function M.rememberScene(canvas,state,w,h,vw,vh)
 local cover=opaqueCover(state)
 if cover and canvas then cover.frame={canvas=canvas,w=w,h=h,vw=vw,vh=vh}end
end
function M.install(game)
 if game[marker]then return end
 local original=game.restoreSave
 if type(original)~='function'then return end
 game.restoreSave=function(self,loaded,recovered,opts)
  -- Released engines before the continued flag still enter via our shared card.
  local entry=self.__ascendantEntryCardV1
  local continued=opts and opts.continued or(entry and entry.entering and entry.active and entry.active.kind=='continue')
  if not continued or require('src.render.Pipelines').worldPipeline()~='voxel'then
   return original(self,loaded,recovered,opts)
  end
  local loader=V.require('LoadingCompanion')
  local cover={game=self,drawn=false,stage='save',vascContinue=true,phase='in',t=0}
  active[1]=cover
  function cover:alpha()return 1 end
  function cover:draw()
   local g=love.graphics;g.push('all');g.setShader();g.setColor(0,0,0,1)
   g.rectangle('fill',-10000,-10000,20000,20000);g.pop();self.drawn=true
  end
  function cover:update()
   if not self.drawn then return end -- present the indicator before restoring
   if self.stage=='save'then
    self.stage='scene';self.drawn=false
    original(game,loaded,recovered,opts)
    self.map=game.overworld and game.overworld.map
    self.presentation=V.require('WorldSceneHold').serial()
    -- Preserve a validation report above us, rather than consuming its input.
    local states=game.stack.states
    local at=1;for i,s in ipairs(states)do if s==game.overworld then at=i+1;break end end
    table.insert(states,at,self)
   end
   local scene=V.require('VoxelScene')
   local ready=require('src.render.Pipelines').worldPipeline()~='voxel'
    or (scene.readyForReveal(game.overworld) and self.drawn
      and V.require('WorldSceneHold').serial()>self.presentation)
   if ready and require('src.render.Pipelines').worldPipeline()=='voxel'then
    local regions=V.require('RegionPreparation')
    self.region=self.region or regions.new(game)
    ready=regions.update(self.region,game)
   end
   loader.probe(self.map or {id='CONTINUE'},ready,'continue')
   if ready then
    self.frame=nil
    for i,s in ipairs(game.stack.states)do if s==self then table.remove(game.stack.states,i);break end end
   end
  end
  game.stack:push(cover)
  loader.probe({id='CONTINUE'},false,'continue')
 end
 game[marker]=true
end
return M
