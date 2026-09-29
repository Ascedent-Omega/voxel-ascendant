-- Bounded derived-art cache. This module does not write wardrobe selections.
local Art={}
function Art.new(mod,models,geometry,baker,equipment)
 local api={built=0,errors={},revision=5};local order,sizes,items={},{},{}
 local root='wardrobe/cobble-v5/'
 local kinds={'idle','walk','blink','preview'}
 local function remove(prefix,key)
  for _,kind in ipairs(kinds)do mod.cache:delete(prefix..key..'-'..kind..'.png')end
 end
 local function measured(key)
  local total=0
  for _,kind in ipairs(kinds)do
   local info=mod.cache:info(root..key..'-'..kind..'.png')
   if not info or info.type~='file'or not info.size or info.size<24 then return nil end
   total=total+info.size
  end
  return total
 end
 -- Retire only our indexed prior revisions. Never scan/delete other mods.
 for _,revision in ipairs({3,4})do
  local prefix='wardrobe/cobble-v'..revision..'/'
  local old=mod.cache:read(prefix..'index.txt')
  if type(old)=='string'and #old<10000 then
   for key in old:gmatch('([0-9a-f]+) %d+')do if #key==64 then remove(prefix,key)end end
   mod.cache:delete(prefix..'index.txt')
  end
 end
 local pending=mod.cache:read(root..'pending.txt')
 if type(pending)=='string'and #pending==64 and pending:match('^[0-9a-f]+$')then remove(root,pending);mod.cache:delete(root..'pending.txt')end
 local references={};for role,base in pairs(models)do references[role]=baker.referenceHeight(base)end
 local function persist()local rows={};for _,key in ipairs(order)do rows[#rows+1]=key..' '..sizes[key]end;assert(mod.cache:write(root..'index.txt',table.concat(rows,'\n')))end
 local function prune()
  local bytes=0;for _,size in pairs(sizes)do bytes=bytes+size end
  while #order>32 or bytes>32*1024*1024 do
   local key=table.remove(order,1);bytes=bytes-sizes[key];sizes[key]=nil;items[key]=nil
   remove(root,key)
  end
 end
 local index=mod.cache:read(root..'index.txt')
 if type(index)=='string'and #index<10000 then
  for key in index:gmatch('([0-9a-f]+) %d+')do if #key==64 and not sizes[key]then
   local size=measured(key)
   if size then order[#order+1]=key;sizes[key]=size else remove(root,key)end
  end end
  prune()
 end
 function api.resolve(role,action,wardrobe,selection)
  local base=assert(models[role],'no Cobble wardrobe for '..tostring(role))
  local parts
  if wardrobe and selection then parts=wardrobe.assets.parts(role:upper(),selection)
  else parts={upper='original',lower='original',footwear='original',head='original',eyewear='original',accessory='original'}end
  selection=selection or{}
  local fields={api.revision,geometry.revision,role,action or'walk',selection.hair or'natural',selection.streak or'none',selection.outfit or'original'}
  for _,slot in ipairs({'upper','lower','footwear','head','eyewear','accessory'})do fields[#fields+1]=parts[slot]or'original'end
  local key=love.data.encode('string','hex',love.data.hash('sha256',table.concat(fields,':')))
  if items[key]then return items[key]end
  local layout=baker.layout(action);local path='mod_cache/'..mod.id..'/'..root..key
  local clips={schema='ascendant.human-cards/v1',id='cobble-wardrobe-'..key,filter='nearest',referenceHeight=references[role]}
  for k,v in pairs(layout)do clips[k]=v end
  clips.idle={sheet=path..'-idle.png',columns=1,duration=1}
  clips.walk={sheet=path..'-walk.png',columns=12,duration=.96}
  clips.blink={sheet=path..'-blink.png',columns=4,duration=.24}
  local result={atlas=path..'-preview.png',clips=clips,key=key,parts=parts}
  if action=='hold'then
   local model=geometry.build(base,role,parts,selection);result.fieldHands={}
   for row,name in ipairs({'down','left','up','right'})do
    local x,y=baker.hand(model,row-1,action);result.fieldHands[name]={x*3*16/references[role],-y*3*16/references[role]}
   end
  end
  local total=measured(key)
  if not total then
   local model=equipment.add(geometry.build(base,role,parts,selection),action)
   total=0
   assert(mod.cache:write(root..'pending.txt',key))
   local ok,err=pcall(function()
   for _,spec in ipairs({{'idle',1},{'walk',12},{'blink',4},{'preview',3}})do
    local data=baker.render(model,spec[2],spec[1],action);local png=data:encode('png');data:release();local bytes=png:getString();png:release()
    assert(mod.cache:write(root..key..'-'..spec[1]..'.png',bytes));total=total+#bytes
   end
   assert(total<=32*1024*1024,'Cobble outfit exceeds cache budget')
   end)
   if not ok then remove(root,key);api.errors[1]=tostring(err);error(err)end
   api.built=api.built+1
  end
  if not sizes[key]then order[#order+1]=key end;sizes[key]=total;prune();persist()
  mod.cache:delete(root..'pending.txt')
  items[key]=result;return result
 end
 function api.health()local bytes=0;for _,size in pairs(sizes)do bytes=bytes+size end
  return{built=api.built,cached=#order,limit=32,bytes=bytes,byteLimit=32*1024*1024,errors=api.errors}end
 return api
end
return Art
