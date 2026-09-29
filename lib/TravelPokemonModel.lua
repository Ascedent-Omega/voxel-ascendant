-- Render the actual selected Cobblemon rig into travel cards. These dense
-- cards retain the field sequence's rider, occlusion and native movement.
local V=...
local M={draws=0,builds=0}
local shaderSource=[[
#ifdef VERTEX
attribute float VertexShade;
varying float shade;
extern float turn;extern float fit;extern vec3 centre;
vec4 position(mat4 projection,vec4 v){
 vec3 p=(v.xyz-centre)*fit;
 float x=p.x*cos(turn)+p.z*sin(turn),z=-p.x*sin(turn)+p.z*cos(turn);
 shade=VertexShade;
 return vec4(x,-(p.y*.94-z*.34),(z*.94+p.y*.34)/10.0,1.0);
}
#endif
#ifdef PIXEL
varying float shade;
vec4 effect(vec4 color,Image tex,vec2 uv,vec2 px){
 vec4 c=Texel(tex,uv)*color;if(c.a<.05)discard;
 return vec4(c.rgb*max(.72,shade),c.a);
}
#endif
]]
function M.enabled()
 return V.mod.options:get('apo_pokemon_model_source')=='cobblemon'
  or V.mod.options:get('apo_follower_sprite_source')=='cobblemon'
end
function M.release(owner)
 local s=owner and owner.travelModel;if not s then return end
 if s.actor then s.actor:release()end
 for _,canvas in pairs(s.canvases or{})do canvas:release()end
 if s.shader then s.shader:release()end
 if s.model then for _,slot in ipairs(s.model.textures or{})do if slot.image and slot.image.release then slot.image:release()end end end
 owner.travelModel=nil
end
local function build(owner,mon,dex,mode)
 local C=V.require('CobblemonContent');local Pack=V.require('CobblemonPack')
 dex=Pack.dex(mon)or dex
 local s={canvases={},epoch=C.epoch or 0};owner.travelModel=s
 local variant=Pack.variant(mon);assert(variant,'unsupported appearance')
 local aspects
 for _,v in ipairs(C.catalog.variants[tostring(dex)]or{})do if v.key==variant then aspects=v.aspects end end
 assert(aspects,'unsupported travel variant')
 local J=assert((loadstring or load)(V.mod:read('lib/ContentJson.lua')))()
 local model=V.require('CobblemonImport').compile(C.catalog,dex,aspects,C.read,J.decode,mode)
 model.crystalDex=dex;model.textures={{}}
 -- This private provider never changes a battle or follower rig's pose.
 local provider={variant=Pack.variant,sample=Pack.sample,image=Pack.image,load=function()return model end}
 model.assetProvider=provider;s.model=model
 s.actor=V.require('StadiumMon').new('travel',provider)
 assert(s.actor:setSpecies(dex,true,mon),'travel rig unavailable')
 s.actor:play('idle',model.actions.idle)
 s.shader=love.graphics.newShader(shaderSource)
 s.dex,s.variant,s.mode=dex,variant,mode;M.builds=M.builds+1
 return s
end
function M.draw(owner,mon,dex,mode,direction,x,bottom,size,alpha,tint)
 if not M.enabled() or not mon or not dex or (alpha or 1)<=0 then return false end
 local s=owner.travelModel
 if s and s.epoch~=(V.require('CobblemonContent').epoch or 0)then M.release(owner);s=nil end
 if s and s.error then return false end
 if not s then
  local ok,value=pcall(build,owner,mon,dex,mode)
  if not ok then M.release(owner);owner.travelModel={error=tostring(value),epoch=V.require('CobblemonContent').epoch or 0};return false end
  s=value
 end
 local g=love.graphics;g.push('all')
 local ok,err=pcall(function()
  local tick=math.floor((owner.frame or 0)/4)
  if tick~=s.tick then
   s.actor.time=(owner.frame or 0)/60;s.actor:pose();s.actor:upload();s.tick=tick;s.rendered={}
   local a,b,c,d,e,f=s.actor.rig:posedBounds()
   s.centre={(a+d)/2,(b+e)/2,(c+f)/2}
   -- One scale for all directions; only grow the framing envelope.
   s.span=math.max(s.span or 0,math.sqrt((d-a)^2+(f-c)^2),(e-b)*.94+math.sqrt((d-a)^2+(f-c)^2)*.34)
  end
  local turn=({down=math.pi,up=0,left=-math.pi/2,right=math.pi/2,side=-math.pi/2})[direction]or 0
  local canvas=s.canvases[direction]
  if not canvas then canvas=g.newCanvas(256,256);canvas:setFilter('linear','linear');s.canvases[direction]=canvas end
  if not s.rendered[direction]then
   g.setCanvas({canvas,depth=true});g.origin();g.setScissor();g.setStencilTest();g.setColorMask(true,true,true,true)
   g.clear(0,0,0,0,true,true);g.setShader(s.shader);g.setDepthMode('less',true);g.setMeshCullMode('none');g.setColor(1,1,1,1)
   s.shader:send('turn',turn);s.shader:send('fit',1.8/math.max(.001,s.span));s.shader:send('centre',s.centre)
   for _,p in ipairs(s.actor.rig.parts)do if p.texture then p.mesh:setTexture(p.texture);g.draw(p.mesh)end end
   s.rendered[direction]=true
  end
 end)
 g.pop()
 if not ok then M.release(owner);owner.travelModel={error=tostring(err),epoch=V.require('CobblemonContent').epoch or 0};return false end
 g.push('all');g.setShader();g.setDepthMode();tint=tint or{1,1,1};g.setColor(tint[1],tint[2],tint[3],alpha or 1)
 g.draw(s.canvases[direction],x-size/2,bottom-size,0,size/256,size/256);g.pop()
 M.draws=M.draws+1;return true
end
return M
