-- Texture-skinned human joints. The accepted source atlas is never rewritten.
-- Coordinates below are landmarks in its neutral column, measured per view.
local P={revision=2,cellWidth=320,cellHeight=384,anchorX=160,anchorY=376,referenceHeight=320}
-- Source-space landmarks; row gutters are measured, not assumed equal.
local profiles={
 ['jessie-hd']={width=930,height=1691,rows={0,430,839,1245,1691},body={{67,31,211,407},{91,451,175,826},{70,864,219,1229},{136,1259,219,1627}},hem=.69,shoulder=.37,knee=.85,hair=true,
 eyes={[0]={{113,119,133,141},{151,117,176,141}},[1]={{114,537,132,562}},[3]={{184,1340,206,1368}}},skin={[0]={{124,144},{161,144}},[1]={{130,568}},[3]={{188,1373}}}},
 ['jessie-voxel']={width=930,height=1691,rows={0,413,835,1235,1691},body={{60,15,220,407},{78,425,183,827},{65,846,218,1231},{128,1241,226,1640}},hem=.69,shoulder=.39,knee=.85,hair=true,
 eyes={[0]={{107,120,131,145},{151,119,177,145}},[1]={{104,537,126,563}},[3]={{187,1345,213,1375}}},skin={[0]={{124,146},{163,146}},[1]={{127,566}},[3]={{191,1378}}}},
 ['james-voxel']={width=960,height=1536,rows={0,384,768,1152,1536},body={{85,56,235,376},{115,440,195,760},{83,824,237,1144},{125,1208,205,1528}},hem=.625,shoulder=.39,knee=.84,
 eyes={[0]={{130,127,151,151},{173,127,194,151}},[1]={{118,509,134,532}},[3]={{188,1279,208,1303}}},skin={[0]={{140,154},{182,154}},[1]={{125,535}},[3]={{201,1304}}},
 legPolys={
 [0]={{121,255,160,255,160,379,116,379,118,332},{160,255,201,255,205,332,205,379,160,379}},
 [1]={{130,255,181,255,183,334,183,379,112,379,112,352,131,349}},
 [2]={{117,255,160,255,159,379,111,379,113,332},{160,255,202,255,205,332,208,379,160,379}},
 [3]={{136,255,186,255,188,349,201,351,201,379,136,379}}},
 armPolys={
 [0]={{99,176,130,181,121,235,120,292,82,292,90,233},{192,181,220,176,228,236,238,293,203,293,199,237}},
 [1]={{146,181,185,181,190,246,184,282,145,282,148,231}},
 [2]={{97,176,130,181,122,235,117,293,78,293,85,233},{192,181,223,176,231,236,241,293,202,293,198,237}},
 [3]={{134,181,172,181,173,231,175,282,140,282,136,246}}}},
 ['james-hd']={width=931,height=1690,rows={0,427,846,1262,1690},body={{91,24,256,410},{111,447,225,829},{91,864,253,1249},{124,1274,235,1664}},hem=.60,shoulder=.39,knee=.82,
 eyes={[0]={{140,112,163,141},{186,112,211,141}},[1]={{138,522,160,548}},[3]={{189,1355,213,1383}}},skin={[0]={{152,144},{195,144}},[1]={{153,555}},[3]={{197,1386}}}}
}
local rightLegs={
 ['jessie-hd']={149,1508,188,1508,181,1534,175,1576,180,1589,205,1600,209,1630,134,1630,135,1573,140,1530},
 ['jessie-voxel']={149,1521,202,1521,194,1584,201,1600,223,1615,223,1643,135,1643,138,1560},
 ['james-hd']={144,1498,198,1498,191,1550,178,1580,174,1625,195,1644,199,1667,134,1667,133,1580,138,1540},
 ['james-voxel']={136,1407,186,1407,188,1501,201,1503,201,1531,136,1531},
}
local shaderSource=[[
extern int partCount; extern vec2 partPoly[12]; extern float partLeg;
extern float hairLayer; extern float isJessie; extern float shoulder; extern float hem;
extern vec4 bodyBounds;
extern vec4 eye0;extern vec4 eye1;
extern vec2 skin0;extern vec2 skin1;
extern float bodyPass; extern float sideView; extern float partArm; extern float donorX;
extern float legRepairEnd;
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
bool inPart(vec2 q){
 bool inside=false;
 for(int i=0;i<12;i++){
  if(i>=partCount)break;
  int j=i==0?partCount-1:i-1;vec2 a=partPoly[i],b=partPoly[j];
  if((a.y>q.y)!=(b.y>q.y) && q.x<(b.x-a.x)*(q.y-a.y)/(b.y-a.y)+a.x)inside=!inside;
 }
 return inside;
}
vec4 effect(vec4 tint,Image tex,vec2 uv,vec2 screen){
 vec4 px=Texel(tex,uv);vec2 q=(uv-bodyBounds.xy)/bodyBounds.zw;
 if(partCount>0 && !inPart(q))return vec4(0.0);
 if(px.a>.10 && partLeg>0.5 && sideView>.5 && q.y<legRepairEnd && max(px.r,max(px.g,px.b))<.42){vec2 donor=uv;donor.x=bodyBounds.x+donorX*bodyBounds.z;float originalAlpha=px.a;px=Texel(tex,donor);px.a=originalAlpha;}
 if(partArm>0.5 && q.y>(isJessie>0.5?.50:.60) && min(px.r,min(px.g,px.b))>.53)return vec4(0.0);
 if(bodyPass>0.5 && sideView<.5 && q.y>shoulder+.08 && q.y<.74 && (q.x<.30 || q.x>.74) && max(px.r,max(px.g,px.b))<.5)return vec4(0.0);
 if(px.a>0.10 && fillArm>0.5 && q.y>shoulder+0.015 && q.y<hem && abs(q.x-armX)<0.31){
  vec2 behind=uv;behind.x=bodyBounds.x+sampleX*bodyBounds.z;
  float originalAlpha=px.a;px=Texel(tex,behind);px.a=originalAlpha;
 }
 bool hair=isJessie>0.5 && px.r>px.g*1.38 && px.r>px.b*1.18 && px.b>px.g*1.2 && px.b>0.12;
 if(hairLayer>0.5 && !hair)return vec4(0.0);
 if(hairLayer<0.0 && hair)return vec4(0.0);
 if(px.a<0.10)return vec4(0.0);
 px=eyeBlink(tex,uv,px,eye0,skin0);px=eyeBlink(tex,uv,px,eye1,skin1);return px*tint;
}
]]
function P.new(path,style)
 local profile=assert(profiles[style]);local g=love.graphics
 local data=love.image.newImageData(path);local w,h=data:getDimensions();assert(w==profile.width and h==profile.height)
 local cw=math.floor(w/3);local image=g.newImage(data);image:setFilter('linear','linear')
 local boxes,bottoms={},{}
 for row=0,3 do
  local source=profile.body[row+1];local off=profile.rows[row+1];local b={source[1],source[2]-off,source[3],source[4]-off};boxes[row]=b;bottoms[row]={}
  for x=b[1],b[3]-1 do for y=b[4]-1,math.floor(b[2]+(b[4]-b[2])*.865),-1 do
   local _,_,_,a=data:getPixel(x,profile.rows[row+1]+y)
   if a>.10 then bottoms[row][#bottoms[row]+1]={x+.5,y+1};break end
  end end
 end
 data:release()
 local shader=g.newShader(shaderSource)
 local function eyeUniform(rect,row)
  if not rect then return{0,0,0,0}end
  return{rect[1]/w,rect[2]/h,rect[3]/w,rect[4]/h}
 end
 local function pose(row,phase,moving,blink)
  local b=boxes[row];local bw,bh=b[3]-b[1],b[4]-b[2]
  local off=profile.rows[row+1];local ch=profile.rows[row+2]-off;local q=g.newQuad(0,off,cw,ch,w,h)
  local side=row==1 or row==3;local facing=row==3 and-1 or 1
  local function point(x,y)return b[1]+bw*x,b[2]+bh*y end
  local function localPoly(points)
   local p={};for i=1,#points,2 do p[i]=(points[i]-b[1])/bw;p[i+1]=(points[i+1]-b[2])/bh end;return p
  end
  local function mask(poly)
   local xy={};for i=1,#poly,2 do xy[i],xy[i+1]=point(poly[i],poly[i+1])end
   g.stencil(function()g.polygon('fill',xy)end,'replace',1,false);g.setStencilTest('equal',1)
  end
  local function texture(poly,shade)
   mask(poly);g.setColor(shade or 1,shade or 1,shade or 1,1);g.draw(image,q,0,0);g.setStencilTest()
  end
  local eyes=profile.eyes[row]or{}
  shader:send('eye0',eyeUniform(eyes[1],row));shader:send('eye1',eyeUniform(eyes[2],row));shader:send('closure',blink or 0)
  for i=1,2 do local p=(profile.skin[row]or{})[i]or{0,0};shader:send('skin'..(i-1),{p[1]/w,p[2]/h})end
  shader:send('partCount',0);shader:send('partLeg',0);shader:send('partArm',0);shader:send('bodyPass',0);shader:send('sideView',side and 1 or 0);shader:send('donorX',row==3 and .70 or .30)
  shader:send('bodyBounds',{b[1]/w,(b[2]+off)/h,bw/w,bh/h});shader:send('fillArm',0)
  shader:send('legRepairEnd',style=='james-voxel'and .73 or(profile.hair and .74 or .69))
  shader:send('armX',row==3 and .30 or .73);shader:send('sampleX',.5)
  shader:send('hairLayer',0);shader:send('isJessie',profile.hair and 1 or 0);shader:send('shoulder',profile.shoulder);shader:send('hem',profile.hem)
  g.setShader(shader)
  if not moving then g.setColor(1,1,1,1);g.draw(image,q,0,0);g.setShader();q:release();return end
  local t=phase*2*math.pi;local swing=math.cos(t)
  local hem=profile.hem;local shoulder=profile.hair and row==2 and .51 or profile.shoulder;local armEnd=side and(profile.hair and .708 or .695)or .715
  shader:send('shoulder',shoulder);shader:send('hairLayer',-1)
  -- Skin each cutout as one continuous mesh: no independently rotating
  -- knee rectangles and no second shoe hidden inside a duplicated side leg.
  local function smooth(a,b,y)local u=math.max(0,math.min(1,(y-a)/(b-a)));return u*u*(3-2*u)end
  local function drawPart(poly,warp,shade,isLeg)
   local points={};for i=1,24,2 do points[#points+1]={poly[i]or 0,poly[i+1]or 0}end
   shader:send('partPoly',unpack(points));shader:send('partCount',#poly/2);shader:send('partLeg',isLeg and 1 or 0);shader:send('partArm',isLeg and 0 or 1)
   local vertices={};local step=6
   local function vertex(x,y)
    local xx,yy=warp(x,y);return{xx,yy,x/w,(y+off)/h,1,1,1,1}
   end
   for yy=0,ch-1,step do for xx=0,cw-1,step do
    local x2,y2=math.min(cw,xx+step),math.min(ch,yy+step)
    for _,v in ipairs({vertex(xx,yy),vertex(x2,yy),vertex(x2,y2),vertex(xx,yy),vertex(x2,y2),vertex(xx,y2)})do vertices[#vertices+1]=v end
   end end
   local mesh=g.newMesh(vertices,'triangles','stream');mesh:setTexture(image)
   g.setColor(shade or 1,shade or 1,shade or 1,1);g.draw(mesh);mesh:release()
   shader:send('partCount',0);shader:send('partLeg',0);shader:send('partArm',0)
  end
  local function limb(poly,px,py,angle,shade,scaleY)
   local x,y=point(px,py)
   drawPart(poly,function(xx,yy)
    local weight=smooth(shoulder,shoulder+.13,(yy-b[2])/bh)
    local a=angle*weight;local dx,dy=xx-x,(yy-y)*(1+((scaleY or 1)-1)*weight)
    return x+dx*math.cos(a)-dy*math.sin(a),y+dx*math.sin(a)+dy*math.cos(a)
   end,shade)
  end
  local function leg(sign,far)
   local center=side and .66 or(sign==1 and .35 or .67)
   local left,right=sign==1 and .08 or .50,sign==1 and .50 or .97
   local poly=sign==1 and {.245,hem-.008,.50,hem-.008,.50,1.01,.08,1.01,.15,hem+.19,.23,hem+.10}
     or {.50,hem-.008,.80,hem-.008,.81,hem+.10,.93,hem+.19,.97,1.01,.50,1.01}
   if not side then
    local split=style=='jessie-hd'and(row==0 and .53 or .505)or(style=='jessie-voxel'and(row==0 and .52 or .55) or .50)
    if not profile.hair then
     poly=sign==1 and {.29,hem-.008,split,hem-.008,split,1.01,.08,1.01,.12,.84,.24,.78,.28,.72}
       or {split,hem-.008,.73,hem-.008,.74,.72,.84,.82,.97,1.01,split,1.01}
    elseif sign==1 then poly[3]=split;poly[5]=split
    else poly[1]=split;poly[#poly-1]=split end
   end
   if side then
    -- Boundary follows the near thigh, shin and toe in the original view.
    poly=profile.hair and {.43,hem-.008,.76,hem-.008,1.04,.76,1.08,1.01,.29,1.01,.29,.935,.54,.875,.49,.755}
       or {.34,hem-.008,.83,hem-.008,1.06,.83,1.08,1.01,.42,1.01,.42,.95,.56,.88,.47,.78}
    if row==3 then
     poly={};local absolute=rightLegs[style]
     for i=1,#absolute,2 do poly[i]=(absolute[i]-b[1])/bw;poly[i+1]=(absolute[i+1]-off-b[2])/bh end
     center=style=='jessie-voxel'and .48 or .39
    end
   end
   if profile.legPolys then poly=localPoly(profile.legPolys[row][side and 1 or(sign==1 and 1 or 2)])end
   local hipX,hipY=point(center,hem)
   local angle=(side and .31*facing or .035)*sign*swing
   local knee=profile.knee;local kx,ky=point(center,knee)
   local airborne=math.max(0,sign*math.sin(t))
   local bend=side and-.24*facing*airborne or 0
   local function warp(xx,yy)
    local k=bend*smooth(knee-.065,knee+.065,(yy-b[2])/bh)
    local dx,dy=xx-kx,yy-ky
    local xx2=kx+dx*math.cos(k)-dy*math.sin(k)
    local yy2=ky+dx*math.sin(k)+dy*math.cos(k)
    dx,dy=xx2-hipX,yy2-hipY
    local a=angle*smooth(hem,hem+.10,(yy-b[2])/bh)
    return hipX+dx*math.cos(a)-dy*math.sin(a),hipY+dx*math.sin(a)+dy*math.cos(a)
   end
   -- Keep a planted foot on the floor. The other foot clears it smoothly;
   -- the hip never detaches from the torso to enforce the ground constraint.
   local maxY=-math.huge
   for _,p in ipairs(bottoms[row])do
    local qx,qy=(p[1]-b[1])/bw,(p[2]-b[2])/bh;local inside=false;local j=#poly-1
    for i=1,#poly,2 do
     local ax,ay,bx,by=poly[i],poly[i+1],poly[j],poly[j+1]
     if (ay>qy)~=(by>qy)and qx<(bx-ax)*(qy-ay)/(by-ay)+ax then inside=not inside end;j=i
    end
    if inside then
     local _,yy=warp(p[1],p[2]);maxY=math.max(maxY,yy)
    end
   end
   local target=b[4]-bh*.020*airborne
   local stretch=(target-hipY)/(maxY-hipY)
   drawPart(poly,function(xx,yy)
    local x,y=warp(xx,yy)
    return x+(side and far and-.11*bw*facing*smooth(hem,hem+.10,(yy-b[2])/bh)or 0),hipY+(y-hipY)*stretch
   end,far and .91 or 1,true)
  end
  -- Far limbs are drawn behind the unchanged torso; toes never mirror.
  if side then leg(-1,true)else leg(1,false);leg(-1,false)end
  local leftArm={.17,shoulder,.32,shoulder+.02,.23,.51,.21,armEnd,-.04,armEnd,.00,.60}
  local rightArm={.69,shoulder+.02,.86,shoulder,1.04,.66,1.02,armEnd,.81,armEnd,.78,.51}
  local sideArm={.52,shoulder,.86,shoulder+.015,1.02,.61,1.02,armEnd,.51,armEnd,.53,.57}
  if row==3 then for i=1,#sideArm,2 do sideArm[i]=1-sideArm[i]end end
  if profile.armPolys then
   if side then sideArm=localPoly(profile.armPolys[row][1])
   else leftArm=localPoly(profile.armPolys[row][1]);rightArm=localPoly(profile.armPolys[row][2])end
  end
  if side then limb(sideArm,row==3 and .28 or .72,shoulder,.26*facing*swing,.86)end
  if side then leg(1,false)end
  -- Torso silhouette includes the full cap, head and hair. Only the side
  -- arm's covered shirt strip is sampled from its neighbouring fabric.
  shader:send('fillArm',side and 1 or 0)
  local body=side and {-3,-.02,3,-.02,3,shoulder,.88,shoulder+.015,.88,hem,.08,hem,.08,shoulder,-3,shoulder}
    or {-3,-.02,3,-.02,3,shoulder,.77,shoulder,.72,.59,.76,hem,.25,hem,.28,.59,.22,shoulder,-3,shoulder}
  if row==3 then for i=1,#body,2 do body[i]=1-body[i]end end
  shader:send('bodyPass',1);texture(body);shader:send('bodyPass',0);shader:send('fillArm',0)
  if side then
   limb(sideArm,row==3 and .28 or .72,shoulder,-.26*facing*swing,1)
  else
   limb(leftArm,.18,shoulder,.07*swing,1,1-.12*math.max(0,-math.sin(t)))
   limb(rightArm,.82,shoulder,-.07*swing,1,1-.12*math.max(0,math.sin(t)))
  end
  if profile.hair then shader:send('hairLayer',1);g.setColor(1,1,1,1);g.draw(image,q,0,0)end
  g.setShader();q:release()
 end
 local api={boxes=boxes}
 function api.render(kind,columns)
  local canvas=g.newCanvas(P.cellWidth*columns,P.cellHeight*4,{dpiscale=1})
  local cell=g.newCanvas(P.cellWidth,P.cellHeight,{dpiscale=1})
  cell:setFilter('nearest','nearest')
  g.push('all');g.setCanvas(canvas);g.origin();g.clear(0,0,0,0);g.setShader();g.setScissor()
  for row=0,3 do for col=0,columns-1 do
   -- Rasterize in a small, identical coordinate space. Drawing the joints
   -- directly at x>4096 changed antialiased head pixels in wide 24-frame atlases.
   g.setCanvas({cell,stencil=true});g.origin();g.clear(0,0,0,0);g.setBlendMode('alpha')
   local b=boxes[row];local scale=P.referenceHeight/(b[4]-b[2])
   g.translate(P.anchorX-(b[1]+b[3])/2*scale,P.anchorY-b[4]*scale);g.scale(scale,scale)
   pose(row,col/columns,kind=='walk',kind=='blink'and({0,.5,1,0})[col+1]or 0)
   g.setStencilTest();g.setShader();g.setCanvas(canvas);g.origin();g.setColor(1,1,1,1)
   g.setBlendMode('alpha','premultiplied');g.draw(cell,col*P.cellWidth,row*P.cellHeight)
  end end
  g.pop();local result=canvas:newImageData();cell:release();canvas:release();return result
 end
 function api.release()image:release();shader:release()end
 return api
end
return P
