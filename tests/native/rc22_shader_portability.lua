-- Native QA driver: dump assembled production shader stages for strict validation.
-- SHADER_OUT must name an existing isolated output directory.
return function(game)
 assert(os.getenv('POKEPORT_IDENTITY')=='vasc-video-polish-qa');love.audio.setVolume(0)
 local function up(fn,wanted)for i=1,100 do local n,v=debug.getupvalue(fn,i);if n==wanted then return v end;if not n then break end end;error('missing upvalue '..wanted)end
 local shader=assert(game.mods.exports.VOXEL_ASCENDANT.Voxel3D).shader
 local source=up(up(shader,'compileShader'),'shaderSource');local V=up(source,'V');local lights=V.require('LocalLights')
 assert(type(love.graphics.validateShader)=='function','native shader validator unavailable')
 local validated=0
 local out=os.getenv('SHADER_OUT');local count=0
 for _,variant in ipairs{'full','mobile-safe','mobile-core'}do
  lights.mobile=variant=='mobile-core';lights.MAX_LIGHTS=lights.mobile and 4 or 8;lights.MAX_BATTLE_LIGHTS=lights.mobile and 2 or 4;lights.MAX_BLOCKERS=lights.mobile and 4 or 8;lights.MAX_PORTALS=lights.mobile and 2 or 4
  for _,grid in ipairs{false,true}do if variant~='mobile-core'or not grid then
   for _,lit in ipairs{false,true}do
    local raw=assert(source(variant,grid,lit))
    for _,gles in ipairs{false,true}do
     local ok,err=love.graphics.validateShader(gles,raw);assert(ok,tostring(variant)..' '..tostring(gles)..': '..tostring(err));validated=validated+1
     local vert,frag=love.graphics._shaderCodeToGLSL(gles,raw)
     local name=variant..'-'..tostring(grid)..'-'..tostring(lit)..'-'..(gles and 'gles'or'gl')
     for ext,body in pairs{vert=vert,frag=frag}do local f=assert(io.open(out..'/'..name..'.'..ext,'w'));f:write(body);f:close();count=count+1; if not gles then local extra=assert(io.open(out..'/'..name..'450.'..ext,'w'));extra:write((body:gsub('#version 330 core','#version 450 core',1)));extra:close();count=count+1 end end
    end
   end
  end end
 end
 print('PASS_SHADER_PORTABILITY',validated,'programs',count,'stages');love.event.quit()
end
