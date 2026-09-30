-- Integration boundaries: UI fitting, exact-map stair opt-in, native healing
-- and persistent wish rewards including full-bag and repeated-input behavior.
local locale='en'
local modules={SetupLocale={text=function(en,de)return locale=='de'and de or en end}}
local V={require=function(n)return assert(modules[n],n)end,mod={}}
local B=assert(loadfile('lib/ObservationBinoculars.lua'))(V)
local font={getHeight=function()return 18 end,getWidth=function(_,s)return #s*9 end,
 getWrap=function(self,s,w)
  local rows={};local row=''
  for word in s:gmatch('%S+')do local next=row==''and word or row..' '..word
   if #next*9>w and row~=''then rows[#rows+1]=row;row=word else row=next end
  end
  rows[#rows+1]=row;return w,rows
 end}
for _,lang in ipairs{'en','de'}do locale=lang
 for _,size in ipairs{{320,180},{390,844},{960,640},{1920,1080}}do
  local p=B.helpLayout(size[1],size[2],font,4)
  assert(p.y>=0 and p.y+p.h<=size[2]and #p.lines>=2)
  for _,line in ipairs(p.lines)do assert(font:getWidth(line)<=p.w-p.pad*2)end
  assert(p.lines[1]:find(lang=='de'and'FERNGLAS'or'BINOCULARS',1,true))
 end
end
local posters=assert(loadfile('lib/LabPosters.lua'))()
assert(posters.matches{id='OAKS_LAB',def={tileset='DOJO',width=5,height=6}})
assert(not posters.matches{id='BILLS_HOUSE',def={tileset='DOJO',width=5,height=6}})
local layouts=posters.layout({edge='north',from=0,upto=128},76.25)
assert(#layouts==3 and layouts[1].top-layouts[1].bottom>=50)
for i,p in ipairs(layouts)do assert(p.from>=0 and p.upto<=128 and p.u0<p.u1 and p.v1<p.v0)
 assert(p.bottom==22 and p.top==72,'large scrolls must hang lower under the reduced ceiling')
 if i>1 then assert(p.from>layouts[i-1].upto)end end
assert(layouts[1].u0==.345 and layouts[2].u0==.866 and layouts[3].u0==.021,'native ball order')
assert(#posters.layout({edge='west',from=0,upto=128},55)==0)
modules.ModSetting={new=function()return{get=function()return true end}end}
modules.Gen1InteriorFloors={profile=function()end}
local stairs=assert(loadfile('lib/Gen1Stairs.lua'))(V)
for _,spec in ipairs{{'MUSEUM_1F','MUSEUM',10,4},{'POKEMON_TOWER_3F','CEMETERY',10,9},{'ROCKET_HIDEOUT_B1F','FACILITY',15,14}}do
 local map={id=spec[1],def={tileset=spec[2],width=spec[3],height=spec[4],warps={{x=3,y=3}}}}
 for _,class in ipairs{'stair_e','stair_down_e'}do
  local f=stairs.flight(map,3,3,{art='stair',class=class,h=16})
  assert(f.count==6 and f.count*f.depth==12 and f.count*f.rise==(f.down and 6 or 10))
  assert(f.rise/f.depth<1,'reviewed stairs must be shallower than 45 degrees')
 end
 map.def.width=1;assert(not stairs.reviewedFlight(map))
end
local calls=0;local commands={heal_party=function(ctx)calls=calls+1;ctx.healed=true;return 'native'end}
package.loaded['src.script.Commands']=commands
local meal=assert(loadfile('lib/HomeMeal.lua'))(V);meal.install();meal.install()
local save={};local map={id='REDS_HOUSE_1F'};local ow={map=map}
assert(commands.heal_party{save=save,overworld=ow}=='native'and calls==1 and meal.save==save)
local game={save=save,overworld=ow,stack={top=function()return ow end}}
meal.update(.1,game);assert(meal.remaining<180)
game.save={};meal.update(.1,game);assert(not meal.save)
commands.heal_party{save=save,overworld={map={id='VIRIDIAN_POKECENTER'}}};assert(not meal.save)
local state;local full=false
V.mod.save={get=function()return state end,set=function(_,k,v)state=v end}
modules.SkyEvents={clock=800}
package.loaded['src.inventory.Bag']={add=function(s,item)
 if full then return false end;s.inventory[item]=(s.inventory[item]or 0)+1;return true end}
local wishes=assert(loadfile('lib/MewSky.lua'))(V)
game.save={inventory={}};game.data={items={NUGGET={},ELIXER={},ULTRA_BALL={},MASTER_BALL={}}}
assert(wishes.DURATION==6 and wishes.progress(791)~=nil and wishes.progress(795)==nil)
full=true;assert(not wishes.claim(game,791,'NUGGET')and not state)
full=false;assert(not wishes.claim(game,791,'MASTER_BALL')and not state)
assert(not wishes.claim(game,795,'NUGGET')and not state)
assert(wishes.claim(game,791,'NUGGET')and game.save.inventory.NUGGET==1)
assert(not wishes.claim(game,791,'ELIXER')and not game.save.inventory.ELIXER)
assert(wishes.claim(game,791+wishes.PERIOD,'ELIXER')and game.save.inventory.ELIXER==1)
assert(wishes.claim(game,791+wishes.PERIOD*2,'ULTRA_BALL')and game.save.inventory.ULTRA_BALL==1)
assert(not wishes.claim(game,791,'NUGGET'),'clock rewind must not duplicate a reward')
assert(not game.save.inventory.MASTER_BALL)
-- Native choice is deferred until selection; capturing A in time allows an
-- unhurried selection after the silhouette has passed. B uses ListMenu's
-- native cancel behavior and never calls the reward callback.
state=nil;game.save.inventory={};modules.SkyEvents.clock=791
local stack={};game.overworld=ow;ow.player={};game.stack={top=function()return stack[#stack]end,
 push=function(_,v)stack[#stack+1]=v end,pop=function()return table.remove(stack)end}
stack[1]=ow;wishes.world=ow;wishes.visible={world=ow,clock=791}
wishes.allowed=function(g)return g.stack:top()==ow end
ow.map={id='ROUTE_1'};wishes.frame={map=ow.map,save=game.save,canvas={release=function()end}}
package.loaded['src.ui.ListMenu']={new=function(g,title,rows,opts)
 return {game=g,title=title,items=rows,onChoose=opts.onChoose}end}
package.loaded['src.render.TextBox']={new=function(g,text)return {text=text}end}
assert(wishes.tryWish(game));local menu=stack[2]
assert(wishes.choiceFrame(ow)==wishes.frame.canvas,'wish window must keep its actual world frame')
assert(#menu.items==3 and not next(game.save.inventory))
modules.SkyEvents.clock=795;menu:onChoose(menu.items[3])
assert(game.save.inventory.ULTRA_BALL==1 and not game.save.inventory.MASTER_BALL)
stack={ow};wishes.visible={world=ow,clock=791};modules.SkyEvents.clock=791
assert(not wishes.tryWish(game),'claimed sighting must not open another choice')
modules.SkyEvents.clock=791+wishes.PERIOD
wishes.visible={world=ow,clock=modules.SkyEvents.clock};assert(wishes.tryWish(game))
game.input={wasPressed=function(_,key)return key=='b'end};game.stack:top():update(0)
assert(not wishes.choice and game.save.inventory.ULTRA_BALL==1,'cancel must not give a reward')
-- Rendering elsewhere in the sky or beyond the short deadline cannot show
-- the A prompt. A centered, world-projected outline can.
local g={setLineWidth=function()end,setColor=function()end,line=function()end,circle=function()end}
wishes.world=ow;ow.map={id='ROUTE_1'};wishes.visible=nil
local ctx={g=g,mapId='ROUTE_1',skyEnabled=true,clock=791,w=800,h=600,edge=600,
 project=function()return 10,300,true end}
assert(wishes.paint(ctx)==1 and not wishes.visible)
ctx.project=function()return 400,300,true end;assert(wishes.paint(ctx)==1 and wishes.visible)
wishes.visible=nil;ctx.clock=795;assert(wishes.paint(ctx)==0 and not wishes.visible)
for _,size in ipairs{{320,180},{390,844},{1100,760},{1920,1080}}do
 local box=wishes.choiceLayout(size[1],size[2]);assert(box.x>=0 and box.y>=0 and box.x+box.w<=size[1]and box.y+box.h<=size[2])
 assert(box.w<=320,'wish choice must stay a small window')
end
-- A rejected frame allocation declines the optional wish without retrying
-- every render or disturbing the world. A later sighting may retry.
wishes.frame=nil;local attempts=0
love={graphics={newCanvas=function()attempts=attempts+1;error('QA allocation rejected')end}}
local canvas={getDimensions=function()return 320,180 end}
wishes.visible={world=ow};wishes.keepFrame(canvas,ow);wishes.keepFrame(canvas,ow)
assert(attempts==1 and not wishes.frame)
modules.SkyEvents.clock=795;wishes.update(0,game,6)
modules.SkyEvents.clock=791;wishes.visible={world=ow};wishes.keepFrame(canvas,ow)
assert(attempts==2)
assert(not wishes.alreadyClaimed({lastOccurrence=828,lastClock=998980},791),'natural sky clock wrap must allow new wishes')
print('PASS responsive EN/DE help, compact lab in ball order, exact shallow stairs, native meal lifecycle, quick aimed Mew with three bounded choices/full bag/cancel')
