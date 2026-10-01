-- Real regional artwork on native guardhouse walls. Viewing is read-only;
-- no map item, Fly destination, island unlock or saved flag is awarded.
local V=...
local M={}
local images={}
local registered,font,fontSize,chartFactory
M.POSTERS={
 {region='sevii',edge='west',u0=.072,u1=.192,v0=.343,v1=.616,page=1},
 {region='kanto',edge='north',u0=.403,u1=.601,v0=.299,v1=.635,page=1},
 {region='sevii',edge='east',u0=.811,u1=.948,v0=.343,v1=.616,page=1},
}
local files={kanto={'kanto_fly_map_wide_zoom.png'},sevii={'sevii_fly_map_master.png'}}
local cache=setmetatable({},{__mode='k'})
function M.clearFrame()
 if M.frame then M.frame.canvas:release();M.frame=nil end
end
local function cleanup()
 M.clearFrame();M.visible=nil;M.viewer=nil;M.dismissed=nil
 for _,i in pairs(images)do if i~=false then i:release()end end;images={}
 if font then font:release();font=nil;fontSize=nil end
 cache=setmetatable({},{__mode='k'})
end
function M.asset(name)
 if name=='kanto_fly_map_wide.png'then name='kanto_fly_map_wide_zoom.png'end
 if not registered then require('src.render.Assets').register(cleanup);registered=true end
 if images[name]==nil then
  local ok,img=pcall(V.require('CompactBackgroundAssets').newImage,V.path..'/assets/maps/'..name,{mipmaps=false,linear=true})
  images[name]=ok and img or false
  if img and ok then img:setFilter('linear','linear')end
 end
 return images[name]or nil
end
function M.image(region,page)
 local names=files[region];local name=names and names[page or 1];return name and M.asset(name)
end
function M.chart(game,region)
 if not chartFactory then
  local source=assert(V.mod:read('integrated/guardhouse_maps/main.lua'))
  local installer=assert((loadstring or load)(source,'@guardhouse-smart-map'))()
  chartFactory=installer({path=V.path,find=V.mod.find,assets={image=function(_,path)
   return M.asset(path:match('([^/]+)$'))
  end}})
 end
 return chartFactory.new(game,region)
end
local function paint(region,page,x,y,w,h)
 local img=M.image(region,page);if not img then return false end
 local iw,ih=img:getDimensions()
 local s=math.min(w/iw,h/ih)
 local g=love.graphics;g.setColor(1,1,1,1)
 g.draw(img,x+(w-iw*s)/2,y+(h-ih*s)/2,0,s,s)
 return true
end
function M.decorate(image)
 local g=love.graphics;local w,h=image:getDimensions()
 -- One shared texture derivative, owned by HorizonWall, at its device-fitted
 -- size. Window paintings, lanterns and the existing wall remain intact.
 local ok,canvas=pcall(g.newCanvas,w,h,{dpiscale=1,msaa=0});if not ok then return end
 g.push('all');g.setCanvas(canvas);g.origin();g.setShader();g.setScissor();g.setDepthMode();g.setStencilTest()
 g.setColor(1,1,1,1);g.setBlendMode('replace');g.clear();g.draw(image,0,0)
 for _,p in ipairs(M.POSTERS)do
  local x,y,bw,bh=p.u0*w,p.v0*h,(p.u1-p.u0)*w,(p.v1-p.v0)*h
  g.setColor(.29,.20,.11,1);g.rectangle('fill',x,y,bw,bh)
  g.setColor(.69,.54,.32,1);g.rectangle('fill',x+3,y+3,bw-6,bh-6)
  g.setColor(.87,.84,.70,1);g.rectangle('fill',x+7,y+7,bw-14,bh-14)
  paint(p.region,p.page,x+9,y+9,bw-18,bh-18)
 end
 g.pop();canvas:setFilter('nearest','nearest');return canvas
