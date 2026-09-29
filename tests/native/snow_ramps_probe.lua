return function(V,game,gen)
 local world=game.overworld or game.world;local map,p=world.map,world.player
 local R=V.require('SnowRamps');local elevation=gen==1 and V.require('LedgeElevation').map(map)or{at=function(_,x,y)return V.require('VoxelScene').groundAt(map,x,y)end}
 local built=R.build(map,gen==1 and game.data or {},elevation)
 assert(#built.list>0,'no eligible native snow ramps on '..tostring(map.id))
 local r=built.list[1];R.observe(world,.8)
 local directions={[1]='right',[-1]='left'};local forward=r.dx~=0 and directions[r.dx]or(r.dy==1 and'down'or'up')
 local opposite={right='left',left='right',up='down',down='up'}
 local function place(x,y,dir)
  p.cellX,p.cellY,p.px,p.py=x,y,x*16,y*16;p.facing=dir;p.moving=false;p.jumping=nil;p.ledgeHop=nil;p.turnTimer=0;p.turnArmed=false
 end
 for _,ascending in ipairs{false,true}do
  local dir=ascending and opposite[forward]or forward
  place(ascending and r.tx or r.sx,ascending and r.ty or r.sy,dir)
  assert(R.permission(world,p,r.lx,r.ly)==true,'native bank permission refused')
  if gen==1 then
   assert(not world:checkLedgeHop(dir),'snow still triggers jump')
   p:tryMove(dir,map,world.entities)
  else world:movePlayer(dir)end
  assert(p.moving and not p.jumping and not p.ledgeHop and p.targetX==r.lx and p.targetY==r.ly,'native step did not walk onto bank')
 end
 place(r.lx,r.ly,forward);R.observe(world,0);assert(R.status().retained,'native thaw drops occupied bank')
 place(r.tx+r.dx,r.ty+r.dy,forward);R.observe(world,0);assert(not R.status().retained)
 R.observe(world,.8);place(r.tx,r.ty,opposite[forward])
 print('PASS_NATIVE_WALK_UP_AND_DOWN_SNOW_BANK',gen,map.id,#built.list,r.sx,r.sy,r.tx,r.ty)
 return r
end
