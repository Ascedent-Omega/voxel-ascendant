-- Conservative screen rows for the ray shader's dir.y >= 0 half-plane.
-- Roll is included through du.y; downward/upside-down views work alike.
local M={}
local function finite(n)return type(n)=='number'and n==n and math.abs(n)<math.huge end
function M.rows(h,ray)
 if not ray then return 0,h end
 local b=ray.base and ray.base[2];local u=ray.du and ray.du[2];local v=ray.dv and ray.dv[2]
 if not(finite(b)and finite(u)and finite(v))then return 0,h end
 -- Include a float32 arithmetic margin and two raster rows. Near-degenerate
 -- fans retain the full target instead of amplifying cancellation error.
 local epsilon=(math.abs(b)+math.abs(u)+math.abs(v)+1)*1e-5
 if math.abs(v)<epsilon then return 0,h end
 local m=b+math.max(0,u)+epsilon
 if v<0 then return 0,math.max(0,math.min(h,math.ceil(h*m/-v)+2)) end
 local y=math.max(0,math.min(h,math.floor(h*(-m)/v)-2))
 return y,h-y
end
return M