end
function M.placements(map)
 local H=V.require('HorizonWall');if H.enabled and not H.enabled()then return{}end
 local native=V.require('Gen1InteriorPanoramas').profileFor(map)
 if not native or native.theme~='gate'then return{}end
 local profile=H.interiorProfileFor(map)
 if not profile or profile.theme~='gate'then return{}end
 if cache[map]then return cache[map]end
 local F=V.require('Gen1InteriorFinish');local panels=V.require('Gen1InteriorLayout').panelsFor(map,profile)
 local feature={};local fits={}
 for _,p in ipairs(panels)do local f=F.placement(p,'gate',profile.shellHeight)
  if f and(not fits[p.edge]or f.width>fits[p.edge].width)then feature[p.edge]=p;fits[p.edge]=f end
 end
 local out={}
 for _,s in ipairs(M.POSTERS)do local p,f=feature[s.edge],fits[s.edge]
  if p and f and s.u0>=f.sourceFrom and s.u1<=f.sourceTo then
   local t=((s.u0+s.u1)/2-f.sourceFrom)/(f.sourceTo-f.sourceFrom);if s.edge=='west'then t=1-t end
   local a=f.left+t*f.width
   out[#out+1]={region=s.region,page=s.page,edge=p.edge,at=p.at,along=a,
    x=p.edge=='north'and a or p.at,z=p.edge=='north'and p.at or a}
  end
 end
 cache[map]=out;return out
end
function M.closest(points,x,z)
 local best,distance
 for _,p in ipairs(points)do local d=(p.x-x)^2+(p.z-z)^2
  if d<=42^2 and(not distance or d<distance)then best,distance=p,d end
 end
 return best
end
function M.update(dt,game,level)
 M.game=game;M.visible=nil
 local ow=game and game.overworld
 if M.frame and(not ow or M.frame.map~=ow.map or M.frame.save~=game.save)then M.clearFrame()end
 if M.viewer then return end
 if not(ow and ow.map and (level or 0)>0 and game.stack:top()==ow and not ow.transitioning
  and not ow.player.inputLocked and not ow.script and not(ow.runner and ow.runner:isRunning()))then M.clearFrame();return end
 local p=M.closest(M.placements(ow.map),(ow.player.px or 0)+8,(ow.player.py or 0)+8)
 if M.dismissed and(M.dismissed.map~=ow.map or not p)then M.dismissed=nil end
 if p and not M.dismissed then
  M.visible={map=ow.map,save=game.save,region=p.region,page=p.page}
  if game.input:wasPressed('b')then M.dismissed={map=ow.map};M.visible=nil;M.clearFrame()end
 elseif not p then M.clearFrame()end
end
function M.keepFrame(canvas,state)
 if not(M.visible and state.map==M.visible.map)or M.viewer then return end
 local w,h=canvas:getDimensions();local g=love.graphics
 if M.frame and(M.frame.w~=w or M.frame.h~=h)then M.clearFrame()end
 if not M.frame then local ok,c=pcall(g.newCanvas,w,h,{msaa=0});if not ok then return end
  M.frame={canvas=c,w=w,h=h,map=state.map,save=M.visible.save}
 end
 g.push('all');g.setCanvas(M.frame.canvas);g.origin();g.setShader();g.setScissor();g.setDepthMode();g.setStencilTest()
 g.setColorMask(true,true,true,true);g.setBlendMode('replace','premultiplied');g.setColor(1,1,1,1);g.draw(canvas,0,0);g.pop()
end
function M.viewFrame(state)
 return M.viewer and M.frame and M.frame.map==state.map and M.viewer.game.stack:top()==M.viewer and M.frame.canvas or nil
