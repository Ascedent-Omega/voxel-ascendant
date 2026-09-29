-- Exercise the actual seating mesh against the chair's support planes.
local function noop()end
local function resource()return {setFilter=noop,release=noop}end
love={graphics=setmetatable({newCanvas=resource,newQuad=resource},{__index=function()return noop end})}
local voxel={newMesh=function(vertices)
 return {vertices=vertices,setVertices=function(self,v)self.vertices=v end,release=noop}
end}
local Seat=assert(loadfile('integrated/ascendant_pokemon_overworld/src/human_johto_seat.lua'))()
local api=Seat.new{mod={},voxel=voxel,profiles={byGeneration={[1]={}}},generation=1}
local count=0
local specs=assert(loadfile("lib/KantoSeatGeometry.lua")){}.specs
for kind,desc in pairs(specs)do
local support,front,back,backTop=desc[2],desc[3],desc[4],desc[5]
for _,height in ipairs{16.875,21.6}do for worldRow=0,3 do for view=0,3 do
 local bounds={};for row=0,3 do bounds[row]={[0]={left=45,right=120,top=row*225+15,bottom=row*225+215}}end
 local source={texture={getDimensions=function()return 495,900 end},bounds=bounds}
 local profile={mapId='KANTO_CHAIR',contact={height=support,front=front,back=back,backTop=backTop},row=view,worldRow=worldRow,index=0,
  sign=view==1 and -1 or 1,bendSign=view==1 and -1 or view==3 and 1 or 0,
  legDepth=view==2 and -1 or view==0 and 1 or 0,headFade={90,116}}
 local unit=height/200
 local v={{8-37.5*unit,0,0,45/495,(view*225+215)/900,1},
 {8+37.5*unit,0,0,120/495,(view*225+215)/900,1},
 {8+37.5*unit,height,0,120/495,(view*225+15)/900,1},
 {8-37.5*unit,height,0,45/495,(view*225+15)/900,1}}
 local original={getVertexCount=function()return 4 end,getVertex=function(_,i)return unpack(v[i])end}
 local record={}
 local mesh=api:prepare(record,original,source,profile,height,0)
 -- A 20px shin interval must retain its original length on every chair.
 local shinA,shinB
 for _,p in ipairs(mesh.vertices)do
  if math.abs(p[5]-190/225)<1e-7 then shinA=p end
 end
 for _,p in ipairs(mesh.vertices)do
  if shinA and math.abs(p[4]-shinA[4])<1e-7 and math.abs(p[5]-210/225)<1e-7 then shinB=p;break end
 end
 assert(shinA and shinB)
 local length=math.sqrt((shinA[1]-shinB[1])^2+(shinA[2]-shinB[2])^2+(shinA[3]-shinB[3])^2)
 assert(math.abs(length-20*unit)<.0001,'chair stretched the shin')
 for yaw=0,7 do for _,lean in ipairs{0,.6,1.1}do
  local c,s=math.cos(yaw*math.pi/4),math.sin(yaw*math.pi/4)
  local model={c,s*math.sin(lean),-s*math.cos(lean),40-8*c,
   0,math.cos(lean),math.sin(lean),8,
   s,-c*math.sin(lean),c*math.cos(lean),168-8*s,0,0,0,1}
  local aligned=api:align(record,model);api:contact(record,aligned)
  assert(model[8]==8,'seating changed the engine-owned transform')
  local fx,fz=worldRow==1 and -1 or worldRow==3 and 1 or 0,worldRow==2 and -1 or worldRow==0 and 1 or 0
  local minY=math.huge
  for _,p in ipairs(mesh.vertices)do
   local x=aligned[1]*p[1]+aligned[3]*p[3]+aligned[4]
   local y=p[2]+aligned[8]
   local z=aligned[9]*p[1]+aligned[11]*p[3]+aligned[12]
   local front=(x-40)*fx+(z-168)*fz
   assert(y>=.0999,'shoe penetrated floor')
   assert(y>=support+.1499 or front>=desc[3]-.0001,'lower body penetrated cushion')
   assert(y>=backTop-.2 or front>=back-.0001,'body penetrated backrest')
   minY=math.min(minY,y)
  end
  assert(minY<=support+1,'feet floated above the cushion')
  count=count+1
 end end
end end end
end
api:clear()
print('PASS seated contact planes: '..count..' height/facing/view/yaw/pitch combinations')
