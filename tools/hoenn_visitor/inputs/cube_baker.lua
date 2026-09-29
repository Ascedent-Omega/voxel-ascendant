-- Deterministic orthographic render of the supplied original cuboid rig.
-- This runs only when a new wardrobe combination needs an atlas.
local Baker={}
local pi,sin,cos=math.pi,math.sin,math.cos
local function rotate(v,r)
 local x,y,z=v[1],v[2],v[3];r=r or{0,0,0}
 local a,b,c=r[1]*pi/180,r[2]*pi/180,r[3]*pi/180
 y,z=y*cos(a)-z*sin(a),y*sin(a)+z*cos(a)
 x,z=x*cos(b)+z*sin(b),-x*sin(b)+z*cos(b)
 x,y=x*cos(c)-y*sin(c),x*sin(c)+y*cos(c)
 return{x,y,z}
end
local function pose(name,phase,moving,action)
 local t=phase*2*pi;local side=name:find('right',1,true)and-1 or 1
 local r={0,0,0};local p={0,0,0}
 if moving then
  if name=='body'then p={.15*sin(t),.6+.25*(1-cos(2*t)),0}
  elseif name=='head'then r={0,1.3*sin(t),0}
  elseif name:find('forearm',1,true)then r={20-10*side*cos(t),0,0}
  elseif name:find('arm_',1,true)then r={-24*side*cos(t),0,0}
  elseif name:find('shin_',1,true)then r={-32*math.max(0,side*sin(t))^2,0,0}
  elseif name:find('leg_',1,true)then r={24*side*cos(t),0,0}end
 elseif name:find('forearm',1,true)then r={7,0,0}end
 if action=='bicycle'then
  if name=='body'then p={0,8,0};r={-12,0,0}
  elseif name:find('forearm',1,true)then r={12,0,0}
  elseif name:find('arm_',1,true)then r={60,0,0}
  elseif name:find('shin_',1,true)then r={-50+20*side*cos(t),0,0}
  elseif name:find('leg_',1,true)then r={65+25*side*cos(t),0,0}end
 elseif action=='fishing'or action=='hold'then
  if name:find('forearm',1,true)then r={20,0,0}
  elseif name:find('arm_',1,true)then r={55,0,action=='hold'and(name=='arm_left'and-20 or 20)or 0}end
 end
 return r,p
end
local corners={{0,0,0},{1,0,0},{1,1,0},{0,1,0},{0,0,1},{1,0,1},{1,1,1},{0,1,1}}
local sides={{{1,4,3,2},{0,0,-1},1},{{5,6,7,8},{0,0,1},.83},{{1,5,8,4},{-1,0,0},.78},{{2,3,7,6},{1,0,0},.90},{{4,8,7,3},{0,1,0},1.08},{{1,2,6,5},{0,-1,0},.63}}
local cameras={{0,0,-1},{-1,0,0},{0,0,1},{1,0,0}}
local function project(v,row)
 if row==0 then return-v[1],-v[3]elseif row==1 then return v[3],-v[1]elseif row==2 then return v[1],v[3]else return-v[3],v[1]end
end
function Baker.transformer(model,phase,moving,action)
 local bones={};for _,b in ipairs(model.bones)do bones[b.name]=b end
 local rotations,positions={},{}
 for name in pairs(bones)do rotations[name],positions[name]=pose(name,phase,moving,action)end
 local function world(v,name,normal)
  local bone=bones[name];if not bone then return v end
  local pivot=bone.pivot or{0,0,0}
  if not normal then for j=1,3 do v[j]=v[j]-pivot[j]end end
  v=rotate(v,rotations[name])
  if not normal then for j=1,3 do v[j]=v[j]+pivot[j]+positions[name][j]end end
  return bone.parent and world(v,bone.parent,normal)or v
 end
 return world,bones
end
function Baker.hand(model,row,action)
 local world,bones=Baker.transformer(model,0,false,action)
 local bone=bones.forearm_right
 for _,c in ipairs(bone.cubes)do if c.material=='skinlight'then
  local point={};for j=1,3 do point[j]=c.origin[j]+c.size[j]/2 end
  point=world(point,bone.name);local x=project(point,row)
  return x,point[2]
 end end
 error('Missing hand landmark')
