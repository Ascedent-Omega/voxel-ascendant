-- A brief, world-projected Mew constellation. Catching the sighting opens a
-- native item choice; each appearance can grant exactly one ordinary item.
local V=...
local M={PERIOD=1207,DURATION=6,OFFSET=419,SAVE_KEY='mewSkyWishes'}
local font,fontSize
M.REWARDS={NUGGET=true,ELIXER=true,ULTRA_BALL=true}
-- Floating outline: ears, head, small body/feet, and Mew's long curled tail.
M.POINTS={{-.6,.8},{-.72,1.25},{-.34,1.06},{.05,1.15},{.43,1.03},{.8,1.22},
 {.76,.7},{.9,.38},{.68,.08},{.32,-.02},{.46,-.4},{.73,-.55},{.91,-.85},
 {.55,-.9},{.22,-.65},{-.1,-.83},{-.45,-.85},{-.47,-.61},{-.28,-.44},
 {-.52,-.08},{-.81,.1},{-.94,.4},{-.6,.8},
 {-.45,-.32},{-.92,-.54},{-1.43,-.58},{-1.8,-.25},{-1.83,.18},
 {-1.6,.51},{-1.28,.47},{-1.19,.2}}
function M.progress(clock)
 local phase=((clock or V.require('SkyEvents').clock)+M.OFFSET)%M.PERIOD
 if phase<M.DURATION then return phase/M.DURATION end
end
function M.alreadyClaimed(state,clock)
 if type(state)~='table'or type(state.lastOccurrence)~='number'then return false end
 -- SkyEvents deliberately wraps after 1,000,003 seconds. A genuine wrap
 -- must not disable wishes for the next entire clock cycle.
 local wrapped=type(state.lastClock)=='number'and state.lastClock-clock>500001
 return not wrapped and state.lastOccurrence>=math.floor((clock+M.OFFSET)/M.PERIOD)
end
function M.allowed(game,level)
 local ow=game and game.overworld
 return (level or 0)>0 and ow and game.save and game.stack:top()==ow
  and ow.map and ow.map.def.generation~=2
  and not ow.player.inputLocked and not ow.transitioning and not ow.flyAnim
  and not ow.script and not(ow.runner and ow.runner:isRunning())
  and V.require('Weather').isOutdoor(ow.map) and V.require('Sky').banded()
  and V.require('SkyEvents').enabled('pidgeot')
  and V.require('DayNight').tod()=='NIGHT'
end
function M.update(dt,game,level)
 M.visible=nil;M.game=game;M.level=level
 M.world=M.allowed(game,level)and game.overworld or nil
 local ow=game and game.overworld
 if not M.world or M.progress()==nil then M.frameFailed=nil end
 if M.frame and(not ow or M.frame.save~=game.save or M.frame.map~=ow.map
  or not M.choice and(not M.world or M.progress()==nil))then M.clearFrame()end
end
function M.clearFrame()
 if M.frame then M.frame.canvas:release();M.frame=nil end
end
function M.keepFrame(canvas,state)
 if not M.visible or M.choice or M.frameFailed or M.visible.world~=state then return end
 local w,h=canvas:getDimensions();local g=love.graphics
 if M.frame and(M.frame.w~=w or M.frame.h~=h)then M.clearFrame()end
 if not M.frame then
  local ok,copy=pcall(g.newCanvas,w,h,{msaa=0})
  if not ok then M.frameFailed=true;return end
  M.frame={canvas=copy,map=state.map,save=M.game.save,w=w,h=h}
 end
 g.push('all');g.setCanvas(M.frame.canvas);g.origin();g.setShader();g.setScissor()
 g.setDepthMode();g.setStencilTest();g.setColorMask(true,true,true,true)
 g.setBlendMode('replace','premultiplied');g.setColor(1,1,1,1);g.draw(canvas,0,0);g.pop()
end
function M.choiceFrame(state)
 local choice,frame=M.choice,M.frame
 if state and choice and frame and choice.game.stack:top()==choice
  and frame.save==choice.game.save and frame.map==state.map then return frame.canvas end
