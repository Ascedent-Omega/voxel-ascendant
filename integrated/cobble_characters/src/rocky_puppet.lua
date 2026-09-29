-- Texture-skinned human joints. The accepted source atlas is never rewritten.
-- Coordinates below are landmarks in its neutral column, measured per view.
local P={revision=2,cellWidth=256,cellHeight=384,anchorX=128,anchorY=376,referenceHeight=320}
local profiles={
 hd={width=660,height=1200,eyes={ [0]={{85,101,101,119},{119,101,137,119}},[1]={{78,112,90,131}},[3]={{128,117,141,135}}},skin={[0]={{93,122},{126,122}},[1]={{94,132}},[3]={{124,137}}}},
 voxel={width=1152,height=1536,eyes={ [0]={{157,120,181,145},{204,120,229,145}},[1]={{147,116,168,144}},[3]={{223,116,241,144}}},skin={[0]={{169,150},{216,150}},[1]={{169,145}},[3]={{219,145}}}},
}
local shaderSource=[[
extern vec4 sourceCell;
extern vec4 bodyBounds;
extern vec4 eye0;extern vec4 eye1;
extern vec2 skin0;extern vec2 skin1;
extern float closure;extern float fillArm;extern float armX;extern float sampleX;
vec4 eyeBlink(Image tex,vec2 uv,vec4 px,vec4 eye,vec2 sampleSkin){
 if(eye.z<=eye.x || uv.x<eye.x || uv.x>eye.z || uv.y<eye.y || uv.y>eye.w || closure<=0.0)return px;
 float sweep=mix(eye.y,eye.w,closure);
 if(uv.y>sweep)return px;
 vec3 skin=Texel(tex,sampleSkin).rgb;
 float u=(uv.x-eye.x)/(eye.z-eye.x);
 float lineY=closure>.99?eye.y+(eye.w-eye.y)*(0.65+0.08*sin(u*3.14159)):sweep;
 float line=(1.0-smoothstep((eye.w-eye.y)*0.035,(eye.w-eye.y)*0.085,abs(uv.y-lineY)))*smoothstep(0.01,0.13,u)*(1.0-smoothstep(0.87,0.99,u));
 return vec4(mix(skin,vec3(0.17,0.11,0.10),line*0.92),px.a);
}
vec4 effect(vec4 tint,Image tex,vec2 uv,vec2 screen){
 vec4 px=Texel(tex,uv);vec2 q=(uv-bodyBounds.xy)/bodyBounds.zw;
 if(fillArm>0.5 && q.y>0.49 && q.y<0.76 && abs(q.x-armX)<0.18){
  vec2 behind=uv;behind.x=bodyBounds.x+sampleX*bodyBounds.z;
  px=Texel(tex,behind);
 }
 if(px.a<0.10)return vec4(0.0);
 px=eyeBlink(tex,uv,px,eye0,skin0);px=eyeBlink(tex,uv,px,eye1,skin1);return px*tint;
}
]]
local function bbox(data,row,cw,ch)
 local l,t,r,b=cw,ch,0,0
 for y=0,ch-1 do for x=0,cw-1 do local _,_,_,a=data:getPixel(x,row*ch+y);if a>.10 then l=math.min(l,x);r=math.max(r,x+1);t=math.min(t,y);b=math.max(b,y+1)end end end
 return{l,t,r,b}
