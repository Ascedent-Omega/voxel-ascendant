-- Art-source extension. The host remains the sole entity/wardrobe owner.
local Integration={}
function Integration.new(provider,wardrobeArt)
 local bySource,byTail,bySprite={},{},{}
 for id,row in pairs(provider.catalog)do
  local name=type(row.source)=='string'and row.source:match('([^/]+)$')
  -- A shared battle picture cannot identify either member of a duo.
  if name then bySource[name]=bySource[name]==nil and id or false end
  local tail=type(row.source)=='string'and row.source:match('([^/]+/[^/]+)$')
  if tail then byTail[tail]=byTail[tail]==nil and id or false end
  for style in pairs(row.styles)do bySprite[provider:spriteId(id,style)]=id end
 end
 bySprite.SPRITE_JESSIE='jessie'
 bySprite.SPRITE_JAMES='james'
 local aliases={oak='professor-oak'}
 local api={schema='ascendant.character-art-source/v1'}
 function api.identity(entity)
  if type(entity)~='table'then return nil end
  local value=entity.cobbleCharacter or entity.def and entity.def.cobbleCharacter
  if value then local row=provider:lookup(value);return row and row.id end
  local id=entity.def and entity.def.sprite or entity.spriteId
  return bySprite[id]
 end
 function api.resolve(ctx)
  if not provider.active or type(ctx)~='table'or ctx.generation~=1 then return nil end
  local style=ctx.style
  if style~='hd'and style~='voxel'and style~='cobble'then return nil end
  local explicit=api.identity(ctx.entity)
  local filename=type(ctx.atlas)=='string'and ctx.atlas:match('([^/]+)$')
  local tail=type(ctx.atlas)=='string'and ctx.atlas:match('([^/]+/[^/]+)$')
  local id=explicit or byTail[tail]or bySource[filename]or aliases[ctx.role]or ctx.role
  local row=provider:lookup(id)
  if not row or not row.styles[style]then return nil end
  local def,art=provider:definition(row.id,style,false)
  if not def then return nil,art end
  if style=='cobble' then
   -- The host owns map identity and seating; artwork/wardrobe variants keep
   -- that source identity even when the provider uses another catalog id.
   def.ascendantSeatSource=row.source
  end
  local action=ctx.action~='walk'and ctx.action or nil
  local dressed=ctx.selection and ctx.wardrobe and not ctx.wardrobe.plain(ctx.selection)
  if action or dressed then
   if style~='cobble'then return nil end -- The host owns existing HD/Voxel outfits/actions.
   if not wardrobeArt then return nil,'wardrobe-provider-unavailable'end
   local derived=wardrobeArt.resolve(row.id,action,ctx.wardrobe,ctx.selection)
   def.ascendantAtlasImage=derived.atlas
   def.ascendantHumanCards=derived.clips
   def.ascendantPokemonBlinkSourceExact=nil;def.ascendantPokemonBlinkSheet=nil
   def.ascendantCharacterAction=action
   def.cobbleWardrobeKey=derived.key
   def.ascendantHumanFieldHands=derived.fieldHands
  end
  def.ascendantExternalCharacterSource=api.schema
  return {definition=def,atlas=def.ascendantAtlasImage,runtime=def.image,
   role=row.id,style=style,art=art}
 end
 function api.health()return {schema=api.schema,active=provider.active,wardrobe=wardrobeArt and wardrobeArt.health()}end
 return api
end
return Integration
