local B=assert(loadfile('lib/Gen1RoomBounds.lua'))({require=function(name)
 assert(name=='Gen1Rooftops')
 return{gate=function(map)return map.id=='ROUTE_12_GATE_2F'end}
end})
local function fixture(set,w,h,depth)
 local d={tileset=set,width=w/2,height=h/2,warps={},blocks={}}
 return {id='FIXTURE',def=d,tileset={blocks={}},isWalkableCell=function(_,x,y)return x>=depth and x<w-depth and y>=depth and y<h-depth end}
end
local m=fixture('FACILITY',30,18,1)
local b=B.forMap(m);assert(b.west==16 and b.north==16 and b.east==464 and b.south==272)
assert(B.forMap(m)==b,'bounds allocated every camera frame')
m=fixture('LOBBY',20,8,2);m.def.warps={{x=12,y=1},{x=1,y=1}}
local orig=m.isWalkableCell;m.isWalkableCell=function(self,x,y)return x==12 and y==1 or x==1 and y==1 or orig(self,x,y)end
b=B.forMap(m);assert(b.north==32 and b.west==32,'warp recessed in original band')
m.isWalkableCell=function(_,x,y)return y>=1 end;B.refresh(m)
assert(B.forMap(m).north==16,'rebuild retained stale collision bounds')
m=fixture('CAVERN',30,18,1);assert(B.forMap(m).north==0,'cave footprint inferred as room')
m=fixture('GATE',8,8,2);m.id='ROUTE_12_GATE_2F'
assert(B.forMap(m).north==32,'lookout retained the two blocked north rows')
m=fixture('LOBBY',4,4,1);assert(B.forMap(m).north==0,'small elevator cropped')
m=fixture('FACILITY',30,18,1);m.def.generation=2;assert(B.forMap(m).north==0)
print('PASS native room bounds: blocked courses, recessed warps, build cache refresh, unsupported/small/generation guards')

m=fixture('FACILITY',30,18,1);m.def.warps={{x=10,y=17},{x=26,y=0},{x=0,y=6}}
local mask=B.floorTiles(m);local function has(x,z)return mask[(z/8+64)*4096+x/8+64]end
assert(has(16,16)and has(448,256),'interior floor lost')
assert(not has(0,16)and not has(16,0)and not has(464,16)and not has(16,272),'floor overhang remains')
assert(has(160,272)and has(416,0)and has(0,96),'entrance/steps lost their floor')
assert(not has(152,272)and not has(408,0)and not has(0,88),'warp floor extends sideways')
assert(not has(-8,16),'outer ring gets a floor')
print('PASS floor footprint: all four overhangs removed, door/stair alcoves preserved, no border floor')
