local modules={};local V={require=function(n)return assert(modules[n],n)end}
local F=assert(loadfile('lib/SilphFountains.lua'))(V);modules.SilphFountains=F
local tiles={};local function key(x,y)return x..','..y end
local function rim(x,y)for dy=0,1 do for dx=0,1 do tiles[key(x+dx,y+dy)]=({{9,10},{25,26}})[dy+1][dx+1]end end end
local map={id='SILPH_CO_1F',def={width=15,height=9,tileset='FACILITY'},tileAt=function(_,x,y)return tiles[key(x,y)]or 20 end,isWaterCell=function()return true end}
assert(F.matches(map));map.def.generation=2;assert(not F.matches(map));map.def.generation=nil
map.def.width=14;assert(not F.matches(map));map.def.width=15
map.id='SILPH_CO_2F';assert(not F.matches(map));map.id='SILPH_CO_1F'
local P={models={},decorColors={silver=14}};modules.VoxelItems=P
rim(24,6);rim(26,6)
local left=F.rimKind(P,map,24,6);local right=F.rimKind(P,map,26,6)
assert(left=='silph_coping_2'and right=='silph_coping_8')
for _,id in ipairs{left,right}do
 local m=P.models[id];assert(m.support==4)
 local area=0
 for _,b in ipairs(m.boxes)do
  assert(b[1]>=0 and b[3]>=0 and b[1]+b[4]<=16 and b[3]+b[6]<=16 and b[2]+b[5]<=4)
  if b[2]==3 then area=area+b[4]*b[6]end
 end
 assert(area<256 and area>180,'exposed corners must round without losing the broad coping')
end
local function edge(m,at)
 local rows={};for _,b in ipairs(m.boxes)do if b[2]==3 and (at==0 and b[1]==0 or at==16 and b[1]+b[4]==16)then rows[b[3]]=true end end;return rows
end
local a,b=edge(P.models[left],16),edge(P.models[right],0)
for z=0,15 do assert(a[z]==b[z],'seam gap between adjoining tops')end
local first,last
for f=0,F.frames-1 do
 local boxes=F.spray(f/F.frames);assert(#boxes<=180)
 for _,p in ipairs(boxes)do
  assert(p[1]>=-14 and p[3]>=-14 and p[1]+p[4]<=14 and p[3]+p[6]<=14,'spray escapes the guaranteed wet footprint')
  assert(p[2]>=-2 and p[2]+p[5]<22,'spray hits ceiling or sinks under water')
 end
 if f==0 then first=boxes else last=boxes end
end
assert(first[140][2]~=last[140][2],'spray does not animate')
print('PASS Silph map guards, joined 4px coping, rounded outer corners, 16 bounded animated spray frames')
