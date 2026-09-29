-- Selected water variants and their failure fallback must be ready before
-- reveal. OFF must allocate nothing, and refused programs must not retry.
for _,rejectGrid in ipairs{false,true}do
 local mode='off';local calls=0
 love={graphics={newShader=function(source)
  calls=calls+1
  if rejectGrid and source:find('#define VOXEL_GRID 1',1,true)then error('unsupported derivatives')end
  return {source=source}
 end}}
 local modules={ModSetting={new=function()return{get=function()return mode end}end},
  Sky={MOON_CRATERS={},CRATER_FRAC=1},DayNight={},ShadowMap={},Mat4={},
  Gen1OutdoorScenery={waterGLSL=''},LocalLights={supported=false}}
 local W=assert(loadfile('lib/Water.lua'))({require=function(n)return assert(modules[n],n)end})
 assert(W.programPrepared(true)and not W.prepareProgram(true)and calls==0)
 for _,selected in ipairs{'sky','full'}do
  mode=selected;assert(not W.programPrepared(true))
  local start=calls
  assert(W.prepareProgram(true));assert(calls-start==(rejectGrid and 2 or 1))
  if rejectGrid then
   assert(not W.programPrepared(true),'missing fallback reported ready')
   assert(W.prepareProgram(true))
  end
  assert(W.programPrepared(true))
  local before=calls
  for i=1,20 do assert(not W.prepareProgram(true))end
  assert(calls==before,'repeated compilation after preparation')
  assert(W.shader(not rejectGrid,selected=='sky'))
  assert(calls==before,'first visible water compiled another program')
 end
end
print('PASS water preload: SKY/FULL, selected grid, refused-grid fallback, OFF, first use and no retry loop')
