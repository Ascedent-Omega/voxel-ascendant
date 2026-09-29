-- A species-aware replacement for the native Pikachu conversation only when
-- another species actually owns that follower. Party/story selection stays
-- with its original provider.
local V=...
local M={}
function M.species(npc,data)
 if not(npc and npc.pikachuFollower)then return nil end
 local mon=npc.ascendantPokemonModelAppearance
 local def=npc.sprite and npc.sprite.def or {}
 local species=mon and mon.species or def.pokemonSpecies
 if not species and npc.ascendantPokemonModelDex then
  for id,row in pairs(data and data.pokemon or{})do
   if tonumber(row.dex)==tonumber(npc.ascendantPokemonModelDex)then species=id;break end
  end
 end
 return species and data and data.pokemon and data.pokemon[species] and species or nil
end
local function portrait(game,npc,species)
 if not(love and love.graphics)then return nil end
 local g=love.graphics
 local mon=npc.ascendantPokemonModelAppearance or {species=species}
 local front=V.require('Gen2CrystalFronts').resolve(game,mon,{kind='summary'})
 local path=front and front.path
 if not path and V.mod and V.mod.find then
  local ok,handle=pcall(V.mod.find,'kanto_ascendant')
  local provider=ok and handle and handle.exports and handle.exports.crystalSpriteProvider
  if provider and provider.apiVersion==1 and type(provider.resolveFront)=='function'then
   local resolved,result=pcall(provider.resolveFront,game.data,mon,{kind='summary',source='vasc_follower'})
   if resolved and result and result.trueColor~=false then path=result.path end
  end
  local exports=ok and handle and handle.exports
  local animation=exports and exports.crystalAnimation
  if not path and animation and type(animation.staticFrameOne)=='function'then
   local shiny=V.require('Gen2CrystalFronts').isShiny(mon)
   local resolved,value=pcall(animation.staticFrameOne,
    {data=game.data,species=species,mon=mon,kind='summary'},'front',shiny and 'shiny'or 'normal')
   if resolved and type(value)=='string'then path=value end
  end
 end
 local trueColor=path~=nil
 if not path then
  path,trueColor=require('src.pokemon.Sprites').path(game.data,species,'front',{kind='overworld',mon=mon})
 end
 if not path then return nil end
 local image=require('src.render.Assets').image(path)
 if not image then return nil end
 local w,h=image:getDimensions();local canvas=g.newCanvas(40,40)
 g.push('all')
 local ok,err=pcall(function()
  g.setCanvas(canvas);g.origin();g.setShader();g.setScissor();g.setDepthMode()
  g.clear(0,0,0,0);g.setColor(1,1,1,1);g.setBlendMode('alpha','alphamultiply')
  if not trueColor then
   local P=require('src.render.PaletteFX')
   local shader=P.keyedShader();local colors=type(mon.palette)=='table'and mon.palette or P.monPal(game.data,species)
   if not(shader and colors)then error('follower palette unavailable')end
   P.sendColors(shader,colors);g.setShader(shader)
  end
  local scale=36/math.max(w,h);g.draw(image,(40-w*scale)/2,(40-h*scale)/2,0,scale,scale)
 end)
 g.pop()
 if not ok then canvas:release();error(err,0)end
 return canvas
end
function M.install()
 local F=require('src.world.PikachuFollower')
 local World=require('src.world.OverworldController')
 if World.sgbPalettes and World.sgbPalettes~=World.__vascFollowerPalettes then
  local innerPalettes=World.sgbPalettes
  local function palettes(world,...)
   local zones=innerPalettes(world,...)
   if world.emote and world.__vascFollowerPicture and world.emote.pikaPic
    and world.emote.pikaPic:match('^vasc%-follower:')then
    local copy={};for i,z in ipairs(zones or{})do copy[i]=z end
    copy[#copy+1]={colors=false,x=56,y=48,w=40,h=40}
    return copy
   end
   return zones
  end
  World.sgbPalettes=palettes;World.__vascFollowerPalettes=palettes
 end
 local previous=F.__vascSpeciesTalk
 if previous and F.talk==previous then return end
 local inner=F.talk
 local function talk(game,world,npc,done)
  local species=M.species(npc,game and game.data)
  if not species or species=='PIKACHU'then return inner(game,world,npc,done)end
  if npc.moving then
   npc.cellX,npc.cellY=npc.targetX or npc.cellX,npc.targetY or npc.cellY
   npc.targetX,npc.targetY=nil,nil;npc.moving=false;npc.progress=0;npc.hopStep=nil
  end
  npc.px,npc.py=npc.cellX*16,npc.cellY*16
  npc.idle=nil
  local ok,pic=pcall(portrait,game,npc,species)
  local token=ok and pic and ('vasc-follower:'..species)or nil
  if world.__vascFollowerPicture then world.__vascFollowerPicture:release()end
  world.__vascFollowerPicture=ok and pic or nil
  if token then world.pikaPicPath,world.pikaPicImg=token,pic end
  pcall(require('src.core.Sound').playCry,game.data,species)
  world.emote={npc=npc,frames=100,bubble=false,pikaPic=token,
   pikaTotal=100,skippable=true,onDone=done}
  return world.emote
 end
 F.talk=talk;F.__vascSpeciesTalk=talk
end
return M
