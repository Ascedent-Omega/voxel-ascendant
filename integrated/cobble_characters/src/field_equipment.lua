-- Equipment lives on the ground/root while the supplied human rig articulates.
local E={}
function E.add(model,action)
 if not action or action=='hold'then return model end
 assert(action=='bicycle'or action=='fishing','unsupported Cobble action: '..tostring(action))
 local bone={name='equipment',parent=model.bones[1].name,pivot={0,0,0},cubes={}}
 model.bones[#model.bones+1]=bone
 local function box(origin,size,material,rotation,pivot)bone.cubes[#bone.cubes+1]={origin=origin,size=size,material=material,rotation=rotation,pivot=pivot}end
 local function rod(y1,z1,y2,z2,width,material,x)
  local dy,dz=y2-y1,z2-z1;local length=math.sqrt(dy*dy+dz*dz)
  box({(x or 0)-width/2,y1,z1-width/2},{width,length,width},material,{math.atan2(dz,dy)*180/math.pi,0,0},{x or 0,y1,z1})
 end
 if action=='bicycle'then
  for _,z in ipairs({-13,13})do
   for n=0,11 do
    local angle=n*math.pi/6;local y=8+7.5*math.cos(angle);local zz=z+7.5*math.sin(angle)
    box({-1.25,y-1.2,zz-2.4},{2.5,2.4,4.8},'ink',{n*30,0,0},{0,y,zz})
   end
   for n=0,2 do local a=n*math.pi/3;rod(8-6*math.cos(a),z-6*math.sin(a),8+6*math.cos(a),z+6*math.sin(a),.5,'gray')end
  end
  rod(8,-13,24,-9,1.3,'gray');rod(8,13,18,1,1.4,'red');rod(18,1,10,-1,1.4,'red');rod(10,-1,8,13,1.4,'red')
  rod(18,1,20,-10,1.4,'red');rod(20,-10,10,-1,1.4,'red');rod(18,1,23,1,1,'gray')
  box({-4,23,-1},{8,1.5,5},'ink');box({-8,24,-10},{16,1.3,1.3},'ink')
  box({-5,10,-2},{10,1,2},'gray');box({-7,9.5,-4},{3,1,5},'ink');box({4,9.5,-4},{3,1,5},'ink')
 else
  model.colors.rod='795337';model.colors.line='d8ddd9'
  rod(22,-12,40,-28,.8,'rod',-4)
  rod(40,-28,11,-31,.2,'line',-4)
  box({-5,10,-32},{2,2,2},'red');box({-5.5,20,-13.5},{3,3,3},'gray')
 end
 return model
end
return E
