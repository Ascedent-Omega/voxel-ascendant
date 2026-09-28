-- Deterministic driver failures must be contained, cleaned up and latched.
local root=arg[1] or '.'
for _,failure in ipairs({'renderer','colour','depth','shader','draw','readback','pixels','none'})do
 local created,released,pushes,pops,draws=0,0,0,0,0
 local function resource(kind)
  created=created+1
  return {release=function(self)assert(not self.dead);self.dead=true;released=released+1 end,
    setFilter=function()end,setWrap=function()end,send=function()end,hasUniform=function()return false end,
    newImageData=function()
      if failure=='readback'then error('readback refused')end
      local t=resource('pixels');t.getPixel=function()return failure=='pixels' and .75 or .25,1 end;return t
    end}
 end
 -- Forward reference for the factory above.
 local factory=resource
 resource=function(...)return factory(...)end
 local noop=function()end
 love={graphics={getRendererInfo=function()if failure=='renderer'then error('renderer unavailable')end;return 'GPU','1','vendor','device'end,
   getSystemLimits=function()return {texturesize=4096}end,
   newShader=function()if failure=='shader'then error('link refused')end;return resource('shader')end,
   newMesh=function()return resource('mesh')end,
   push=function()pushes=pushes+1 end,pop=function()pops=pops+1 end,
   origin=noop,setScissor=noop,setStencilTest=noop,setColorMask=noop,setCanvas=noop,clear=noop,
   setDepthMode=noop,setMeshCullMode=noop,setBlendMode=noop,setColor=noop,setShader=noop,rectangle=noop,
   draw=function()draws=draws+1;if failure=='draw'then error('GPU draw refused')end end}}
 local modules={CanvasPresentation={OS='Android'},PixelCanvas={new=function(_,_,opts)
   local depth=opts.format:find('depth',1,true)
   if failure=='colour' or depth and failure=='depth'then return false,'allocation refused'end
   return true,resource(depth and 'depth' or 'colour')
 end}}
 local D=assert(loadfile(root..'/lib/DeviceShadows.lua'))({require=function(n)return modules[n]end})
 local writer={send=noop,hasUniform=function()return false end}
 local passed=D.prepare(writer);assert(passed==(failure=='none'),failure)
 assert(created==released,failure..' leaked resources')
 assert(pushes==pops,failure..' leaked graphics state')
 local n=created
 for i=1,60 do assert(D.prepare(writer)==passed)end
 assert(created==n,failure..' retried every frame')
 print('PASS device failure '..failure..': cleanup, restoration, session latch')
end
