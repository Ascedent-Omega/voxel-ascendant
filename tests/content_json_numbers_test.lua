local J=assert(loadfile('lib/ContentJson.lua'))()
local good={['0']=0,['-0']=0,['1']=1,['-123']=-123,['0.125']=.125,['-0.125']=-.125,
 ['1e3']=1000,['2E-3']=.002,['4e+2']=400,['1.25e2']=125,['1e-999']=0}
for raw,expected in pairs(good)do
 assert(J.decode(raw)==expected,raw)
 assert(J.decode('[ '..raw..' , true, false, null, "ok" ]')[1]==expected,raw)
end
for _,raw in ipairs{'','-','+1','.1','01','-01','1.','1e','1E+','1e-','1e--2','1e1.2',
 '1e999','-1e999','NaN','Infinity','0x12','1 2','[1,]','[1e]','[.2]','[+1]',
 '{"a":1,"a":2}','truex','nul','[1\v,2]','1\0','"\255"','"\\uD800"'}do
 assert(J.decode(raw)==nil,'accepted '..raw)
end
assert(J.decode('[-0]')[1]==0)
assert(J.decode('{"a":false,"b":null}').a==false)
assert(J.decode('{"a":false,"b":null}').b==J.null)
assert(J.decode('"\\uD83D\\uDE00"')=='\240\159\152\128')
print('PASS_CONTENT_JSON_NUMBERS')
