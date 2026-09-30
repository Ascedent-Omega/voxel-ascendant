local root='integrated/cobble_characters/'
local catalog=assert(loadfile(root..'src/catalog.lua'))()
local provider=assert(loadfile(root..'src/provider.lua'))().new({path='mods/cobble',find=function()end},catalog)
local integration=assert(loadfile(root..'src/integration.lua'))().new(provider,{resolve=function()error('NPC must not use wardrobe baker')end})
package.loaded['src.core.Game']={mods={exports={}}}
local Walking=assert(loadfile('integrated/ascendant_pokemon_overworld/src/walking_sprites.lua'))()
local old={schema='ascendant.character-art-source/v1',resolve=function(ctx)
 if ctx.action=='bicycle'then error('no Cobble wardrobe for '..ctx.role)end
 local result=integration.resolve(ctx);result.definition.ascendantSeatSource=nil;return result
end}
local binder=setmetatable({generation=1,mod={characterArtSource=integration,find=function()return{exports={characterArtSource=old}}end,options={get=function()return 'cobble'end}}},{__index=Walking})
for _,role in ipairs{'biker','cue-ball'}do
 local r=integration.resolve{generation=1,role=role,action='bicycle',style='cobble'}
 assert(r.definition.cobbleCharacter==role and r.definition.ascendantCharacterAction=='bicycle')
 assert(r.definition.ascendantHumanCards.walk.columns==12)
 for _,clip in pairs(r.art.humanCards)do if type(clip)=='table'and clip.sheet then
  local f=assert(io.open(root..clip.sheet,'rb'));assert(f:read(8)=='\137PNG\r\n\26\n');f:close()
 end end
 local fromOld=binder:externalArt({},'assets/characters/actions/'..role..'/bicycle_4x3.png',role,'bicycle')
 assert(fromOld.definition.ascendantCharacterAction=='bicycle','old Card aborted bike binding')
 local walk=integration.resolve{generation=1,role=role,style='cobble',action='walk'}
 assert(not walk.definition.ascendantCharacterAction and not walk.atlas:find('bicycle',1,true),'standing/swimming identity received bicycle')
end
local path='assets/characters/npcs/reds-mother-kasc-hd-4x3-walk-sheet-v2.png'
local mom=binder:externalArt({},path,'reds-mother')
assert(mom.definition.ascendantSeatSource==path,'old Card lost host seat identity')
love={graphics={}}
local profiles=assert(loadfile('integrated/ascendant_pokemon_overworld/src/human_seat_profiles.lua'))()
local seat=assert(loadfile('integrated/ascendant_pokemon_overworld/src/human_johto_seat.lua'))().new{generation=1,profiles=profiles,voxel={},mod={options={get=function(_,k)if k=='actor_voxel_grid'then return'off'elseif k=='hd_walking_sprites'then return true end end}}}
local actor={sprite={def=mom.definition},def={index=1},cellX=5,cellY=4,px=80,py=64}
assert(seat:pose({overworld={map={id='REDS_HOUSE_1F'},npcs={actor},player={px=0,py=0}}},{sprite=actor.sprite},nil,1),'old Card still rejected by seat renderer')
print('PASS Cobble rider actions, no runtime baking, walking preserved, old Card fallback and seat identity')
