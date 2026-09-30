-- Immutable CPU atlas view. Native getPixel runs once per source pixel;
-- geometry readers retain the same exact RGBA values and dimensions.
local M={}
function M.decode(data,budget)
  local w,h=data:getDimensions()
  local rgba={}
  for y=0,h-1 do
    if budget then budget.check()end
    for x=0,w-1 do
      local r,g,b,a=data:getPixel(x,y);local i=(y*w+x)*4
      rgba[i+1],rgba[i+2],rgba[i+3],rgba[i+4]=r,g,b,a
    end
  end
  return {getDimensions=function()return w,h end,
    getWidth=function()return w end,getHeight=function()return h end,
    getPixel=function(_,x,y)
      assert(x>=0 and y>=0 and x<w and y<h,"pixel outside tileset")
      local i=(math.floor(y)*w+math.floor(x))*4
      return rgba[i+1],rgba[i+2],rgba[i+3],rgba[i+4]
    end}
end
return M
