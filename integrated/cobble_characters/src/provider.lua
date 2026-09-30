local Provider = {}
Provider.__index = Provider
local DIRECTIONS = {down=0,left=1,up=2,right=3}
local ALIASES = {rocky="officer-rocky",jenny="officer-rocky",["officer-jenny"]="officer-rocky",["police-female"]="officer-rocky"}

local function clone(v)
  if type(v) ~= "table" then return v end
  local out = {}; for k,x in pairs(v) do out[k]=clone(x) end; return out
end

function Provider.new(mod, catalog, options)
  options=options or {}
  local h=mod.find and mod:find('ASCENDANT_HD_CHARACTERS')
  if not (h and h.exports and h.exports.humanArt)then
    catalog=clone(catalog)
    for _,row in pairs(catalog)do row.styles.hd=nil end
  end
  return setmetatable({mod=mod,catalog=catalog,active=true,originals=setmetatable({}, {__mode="k"}),
    clock=options.clock or function() return love and love.timer and love.timer.getTime() or 0 end,
    SpriteRenderer=options.SpriteRenderer,registered=0},Provider)
end

function Provider:lookup(id)
  if type(id) ~= "string" then return nil,"invalid_character" end
  id=ALIASES[id:lower()] or id:lower()
  local row=self.catalog[id]
  if not row then return nil,"unknown_character:"..id end
  return row
end

function Provider:spriteId(id, style)
  return "SPRITE_COBBLE_"..id:upper():gsub("[^A-Z0-9]","_").."_"..style:upper()
end

function Provider:hdProvider()
 local h=self.mod.find and self.mod:find('ASCENDANT_HD_CHARACTERS')
 return h and h.exports and h.exports.humanArt
end
function Provider:definition(id, style, animated2D, action)
  local row,err=self:lookup(id);if not row then return nil,err end
  style=style or "cobble"
  local art=row.styles[style];if not art then return nil,"style_unavailable:"..tostring(style) end
  local actionArt=not animated2D and action and art.actions and art.actions[action]
  if actionArt then art=actionArt end
  local hd=style=="hd" and self:hdProvider()
  if style=="hd" and not hd then return nil,"hd_dlc_required" end
  local root=hd and hd.characterRoot or self.mod.path.."/"
  local def={id=self:spriteId(row.id,style),image=root..(animated2D and art.animatedRuntime or art.runtime),
    frames=animated2D and art.frames or 6,frameWidth=16,frameHeight=16,frameColumns=1,
    anchorX=8,anchorY=16,walker=true,trueColor=true,
    cobbleCharacter=row.id,cobbleStyle=style,cobbleAnimated2D=animated2D==true,
    ascendantRole=row.id,ascendantScaleClass=row.scaleClass,ascendantWorldHeight=row.worldHeight}
  if actionArt then def.ascendantCharacterAction=action end
  if not animated2D then
    def.ascendantAtlasImage=root..(art.presentationAtlas or art.atlas)
    def.ascendantAtlasRelative=art.presentationAtlas or art.atlas
    if art.humanCards then
      def.ascendantHumanCards=clone(art.humanCards)
      def.ascendantHumanCards.id=def.id
      for _,kind in ipairs({'idle','walk','blink'})do
        local clip=def.ascendantHumanCards[kind];if clip then clip.sheet=root..clip.sheet end
      end
    elseif style=="cobble" then
      def.ascendantHumanCards={schema="ascendant.human-cards/v1",id=def.id,filter="nearest",
        cellWidth=64,cellHeight=80,anchorX=32,anchorY=78,referenceHeight=art.cardReferenceHeight or 75,
        idle={sheet=root..art.idle,columns=1,duration=1},
        walk={sheet=root..art.walk,columns=art.walkFrames,duration=art.walkSeconds},
        blink=art.blink and {sheet=root..art.blink,columns=4,duration=.24} or nil}
    end
    -- Existing VASC human renderer reads this legacy sidecar seam too.
    -- These are actual eye/lid renders, not fabricated blink pixels.
    if art.blink and not def.ascendantHumanCards then
      def.ascendantPokemonBlinkSourceExact=true
      def.ascendantPokemonBlinkSheet=root..art.blink
    end
  end
  return def,art,row
end

function Provider:frame(art, facing, moving, seconds, seed)
  local row=DIRECTIONS[facing] or 0
  local t=math.max(0,tonumber(seconds) or 0)
  local phase=tonumber(seed) or 0
  if moving then
    return row*art.stride+1+math.floor((t%art.walkSeconds)/art.walkSeconds*art.walkFrames)
  end
  if art.blinkFrames>0 then
    local bt=(t+phase)%4
    if bt>=2.65 and bt<2.99 then
      local index=math.min(art.blinkFrames-1,math.floor((bt-2.65)/.34*art.blinkFrames))
      return row*art.stride+1+art.walkFrames+index
    end
  end
  return row*art.stride
