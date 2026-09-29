local f=assert(io.open('integrated/ascendant_pokemon_overworld/src/voxel_characters.lua'));local source=f:read('*a');f:close()
local first=assert(source:find('  %-%- These full Voxel sheets'))
local last=assert(source:find('  local function loadCardAtlas',first,true))
local body=source:sub(first,last-1)
local canonical,uploads,releases,cancelled=0,0,0,0
local decoder={}
local nextStart,done=true,nil
function decoder.start(path,limit)assert(limit==16*1024*1024);return nextStart end
function decoder.poll(job)assert(job==true);return done end
function decoder.cancel(job)assert(job==true);cancelled=cancelled+1 end
local failUpload=false
love={graphics={newImage=function(pixels)uploads=uploads+1;if failUpload then error('GPU failure')end;return {pixels=pixels}end}}
local Assets={resolve=function(p)return p end,image=function(path)canonical=canonical+1;return {native=path}end}
local checks=0
local self={mod={_vascIntegrated=true},cardBounds={forPath=function(path)checks=checks+1;return not path:find('unknown',1,true)end}}
local constructor=assert((loadstring or load)('return function(self,imageDecoder,Assets)\n'..body..'\nreturn humanAtlasTexture,cancelHumanDecode\nend'))()
local step,cancel=constructor(self,decoder,Assets)
local path='mods/VASC/assets/characters/voxel-npcs/test.png'
assert(step(path,true)==nil and canonical==0 and uploads==0,'launch blocked/uploaded')
assert(step(path,true)==nil and uploads==0,'pending decode uploaded')
assert(step(path..'other',false)==nil and canonical==0,'draw duplicated pending source')
local pixels={release=function()releases=releases+1 end}
done=pixels
local texture,owned=step(path,true)
assert(checks==1,'pending poll rehashed the PNG')
assert(texture.pixels==pixels and owned and uploads==1 and releases==1 and canonical==0,'ownership/decode path')
cancel();assert(cancelled==0,'completed job cancelled')
done=nil;assert(step(path,true)==nil);cancel();assert(cancelled==1,'pending job leaked')
nextStart=nil;assert(step(path,true)==nil and canonical==0,'capacity busy used sync fallback')
nextStart=false;texture,owned=step(path,true);assert(texture.native and not owned and canonical==1,'unsupported fallback')
nextStart=true;assert(step(path,true)==nil);done=false
texture,owned=step(path,true);assert(texture.native and not owned and canonical==2,'failed worker fallback')
texture,owned=step(path,false);assert(texture.native and not owned and canonical==3,'uncovered path started orphan job')
texture,owned=step('other.png',true);assert(texture.native and not owned and canonical==4,'foreign image intercepted')
assert(step(path,true)==nil);done=pixels;failUpload=true
assert(not pcall(step,path,true)and releases==2,'failed upload leaked pixels')
cancel();assert(cancelled==1,'failed upload left worker pending')
print('PASS human atlas worker: no synchronous decode while pending, ownership, busy/unsupported/failure, cancellation')
