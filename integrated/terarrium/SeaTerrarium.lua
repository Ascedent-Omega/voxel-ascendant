-- Project Terrarium / Kanto Sea V2. Visual direction: ODias.
-- New interior; the host keeps its original opaque shell, neutral button and branding.
-- Lua 5.1 / LuaJIT. No assets, map mutations, RNG state or external module dependencies.
local R = {revision='kanto-sea-v2-reference-handheld', waterY=-0.08, radius=73.5, battleY=-30}
-- A clear central water column, with only selected peripheral reef shoulders rising.
local function reefLimit(x,z,r,tx)
 r=r or 0
 if (x-tx)^2+(z+25)^2<(19+r)^2 then return -44 end
 local radial=math.sqrt(x*x+z*z)
 if z>18 and math.abs(x)<35 then return -42 end
 if radial>43 then return -31.5 end
 if radial>32 then return -34.5 end
 return -44
end

-- Explicit dispatch key. The host decides which Kanto ocean encounters use this key.
function R.appliesTo(id) return id=='KANTO_SEA' end
function R.button(h) end -- Preserve the host's NEUTRAL Pokeball button.
-- Sea-only setup hook, before arena placement/cache creation. Standard side X
-- spacing is retained; the two shelves move rearward to match the supplied V2 view.
-- The rear-camera layout retains its standard X/Z and uses deeper compact shelves.
-- The actor foot adapter must honor p[2] when this marker is present (see README).
function R.configureSetup(setup)
 assert(setup and setup.actors,'Sea requires the actual host actor setup')
 for _,side in ipairs({'player','enemy'})do
  setup.actors[side][2]=setup.cameraMode=='behind' and -38 or R.battleY
  if setup.cameraMode~='behind' then setup.actors[side][3]=-36 end
 end
 setup.seaActorHeight=true
 return setup
end

local sin,cos,sqrt,pi = math.sin,math.cos,math.sqrt,math.pi
local function innerY(x,z)
 return -1-66*sqrt(math.max(0,1-(x*x+z*z)/(73.5*73.5)))
end
local function key(x,z) return x..':'..z end
local function noise(x,z) return (sin(x*17.31+z*43.17)*437.58)%1 end
local sand={{.72,.735,.59},{.735,.75,.615},{.75,.765,.63},{.70,.73,.595},{.72,.75,.62}}
local rock={{.27,.40,.43},{.32,.46,.48},{.39,.51,.51},{.43,.54,.51},{.33,.44,.44}}
local coral={{.88,.23,.43},{.92,.43,.52},{.65,.32,.79},{.28,.53,.83},{.88,.50,.26}}
local kelp={{.28,.55,.24},{.36,.66,.26},{.48,.71,.29},{.25,.56,.42}}

-- The tiled terrain follows the INNER bowl. Each tile is a connected surface,
-- with only exposed risers; no solid blocks extend through the porcelain.
local function terrain()
 local cells={}
 for ix=-17,17 do for iz=-17,17 do
  local x,z=ix*4,iz*4
  local far=sqrt((math.abs(x)+2)^2+(math.abs(z)+2)^2)
  if far<65.2 then
   local mound=3*sin(x*.075)*sin(z*.085)+2*cos((x-z)*.075)
   local y=math.ceil(math.max(-60+mound,innerY(far,0)+2.4)/2)*2
   if (x-8)^2+(z+8)^2<15^2 then y=-60 end
   cells[key(ix,iz)]={x=x,z=z,y=y,ix=ix,iz=iz}
  end
 end end
 return cells
end

