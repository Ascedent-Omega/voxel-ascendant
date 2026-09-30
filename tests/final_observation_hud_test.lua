-- Final composites must not inherit the iOS world-canvas reflection.
local state={transform='inherited',canvas='previous',color='previous'}
local saved,draws,origins
local font={getWidth=function(_,s)return #s*7 end,getHeight=function()return 14 end,
 getWrap=function(_,s)return 100,{s}end,release=function()end}
local g={push=function(mode)assert(mode=='all');saved={transform=state.transform,canvas=state.canvas,color=state.color}end,
 pop=function()state=saved end,setCanvas=function(c)state.canvas=c end,
 origin=function()state.transform='upright';origins=origins+1 end,
 translate=function()error('final HUD translated into world reflection')end,
 scale=function()error('final HUD reflected')end,
 newFont=function()return font end,setFont=function()end,setLineWidth=function()end,
 setColor=function()state.color='hud'end}
for _,name in ipairs{'rectangle','printf','print','polygon'}do
 g[name]=function()assert(state.transform=='upright'and state.canvas=='final');draws=draws+1 end
end
love={graphics=g,system={getOS=function()return 'iOS'end}}
local modules={SetupLocale={text=function(en)return en end},
 CanvasPresentation={begin2D=function()error('world-canvas contract used for final HUD')end},
 Gen1Rooftops={gate=function()return true end},FreeMove={drop=function()end},Voxel3D={}}
local V={require=function(n)return assert(modules[n],n)end}
local M=assert(loadfile('lib/MewSky.lua'))(V);modules.MewSky=M
local OW={interact=function()end,handleInput=function()end}
package.loaded['src.world.OverworldController']=OW
package.loaded['src.render.Pipelines']={level=function()return 6 end}
local B=assert(loadfile('lib/ObservationBinoculars.lua'))(V);B.install()
local player={cellX=1,cellY=1,facingCell=function()return 1,0 end}
local world=setmetatable({player=player,map={id='OTHER',signAtCell=function()return{text='BINOCULARS'}end},
 npcAtCell=function()end},{__index=OW})
local top=world;local game={overworld=world,save={},stack={top=function()return top end}}
local function check(draw)
 draws,origins=0,0
 assert(draw('final',390,844)=='final')
 assert(draws>0 and origins==1)
 assert(state.transform=='inherited'and state.canvas=='previous'and state.color=='previous','HUD leaked graphics state')
end
M.visible=true;check(M.hud)
local choice={game=game,save=game.save,title='Wish',footer='A / B',index=1,items={{label='Nugget'},{label='Elixir'},{label='Ultra Ball'}}}
M.choice=choice;top=choice;check(M.hud)
M.choice=nil;M.visible=nil;top=world
world:interact();B.update(1/60,game);assert(B.current())
check(B.hud);B.close();assert(not player.inputLocked)
print('PASS iOS final Mew prompt, wish choice and binocular HUD remain upright and restore graphics state')
