local active,buildings,npc,language=true,true,false,'en'
local original,calls=0,{}
local OW={interact=function()original=original+1 end}
local game={stack={push=function(_,box)calls[#calls+1]=box end}}
package.loaded['src.core.Game']=game
package.loaded['src.world.OverworldController']=OW
package.loaded['src.render.TextBox']={new=function(_,text)return{text=text}end}
local mods={VoxelState={active=function()return active end},
 Gen1PalletVillage={buildings={get=function()return buildings end}},
 SetupLocale={text=function(en,de)return language=='de'and de or en end}}
local M=assert(loadfile('lib/CeladonClosedShop.lua')){require=function(n)return assert(mods[n],n)end}
M.install();M.install()
local x,y=39,19
local w=setmetatable({map={id='CELADON_CITY'},player={facingCell=function()return x,y end},npcAtCell=function()return npc end},{__index=OW})
w:interact();assert(#calls==1 and calls[1].text:find('department store',1,true));assert(original==0)
language='de';w:interact();assert(calls[2].text:find('insolvent',1,true))
active=false;w:interact();active=true
buildings=false;w:interact();buildings=true
npc=true;w:interact();npc=false
x=38;w:interact();x=39
w.map.id='SAFFRON_CITY';w:interact()
assert(original==5 and #calls==2,'native interaction or unrelated entrance intercepted')
print('PASS closed shop: exact facade, bilingual, voxel only, building toggle, NPC priority, vanilla unchanged')