end
function M.paint(ctx)
 if not(M.world and ctx and not ctx.battleView
  and ctx.mapId==M.world.map.id and ctx.skyEnabled)then return 0 end
 local p=M.progress(ctx.clock);if not p then return 0 end
 if ctx.weather=='storm'or ctx.weather=='fog'or ctx.weather=='volcanic'then return 0 end
 local az=-.5+p;local el=.55+math.sin(p*math.pi)*.025
 local x,y,visible=ctx.project(az,el)
 if visible==false or not x or not y or x<0 or x>ctx.w or y<0 or y>ctx.edge then return 0 end
 local g=ctx.g;local alpha=math.min(1,p/.12,(1-p)/.12)*(ctx.alpha or 1)
 local dots={}
 for i,point in ipairs(M.POINTS)do
  local tx,ty,on=ctx.project(az+point[1]*.027,el+point[2]*.027)
  if tx and ty and on~=false then dots[i]={tx,ty}end
 end
 g.setLineWidth(1)
 g.setColor(.8,.86,1,alpha*.26)
 for i=2,#M.POINTS do
  if i~=24 and dots[i-1]and dots[i]then g.line(dots[i-1][1],dots[i-1][2],dots[i][1],dots[i][2])end
 end
 for i,dot in pairs(dots)do
  local r=i%4==0 and 1.2 or .7
  g.setColor(.88,.92,1,alpha*(i%4==0 and .88 or .48));g.circle('fill',dot[1],dot[2],r,6)
 end
 g.setColor(1,1,1,1)
 -- The silhouette can pass elsewhere on screen, but A only catches it when
 -- the player actually looks towards it. No offscreen/camera-independent wish.
 if alpha>.2 and math.abs(x-ctx.w*.5)<ctx.w*.17 and math.abs(y-ctx.h*.5)<ctx.h*.24 then
  M.visible={world=M.world,clock=ctx.clock or V.require('SkyEvents').clock}
 end
 return 1
end
function M.claim(game,clock,item)
 if not M.REWARDS[item]or M.progress(clock)==nil then return false,'unavailable' end
 local api=V.mod and V.mod.save
 if not(api and api.get and api.set and game and game.save)then return false,'unavailable' end
 local state=api:get(M.SAVE_KEY)or{}
 if type(state)~='table'then state={}end
 local occurrence=math.floor((clock+M.OFFSET)/M.PERIOD)
 if M.alreadyClaimed(state,clock)then return false,'claimed' end
 if not(game.data.items and game.data.items[item])then return false,'unavailable' end
 if not require('src.inventory.Bag').add(game.save,item,1,game.data)then return false,'full' end
 api:set(M.SAVE_KEY,{lastOccurrence=occurrence,lastClock=clock})
 return true,item
end
function M.tryWish(game)
 local s=M.visible;local ow=game and game.overworld
 if not(s and s.world==ow and M.world==ow and M.frame and M.frame.save==game.save
  and M.frame.map==ow.map and M.progress()~=nil and M.allowed(game,M.level))then return false end
 local L=V.require('SetupLocale');local clock=s.clock
 local state=V.mod.save:get(M.SAVE_KEY)
 if M.alreadyClaimed(state,clock)then return false end
 local rows={{label=L.text('Nugget','Nugget'),value='NUGGET'},
  {label=L.text('Elixir','Elixier'),value='ELIXER'},
  {label=L.text('Ultra Ball','Hyperball'),value='ULTRA_BALL'}}
 local menu={game=game,save=game.save,kind='MewWish',isOpaque=false,
  title=L.text('Make a wish','Wuensch dir etwas'),items=rows,index=1,
  footer=L.text('A: Choose  B: Cancel','A: Waehlen  B: Zurueck')}
 function menu:exit()if M.choice==self then M.choice=nil end end
 function menu:draw()end -- Draw the small window in the final-resolution HUD.
 function menu:onChoose(item)
  if game.stack:top()~=self or game.save~=self.save then return end
  local ok,result=M.claim(game,clock,item.value)
  game.stack:pop();self:exit()
  local msg
  if ok then msg=L.text('Your wish came true!\nReceived '..item.label..'.','Dein Wunsch wurde erfuellt!\n'..item.label..' erhalten.')
  elseif result=='full'then msg=L.text('Your bag is full.','Dein Beutel ist voll.')
  else msg=L.text('The shooting stars have passed.','Die Sternschnuppen sind vorbeigezogen.')end
  game.stack:push(require('src.render.TextBox').new(game,msg))
 end
 function menu:update(dt)
  if game.save~=self.save then game.stack:pop();self:exit();return end
  local input=game.input
  if input:wasPressed('b')then game.stack:pop();self:exit()
  elseif input:wasPressed('up')then self.index=(self.index-2)%3+1
  elseif input:wasPressed('down')then self.index=self.index%3+1
  elseif input:wasPressed('a')then self:onChoose(self.items[self.index])end
 end
 M.choice=menu
 game.stack:push(menu);M.visible=nil
 return true