end
function Baker.faces(model,row,phase,moving,blink,action)
 local world=Baker.transformer(model,phase,moving,action)
 local faces={}
 for _,bone in ipairs(model.bones)do
  local eye=bone.name:find('eye_',1,true);local lid=bone.name:find('lid_',1,true)
  if not(eye and blink>=.8 or lid and blink<.8)then
   for _,cube in ipairs(bone.cubes or{})do
    local points={};local pivot=cube.pivot or bone.pivot or{0,0,0}
    for i,c in ipairs(corners)do
     local point={};for j=1,3 do point[j]=cube.origin[j]+cube.size[j]*c[j]end
     if eye and blink>0 then point[2]=bone.pivot[2]+(point[2]-bone.pivot[2])*.12 end
     if cube.rotation then
      for j=1,3 do point[j]=point[j]-pivot[j]end;point=rotate(point,cube.rotation)
      for j=1,3 do point[j]=point[j]+pivot[j]end
     end
     points[i]=world(point,bone.name)
    end
    local hex=model.colors[cube.material]or cube.color or'ffffff'
    local rgb={tonumber(hex:sub(1,2),16)/255,tonumber(hex:sub(3,4),16)/255,tonumber(hex:sub(5,6),16)/255}
    for _,face in ipairs(sides)do
     local normal=world(rotate(face[2],cube.rotation),bone.name,true);local camera=cameras[row+1]
     if normal[1]*camera[1]+normal[2]*camera[2]+normal[3]*camera[3]>.001 then
      local polygon,depth={},0
      for _,index in ipairs(face[1])do local v=points[index];local x,z=project(v,row);polygon[#polygon+1]=x;polygon[#polygon+1]=v[2];depth=depth+z/4 end
      faces[#faces+1]={polygon=polygon,depth=depth+(cube.inflate or 0),color=rgb,shade=face[3]}
     end
    end
   end
  end
 end
 table.sort(faces,function(a,b)return a.depth<b.depth end)
 return faces
end
function Baker.layout(action)
 return action and action~='hold'and {cellWidth=256,cellHeight=224,anchorX=128,anchorY=220}or{cellWidth=128,cellHeight=160,anchorX=64,anchorY=156}
end
function Baker.referenceHeight(model)
 local low,high=math.huge,-math.huge
 for _,f in ipairs(Baker.faces(model,0,0,false,0))do for i=2,#f.polygon,2 do low=math.min(low,f.polygon[i]);high=math.max(high,f.polygon[i])end end
 return (high-low)*3
end
function Baker.render(model,columns,kind,action)
 local g=love.graphics;local layout=Baker.layout(action);local cw,ch=layout.cellWidth,layout.cellHeight;local canvas=g.newCanvas(cw*columns,ch*4)
 g.push('all');g.setCanvas(canvas);g.origin();g.clear(0,0,0,0);g.setShader();g.setScissor();g.setDepthMode();g.setBlendMode('alpha')
 for row=0,3 do for col=0,columns-1 do
  g.setScissor(col*cw,row*ch,cw,ch)
  local blink=kind=='blink'and({0,.5,1,0})[col+1]or 0
  local phase=kind=='walk'and col/columns or kind=='preview'and({0,0,.5})[col+1]or 0
  local faces=Baker.faces(model,row,phase,kind=='walk'or kind=='preview'and col>0,blink,action)
  for _,face in ipairs(faces)do
   local points={};for j=1,#face.polygon,2 do points[j]=col*cw+layout.anchorX+face.polygon[j]*3;points[j+1]=row*ch+layout.anchorY-face.polygon[j+1]*3 end
   g.setColor(math.min(1,face.color[1]*face.shade),math.min(1,face.color[2]*face.shade),math.min(1,face.color[3]*face.shade),1)
   g.polygon('fill',points)
  end
 end end
 g.pop();local data=canvas:newImageData();canvas:release();return data
end
return Baker
