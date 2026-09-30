local root=assert(os.getenv('QA_PERF_REFERENCE'),'set QA_PERF_REFERENCE to the rc.2 source directory')
local function load(name,V)return assert(loadfile(name))(V)end
-- Uniforms: mutable scratch matrices must resend, failed sends must retry.
local U=load('lib/UniformMemo.lua').new();local sends=0;local fail=false
local shader={send=function()sends=sends+1;if fail then error('refused')end end}
local matrix={1,2,3,4}
U.send(shader,'model',matrix,'row');U.send(shader,'model',matrix,'row');assert(sends==1)
matrix[2]=5;U.send(shader,'model',matrix,'row');assert(sends==2)
U.send(shader,'model',{1,5,3,4},'row');assert(sends==2)
U.send(shader,'model',0);U.send(shader,'model',0);assert(sends==3)
fail=true;U.send(shader,'model',1);fail=false;U.send(shader,'model',1);assert(sends==5)
U.clear();U.send(shader,'model',1);assert(sends==6)
-- CPU RGBA atlas: exact channels including alpha; one native read per pixel.
local reads=0;local source={getDimensions=function()return 16,16 end,
 getPixel=function(_,x,y)reads=reads+1;return x/15,y/15,(x+y)/30,(x+y)%3/2 end}
local pixels=load('lib/TilesetPixels.lua').decode(source)
assert(reads==256)
for n=1,10 do for y=0,15 do for x=0,15 do
 local r,g,b,a=pixels:getPixel(x,y);assert(r==x/15 and g==y/15 and b==(x+y)/30 and a==(x+y)%3/2)
end end end
assert(reads==256)
-- Conservative frustum: translation, curve, unknown/rotated meshes and edges.
local P=load('lib/PropVisibility.lua');local M=load('lib/Mat4.lua');local visible=P.forView(M.identity())
local box={-.5,-.5,-.5,.5,.5,.5}
assert(visible(box,M.identity()));assert(not visible(box,M.translate(5,0,0)))
assert(not visible(box,M.translate(0,0,3)));assert(visible(box,M.translate(0,0,3),2),'depth pull clipped at far plane')
assert(visible(nil,M.translate(5,0,0)));assert(visible(box,M.rotateY(.5)))
assert(visible(box,M.translate(1.54,0,0)));assert(not visible(box,M.translate(1.56,0,0)))
assert(P.forView(M.identity(),1,0,0)({-.5,0,-.5,.5,1,.5},M.identity()))
local mesh={};P.remember(mesh,box);assert(P.known(mesh)==box)
-- Billboard transform: compare full matrix multiplication over signs/sizes/yaw.
local B=load('lib/BattleBillboard.lua',{require=function(n)if n=='Mat4' then return M end;return{}end})
for i=1,1000 do local x,y,z,w,h,a=i/7,-i/11,i/13,(i%9-4)/3,i/17,i/23
 local reference=M.mul(M.mul(M.translate(x,y,z),M.rotateY(a)),M.scale(w,h,1))
 local actual=B.matrix(x,y,z,w,h,a)
 for j=1,16 do assert(math.abs(reference[j]-actual[j])<1e-12,'billboard pose changed')end
end
-- Third-person boom: compare against rc.2 with ledges, surf and live block edits.
local calls=0
local modules={ModSetting={new=function()return{get=function()return false end}end},
 VoxelScene={groundAt=function(map,x,y)calls=calls+1;return(x*3+y*7)%4*4 end},
 TileShape={forMap=function()return{[1]={class='ledge'},[2]={class='ground'}}end}}
local V={require=function(n)return modules[n]or{}end}
local old=load(root..'/lib/ThirdPerson.lua',V);local new=load('lib/ThirdPerson.lua',V)
local map={widthCells=20,heightCells=20,block=false}
function map:inBounds(x,y)return x>=0 and y>=0 and x<20 and y<20 end
function map:isWalkableCell(x,y)return not self.block and (x+y)%5~=0 end
function map:isWaterCell(x,y)return(x+y)%10==0 end
function map:cellTile(x,y)return(x+y)%3==0 and 1 or 2 end
local ow={map=map};local saved=0
for i=1,200 do
 local p={40+i%8,10+i%25,48+i%7};local a=i/19;local bx,by,bz=math.sin(a),.2,math.cos(a)
 calls=0;local expected=old.reach(ow,p,bx,by,bz,80);local before=calls
 calls=0;local actual=new.reach(ow,p,bx,by,bz,80);saved=saved+before-calls
 assert(math.abs(expected-actual)<1e-9,'boom collision changed')
 if i==100 then map.block=true end
end
assert(saved>100,'per-cell memo did not remove repeated samples')
print('PASS performance receipts: mutable uniforms, exact RGBA, conservative culling, 1000 billboard poses and 200 boom comparisons; saved '..saved..' ground queries')