end

function Provider:createRenderer(id, style, options)
  options=options or {}
  local def,art=self:definition(id,style,options.animated2D)
  if not def then return nil,art end
  local Renderer=self.SpriteRenderer or require("src.render.SpriteRenderer")
  local ok,sprite=pcall(Renderer.new,def,options.seed or "cobble")
  if not ok then return nil,tostring(sprite) end
  if options.animated2D then
    local owner=self;local nativeDraw=sprite.draw
    local phase=0;for i=1,#tostring(options.seed or id) do phase=(phase+tostring(options.seed or id):byte(i)*.017)%4 end
    sprite.draw=function(s,px,py,cx,cy,facing,walkPhase,stepFlip,topHalf,forceFlip,frameOverride,oamRow)
      -- frameOverride disables the native left/right and alternating-step flips.
      -- Our four rows contain separately rendered views, including asymmetric R logos.
      local frame=owner:frame(art,facing,walkPhase==1,owner.clock(),phase)
      return nativeDraw(s,px,py,cx,cy,facing,walkPhase,stepFlip,topHalf,false,frame,oamRow)
    end
    sprite.getPoseGeometry=function(s,facing,walkPhase,stepFlip)
      local frame=owner:frame(art,facing,walkPhase==1,owner.clock(),phase)
      local geometry=s:getFrameGeometry(frame)
      geometry.facing,geometry.walkPhase,geometry.stepFlip,geometry.mirror=facing,walkPhase,stepFlip,false
      return geometry
    end
  end
  return sprite,def
end

function Provider:bind(entity,id,style,options)
  if not self.active then return false,"inactive" end
  if type(entity)~="table" then return false,"invalid_entity" end
  local original=self.originals[entity]
  if original and entity.sprite~=original.replacement then return false,"visual_owner_changed" end
  local sprite,def=self:createRenderer(id,style,options)
  if not sprite then return false,def end
  if not original then original={sprite=entity.sprite,spriteDef=entity.spriteDef};self.originals[entity]=original end
  original.replacement=sprite
  entity.sprite,entity.spriteDef=sprite,def
  return true
end

function Provider:restore(entity)
  local original=self.originals[entity];if not original then return false end
  if entity.sprite==original.replacement then
    entity.sprite=original.sprite
    -- An independently replaced spriteDef belongs to the newer owner.
    if entity.spriteDef==original.replacement.def then entity.spriteDef=original.spriteDef end
  end
  self.originals[entity]=nil
  return true
end

function Provider:activate() self.active=true;return true end
function Provider:deactivate()
  self.active=false
  local entities={};for entity in pairs(self.originals) do entities[#entities+1]=entity end
  for _,entity in ipairs(entities) do self:restore(entity) end
  return true
end

function Provider:register()
  if self.registered>0 then return self.registered end
  local ids={};for id in pairs(self.catalog) do ids[#ids+1]=id end;table.sort(ids)
  for _,id in ipairs(ids) do
    for _,style in ipairs({"cobble","hd","voxel"}) do
      if self.catalog[id].styles[style] and (style~="hd" or self:hdProvider()) then
        local def=self:definition(id,style,false)
        self.mod.content.sprites:register(def.id,def);self.registered=self.registered+1
      end
    end
  end
  return self.registered
end

function Provider:health()
  local bound=0;for _ in pairs(self.originals) do bound=bound+1 end
  return {schema="ascendant.compat-status/v1",ok=true,state=self.active and "ready" or "inactive",
    registeredSprites=self.registered,boundEntities=bound,externalRegistration=false,
    automaticReplacement=false,saveWrites=false}
end

function Provider:public()
  local owner=self
  return {schema="ascendant.cobble-characters/v1",
    catalog=function() return clone(owner.catalog) end,
    lookup=function(id) local r,e=owner:lookup(id);return r and clone(r),e end,
    spriteDefinition=function(...) local d,a,r=owner:definition(...);return d,clone(a),clone(r) end,
    createRenderer=function(...) return owner:createRenderer(...) end,
    bind=function(...) return owner:bind(...) end,
    restore=function(...) return owner:restore(...) end,
    activate=function() return owner:activate() end,
    deactivate=function() return owner:deactivate() end,
    health=function() return owner:health() end}
end
return Provider
