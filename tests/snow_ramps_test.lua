for gen=1,2 do
 local map={def={tileset='OVERWORLD',generation=gen},widthCells=8,heightCells=8}
 function map:inBounds(x,y)return x>=0 and y>=0 and x<8 and y<8 end
 function map:isWaterCell()return false end
 function map:isWalkableCell(x,y)return self:inBounds(x,y)and not(x==3 and y==3)end
 function map:cellTile(x,y)return x==3 and y==3 and 2 or 1 end
 function map:cellCollision(x,y)return x==3 and y==2 and 0xa3 or x==3 and y==3 and 7 or 0 end
 local elevation={at=function(_,x,y)return y<=2 and 6 or 0 end}
 local data={field={ledges={{facing='down',input='down',standingTile=1,ledgeTile=2}}}}
 local p={cellX=3,cellY=2,px=48,py=32};local state={map=map,player=p,entities={}}
 package.loaded['src.core.Game']={data=data,overworld=state,world=state}
 package.loaded['src.world.Collision']={occupied=function(entities,x,y)return entities[1]and entities[1].cellX==x and entities[1].cellY==y end}
 package.loaded['src.world.gen2.Permissions']={ledgeFacings=function(c)return c==0xa3 and{down=true}or nil end,stepPermitted=function()return true end}
 local modules={Weather={isOutdoor=function()return true end},LedgeElevation={map=function()return elevation end},VoxelState={level=1},VoxelScene={groundAt=function(m,x,y)return elevation:at(x,y)end}}
 local R=assert(loadfile((gen==2 and'gen2/'or'')..'lib/SnowRamps.lua')){require=function(n)return assert(modules[n],n)end}
 local built=R.build(map,data,elevation);assert(#built.list==1,'native ledge not recognized')
 R.observe(state,.7);assert(R.status().active)
 assert(R.permission(state,p,3,3)==true,'descending snow step blocked')
 p.cellY=4;p.py=64;assert(R.permission(state,p,3,3)==true,'ascending snow step blocked')
 p.cellX=2;p.cellY=3;assert(R.permission(state,p,3,3)==false,'sideways wall crossing')
 p.cellX=3;p.cellY=4;state.entities={{cellX=3,cellY=3}}
 assert(R.permission(state,p,3,3)==false,'snow bypasses occupied cell');state.entities={}
 p.cellY=3;p.py=48;local h=R.height(map,56,56);assert(h and h>=6 and h<7,'rendered feet not on filled lip')
 R.observe(state,0);assert(R.status().retained and R.permission(state,p,3,4)==true,'melting strands player')
 p.cellY=5;p.py=80;R.observe(state,0);assert(not R.status().retained)
 p.cellY=4;p.py=64;assert(R.permission(state,p,3,3)==nil,'thawed bank still traversable')
 print('PASS snow ramp generation',gen,'native lip, uphill/downhill, occupied/side veto, support and safe thaw')
end
