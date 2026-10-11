-- Exact KASC Sevii four-actor stage receipt. Ordinary VASC and all singles
-- never enter this path. The gameplay controller remains KASC's authority.
local V=...
local M={}
local function cell(c)
  return type(c)=='table' and type(c.x)=='number' and type(c.y)=='number'
    and c.x==c.x and c.y==c.y and c.x>=0 and c.y>=0
    and c.x%1==0 and c.y%1==0
end
local function world(c)return {c.x*16+8,c.y*16+8}end
local function mean(a,b)
  return {(a[1]+b[1])/2,(a[2]+b[2])/2}
end
function M.layoutFor(state,battle)
  local map=state and state.map
  local layout=battle and battle.doubleBattle==true
    and battle.seviiDoubleArena
  if not(layout and map and map.def
      and map.def.kaOwner=='kasc.sevii-expedition/v1'
      and layout.map==map.id
      and type(layout.center)=='table' and cell(layout.center)
      and type(layout.player)=='table' and #layout.player==2
      and type(layout.enemy)=='table' and #layout.enemy==2
      and battle.player and battle.player2 and battle.enemy and battle.enemy2
      and battle.sides and battle.sides[1] and battle.sides[2]
      and type(battle.sides[1].battlers)=='table'
      and type(battle.sides[2].battlers)=='table'
      and battle.sides[1].battlers[1]==battle.player
      and battle.sides[1].battlers[2]==battle.player2
      and battle.sides[2].battlers[1]==battle.enemy
      and battle.sides[2].battlers[2]==battle.enemy2)then return nil end
  local width=map.widthCells or (map.def and map.def.width and map.def.width*2)
  local height=map.heightCells or (map.def and map.def.height and map.def.height*2)
  if type(width)~='number' or type(height)~='number'
      or width<=0 or height<=0 then return nil end
  -- Treasure Beach's authored encounter grass includes low shore plants at
  -- these feet. This exact court has been checked in the native four-actor
  -- camera; the tall Kindle Road growth still needs the normal grass veto.
  local verifiedBeachCourt=map.id=='KA_SEVII_TREASURE'
    and layout.center.x==13 and layout.center.y==22
  local occupied={}
  for _,side in ipairs{layout.player,layout.enemy}do
    for _,c in ipairs(side)do
      if not cell(c) or c.x>=width or c.y>=height then return nil end
      local key=c.x..':'..c.y
      if occupied[key] then return nil end
      occupied[key]=true
      if type(map.isWalkableCell)=='function' and not map:isWalkableCell(c.x,c.y)
          or type(map.warpAtCell)=='function' and map:warpAtCell(c.x,c.y)
          or type(map.isWarpTileCell)=='function' and map:isWarpTileCell(c.x,c.y)
          or not verifiedBeachCourt and type(map.isGrassCell)=='function'
            and map:isGrassCell(c.x,c.y)
          or type(map.isWaterCell)=='function' and map:isWaterCell(c.x,c.y)then
        return nil
      end
    end
  end
  -- Tall grass is real foreground geometry in MAP. A tuft in front of a
  -- battler can hide most of its silhouette even when all four feet are on
  -- clear tiles, so keep the immediate camera-facing apron bare as well.
  if not verifiedBeachCourt and type(map.isGrassCell)=='function'then
    for y=layout.center.y-3,layout.center.y+3 do
      for x=layout.center.x-2,layout.center.x+2 do
        if x<0 or y<0 or x>=width or y>=height
            or map:isGrassCell(x,y)then return nil end
      end
    end
  end
  return layout
end
function M.attach(arena,layout,physical)
  if not(arena and layout)then return nil end
  local p1,p2=world(layout.player[1]),world(layout.player[2])
  local e1,e2=world(layout.enemy[1]),world(layout.enemy[2])
  arena.doubleBattle=true
  local playerMid,enemyMid=mean(p1,p2),mean(e1,e2)
  if physical then
    arena.playerSlots={p1,p2}
    arena.enemySlots={e1,e2}
    arena.player,arena.enemy=playerMid,enemyMid
    arena.mid=mean(playerMid,enemyMid)
    arena.cam=layout.camera=='wide'and'wide'or'tele'
  else
    if not(arena.player and arena.enemy)then return nil end
    local function translated(point,origin,dest)
      return {dest[1]+point[1]-origin[1],dest[2]+point[2]-origin[2]}
    end
    arena.playerSlots={translated(p1,playerMid,arena.player),
      translated(p2,playerMid,arena.player)}
    arena.enemySlots={translated(e1,enemyMid,arena.enemy),
      translated(e2,enemyMid,arena.enemy)}
  end
  return arena
end
function M.mapArena(map,layout)
  local arena={map=map,shape='wide',x=layout.center.x-1,
    y=layout.center.y-2,w=3,h=6,presentationMode='MAP'}
  return M.attach(arena,layout,true)
end
function M.frameReady(visuals,textures,width,height,battle)
  if not(type(visuals)=='table'and type(textures)=='table'
      and type(width)=='number'and width>0
      and type(height)=='number'and height>0)then
    return false,'double-frame-missing'
  end
  local count=0
  local hulls={}
  local stable=battle and battle.phase=='menu' and not battle.sendingOut
    and not battle.enemySendingOut and not battle.pendingSwitch
  for _,slot in ipairs{'player','player2','enemy','enemy2'}do
    local battler=battle and battle[slot]
    if stable and battler and battler.mon and battler.mon.hp>0
        and not battler.fainted and not textures[slot]then
      return false,'double-actor-missing-'..slot
    end
    if textures[slot]then
      local receipt=visuals[slot]
      local h=receipt and receipt.hull
      if not(h and type(h[1])=='number'and type(h[2])=='number'
          and type(h[3])=='number'and type(h[4])=='number'
          and h[3]>0 and h[4]>0 and h[1]>=0 and h[2]>=0
          and h[1]+h[3]<=width and h[2]+h[4]<=height)then
        return false,'double-actor-outside-'..slot
      end
      if stable and battler and receipt.battler~=battler then
        return false,'double-actor-owner-'..slot
      end
      for _,other in ipairs(hulls)do
        local x=math.max(h[1],other[1])
        local y=math.max(h[2],other[2])
        local w=math.max(0,math.min(h[1]+h[3],other[1]+other[3])-x)
        local ht=math.max(0,math.min(h[2]+h[4],other[2]+other[4])-y)
        if w*ht>=.9*math.min(h[3]*h[4],other[3]*other[4])then
          return false,'double-actors-overlap'
        end
      end
      hulls[#hulls+1]=h
      count=count+1
    end
  end
  return count>=2, count>=2 and nil or'double-actors-missing'
end
return M
