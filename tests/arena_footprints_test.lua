-- Differential search coverage. Reference is the saved pre-change module.
local referencePath=assert(os.getenv('QA_ARENA_REFERENCE'),'set QA_ARENA_REFERENCE')
local V={data=function()return{}end,require=function(name)
 if name=='VoxelFurniture'then return{supportAt=function(map,x,y)return map.seat and map.seat==math.floor(x/16)+math.floor(y/16)*map.widthCells and{}or nil end}end
 if name=='VoxelScene'then return{groundAt=function(map,x,y)return map.raised and x>=map.widthCells/2 and 16 or 0 end}end
 return{}
end}
local old=assert(loadfile(referencePath))(V)
local new=assert(loadfile('lib/BattleArena.lua'))(V)
for _,m in ipairs{old,new}do
 m.keepRouteAnchorInBounds=function()return true end
 m.keepAnchorSafe=function(_,arena)return (arena.mid[1]+arena.mid[2])%7~=0 end
end
local function equal(a,b)
 assert(type(a)==type(b),'search result type')
 if type(a)~='table'then assert(a==b,'search result value');return end
 for k,v in pairs(a)do equal(v,b[k])end
 for k in pairs(b)do assert(a[k]~=nil,'extra search field')end
end
local cases=0
for seed=1,12 do
 local w,h=18+seed,21+seed
 local map={widthCells=w,heightCells=h,calls=0,blocked={},raised=seed%2==0,seat=math.floor(w*h/2)}
 function map:inBounds(x,y)return x>=0 and y>=0 and x<w and y<h end
 function map:warpAtCell(x,y)return (x*13+y*7+seed)%71==0 end
 function map:isWarpTileCell(x,y)return (x*3+y*17+seed)%83==0 end
 function map:isGrassCell(x,y)return (x*19+y*23+seed)%97==0 end
 function map:isWalkableCell(x,y)self.calls=self.calls+1;return not self.blocked[x+y*w] and (x*7+y*13+seed)%53~=0 end
 function map:isWaterCell(x,y)return (x*7+y*13+seed)%53==0 end
 for _,pos in ipairs{{0,0},{w/2,h/2},{w-1,h-1}}do
  for _,surf in ipairs{false,true}do
   for _,options in ipairs{{},{maxDistance=0},{maxDistance=3},{maxDistance=7.5,roomy=true},{maxDistance=8,wideOnly=true},{maxDistance=-5},{maxDistance=7,compact=true},{maxDistance=8,height=16}}do
    for _,clear in ipairs{false,true}do
     equal(old.search(map,pos[1],pos[2],surf,clear,options),new.search(map,pos[1],pos[2],surf,clear,options));cases=cases+1
    end
   end
  end
 end
 -- The same map object changes between calls; no request data may persist.
 for y=0,h-1 do for x=0,w-1 do map.blocked[x+y*w]=true end end
 equal(old.search(map,8,8,false,true,{maxDistance=8}),new.search(map,8,8,false,true,{maxDistance=8}))
 assert(new.search(map,8,8,false,true,{maxDistance=8})==nil)
end
print('PASS arena footprints: '..cases..' exact searches; live same-object collision edits')
