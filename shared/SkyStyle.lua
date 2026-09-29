-- Stable, non-lattice sky sampling. This local PRNG never touches gameplay RNG.
local M={}
local state=187741
local directions={}
local function random()
 state=(state*48271)%2147483647
 return state/2147483647
end
function M.star(i)
 i=math.max(1,math.floor(i or 1))
 while #directions<i do
  local az,y,d
  -- Modest angular separation avoids accidental doubles without imposing
  -- a grid, a golden-angle spiral, or an azimuth/elevation correlation.
  for attempt=1,96 do
   az=random()*math.pi*2-math.pi;y=.035+random()*.96
   local r=math.sqrt(1-y*y);d={math.sin(az)*r,y,math.cos(az)*r}
   local clear=true
   for _,p in ipairs(directions)do
    if p[1]*d[1]+p[2]*d[2]+p[3]*d[3]>.9991 then clear=false;break end
   end
   if clear then break end
  end
  directions[#directions+1]={d[1],d[2],d[3],az,math.asin(y)}
 end
 local d=directions[i];return d,d[4],d[5]
end
function M.sample(i,salt)
 local x=(i*104729+(salt or 0)*13007+918273)%2147483647
 for _=1,3 do x=(x*48271)%2147483647 end
 return x/2147483647
end
-- Existing authored silhouettes, cleaned at render time: alpha fringe removal,
-- five deliberate voxel tones, neutral undersides. No blur or larger atlas.
function M.wetCloudTint(weather, night)
 local value = (weather == "storm" and .34 or .52) * (1 - math.max(0, math.min(1, night or 0)) * .55)
 return value, value, value
end
M.CLOUD_GLSL=[[
extern float wetCloud;
vec4 effect(vec4 color,Image tex,vec2 uv,vec2 sc){
 vec4 p=Texel(tex,uv);
 if(p.a<.48)discard;
 float light=dot(p.rgb,vec3(.30,.59,.11));
 light=floor(clamp((light-.30)/.70,0.0,1.0)*4.0+.5)/4.0;
 vec3 tone=mix(vec3(.51,.57,.64),vec3(1.0,.985,.945),light);
 // Rain and storm use neutral grey at every level, including highlights.
 tone=mix(tone,vec3(mix(.56,1.0,light)),wetCloud);
 return vec4(tone,1.0)*color;
}
]]
local cloudShader
function M.beginClouds(g, weather)
 if not(g.newShader and g.setShader and g.getShader)then return nil,false end
 if cloudShader==nil then local ok,s=pcall(g.newShader,M.CLOUD_GLSL);cloudShader=ok and s or false end
 if not cloudShader then return nil,false end
 cloudShader:send("wetCloud", (weather == "rain" or weather == "storm") and 1 or 0)
 local old=g.getShader();g.setShader(cloudShader);return old,true
end
function M.invalidate()
 if cloudShader and cloudShader.release then cloudShader:release()end
 cloudShader=nil
end
return M
