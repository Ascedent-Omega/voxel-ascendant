-- Garment geometry for the host's authored part inventory. Saved choice IDs
-- remain owned by KASC; unsupported new parts fail explicitly.
local G={revision=1}
local function copy(v)if type(v)~='table'then return v end;local o={};for k,x in pairs(v)do o[k]=copy(x)end;return o end
local hair={black='29272b',brown='77502f',blond='ddbc65',silver='c5cbd2',red='a83e32',blue='356cac',purple='8654a9'}
local function hex(rgb)return string.format('%02x%02x%02x',rgb[1],rgb[2],rgb[3])end
function G.build(base,role,parts,selection)
 local m=copy(base);m.garments=nil;selection=selection or{}
 local b={};for _,bone in ipairs(m.bones)do b[bone.name]=bone end
 local function cube(bone,origin,size,mat,tag)
  local c={origin=origin,size=size,material=mat,tag=tag};b[bone].cubes=b[bone].cubes or{};table.insert(b[bone].cubes,c);return c
 end
 local function remove(bone,predicate)local out={};for _,c in ipairs(b[bone].cubes or{})do if not predicate(c)then out[#out+1]=c end end;b[bone].cubes=out end
 local function color(slot,default)
  local name=parts[slot]or'original';local part=assert(base.garments[slot][name],'unsupported Cobble '..slot..'/'..name)
  return part.colors[1]and hex(part.colors[1])or default
 end
 for slot in pairs(base.garments)do color(slot)end
 m.colors.cloth=color('upper','303034');m.colors.trousers=color('lower','304e70');m.colors.shoe=color('footwear','343438')
 local upper,lower,foot,head=parts.upper,parts.lower,parts.footwear,parts.head
 if upper~='original'then
  remove('body',function(c)return c.tag=='upper'end)
  local tee=upper=='cream-tee'or upper=='rust-tee'
  local vest=upper=='lotta-vest'
  cube('body',{-5,15,-3},{10,13,6},'cloth','upper')
  if not tee then
   m.colors.trim=upper=='champion-jacket'and'cca747'or'e9e0c9'
   if vest then m.colors.cloth='24262d';cube('body',{-3,16,-3.25},{6,11,1},'white','upper')end
   for _,side in ipairs({-1,1})do
    cube('body',{side<0 and-5 or 2,15,-3.7},{3,12.5,1},'cloth','upper')
    cube('body',{side<0 and-2.2 or 1.5,15,-4.1},{.7,11.5,.6},'trim','upper')
    if not vest then cube('body',{side<0 and-4.5 or 2,19,-4.15},{2.5,2.5,.5},'trim','upper')end
   end
  end
  for _,side in ipairs({'left','right'})do
   remove('arm_'..side,function(c)return not c.material:match('^skin')end)
   remove('forearm_'..side,function(c)return not c.material:match('^skin')end)
   local x=side=='left'and 4.7 or-9.3
   cube('arm_'..side,{x,tee and 23 or 21,-2.5},{4.6,tee and 4 or 6,5},'cloth','upper')
   if not tee and not vest then cube('forearm_'..side,{side=='left'and 4.8 or-9.2,16,-2.4},{4.4,5,4.8},'cloth','upper')end
  end
 end
 if lower~='original'then
  remove('body',function(c)return c.tag=='lower'end)
  local shorts=lower=='lotta-shorts';if shorts then m.colors.trousers='37455b'end
  cube('body',{-5,14,-3},{10,3,6},'trousers','lower')
  for _,side in ipairs({'left','right'})do
   local x=side=='left'and .7 or-4.7
   b['leg_'..side].cubes={}
   cube('leg_'..side,{x,9,-2.5},{4,6,5},shorts and'skin'or'trousers','lower')
   if shorts then cube('leg_'..side,{x-.2,11,-2.7},{4.4,4,5.4},'trousers','lower')end
   remove('shin_'..side,function(c)return c.origin[2]>=3 end)
   cube('shin_'..side,{x,3,-2.5},{4,6,5},shorts and'skin'or'trousers','lower')
   if lower=='sand-cargo'or lower=='trail-trousers'then cube('leg_'..side,{side=='left'and x+3.5 or x-.7,10,-1.5},{1.2,3,3},'trousers','lower')end
  end
 end
 if foot~='original'then
  local boot=foot:find('boot',1,true)or foot=='trail-shoes'or foot=='champion-oxblood'
  -- Authored light sneakers contain a large navy leg area; use the shoe itself.
  if foot=='cream-sneakers'then m.colors.shoe='e8dfc2'elseif foot=='lotta-boots'then m.colors.shoe='303036'end
  for _,side in ipairs({'left','right'})do
   local x=side=='left'and .7 or-4.7
   remove('shin_'..side,function(c)return c.origin[2]<3 or boot and c.origin[2]<8 end)
   if boot then cube('shin_'..side,{x-.2,2,-2.8},{4.4,6.5,5.6},'shoe','footwear')end
   cube('shin_'..side,{x-.5,.5,-4.5},{5,3,7},'shoe','footwear')
   cube('shin_'..side,{x-.5,0,-4.5},{5,1,7},'sole','footwear')
   cube('shin_'..side,{x+.5,2.5,-4.2},{3,1,2},boot and'gray'or'white','footwear')
  end
 end
 if head~='original'and not(head=='source-head'and role~='red')then
  remove('head',function(c)return c.tag=='hat'end)
  if head=='open-hair'or head=='source-head'then
   if role=='red'then
    for _,x in ipairs({-4,0,3})do local c=cube('head',{x-1,39,-3},{3,4,5},'hairred','hair');c.rotation={0,0,x*4};c.pivot={x,39,0}end
   end
  else
   -- Clip only spikes above the cap, keeping each identity's lower hair.
   remove('head',function(c)return c.tag=='hair'and c.origin[2]>39 end)
   m.colors.cap=color('head','d44838')
   cube('head',{-6.5,38,-5.5},{13,6,11},'cap','hat')
   cube('head',{-5.5,43.5,-4.5},{11,1,9},'cap','hat')
   local backward=head:find('backward',1,true)
   cube('head',{-6,37.5,backward and 4 or-10},{12,1,6},'cap','hat')
   cube('head',{-2,39,backward and 5.4 or-6.1},{4,3,.7},'white','hat')
  end
 end
 if hair[selection.hair]then for _,bone in ipairs(m.bones)do for _,c in ipairs(bone.cubes or{})do if c.tag=='hair'then c.material='chosenHair'end end end;m.colors.chosenHair=hair[selection.hair]end
 if hair[selection.streak]then
  m.colors.streak=hair[selection.streak]
  cube('head',{-4,36.5,-6.2},{1.3,4,1},'streak','hair')
 end
 if parts.eyewear~='original'then
  for _,x in ipairs({-4.8,1})do
   local black=parts.eyewear=='sunglasses'
   cube('head',{x,33.4,-7},{3.8,black and 3.6 or .5,.5},'ink','eyewear')
   if not black then
    cube('head',{x,36.5,-7},{3.8,.5,.5},'ink','eyewear')
    cube('head',{x,33.4,-7},{.5,3.6,.5},'ink','eyewear')
    cube('head',{x+3.3,33.4,-7},{.5,3.6,.5},'ink','eyewear')
   end
  end
  cube('head',{-1,35,-7},{2,.5,.5},'ink','eyewear')
  for _,x in ipairs({-5.8,5.3})do cube('head',{x,35,-6.8},{.5,.5,7},'ink','eyewear')end
 end
 if parts.accessory=='pink-bag'then
  m.colors.bag='b04e89'
  for _,c in ipairs(b.body.cubes or{})do if c.tag=='bag'and c.material~='gold'and c.material~='black'then c.material='bag'end end
 elseif selection.outfit=='champion'then
  m.colors.bag='4b4055'
  for _,c in ipairs(b.body.cubes or{})do if c.tag=='bag'and c.material~='gold'then c.material='bag'end end
 end
 return m
end
return G
