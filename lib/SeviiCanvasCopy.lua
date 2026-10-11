-- Snapshot a companion's reusable side canvas before it paints the lead.
-- This runs while the caller may still have a shader, clip or transform set.
local M={}

function M.copy(g,source,target)
  local previous=g.getCanvas()
  g.push('all')
  local drawn,drawError=pcall(function()
    g.setCanvas(target)
    g.origin()
    g.setShader()
    g.setScissor()
    g.setBlendMode('replace','premultiplied')
    g.setColor(1,1,1,1)
    g.clear(0,0,0,0)
    g.draw(source,0,0)
  end)
  local restored,restoreError=pcall(g.pop)
  if previous then g.setCanvas(previous)else g.setCanvas()end
  if not restored then error(restoreError,0)end
  if not drawn then error(drawError,0)end
  return target
end

return M