end
function M.install()
 local OW=require('src.world.OverworldController')
 if OW._vascMewWish then return end;OW._vascMewWish=true
 local interact=OW.interact
 function OW:interact(...)
  -- Run the native interaction first. NPCs, hidden objects, signs and map
  -- scripts keep priority; only an otherwise idle A may catch the sky event.
  local result=interact(self,...)
  local game=require('src.core.Game')
  if game.stack:top()==self and M.tryWish(game)then return true end
  return result
 end
 require('src.render.Assets').register(function()
  M.clearFrame();M.choice=nil;M.visible=nil
  if font then font:release();font=nil;fontSize=nil end
 end)
end
function M.choiceLayout(w,h)
 local size=math.max(14,math.min(22,math.floor(h*.025)))
 local width=math.min(w-24,320,math.max(240,w*.3))
 local height=size*8.1+24
 return {x=(w-width)/2,y=math.min(h*.58,h-height-16),w=width,h=height,size=size}
end
function M.hud(out,w,h)
 local choice=M.choice
 if choice and(choice.game.stack:top()~=choice or choice.save~=choice.game.save)then choice=nil end
 if not M.visible and not choice then return out end
 local g=love.graphics;g.push('all');g.setCanvas(out)
 -- Pipelines.present receives the final composite. The iOS world-canvas
 -- reflection has already been applied; final HUD text stays upright.
 g.origin()
 local size=math.max(14,math.min(22,math.floor(h*.025)))
 if fontSize~=size then if font then font:release()end;font=g.newFont(size);fontSize=size end
 g.setFont(font)
 if choice then
  local box=M.choiceLayout(w,h);local x,y,width=box.x,box.y,box.w
  g.setColor(.055,.065,.11,.96);g.rectangle('fill',x,y,width,box.h,9,9)
  g.setColor(.64,.73,.95,.85);g.setLineWidth(1);g.rectangle('line',x+.5,y+.5,width-1,box.h-1,9,9)
  g.setColor(.93,.95,1,1);g.printf(choice.title,x+12,y+12,width-24,'center')
  for i,item in ipairs(choice.items)do
   local rowY=y+12+size*1.8+(i-1)*size*1.8
   if i==choice.index then
    g.setColor(.24,.3,.48,1);g.rectangle('fill',x+9,rowY-3,width-18,size*1.65,5,5)
    g.setColor(.96,.89,.58,1);g.polygon('fill',x+17,rowY+3,x+17,rowY+size-3,x+24,rowY+size/2)
   end
   g.setColor(.93,.95,1,1);g.print(item.label,x+32,rowY)
  end
  g.setColor(.71,.77,.88,1);g.printf(choice.footer,x+10,y+box.h-size*1.35-8,width-20,'center')
 else
  local text=V.require('SetupLocale').text('A: Make a wish','A: Wuensch dir etwas')
  local width=math.min(w-24,font:getWidth(text)+24);local height=size*1.3+12
  g.setColor(.035,.045,.08,.7);g.rectangle('fill',(w-width)/2,h-height-12,width,height,6,6)
  g.setColor(.9,.94,1,.95);g.printf(text,(w-width)/2+8,h-height-6,width-16,'center')
 end
 g.pop();return out
end
return M