end
function M.open(game)
 local s=M.visible
 if not(s and M.frame and s.save==game.save and s.map==game.overworld.map and game.stack:top()==game.overworld)then return false end
 if not M.image(s.region,s.page)then return false end
 local screen=M.chart(game,s.region)
 if not screen or screen.fly or screen.region~=s.region then return false end
 local viewer={game=game,save=game.save,map=s.map,region=s.region,isOpaque=false,kind='GateMapViewer',screen=screen,__ascendantGlobalUiSkinSkip=true}
 function viewer:draw()end
 function viewer:exit()M.viewer=nil;M.dismissed={map=self.map};M.visible=nil;M.clearFrame()end
 screen.showSelectedInfo=function(self)
  local text=chartFactory.formatLocationInfo(self.locations[self.selected],self.language,game,self.current==self.selected)
  viewer.info={};for page in (text..'\f'):gmatch('(.-)\f')do viewer.info[#viewer.info+1]=page end;viewer.infoPage=1
 end
 function viewer:update(dt)
  local input=game.input
  if game.save~=self.save or not game.overworld or game.overworld.map~=self.map then
   game.stack:pop();self:exit();return
  end
  if self.info then
   if input:wasPressed('b')then self.info=nil
   elseif input:wasPressed('a')then self.infoPage=self.infoPage+1;if self.infoPage>#self.info then self.info=nil end end
   return
  end
  self.screen:update(dt)
  self.region=self.screen.region
  if game.stack:top()~=self then self:exit()end
 end
 M.viewer=viewer;game.stack:push(viewer);M.visible=nil;return true
end
function M.install()
 local OW=require('src.world.OverworldController');if OW._vascGateMaps then return end;OW._vascGateMaps=true
 local native=OW.interact
 function OW:interact(...)
  local result=native(self,...);local game=require('src.core.Game')
  if game.stack:top()==self and M.open(game)then return true end
  return result
 end
end
function M.hud(canvas,w,h)
 local viewer=M.viewer;local p=viewer or M.visible;if not p then return canvas end
 local g=love.graphics;local L=V.require('SetupLocale');g.push('all');g.setCanvas(canvas);g.origin();g.setShader();g.setScissor()
 g.setDepthMode();g.setStencilTest();g.setBlendMode('alpha','alphamultiply');g.setColorMask(true,true,true,true)
 if viewer then
  local scale=math.min((w-24)/576,(h-24)/324);local x,y=(w-576*scale)/2,(h-324*scale)/2
  g.translate(x,y);g.scale(scale,scale);viewer.screen:draw()
  if viewer.info then
   g.setColor(.02,.08,.12,.97);g.rectangle('fill',432,84,136,112,4,4)
   g.setColor(.12,.85,.95,1);g.rectangle('line',432,84,136,112,4,4)
   if fontSize~=12 then if font then font:release()end;font=g.newFont(12);fontSize=12 end;g.setFont(font)
   g.setColor(1,1,1,1);g.printf(viewer.info[viewer.infoPage],440,96,120,'center')
   g.printf(L.text('A: Next  B: Close','A: Weiter  B: Zurueck'),440,172,120,'center')
  end
  g.pop();return canvas
 end
 local size=math.max(14,math.min(24,math.floor(h*.025)))
 if fontSize~=size then if font then font:release()end;font=g.newFont(size);fontSize=size end;g.setFont(font)
 local name=p.region=='kanto'and'Kanto'or'Sevii'
 local bw=math.min(w-24,360)
 local bh=size*4.8;local x,y=(w-bw)/2,h-bh-24
 g.setColor(.08,.10,.12,.96);g.rectangle('fill',x,y,bw,bh,8,8)
 g.setColor(.75,.66,.43,1);g.rectangle('line',x+.5,y+.5,bw-1,bh-1,8,8)
 g.setColor(1,1,1,1)
 g.printf(L.text('Look at the '..name..' map?',name..'-Karte anschauen?'),x+12,y+12,bw-24,'center')
 g.printf(L.text('A: View     B: No','A: Ansehen     B: Nein'),x+12,y+12+size*2,bw-24,'center')
 g.pop();return canvas
end
return M
