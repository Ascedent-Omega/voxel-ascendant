-- Retained entrance vestibules connect the real warp to the arena enclosure.
-- Only the two cached glass leaves move; native maps and scripts own travel.
local V=...
local M={}
function M.geometry(map,depth)
 local p=V.require('Gen1GymInteriors').exitDoor(map)
 if not p then return end
 local groups={}
 local function group(family)
  local g={family=family,vertices={},indices={}};groups[#groups+1]=g;return g
 end
 local function quad(g,points,uv)
  local n=#g.vertices;uv=uv or{{.04,.90},{.05,.90},{.05,.91},{.04,.91}}
  for i,v in ipairs(points)do g.vertices[#g.vertices+1]={v[1],v[2],v[3],uv[i][1],uv[i][2],1}end
  for _,i in ipairs{1,2,3,1,3,4}do g.indices[#g.indices+1]=n+i end
 end
 local function front(g,a,b,lo,hi,z,mirror)
  quad(g,{{b,lo,z},{a,lo,z},{a,hi,z},{b,hi,z}},
   {{mirror and 0 or 1,1},{mirror and 1 or 0,1},{mirror and 1 or 0,0},{mirror and 0 or 1,0}})
 end
 local a,b,z=p.from,p.upto,p.at;local half=(b-a)/2
 local l,r=a-half-2,b+half+2;local back=z+(depth or 32)
 local frame=group(p.material)
 -- Solid leaf pockets, lintel and returns physically meet the far wall.
 for _,span in ipairs{{l,a},{b,r}}do
  quad(frame,{{span[2],0,z-.5},{span[1],0,z-.5},{span[1],26,z-.5},{span[2],26,z-.5}})
 end
 quad(frame,{{r,24,z-.5},{l,24,z-.5},{l,28,z-.5},{r,28,z-.5}})
 for _,x in ipairs{l,r}do
  quad(frame,{{x,0,z-.5},{x,0,back},{x,28,back},{x,28,z-.5}})
 end
 quad(frame,{{l,28,z-.5},{l,28,back},{r,28,back},{r,28,z-.5}})
 -- Full-width stationary picture seals the opening throughout the warp.
 local function motion(sign)
  return {mapId=map.id,edge='south',at=z,horizontal=true,center=(a+b)/2,
    width=b-a,travel=half,sign=sign}
 end
 local recess=group('room_door_recess')
 recess.doorView=V.require('Gen1GlassDoors').outViewKey(map,p.warp)
 recess.slidingDoor=motion(0)
 front(recess,a,b,0,24,z+.5,true)
 for leaf=1,2 do
  local g=group('room_glass_door');g.slidingDoor=motion(leaf==1 and -1 or 1)
  local x=a+(leaf-1)*half
  front(g,x,x+half,0,24,z+.125,leaf==2)
 end
 return groups
end
return M
