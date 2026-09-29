return function(game)
 assert(os.getenv('POKEPORT_IDENTITY')=='vasc-video-polish-qa');love.audio.setVolume(0)
 if os.getenv('QA_DISABLE_JIT')=='1'and jit then jit.off();jit.flush()end
 io.stdout:setvbuf('no')
 local root=assert(os.getenv('QA_VASC_ROOT'));local U=require('tests.drivers.util')
 local function read(p)local f=assert(io.open(root..'/'..p,'rb'));local s=f:read('*a');f:close();return s end
 local J=assert(loadfile(root..'/lib/ContentJson.lua'))()
 local B=assert(loadfile(root..'/lib/CobblemonBinary.lua'))()
 local Old=assert(loadfile(assert(os.getenv('QA_BINARY_BASELINE'))))()
 local function estimate(v,seen)
  if type(v)=='string'then return #v+24 end
  if type(v)~='table'or seen[v]then return 0 end
  seen[v]=true;local b=128;for k,x in pairs(v)do b=b+48+estimate(k,seen)+estimate(x,seen)end;return b
 end
 local index=assert(J.decode(read('assets/cobblemon-binary/index.json')))
 local function same(a,b,path)
  if a==J.null then assert(b==J.null,path);return end
  assert(type(a)==type(b),'type '..path)
  if type(a)~='table'then assert(a==b,'value '..path);return end
  for k,v in pairs(a)do same(v,b[k],path..'.'..tostring(k))end
  for k in pairs(b)do assert(a[k]~=nil,'extra '..path)end
 end
 local keys={};for h in pairs(index.records)do keys[#keys+1]=h end;table.sort(keys)
 local out={models={},oldMs=0,newMs=0,jsonBytes=0,binaryBytes=0,jitEnabled=jit and jit.status()or false}
 for i,h in ipairs(keys)do
  local raw=read('assets/cobblemon-prepared/models/'..h..'.json')
  local blob=read('assets/cobblemon-binary/'..h..'.bin')
  local function run(binary)
   local t=love.timer.getTime();local bytes=blob
   assert(love.data.encode('string','hex',love.data.hash('sha256',bytes))==index.records[h])
   local value,charge
   if binary then value,charge=B.decode(blob,h,J.null)else value=assert(Old.decode(blob,h,J.null));charge=estimate(value,{})end
   assert(value);local elapsed=(love.timer.getTime()-t)*1000
   assert(charge==estimate(value,{}),'accounting mismatch '..h)
   return value,elapsed
  end
  local a,b,x,y
  if i%2==0 then b,y=run(true);a,x=run(false)else a,x=run(false);b,y=run(true)end
  same(a,b,h);out.oldMs=out.oldMs+x;out.newMs=out.newMs+y
  out.jsonBytes=out.jsonBytes+#raw;out.binaryBytes=out.binaryBytes+#blob
  out.models[#out.models+1]={hash=h,oldMs=x,newMs=y}
  if i==1 then
   assert(not B.decode(blob,'wrong',J.null))
   assert(not B.decode(blob..'trailing','wrong',J.null))
   for n=1,math.min(#blob-1,150)do assert(not B.decode(blob:sub(1,n),h,J.null))end
   local function invalid(body,size)
    return 'CMB1'..love.data.pack('string','<I4',size or #body)..blob:sub(9,40)..love.data.compress('string','zlib',body)
   end
   local body='a'..love.data.pack('string','<I4',3)..'nna'..love.data.pack('string','<I4',0)
   local tree,charge=B.decode(invalid(body),h,J.null)
   assert(tree and charge==estimate(tree,{}),'shared null accounting')
   for _,body in ipairs{'x','a','a'..love.data.pack('string','<I4',1000001),'d'..love.data.pack('string','<d',math.huge),'o'..love.data.pack('string','<I4',1)..'tf','a'..love.data.pack('string','<I4',0)..'t',string.rep('a'..love.data.pack('string','<I4',1),66)..'t'}do
    assert(not B.decode(invalid(body),h,J.null),'accepted malformed binary')
   end
   assert(not B.decode(invalid('t',33554433),h,J.null))
   assert(not B.decode(invalid('t',2),h,J.null))
  end
  if i%8==0 then collectgarbage('collect');U.wait(1)end
 end
 local f=assert(io.open(assert(os.getenv('SHOT_DIR'))..'/decode.json','w'))
 f:write(assert(require('src.link.Json').encode(out)));f:close()
 print('PASS_MODEL_ACCOUNTING',#keys,out.oldMs,out.newMs,out.jsonBytes,out.binaryBytes);love.event.quit(0)
end
