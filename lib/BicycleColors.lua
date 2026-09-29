-- Recolour only protected frame paint; wardrobe garments and wheel rubber
-- never enter this mask. The original approved atlas supplies the mask colour.
local V=...
local M={built=0}
M.setting=V.require('ModSetting').new('bicycleColor','BICYCLE COLOUR',
 {'original','red','green','gold','violet','white','black'},
 {'ORIGINAL','RED','GREEN','GOLD','VIOLET','WHITE','BLACK'},'original')
local colors={red={.95,.12,.1},green={.18,.75,.3},gold={1,.68,.08},violet={.66,.24,.95},white={.95,.96,1},black={.14,.16,.19}}
local sources,cache={},{}
local shader
function M.clear()
 M.failedTexture,M.failedColor,M.lastError=nil,nil,nil
 for key,item in pairs(cache)do item.canvas:release();cache[key]=nil end
 for key,item in pairs(sources)do item.base:release();item.mask:release();sources[key]=nil end
 if shader then shader:release();shader=nil end
end
local function paintTexture(texture,def,role)
 local color=colors[M.setting:get()]
 if not color or not def or def.ascendantCharacterAction~='bicycle' or not def.voxelSpriteDemo
  or (role~='red'and role~='blue'and role~='green')then return texture end
 -- Only one player rides at a time. Bound retained GPU memory when the
 -- wardrobe switches protagonists; do not retain three full paint atlases.
 for key,item in pairs(cache)do if key~=role then item.canvas:release();cache[key]=nil end end
 for key,item in pairs(sources)do if key~=role then item.base:release();item.mask:release();sources[key]=nil end end
 local entry=cache[role]
 if entry and entry.source==texture and entry.color==color then return entry.canvas end
 local source=sources[role]
 if not source then
  local root=V.mod.path..'/integrated/ascendant_pokemon_overworld/assets/voxel-wardrobe/'..role..'/'
  source={base=love.graphics.newImage(root..'source-bicycle.png'),mask=love.graphics.newImage(root..'protected-bicycle.png')}
  source.base:setFilter('nearest','nearest');source.mask:setFilter('nearest','nearest');sources[role]=source
 end
 local g=love.graphics
 shader=shader or g.newShader([[
 extern Image base;extern Image protected;extern vec3 paint;
 vec4 effect(vec4 color,Image tex,vec2 uv,vec2 px){
  vec4 c=Texel(tex,uv);vec4 b=Texel(base,uv);
  float mask=Texel(protected,uv).r;
  // The authored frames are blue. Skin, hardware, lights and tyres cannot
  // pass both this material test and the explicit garment protection mask.
  if(mask>.99 && b.a>.05 && b.b>b.r*1.5 && b.b>b.g*1.1 && b.b>.18){
   c.rgb=paint*(.35+.65*b.b);
  }
  return c*color;
 }
 ]])
 local canvas=g.newCanvas(texture:getDimensions());canvas:setFilter('linear','linear')
 g.push('all')
 local ok,err=pcall(function()
  g.setCanvas(canvas);g.origin();g.setScissor();g.setDepthMode();g.clear(0,0,0,0)
  g.setBlendMode('replace','premultiplied');g.setColor(1,1,1,1);g.setShader(shader)
  shader:send('base',source.base);shader:send('protected',source.mask);shader:send('paint',color);g.draw(texture)
 end)
 g.pop()
 if not ok then canvas:release();error(err)end
 if entry then entry.canvas:release()end
 cache[role]={source=texture,color=color,canvas=canvas};M.built=M.built+1
 return canvas
end
function M.texture(texture,def,role)
 local selected=M.setting:get()
 if M.failedTexture==texture and M.failedColor==selected then return texture end
 local ok,result=pcall(paintTexture,texture,def,role)
 if ok then return result end
 M.failedTexture,M.failedColor,M.lastError=texture,selected,tostring(result)
 return texture
end
M.setting:onChange(function()M.clear()end)
V.mod.exports.bicycleColors=M
return M