end
function P.new(path,style)
 local profile=assert(profiles[style]);local g=love.graphics
 local data=love.image.newImageData(path);local w,h=data:getDimensions();assert(w==profile.width and h==profile.height)
 local cw,ch=w/3,h/4;local image=g.newImage(data);image:setFilter('linear','linear')
 local boxes,bottoms={},{}
 for row=0,3 do
  local b=bbox(data,row,cw,ch);boxes[row]=b;bottoms[row]={}
  for x=b[1],b[3]-1 do for y=b[4]-1,math.floor(b[2]+(b[4]-b[2])*.865),-1 do
   local _,_,_,a=data:getPixel(x,row*ch+y)
   if a>.10 then bottoms[row][#bottoms[row]+1]={x+.5,y+1};break end
  end end
 end
 data:release()
 local shader=g.newShader(shaderSource)
 local function eyeUniform(rect,row)
  if not rect then return{0,0,0,0}end
  return{rect[1]/w,(rect[2]+row*ch)/h,rect[3]/w,(rect[4]+row*ch)/h}
 end
 local function pose(row,phase,moving,blink)
  local b=boxes[row];local bw,bh=b[3]-b[1],b[4]-b[2]
  local q=g.newQuad(0,row*ch,cw,ch,w,h)
  local side=row==1 or row==3;local facing=row==3 and-1 or 1
  local function point(x,y)return b[1]+bw*x,b[2]+bh*y end
  local function mask(poly)
   local xy={};for i=1,#poly,2 do xy[i],xy[i+1]=point(poly[i],poly[i+1])end
   g.stencil(function()g.polygon('fill',xy)end,'replace',1,false);g.setStencilTest('equal',1)
  end
  local function texture(poly,shade)
   mask(poly);g.setColor(shade or 1,shade or 1,shade or 1,1);g.draw(image,q,0,0);g.setStencilTest()
  end
  local eyes=profile.eyes[row]or{}
  shader:send('eye0',eyeUniform(eyes[1],row));shader:send('eye1',eyeUniform(eyes[2],row));shader:send('closure',blink or 0)
  for i=1,2 do local p=(profile.skin[row]or{})[i]or{0,0};shader:send('skin'..(i-1),{p[1]/w,(p[2]+row*ch)/h})end
  shader:send('bodyBounds',{b[1]/w,(b[2]+row*ch)/h,bw/w,bh/h});shader:send('fillArm',0)
  shader:send('armX',row==3 and .47 or .58);shader:send('sampleX',row==3 and .66 or .33)
  g.setShader(shader)
  if not moving then g.setColor(1,1,1,1);g.draw(image,q,0,0);g.setShader();q:release();return end
  local t=phase*2*math.pi;local swing=math.cos(t)
  local hem=style=='hd'and(row==2 and .76 or .73)or .75
  local shoulder=.48;local armEnd=hem+.015
  local function limb(poly,px,py,angle,shade,scaleY)
   local x,y=point(px,py);g.push();g.translate(x,y);g.rotate(angle);g.scale(1,scaleY or 1);g.translate(-x,-y);texture(poly,shade);g.pop()
  end
  local function leg(sign,far)
   local center=side and .5 or(sign==1 and .35 or .67)
   local left,right=side and .18 or(sign==1 and .10 or .51),side and .77 or(sign==1 and .50 or .93)
   local angle=(side and .40*facing or .065)*sign*swing
   local x,y=point(center,hem)
   local knee=.865;local bend=side and-.30*facing*math.max(0,sign*math.sin(t))or 0
   local kx,ky=point(center,knee);local maxY=-math.huge
   for _,p in ipairs(bottoms[row])do if p[1]>=b[1]+bw*left and p[1]<=b[1]+bw*right then
    local dx,dy=p[1]-kx,p[2]-ky
    local xx=kx+dx*math.cos(bend)-dy*math.sin(bend)
    local yy=ky+dx*math.sin(bend)+dy*math.cos(bend)
    maxY=math.max(maxY,y+(xx-x)*math.sin(angle)+(yy-y)*math.cos(angle))
   end end
   local lift=math.min(0,b[4]-maxY)
   g.push();g.translate(0,lift);g.translate(x,y);g.rotate(angle);if not side then g.scale(1,1-.14*math.max(0,sign*math.sin(t)))end;g.translate(-x,-y)
   texture({left,hem-.015,right,hem-.015,right,knee+.01,left,knee+.01},far and .87 or 1)
   limb({left,knee-.01,right,knee-.01,right,1.005,left,1.005},center,knee,bend,far and .87 or 1)
   g.pop()
  end
  -- Far limbs are drawn behind the unchanged torso; toes never mirror.
  if side then leg(-1,true)else leg(1,false);leg(-1,false)end
  local leftArm={-.02,shoulder+.02,.22,shoulder,.29,.57,.25,armEnd,.00,armEnd,-.04,.66}
  local rightArm={.77,shoulder,1.02,shoulder+.02,1.04,.66,1,armEnd,.74,armEnd,.71,.57}
  local sideArm={.46,shoulder,.69,shoulder+.01,.70,armEnd,.46,armEnd,.45,.60}
  if row==3 then for i=1,#sideArm,2 do sideArm[i]=1-sideArm[i]end end
  if side then limb(sideArm,row==3 and .43 or .57,shoulder,.32*facing*swing,.86)end
  if side then leg(1,false)end
  -- Torso silhouette includes the full cap, head and hair. Only the side
  -- arm's covered shirt strip is sampled from its neighbouring fabric.
  shader:send('fillArm',side and 1 or 0)
  local body=side and {-.03,-.01,1.03,-.01,1.03,.47,.71,.49,.71,hem,.22,hem,.24,.53,-.03,.47}
    or {-.03,-.01,1.03,-.01,1.03,shoulder,.77,shoulder,.72,.59,.82,hem,.19,hem,.28,.59,.22,shoulder,-.03,shoulder}
  texture(body);shader:send('fillArm',0)
  if side then
   limb(sideArm,row==3 and .43 or .57,shoulder,-.32*facing*swing,1)
  else
   limb(leftArm,.18,shoulder,.13*swing,1,1-.12*math.max(0,-math.sin(t)))
   limb(rightArm,.82,shoulder,-.13*swing,1,1-.12*math.max(0,math.sin(t)))
  end
  g.setShader();q:release()
 end
 local api={boxes=boxes}
 function api.render(kind,columns)
  local canvas=g.newCanvas(P.cellWidth*columns,P.cellHeight*4,{dpiscale=1})
  g.push('all');g.setCanvas({canvas,stencil=true});g.origin();g.clear(0,0,0,0);g.setShader();g.setScissor();g.setBlendMode('alpha')
  for row=0,3 do for col=0,columns-1 do
   g.push();g.setScissor(col*P.cellWidth,row*P.cellHeight,P.cellWidth,P.cellHeight)
   local b=boxes[row];local scale=P.referenceHeight/(b[4]-b[2])
   g.translate(col*P.cellWidth+P.anchorX-(b[1]+b[3])/2*scale,row*P.cellHeight+P.anchorY-b[4]*scale);g.scale(scale,scale)
   pose(row,col/columns,kind=='walk',kind=='blink'and({0,.5,1,0})[col+1]or 0)
   g.pop()
  end end
  g.setStencilTest();g.pop();local result=canvas:newImageData();canvas:release();return result
 end
 function api.release()image:release();shader:release()end
 return api
end
return P