function R.build(h,setup)
 assert(h and type(h.quad)=='function','SeaTerrarium.build requires host quad')
 assert(setup and setup.trainers and setup.actors,'SeaTerrarium requires unchanged host participant setup')
 assert(setup.seaActorHeight==true,'Call Sea.configureSetup before building/placing Sea actors')
 local tentX=setup.cameraMode=='behind' and -17 or -8
 local function reefCeiling(x,z,r)return reefLimit(x,z,r,tentX)end
 local Q=h.quad
 -- group is optional, useful to hosts that maintain separate scenery submeshes.
 local currentGroup,handheldOrigin
 local function group(s) currentGroup=s;if h.group then h.group(s) end end
 local function quad(a,b,c,d,col,shade)
  if currentGroup=='tentacool' then
   -- A single rigid scale/translation keeps every body part below the surface.
   -- Crown Y=-20.50, lowest tentacle Y=-40.94: 20.42 units of water above.
   local function mid(p)return {tentX+(p[1]+15)*.8,-20.5+(p[2]+11.6)*.8,-25+(p[3]+29)*.8}end
   a,b,c,d=mid(a),mid(b),mid(c),mid(d)
  elseif currentGroup=='lost_handheld' then
   -- A worn object leaning back in the sand; every detail shares one rigid pose.
   local function tilt(p)
    local xx=p[1];local yy=p[2]*.906307+p[3]*.422618
    local zz=-p[2]*.422618+p[3]*.906307
    return {handheldOrigin[1]+xx*.939693+zz*.342020,
     handheldOrigin[2]+yy,handheldOrigin[3]-xx*.342020+zz*.939693}
   end
   a,b,c,d=tilt(a),tilt(b),tilt(c),tilt(d)
  end
  Q(a,b,c,d,col,shade or 1)
 end
 local function box(x,y,z,w,ht,d,col)
  local a,b,e,f,t=x-w/2,x+w/2,z-d/2,z+d/2,y+ht
  quad({a,t,e},{b,t,e},{b,t,f},{a,t,f},col)
  quad({a,y,f},{b,y,f},{b,t,f},{a,t,f},col,.83)
  quad({b,y,e},{a,y,e},{a,t,e},{b,t,e},col,.68)
  quad({b,y,f},{b,y,e},{b,t,e},{b,t,f},col,.89)
  quad({a,y,e},{a,y,f},{a,t,f},{a,t,e},col,.74)
 end
 local cells=terrain()
 local function floorAt(x,z)
  local p=cells[key(math.floor(x/4+.5),math.floor(z/4+.5))]
  return p and p.y or innerY(x,z)+2.4
 end
 local function footY(x,z,r)
  local y=floorAt(x,z)
  for _,dx in ipairs({-r,r})do for _,dz in ipairs({-r,r})do
   y=math.max(y,floorAt(x+dx,z+dz))
  end end
  return y
 end
 local function column(x,z,w,d,top,col)
  -- A pillar is divided at terrain cell boundaries, rooting every visible foot.
  local x0,x1,z0,z1=x-w/2,x+w/2,z-d/2,z+d/2
  for ix=math.floor((x0+2)/4),math.floor((x1+2-1e-6)/4)do
   for iz=math.floor((z0+2)/4),math.floor((z1+2-1e-6)/4)do
    local a,b=math.max(x0,ix*4-2),math.min(x1,ix*4+2)
    local c,dz=math.max(z0,iz*4-2),math.min(z1,iz*4+2)
    local far=sqrt(math.max(math.abs(a),math.abs(b))^2+math.max(math.abs(c),math.abs(dz))^2)
    local y=math.max(floorAt(ix*4,iz*4),innerY(far,0)+.3)
    if top>y then box((a+b)/2,y,(c+dz)/2,b-a,top-y,dz-c,col)end
   end
  end
 end
 local function beveled(x,y,z,w,ht,d,col)
  local cut=math.min(w,d)*.17
  local p={{-w/2+cut,-d/2},{w/2-cut,-d/2},{w/2,-d/2+cut},{w/2,d/2-cut},
   {w/2-cut,d/2},{-w/2+cut,d/2},{-w/2,d/2-cut},{-w/2,-d/2+cut}}
  for i,a in ipairs(p)do local b=p[i%8+1]
   quad({x+a[1],y,z+a[2]},{x+b[1],y,z+b[2]},
    {x+b[1]*.92,y+ht,z+b[2]*.92},{x+a[1]*.92,y+ht,z+a[2]*.92},col,.77+.12*sin(i*.8))
   quad({x,y+ht,z},{x+a[1]*.92,y+ht,z+a[2]*.92},
    {x+b[1]*.92,y+ht,z+b[2]*.92},{x,y+ht,z},col)
  end
 end

 group('inner_porcelain')
 -- Uncovered areas preserve a readable porcelain liner. The exterior is host-owned.
 for j=0,15 do
  local a,b=j*pi/32,(j+1)*pi/32
  local ra,rb=73.5*sin(a),73.5*sin(b)
  local ya,yb=-1-66*cos(a),-1-66*cos(b)
  local c={.17+j*.013,.33+j*.016,.39+j*.017}
  for i=0,95 do local u,v=i*pi/48,(i+1)*pi/48
   quad({ra*cos(u),ya,ra*sin(u)},{ra*cos(v),ya,ra*sin(v)},
    {rb*cos(v),yb,rb*sin(v)},{rb*cos(u),yb,rb*sin(u)},c,.87+.07*sin(u))
  end
 end
 for i=0,95 do local u,v=i*pi/48,(i+1)*pi/48
  quad({73.5*cos(u),-1,73.5*sin(u)},{73.5*cos(v),-1,73.5*sin(v)},
   {73.5*cos(v),0,73.5*sin(v)},{73.5*cos(u),0,73.5*sin(u)},{.58,.70,.68},.88)
 end

 group('seabed')
 for ix=-17,17 do for iz=-17,17 do
  local p=cells[key(ix,iz)]
  if p then
   local x,z,y=p.x,p.z,p.y
   local c=sand[1+math.floor(noise(ix,iz)*#sand)]
   -- Rocky reef substrate merges with the curved walls; sand collects in the
   -- sheltered central valley and a few side pockets rather than coating it all.
   if (math.abs(x)>23 or z<-37) and noise(ix+31,iz+17)>.18 then
    c=rock[2+math.floor(noise(ix+4,iz)*3)]
   end
   quad({x-2,y,z-2},{x+2,y,z-2},{x+2,y,z+2},{x-2,y,z+2},c)
   local sides={{-1,0,x-2,z+2,x-2,z-2},{1,0,x+2,z-2,x+2,z+2},
    {0,-1,x-2,z-2,x+2,z-2},{0,1,x+2,z+2,x-2,z+2}}
   for _,s in ipairs(sides)do
    local n=cells[key(ix+s[1],iz+s[2])]
    local low=n and n.y or math.max(innerY(s[3],s[4]),innerY(s[5],s[6]))+.2
    if low<y then quad({s[3],low,s[4]},{s[5],low,s[6]},
     {s[5],y,s[6]},{s[3],y,s[4]},c,.77)end
   end
  end
 end end

 -- Branching voxel corals are occupancy unions: hidden touching faces are omitted.
 local function voxels(cx,cy,cz,step,list,base)
  local set={}
  local function vk(x,y,z)return x..':'..y..':'..z end
  for _,p in ipairs(list)do set[vk(p[1],p[2],p[3])]=p end
  local dirs={{1,0,0},{-1,0,0},{0,1,0},{0,-1,0},{0,0,1},{0,0,-1}}
  for _,p in ipairs(list)do
   if set[vk(p[1],p[2],p[3])]==p then
    local x,y,z=cx+p[1]*step,cy+p[2]*step,cz+p[3]*step
    local a,b,e,f,t=x-step/2,x+step/2,z-step/2,z+step/2,y+step
    local faces={{{b,y,f},{b,y,e},{b,t,e},{b,t,f}},{{a,y,e},{a,y,f},{a,t,f},{a,t,e}},
     {{a,t,e},{b,t,e},{b,t,f},{a,t,f}},{{a,y,f},{b,y,f},{b,y,e},{a,y,e}},
     {{a,y,f},{b,y,f},{b,t,f},{a,t,f}},{{b,y,e},{a,y,e},{a,t,e},{b,t,e}}}
    for i,d in ipairs(dirs)do if not set[vk(p[1]+d[1],p[2]+d[2],p[3]+d[3])]then
     local f0=faces[i];quad(f0[1],f0[2],f0[3],f0[4],base,({.89,.73,1,.64,.85,.70})[i])
    end end
   end
  end
 end
 local function branch(x,z,y,s,c,seed)
  local v={}
  local function add(a,b,d)v[#v+1]={a,b,d}end
  for k=0,6 do add(0,k,0)end
  for _,arm in ipairs({{-1,2,4},{1,3,6}})do
   local sign,start,finish=arm[1],arm[2],arm[3]
   add(sign,start,0);add(sign*2,start,0)
   for k=start,finish do add(sign*2,k,0)end
  end
  for k=1,3 do add(0,k,1)end
  add(0,3,2);add(0,4,2)
  add(0,1,-1);add(0,2,-1);add(0,2,-2);add(0,3,-2);add(0,4,-2)
  add(-1,1,0);add(1,1,0)
  add(-2,3,1);add(-2,4,1);add(2,4,-1);add(2,5,-1)
  add(0,4,1);add(1,4,1);add(1,5,1)
  -- Secondary forks fill out the colony in depth, keeping its reserved footprint.
  add(-1,3,1);add(-1,4,1);add(-1,5,1)
  add(1,2,-1);add(1,3,-1);add(1,4,-1)
  add(-1,2,-1);add(-1,3,-1);add(-1,4,-1)
  add(1,3,2);add(1,4,2);add(1,5,2)
  add(-1,3,-2);add(-1,4,-2);add(-1,5,-2)
  if seed%2==0 then add(1,5,0);add(1,6,0);add(0,7,0)end
  voxels(x,y,z,s,v,c)
 end
 -- Two natural standing formations follow the ACTUAL host actor anchors.
 -- Their tops meet the configured Sea actor height. The spine meets the existing reef,
 -- avoiding both decorative Pokemon and preserving the central water column.
 local battleForms={}
 group('battle_reef')
 for n,side in ipairs({'player','enemy'})do
  local p=setup.actors[side];local dx,dz
  if setup.cameraMode=='behind' then
   dx,dz=(side=='player' and -2 or 3),(side=='player' and 2 or -13)
  else dx,dz=(side=='player' and -3 or 3),0 end
  local rx,rz=p[1]+dx,p[3]+dz
  local base=math.max(-56,footY(rx,rz,10.5)+.7)
  column(rx,rz,20,19,base,rock[2])
  local tiers={}
  for k=0,3 do
   local f=1-k/3
   local x,z=p[1]+dx*f,p[3]+dz*f
   local low=base+(p[2]-.7-base)*k/4
   local high=base+(p[2]-.7-base)*(k+1)/4
   local w,d=13.8+6.2*f,12.5+6.5*f
   beveled(x,low,z,w,high-low,d,rock[(k+n)%5+1])
   tiers[#tiers+1]={x,z,w,d,low,high}
  end
  -- A small irregular voxel sand cap: flat at the exact standing height.
  for ix=-4,4 do for iz=-3,3 do
   local x,z=ix*1.6,iz*1.6
   if (x/7.3)^2+(z/6.1)^2<1 then
    box(p[1]+x,p[2]-.7,p[3]+z,1.6,.7,1.6,sand[2+(ix+iz+20)%3])
   end
  end end
  battleForms[#battleForms+1]={tiers=tiers,anchor=p,root={rx,rz},base=base}
 end
 local function clearOfBattle(x,z,r,low,high)
  for _,form in ipairs(battleForms)do for _,q in ipairs(form.tiers)do
   if high>q[5] and low<q[6] and math.abs(x-q[1])<q[3]*.5+r+.4
    and math.abs(z-q[2])<q[4]*.5+r+.4 then return false end
  end end
  return true
 end

 -- Broad, terraced reef walls form an asymmetric horseshoe, not an even ring.
 -- Each visible foot is split at terrain steps and rooted inside the curved bowl.
 local reefs={}
 local wallSites={{-42,-25,11,11},{-34,-38,10,10},{-46,-8,10,12},
  {38,-25,12,11},{43,-6,10,12},{32,13,11,10},{-29,7,11,10},
  {-22,24,10,9},{18,-43,10,10},{32,-40,9,9},{-4,-48,10,9},
  {-40,20,9,9},{-13,36,9,8},{27,32,9,8},{-46,-31,8,8}}
 group('reef_rock')
 for n,p in ipairs(wallSites)do
  local x,z,w,d=p[1],p[2],p[3],p[4]
  for _,side in ipairs({'player','enemy'})do local tr=setup.trainers[side]
   if math.abs(x-tr[1])<w*.6+7 and math.abs(z-tr[3])<d*.6+7 then
    x=tr[1]+(x<tr[1] and -1 or 1)*(w*.6+8)
   end
  end
  local y=footY(x,z,math.max(w,d)*.5)
  local top=math.max(y+.6,math.min(y+1.2+n%2,reefCeiling(x,z,5)-10))
  column(x,z,w,d,top-1.2,rock[n%5+1])
  beveled(x,top-1.2,z,w,1.2,d,rock[(n+1)%5+1])
  -- A narrower second shoulder breaks the silhouette and gives natural ledges.
  local bx,bz=x-w*.19,z-d*.16
  beveled(bx,top,bz,w*.55,1.0,d*.57,rock[(n+2)%5+1])
  reefs[#reefs+1]={x,z,w,d,top+1}
 end

 -- A real recess under an open lintel; its piers connect to the seabed.
 group('reef_cavity')
 column(23,2,3.2,4,-51,rock[2]);column(32,2,3.2,4,-51,rock[2])
 box(27.5,-51,2,12.2,2.4,4,rock[4])
 box(27.5,-48.6,2,8,.8,3.5,rock[3])

 -- All colonies reserve their full footprint. Nearby siblings form clusters,
 -- while a winding sandy valley and Staryu's pocket are left open.
 local occupied={{27.5,2,7},{-13,-18,3.1}}
 local function baseAt(x,z,r)
  local y=footY(x,z,r)
  for _,q in ipairs(reefs)do
   if math.abs(x-q[1])<q[3]*.5+r and math.abs(z-q[2])<q[4]*.5+r then
    y=math.max(y,q[5])
   end
  end
  return y
 end
 local function site(wantX,wantZ,r,headroom)
  for attempt=0,2500 do
   local a=attempt*2.399963;local shift=attempt==0 and 0 or .85*sqrt(attempt)
   local x,z=wantX+cos(a)*shift,wantZ+sin(a)*shift
   local good=x*x+z*z<(57-r)^2 and (x-8)^2+(z+8)^2>(14+r)^2
   -- The channel narrows and bends in front of the deep sandy pocket.
   if z>5 and z<43 and math.abs(x-(7-.28*z))<3+r then good=false end
   for _,side in ipairs({'player','enemy'})do local tr=setup.trainers[side]
    if math.abs(x-tr[1])<r+7.5 and math.abs(z-tr[3])<r+7.5 then good=false end
   end
   for _,q in ipairs(occupied)do
    if (x-q[1])^2+(z-q[2])^2<(r+q[3]+.35)^2 then good=false end
   end
   if good then
    local y=baseAt(x,z,r);local cap=reefCeiling(x,z,r)
    if cap-y>=headroom and clearOfBattle(x,z,r,y,cap) then
     occupied[#occupied+1]={x,z,r}
     return x,z,y,cap
    end
   end
  end
  error('No connected reef site near '..wantX..','..wantZ)
 end
 local function plinth(x,z,y,r,n)
  column(x,z,r*1.7,r*1.65,y+.55,rock[n%5+1])
  beveled(x,y+.55,z,r*1.72,.55,r*1.67,rock[(n+1)%5+1])
  return y+1.1
 end

 -- Shelving coral alternates wider plates and low encrusting cushions.
 group('plate_coral')
 for n,p in ipairs({{-37,-40},{41,-17},{-28,0},{22,-41},{33,13},
  {-18,31},{-37,13},{31,29},{-9,-47},{-32,-28}})do
  local x,z,y,cap=site(p[1],p[2],4.4,3.8);y=plinth(x,z,y,3.8,n)
  local rise=math.min(1,(cap-y)/3.1)
  column(x,z,2.4,2.4,y+2.5*rise,rock[3])
  for j=0,2 do
   beveled(x,y+(.35+j*.95)*rise,z,7.6-j*1.25,.65*rise,6.1-j*.75,coral[(n+1)%5+1])
  end
 end

 -- Branching thickets: larger violet/pink communities on the left, warmer
 -- red/salmon on the right, with small low colonies filling the deep foothills.
 group('coral')
 local thickets={{-42,-25,3},{-32,-37,1},{-44,-7,2},{37,-24,1},
  {42,-4,3},{29,16,2},{-27,8,1},{-21,25,3},{15,-42,4},
  {31,-40,5},{-3,-48,2},{-39,20,3},{-18,-12,3},{25,-15,1},
  {-13,13,2},{19,23,1},{-29,-19,3},{-21,-46,4},{-34,32,2},
  {34,31,1},{-12,35,3},{-26,-2,2},{40,-34,1},{-39,-37,3}}
 for n,p in ipairs(thickets)do
  local r=n<13 and 3.1 or 2.45
  local x,z,y,cap=site(p[1],p[2],r,n<13 and 8 or 6.8)
  local floor=plinth(x,z,y,r,n)
  local step=math.min(r/2.6,(cap-floor)/8,n<13 and 1.05 or .8)
  branch(x,z,floor,step,coral[p[3]],n)
 end
 -- Fine branching colonies enrich the deep garden edges, not the open sea.
 for n,p in ipairs({{-15,12},{20,18},{-26,30},{32,24},{-30,-31},
  {27,-38},{-14,-40},{-34,7},{-7,33},{20,35},{-38,27},{40,17}})do
  local x,z,y,cap=site(p[1],p[2],1.7,4.8);y=plinth(x,z,y,1.55,n)
  branch(x,z,y,math.min(.54,(cap-y)/8),coral[(n+1)%5+1],n)
 end

 -- Tube mouths are recessed dark squares, in compact five-stem colonies.
 group('reef_sponges')
 for n,p in ipairs({{-35,-16},{34,-15},{-23,17},{25,24},{-12,-43},
  {27,-34},{-43,6},{-29,32},{39,14},{-20,-30}})do
  local x,z,y,cap=site(p[1],p[2],3.3,5.5);y=plinth(x,z,y,3.3,n)
  local col=({{.25,.63,.73},coral[2],coral[5],coral[3]})[n%4+1]
  for j=0,4 do
   local a=j*2*pi/5;local cx,cz=x+cos(a)*1.8,z+sin(a)*1.7
   local ht=math.min(2.3+(n+j)%3,cap-y-.08)
   beveled(cx,y,cz,1.65,ht,1.65,col)
   box(cx,y+ht+.012,cz,.65,.025,.65,{.16,.23,.29})
  end
 end

 -- Fan coral has a different flat, branching silhouette from the upright thickets.
 group('fan_coral')
 for n,p in ipairs({{-42,-14},{35,-7},{-25,-40},{24,34},{-32,22},{44,6}})do
  local x,z,y,cap=site(p[1],p[2],3,4.7);y=plinth(x,z,y,2.7,n)
  local v={};local step=math.min(.82,(cap-y)/7)
  for k=0,5 do v[#v+1]={0,k,0}end
  for _,sign in ipairs({-1,1})do
   for k=1,3 do
    v[#v+1]={sign*k,k+1,0};v[#v+1]={sign*(k-1),k+1,0}
    v[#v+1]={sign*k,k+2,0};v[#v+1]={sign*k,k+3,0}
   end
  end
  voxels(x,y,z,step,v,coral[n%2+1])
 end

 group('marine_plants')
 local gardens={{-48,-23},{-44,-34},{-31,-47},{-14,-49},{24,-48},
  {44,-28},{47,-13},{45,14},{37,24},{20,32},{-32,30},{-45,7},
  {-34,-6},{23,-28},{-21,6},{-25,-23},{-8,27},{34,5}}
 for n,p in ipairs(gardens)do
  local x,z,y,cap=site(p[1],p[2],2.5,7.0);y=plinth(x,z,y,2.25,n)
  for j=-1,1 do
   local ht=math.min(5+(n+j*3)%6,math.floor(cap-y))
   for k=0,ht-1 do
    local bend=sin(k*.5+n)*.4
    box(x+j*1.3+bend,y+k,z+(j%2)*.6,.70,1,.65,kelp[(n+j+8)%4+1])
    if k%3==1 and k<ht-1 then
     box(x+j*1.3+bend+.3,y+k+.35,z+(j%2)*.6,1.3,.4,.65,kelp[(n+j+9)%4+1])
    end
   end
  end
 end

 -- Short coral shelves grow directly from selected exposed rock faces. These
 -- connected encrusting patches break up bare walls without changing the layout.
 group('coral')
 for n,q in ipairs(reefs)do
  local x,z=q[1]+q[3]*.13,q[2]+q[4]*.5+.12
  local y=math.min(q[5]-5,reefCeiling(x,z,2)-3)
  local good=y>footY(x,z,1.5)+1.2 and clearOfBattle(x,z,2,y,y+2.5)
  for _,p in ipairs(occupied)do if (x-p[1])^2+(z-p[2])^2<(p[3]+1.8)^2 then good=false end end
  if good then
   occupied[#occupied+1]={x,z,1.8}
   for j=0,2 do
    beveled(x-j*.25,y+j*.7,z,3.1-j*.45,.38,1.55-j*.2,coral[n%5+1])
   end
  end
 end
 group('marine_plants')

 -- Fine low growth between the major colonies, increasingly dense near the floor.
 -- Smaller seagrass communities knit the lower shelves together without filling
 -- the central passage or raising more objects into Tentacool's water layer.
 for n,p in ipairs({{-38,-20},{-34,11},{-29,28},{-19,34},{-19,-4},
  {31,-26},{38,9},{31,29},{20,30},{20,-31},{-37,-33},{36,-37}})do
  local x,z,y,cap=site(p[1],p[2],1.65,4.0);y=plinth(x,z,y,1.5,n)
  for j=-1,1 do
   local ht=math.min(3+(n+j+6)%3,math.floor(cap-y))
   for k=0,ht-1 do
    box(x+j*.85+sin(k+n)*.18,y+k,z+(j%2)*.55,.55,1,.55,kelp[(n+j+8)%4+1])
   end
  end
 end

 group('seabed_details')
 for n,p in ipairs({{-17,20},{19,14},{-32,14},{34,-30},{-28,-12},
  {-7,-41},{13,32},{-32,38},{-41,27},{41,24},{-44,-41},{37,-41},
  {-16,-37},{22,-23},{-37,-3},{27,18},{-24,37},{-8,39}})do
  local x,z,y,cap=site(p[1],p[2],1.35,1.8)
  y=plinth(x,z,y,1.2,n)
  for j=0,2 do
   beveled(x+(j-1)*.65,y,z+sin(j*2)*.5,1.05,.35+(j%2)*.28,1.0,coral[(n+2)%5+1])
  end
 end
 -- Small rubble stays on its own terrain cell and out of all organism footprints.
 -- Encrusting growth attaches to exposed rock shoulders, sharing their exact top.
 for n,q in ipairs(reefs)do
  local x,z=q[1]-q[3]*.19,q[2]-q[4]*.16;local y=q[5]
  local good=y+1.5<reefCeiling(x,z,1.4) and clearOfBattle(x,z,1.5,y,y+1.5)
  for _,p in ipairs(occupied)do if (x-p[1])^2+(z-p[2])^2<(p[3]+1.5)^2 then good=false end end
  if good then
   occupied[#occupied+1]={x,z,1.5}
   beveled(x,y,z,2.6,.6,2.5,coral[n%5+1])
   beveled(x-.35,y+.6,z+.15,1.3,.5,1.4,coral[n%5+1])
  end
 end
 for i=1,180 do
  local x,z=(noise(i,12)-.5)*110,(noise(6,i)-.5)*110
  local good=x*x+z*z<55^2 and (x-8)^2+(z+8)^2>14^2
  for _,q in ipairs(occupied)do if (x-q[1])^2+(z-q[2])^2<(q[3]+1.1)^2 then good=false end end
  if good then
   local w=.8+noise(i,22)*1.2;local y=baseAt(x,z,w*.5)
   if clearOfBattle(x,z,w,y,y+.45)then column(x,z,w,w*.8,y+.45,rock[i%5+1])end
  end
 end

 -- ONE removable easter egg, set off the deep passage in a small worn cradle.
 -- Its lower back edge rests on the same sand height; adjacent stones hide a corner.
 group('seabed_details')
 local eggY=footY(-13,-18,1.65)
 column(-13,-18,3.0,2.2,eggY,sand[4])
 column(-15.4,-18.4,1.05,1.3,eggY+1.1,rock[3])
 column(-11.25,-18.8,.9,1.1,eggY+.8,rock[2])
 column(-12.4,-16.55,1.0,.85,eggY+.8,rock[3])
 group('lost_handheld');handheldOrigin={-13,eggY+.17,-18}
 local yellow={.78,.65,.27};local black={.025,.035,.040}
 -- Compact Color-style case with stepped corners; its original resting pose stays fixed.
 box(0,0,0,2.08,.25,.8,yellow)
 box(0,.25,0,2.45,3.55,.8,yellow)
 box(0,3.8,0,2.12,.22,.8,yellow)
 box(-.02,1.87,.405,1.91,1.61,.09,{.20,.23,.22})
 box(-.02,2.12,.51,1.43,1.06,.045,{.055,.095,.105})
 box(-.62,.64,.415,.27,.86,.11,black)
 box(-.62,.935,.415,.83,.27,.11,black)
 box(.48,.87,.43,.36,.36,.12,black)
 box(.91,1.17,.43,.36,.36,.12,black)
 box(-.25,.30,.42,.35,.13,.10,black)
 box(.30,.30,.42,.35,.13,.10,black)
 box(-.86,3.59,.41,.38,.10,.04,{.57,.53,.30})

 group('surface_rocks')
 -- Small weathered tips hug the curved rear wall instead of free-standing towers.
 for n,p in ipairs({{-39,-50,4},{14,-62,3}})do
  local x,z,t=p[1],p[2],p[3]
  column(x,z,9,8,-4,rock[2])
  beveled(x,-4,z,8,t+4,7,rock[3])
  beveled(x-.6,t,z-.3,5,.6,4.5,{.57,.61,.55})
 end

 group('trainer_supports')
 -- Host platforms stay at their original anchors. Real narrow rock supports join
 -- their undersides to the seabed; the host still draws the standard pads/steps.
 for _,side in ipairs({'player','enemy'})do
  local p=setup.trainers[side];local x,z=p[1],p[3]
  column(x,z,13,12,-20,rock[2]);column(x-.4,z,11,10.5,-10,rock[3])
  column(x,z,9.5,9.5,-4,rock[2]);box(x,-4,z,12.5,4,12.5,rock[3])
  if setup.cameraMode=='behind' then
   local d=z>0 and -1 or 1;column(x,z+d*8,8,3,0,rock[3])
  else
   local d=x>0 and -1 or 1;column(x+d*8,z,3,8,0,rock[3])
  end
 end

 group('tentacool')
 local tx,tz=-15,-29
 local blue,light,dark={.24,.59,.76},{.40,.74,.86},{.13,.35,.49}
 box(tx,-23,tz,10.5,2,8.0,blue)
 box(tx,-21,tz,13,3.5,10,blue)
 box(tx,-17.5,tz,11,3,8.5,light)
 box(tx,-14.5,tz,7.8,2.0,6.3,light)
 box(tx,-12.5,tz,4.5,.9,3.8,blue)
 -- Two large red sensory orbs, with lit crown facets.
 for _,s in ipairs({-1,1})do
  box(tx+s*4.7,-18,tz+.2,3.8,4.8,4.7,{.71,.16,.26})
  box(tx+s*4.7,-16.9,tz+.65,3.9,3.1,4.3,{.86,.27,.36})
  box(tx+s*4.5,-13.8,tz+.5,2.7,.8,3.0,{.95,.42,.47})
  box(tx+s*2.9,-22.3,tz+5.02,2.5,2.8,.45,{.87,.94,.89})
  box(tx+s*2.7,-22.0,tz+5.48,1.0,1.9,.22,{.045,.11,.16})
  box(tx+s*2.9,-20.25,tz+5.72,.55,.5,.1,{.98,1,1})
 end
 box(tx,-23.7,tz+1.0,7,.8,5,dark)
 -- Two continuous squared tentacles, with small connected bends and curled tips.
 for _,s in ipairs({-1,1})do
  local px,pz=tx+s*3.4,tz+1.2
  local lastX,lastZ=px,pz
  for k=0,13 do
   local x=px+s*math.sin(k*.48)*1.1
   local z=pz+math.sin(k*.31)*1.4
   local w,d=math.abs(x-lastX)+.85,math.abs(z-lastZ)+.85
   box((x+lastX)/2,-24.6-k*.95,(z+lastZ)/2,w,1.02,d,{.58,.65,.58})
   lastX,lastZ=x,z
  end
  box(lastX+s*.55,-37.15,lastZ,1.8,.9,.85,{.67,.70,.59})
 end

 group('staryu')
 -- Five pointed, stepped voxel star. Its underside rests on the deepest sand.
 local sx,sz=8,-8;local sy=-60
 local polygon={}
 for i=0,9 do
  local a=-pi/2+i*pi/5;local r=(i%2==0)and 9 or 3.9
  polygon[#polygon+1]={r*cos(a),r*sin(a)}
 end
 local function inStar(x,z)
  local yes=false;local j=#polygon
  for i=1,#polygon do
   local a,b=polygon[i],polygon[j]
   if (a[2]>z)~=(b[2]>z) and x<(b[1]-a[1])*(z-a[2])/(b[2]-a[2])+a[1]then yes=not yes end
   j=i
  end
  return yes
 end
 local list={};local unit=1.05
 for x=-9,9 do for z=-9,9 do if inStar(x*unit,z*unit)then
  list[#list+1]={x,0,z}
  if inStar(x*unit*1.23,z*unit*1.23)then list[#list+1]={x,1,z}end
 end end end
 voxels(sx,sy,sz,unit,list,{.68,.47,.19})
 box(sx,sy+2.1,sz,5.4,.8,5.4,{.91,.68,.25})
 box(sx,sy+2.9,sz,3.5,.8,3.5,{.63,.13,.19})
 box(sx,sy+3.7,sz,2.5,.6,2.5,{.90,.22,.28})
 box(sx-.35,sy+4.3,sz-.35,.9,.13,.8,{1,.64,.46})
end

-- One horizontal water surface. Sixth argument is ALPHA, never opaque shade.
-- No transparent side walls, stacked blue slabs, physical divider or closed dome.
function R.buildWater(h)
 assert(h and type(h.quad)=='function','buildWater requires an RGBA quad collector')
 for i=0,95 do local a,b=i*pi/48,(i+1)*pi/48
  h.quad({0,R.waterY,0},{73.5*cos(a),R.waterY,73.5*sin(a)},
   {73.5*cos(b),R.waterY,73.5*sin(b)},{0,R.waterY,0},{.055,.40,.61},.25)
 end
end

-- Allocate once per arena cache entry. Draw in the SAME depth-backed 3D canvas,
-- after opaque scenery/participants and before above-water translucent FX + HUD.
-- Alpha depth-test keeps the original shell and everything above water opaque.
function R.newWaterRenderer(api)
 assert(api and api.Voxel3D and api.Mat4,'Water renderer requires Voxel3D and Mat4')
 local g=love.graphics;local mesh,shader;local S={}
 local function init()
  local v={}
  R.buildWater({quad=function(a,b,c,d,rgb,alpha)
   -- Each fan quad is one nondegenerate triangle, not two coincident surfaces.
   for _,p in ipairs({a,b,c})do v[#v+1]={p[1],p[2],p[3],rgb[1],rgb[2],rgb[3],alpha}end
  end})
  local ok,err=pcall(function()
   mesh=g.newMesh({{'VertexPosition','float',3},{'VertexColor','float',4}},v,'triangles','static')
   shader=g.newShader([[
    uniform float seaTime;
    varying vec2 seaXZ;
    vec4 effect(vec4 color, Image tex, vec2 uv, vec2 screen) {
     vec2 p=seaXZ;
     float w=sin(p.x*.20+p.y*.31+seaTime*.55)*sin(p.y*.36-p.x*.08-seaTime*.38);
     float ripple=smoothstep(.48,.90,w);
     float rim=smoothstep(69.5,73.4,length(p));
     float edge=.5+.5*sin(p.y*.55+p.x*.34+seaTime*.4);
     float crest=smoothstep(.982,.998,sin(p.y*.23+p.x*.075+sin(p.x*.14)*.8+seaTime*.42));
     float broken=smoothstep(-.1,.5,sin(p.x*.31-seaTime*.2));
     float glint=crest*broken;
     float light=ripple*.28+rim*edge*.19+glint*.40;
     vec3 tint=mix(color.rgb,vec3(.61,.86,.89),light);
     float alpha=color.a + ripple*.085 + rim*edge*.09+glint*.12;
     return vec4(tint,alpha);
    }]],[[
    uniform mat4 vp;
    uniform mat4 model;
    varying vec2 seaXZ;
    vec4 position(mat4 transform_projection,vec4 p) {
     seaXZ=p.xz;
     return vp*model*p;
    }]])
  end)
  if not ok then
   if mesh then mesh:release()end;if shader then shader:release()end
   mesh,shader=nil,nil;error(err)
  end
 end
 function S.draw(arena,y,time)
  assert(arena and arena.mid,'Sea water needs arena.mid')
  if not mesh then init()end
  g.push('all')
  local ok,err=pcall(function()
   g.setShader(shader)
   shader:send('vp','row',api.Voxel3D.vp)
   shader:send('model','row',api.Mat4.translate(arena.mid[1],y,arena.mid[2]))
   shader:send('seaTime',time or 0)
   g.setColor(1,1,1,1);g.setBlendMode('alpha','alphamultiply')
   g.setMeshCullMode('none');g.setDepthMode('lequal',false)
   g.draw(mesh)
  end)
  g.pop();if not ok then error(err)end
 end
 function S.release()
  if mesh then mesh:release()end;if shader then shader:release()end
  mesh,shader=nil,nil
 end
 return S
end
return R
