local modules={ModSetting={new=function(_,_,_,_,default)return{value=default,get=function(s)return s.value end}end}}
local V={}
V.require=function(n)if not modules[n]then modules[n]=assert(loadfile('lib/'..n..'.lua'))(V)end;return modules[n]end
local H=V.require('Halloween');local Mat=V.require('Mat4')
local function point(m,x,y,z)return{m[1]*x+m[2]*y+m[3]*z+m[4],m[5]*x+m[6]*y+m[7]*z+m[8],m[9]*x+m[10]*y+m[11]*z+m[12]}end
local function near(a,b)for i=1,3 do assert(math.abs(a[i]-b[i])<1e-7,'accessory detached from actor')end end
for _,actorWidth in ipairs{4,5.7,12}do
for _,height in ipairs{12,16,23}do
 for _,yaw in ipairs{0,.9,2.7}do
  for _,mirror in ipairs{1,-1}do
   local model=Mat.mul(Mat.translate(47,6,83),Mat.mul(Mat.rotateY(yaw),Mat.mul(Mat.rotateX(-.5),Mat.scale(mirror,1.006,1))))
   local pose={model=model,x=8.4,top=height-.2,width=actorWidth,height=height,pull=2}
   local brimWidth=math.max(4,math.min(9,pose.width*.95))
   local hat=H.costumeMatrix('october_witch_hat',Mat.identity(),pose)
   near(point(hat,8,14,0),point(model,pose.x,pose.top-brimWidth*.18,0))
   -- Both faces of the brim must intersect the upper hair; tangent
   -- contact at the top silhouette still reads as floating in perspective.
   local localPose={model=Mat.identity(),x=pose.x,top=pose.top,width=pose.width,height=height}
   local localHat=H.costumeMatrix('october_witch_hat',Mat.identity(),localPose)
   assert(point(localHat,8,15.3,0)[2]<pose.top-.3,'upper brim floats above hair')
   assert(point(localHat,8,14,0)[2]>pose.top-height*.16,'brim covers face')
   local left,right=point(hat,2,14,0),point(hat,14,14,0)
   local width=math.sqrt((left[1]-right[1])^2+(left[2]-right[2])^2+(left[3]-right[3])^2)
   assert(math.abs(width-brimWidth)<1e-7,'oversized brim')
   near(point(H.costumeMatrix('october_bat_cape',Mat.identity(),pose),8,16,0),point(model,pose.x,pose.top,0))
  end
 end
end
end
local native=H.costumeMatrix('october_witch_hat',Mat.identity())
near(point(native,8,14,0),{8,16-8*.95*.18,0})
assert(point(native,8,22.5,0)[2]<21,'native hat oversized')
print('PASS hats follow actual actor crown, lean, yaw, mirror, breath, size and lift; cape follows posed body; native face stays clear')
