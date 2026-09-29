local S={}
S.GLSL=[[
uniform float scenerySnow;
vec3 snowFoliage(vec3 source,float amount){
 float green=smoothstep(.008,.075,source.g-max(source.r,source.b));
 float brightness=max(source.r,max(source.g,source.b));
 float tone=floor(clamp(brightness*2.2,0.0,1.0)*4.0)/4.0;
 vec3 snow=mix(vec3(.64,.72,.80),vec3(.96,.98,1.0),tone);
 float coat=smoothstep(.02,.70,clamp(amount,0.0,1.0));
 return mix(source,snow,green*coat*.97);
}
]]
function S.inject(source)
 source=source:gsub('#ifdef PIXEL',function()return '#ifdef PIXEL\n'..S.GLSL end,1)
 return (source:gsub('vec3 rgb = p.rgb','p.rgb=snowFoliage(p.rgb,scenerySnow);\n    vec3 rgb = p.rgb',1))
end
function S.amount(context)
 if type(context)~='table' or context.outdoor~=true or context.surfaces==false or context.weather~='snow'then return 0 end
 local n=tonumber(context.amount)or 0;if n~=n then return 0 end
 return math.max(0,math.min(1,n))
end
return S
