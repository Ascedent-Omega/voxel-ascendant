local B=assert(loadfile('lib/FrameBudget.lua'))()
for i=1,120 do B.observe(1/30,false)end
assert(B.scale==.75,'loading must not lower quality')
for i=1,600 do B.observe(1/30,true)end
assert(B.scale==.5,'bounded low rung')
for i=1,6000 do B.observe(1/120,true)end
assert(B.scale==1,'recover after sustained headroom')
B.reset();B.observe(.5,true)
assert(B.scale==.75,'one long stall is not a GPU budget')
for i=1,600 do B.observe(1/60,true)end
assert(B.scale==.75,'60 Hz must not oscillate')
print('PASS frame budget: loading exclusion, floor/ceiling, recovery, single-stall rejection and 60 Hz hysteresis')
