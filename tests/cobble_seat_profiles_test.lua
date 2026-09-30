-- Retain source-reviewed NPC seating across a Cobble artwork replacement.
 local root=(os.getenv('VASC_SEAT_SOURCE')or'.')..'/'
 local base=root..'integrated/ascendant_pokemon_overworld/'
 local Profiles=assert(loadfile(base..'src/human_seat_profiles.lua'))()
 local Seat=assert(loadfile(base..'src/human_johto_seat.lua'))()
 local Catalog=assert(loadfile(root..'integrated/cobble_characters/src/catalog.lua'))()
 local Provider=assert(loadfile(root..'integrated/cobble_characters/src/provider.lua'))()
 local Integration=assert(loadfile(root..'integrated/cobble_characters/src/integration.lua'))()
 local provider=Provider.new({path='mods/VOXEL_ASCENDANT/integrated/cobble_characters',find=function()end},Catalog)
 local mod={options={get=function(_,key)if key=='actor_voxel_grid'then return'off'elseif key=='card_animation_mode'then return'classic'elseif key=='human_acting_pilot'then return false end;return true end}}
 love=love or {};love.graphics=love.graphics or {}
 local seat=Seat.new{mod=mod,generation=1,voxel={},profiles=Profiles}
 local integration=Integration.new(provider)
 local totals={hd=0,voxel=0,cobble=0,cobbleAvailable=0,profiles=0}
 for _,profile in ipairs(Profiles.entries)do if profile.generation==1 then
 totals.profiles=totals.profiles+1
 local actor={def={index=profile.index},cellX=profile.cellX,cellY=profile.cellY,px=profile.px,py=profile.py}
 local game={overworld={map={id=profile.mapId},npcs={actor},player={px=0,py=0}}}
 local hd={ascendantRole=profile.role,ascendantAtlasImage='mods/test/'..profile.path}
 local voxel={ascendantRole=profile.role,voxelSpriteDemo=true,ascendantAtlasImage='mods/test/'..profile.path:gsub('/npcs/','/voxel-npcs/')}
 local art=integration.resolve{generation=1,role=profile.role,atlas=profile.path,style='cobble',action='walk'}
 local cobble=art and art.definition
 if cobble then totals.cobbleAvailable=totals.cobbleAvailable+1 end
 for style,def in pairs{hd=hd,voxel=voxel,cobble=cobble}do
  actor.sprite={def=def};local admitted=seat:pose(game,{spriteRef={actor.sprite}},nil,1)
  if admitted then totals[style]=totals[style]+1 end
  if style=='cobble' then
   assert(admitted,'Cobble seat missing: '..profile.mapId..':'..profile.index)
   actor.moving=true;assert(not seat:pose(game,{spriteRef={actor.sprite}},nil,2),'moving actor seated');actor.moving=false
   actor.cellX=actor.cellX+1;assert(not seat:pose(game,{spriteRef={actor.sprite}},nil,3),'displaced actor seated');actor.cellX=profile.cellX
   local identity=def.ascendantSeatSource;def.ascendantSeatSource=nil
   assert(not seat:pose(game,{spriteRef={actor.sprite}},nil,4),'untagged artwork admitted')
   def.ascendantSeatSource='assets/characters/npcs/wrong-person.png'
   assert(not seat:pose(game,{spriteRef={actor.sprite}},nil,4),'wrong source identity seated');def.ascendantSeatSource=identity
  end
  if style=='cobble' and not admitted then print('COBBLE SEAT REJECTED',profile.mapId,profile.index,profile.role)end
 end
 end end
 print('COUNTS',totals.profiles,'profiles',totals.hd,'HD admitted',totals.voxel,'voxel admitted',totals.cobbleAvailable,'Cobble available',totals.cobble,'Cobble admitted')
 assert(totals.hd==totals.profiles and totals.voxel==totals.profiles)
 assert(totals.cobbleAvailable==totals.profiles and totals.cobble==totals.profiles)
 print('PASS all registered Cobble NPC seat profiles restored')
