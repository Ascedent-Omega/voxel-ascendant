local M=assert(loadfile('lib/Gen1InteriorLayout.lua'))({})
local panels={
 {edge='south',at=128,from=0,upto=96,openings={{from=16,upto=32,height=24}}},
 {edge='north',at=128,from=0,upto=128,openings={{from=96,upto=112,height=24,open=true}}},
 {edge='east',at=32,from=0,upto=64,openings={}},
 {edge='east',at=32,from=48,upto=96,openings={},endcap=true},
 {edge='north',at=144,from=0,upto=128,openings={}},
}
local out=M.uniquePlanes(panels)
assert(#out==5 and out[2].from==96 and out[2].upto==128)
assert(out[2].openings[1].open and out[2].openings[1].from==96)
assert(out[4].from==64 and out[4].upto==96 and out[4].endcap)
assert(out[5].at==144,'separate rooms were merged')
assert(panels[2].from==0 and panels[4].from==48,'source layout mutated')
print('PASS single wall-plane coverage, partial overlaps, retained doors/endcaps and separate partitions')
