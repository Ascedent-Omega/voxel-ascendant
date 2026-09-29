-- Bounded, render-only boot impressions. The update clock is independent of
-- SFX volume; no tracks in mid-hop, while surfing/cycling or on teleport.
local V=...
local S={MAX=64,LIFE=55,marks={},clock=0,revision=0,last={draws=0,count=0}}
local map,previous,side,mesh,texture,uploadKey,failed
local function reset()
 S.marks={};previous=nil;side=1;S.revision=S.revision+1
end
function S.update(dt,game,mode)
 S.clock=S.clock+math.max(0,math.min(.15,tonumber(dt)or 0))
 local world=game and(game.overworld or game.world);local current=world and world.map;local p=world and world.player
 if map~=current then reset();map=current end
 local active=p and mode=='snow' and V.require('DeepSnow').setting:get()=='deep'
 if not active then if #S.marks>0 or previous then reset()end;return end
 for i=#S.marks,1,-1 do if S.clock-S.marks[i].time>=S.LIFE then table.remove(S.marks,i);S.revision=S.revision+1 end end
 local x,z=(p.px or(p.cellX or 0)*16)+8,(p.py or(p.cellY or 0)*16)+8
 if p.jumping or p.ledgeHop or p.surfing or(game.save and game.save.onBike)then previous={x,z};return end
 if not previous then previous={x,z};return end
 local dx,dz=x-previous[1],z-previous[2];local length=math.sqrt(dx*dx+dz*dz)
 if length<5 then return end
 previous={x,z}
 if length>20 then return end
 local _,_,_,land=V.require('WorldWeather').surface(map,x,z)
 if not land then return end
 side=-(side or 1);dx,dz=dx/length,dz/length
 S.marks[#S.marks+1]={x=x-dz*side*1.15,z=z+dx*side*1.15,dx=dx,dz=dz,time=S.clock}
 if #S.marks>S.MAX then table.remove(S.marks,1)end
 S.revision=S.revision+1
end
function S.vertices(height)
 local out,count={},0
 local order={1,2,3,1,3,4}
 for _,mark in ipairs(S.marks)do
  local y=height(mark.x,mark.z)
  if y then
   local alpha=.64*math.max(0,math.min(1,(S.LIFE-(S.clock-mark.time))/15))
   for _,part in ipairs{{-.95,-.15,.70},{.10,1.15,.85}}do
    local corners={{-part[3],part[1]},{part[3],part[1]},{part[3],part[2]},{-part[3],part[2]}}
    local face={};local valid=true
    for i,q in ipairs(corners)do
     local x=mark.x-mark.dz*q[1]+mark.dx*q[2];local z=mark.z+mark.dx*q[1]+mark.dz*q[2]
     local h=height(x,z);if not h or math.abs(h-y)>.4 then valid=false;break end
     face[i]={x,h+.055,z,.5,.5,1,.48,.59,.69,alpha}
    end
    if valid then for _,i in ipairs(order)do out[#out+1]=face[i]end;count=count+1 end
   end
  end
 end
 return out,count
end
function S.draw(state,height,surfaceKey)
 S.last={draws=0,count=0}
 if failed or state.map~=map or #S.marks==0 or state.snowArena then return false end
 local G=V.require('Voxel3D');local g=love.graphics;local pushed=false
 local ok,err=pcall(function()
  local key=S.revision..':'..math.floor(S.clock*2)..':'..surfaceKey
  if uploadKey~=key then
   local verts,n=S.vertices(height);S.count=n
   if n>0 then
    if not mesh then mesh=g.newMesh({{'VertexPosition','float',3},{'VertexTexCoord','float',2},{'VertexShade','float',1},{'VertexColor','float',4}},S.MAX*12,'triangles','dynamic')end
    mesh:setVertices(verts,1,#verts);mesh:setDrawRange(1,#verts)
   end
   uploadKey=key
  end
  if not S.count or S.count==0 then return end
  if not texture then local data=love.image.newImageData(1,1);data:setPixel(0,0,1,1,1,1);texture=g.newImage(data);data:release()end
  g.push('all');pushed=true;g.setColor(1,1,1,1);g.setDepthMode('lequal',false);g.setMeshCullMode('none')
  G.weatherGround(false);G.weatherGrass(false);G.glass(false)
  G.draw(mesh,texture);g.pop();pushed=false;S.last={draws=1,count=S.count}
 end)
 if pushed then g.pop()end
 if not ok then failed=tostring(err);S.error=failed;print('[VASC tracks] disabled: '..failed)end
 return ok
end
function S.invalidate()
 for _,v in ipairs{mesh or false,texture or false}do if v and v.release then v:release()end end
 mesh,texture,uploadKey,failed=nil,nil,nil,nil;S.error=nil;reset();map=nil
end
return S
