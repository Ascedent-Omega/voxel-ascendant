return function(game)
 assert(os.getenv('POKEPORT_IDENTITY')=='vasc-video-polish-qa');love.audio.setVolume(0)
 if os.getenv('QA_DISABLE_JIT')=='1' and jit then jit.off();jit.flush()end
 local U=require('tests.drivers.util');local root=assert(os.getenv('QA_VASC_ROOT'))
 local old=assert(loadfile(assert(os.getenv('QA_JSON_BASELINE'))))()
 local new=assert(loadfile(root..'/lib/ContentJson.lua'))()
 local function read(p)local f=assert(io.open(p,'rb'));local s=f:read('*a');f:close();return s end
 local function same(a,b)
  if a==old.null then assert(b==new.null);return end
  assert(type(a)==type(b),'different type')
  if type(a)~='table'then assert(a==b,'different value');return end
  for k,v in pairs(a)do same(v,b[k])end
  for k in pairs(b)do assert(a[k]~=nil,'extra key')end
 end
 -- Differential grammar corpus includes short malformed tokens and truncation.
 local cases=0
 local function compare(s)
  local a,e=old.decode(s);local b,f=new.decode(s)
  assert((a==nil)==(b==nil),'acceptance: '..s)
  if a~=nil then same(a,b)else assert(e==f,'error changed: '..s)end
  cases=cases+1
 end
 local chars={'0','1','9','-','+','.','e','E','x',' '}
 local function generate(s,n)
  compare(s);compare('['..s..']')
  if n>0 then for _,c in ipairs(chars)do generate(s..c,n-1)end end
 end
 generate('',4)
 local files=assert(loadfile(assert(os.getenv('QA_MODEL_LIST'))))()
 local out={runtime=jit and jit.version or _VERSION,jitEnabled=jit and jit.status()or false,models={},grammar=cases,bytes=0,referenceMs=0,optimizedMs=0}
 for i,p in ipairs(files)do
  local raw=read(root..'/'..p);local a,b
  -- Alternate order; only decoder execution is timed, not disk I/O/equality.
  local function run(j)
   local t=love.timer.getTime();local value=assert(j.decode(raw));return value,(love.timer.getTime()-t)*1000
  end
  local x,y
  if i%2==0 then b,y=run(new);a,x=run(old)else a,x=run(old);b,y=run(new)end
  same(a,b);out.referenceMs=out.referenceMs+x;out.optimizedMs=out.optimizedMs+y;out.bytes=out.bytes+#raw
  out.models[#out.models+1]={path=p,bytes=#raw,referenceMs=x,optimizedMs=y}
  a,b=nil,nil
  if i%8==0 then collectgarbage('collect');U.wait(1)end
 end
 local f=assert(io.open(assert(os.getenv('SHOT_DIR'))..'/decode.json','w'));f:write(assert(require('src.link.Json').encode(out)));f:close()
 print('PASS_CONTENT_DECODE',#files,cases,out.referenceMs,out.optimizedMs);love.event.quit(0)
end
