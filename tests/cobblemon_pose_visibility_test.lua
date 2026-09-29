local cache={};local V={};V.require=function(n)if not cache[n]then cache[n]=assert(loadfile('lib/'..n..'.lua'))(V)end;return cache[n]end
local G=V.require('CobblemonGeometry');local Import=V.require('CobblemonImport')
local decode=assert(loadfile('lib/ContentJson.lua'))().decode
local function read(p)local f=assert(io.open(p));local s=f:read('*a');f:close();return s end
local catalog=decode(read('assets/cobblemon-catalog.json'))
for _,aspects in ipairs{{},{shiny=true}}do
 local m=Import.compile(catalog,18,aspects,read,decode)
 local names={};for i,n in ipairs(m.boneNames)do names[n]=i end
 for _,action in ipairs{'idle','walk','battle','attack_default','flinch','faint'}do
  for _,t in ipairs{0,7,15,30}do
   local rows=G.sample(m,m.actions[action],t,true)
   for _,side in ipairs{'left','right'}do
    assert(rows[names['wing_open_'..side]][7]==0,action..' draws open wing over folded wing')
    assert(rows[names['wing_closed_'..side]][7]~=0,action..' lost folded wing')
   end
  end
 end
 local c=m.anims[m.actions.walk];c.visibility[tostring(names.wing_open_left)]=true;c.visibility[tostring(names.wing_closed_left)]=false
 local row=G.sample(m,m.actions.walk,0,true);assert(row[names.wing_open_left][7]~=0 and row[names.wing_closed_left][7]==0,'visibility failed to restore')
end
print('PASS real Pidgeot normal/shiny pose visibility, folded-walk selection and restoration')
for _,aspects in ipairs{{},{shiny=true}}do
 local m=Import.compile(catalog,18,aspects,read,decode,'fly')
 local names={};for i,n in ipairs(m.boneNames)do names[n]=i end
 for _,time in ipairs{0,7,15,30}do
  local rows=G.sample(m,m.actions.idle,time,true)
  for _,side in ipairs{'left','right'}do
   assert(rows[names['wing_open_'..side]][7]~=0,'flying Pidgeot lost extended wing')
   assert(rows[names['wing_closed_'..side]][7]==0,'flying Pidgeot duplicates folded wing')
  end
 end
end
print('PASS Pidgeot normal/shiny flight pose, extended wings and isolated ground pose')
