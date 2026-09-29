-- Exercise production draw-state functions without compiling the renderer.
local f=assert(io.open('lib/Voxel3D.lua','r'));local source=f:read('*a');f:close()
local first=assert(source:find('function Voxel3D.rooftopMaterials(mask)',1,true))
local last=assert(source:find('function Voxel3D.seasonFoliage',first,true))
local native,roof,blank={},{},{}
local sent={};local shader={send=function(_,key,value)sent[key]=value end}
local env=setmetatable({Voxel3D={glassMask=native},GlassMask={blank=function()return blank end},active=true,activeShader=shader},{__index=_G})
local fn=assert(loadstring(source:sub(first,last-1)));setfenv(fn,env);fn()
assert(env.Voxel3D.rooftopMaterials(roof));assert(sent.glassMask==roof and sent.rooftopMaterials==1)
assert(env.Voxel3D.rooftopMaterials(nil));assert(sent.glassMask==native and sent.rooftopMaterials==0)
env.Voxel3D.glassMask=nil;assert(env.Voxel3D.rooftopMaterials(nil));assert(sent.glassMask==blank)
env.active=false;sent={};assert(not env.Voxel3D.rooftopMaterials(roof));assert(not next(sent))
print('PASS rooftop mask draw isolation, native atlas restoration, blank fallback, inactive zero-work')
