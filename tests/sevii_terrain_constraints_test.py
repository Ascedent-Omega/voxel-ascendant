"""Exercise height solving across movement-layer boundaries and bad seams."""
import contextlib, importlib.util, io
from pathlib import Path
p=Path(__file__).resolve().parents[1]/'scripts/build_sevii_voxel_profiles.py'
spec=importlib.util.spec_from_file_location('terrain',p);g=importlib.util.module_from_spec(spec);spec.loader.exec_module(g)
class Rom:
 def ptr(self,at):return 0x2d4f70
# A drawn stair connects two terraces. The source's adjacent, collision-free
# upper/lower grass edges must not merge those discrete movement layers.
def source(name,cells,w,h,connections=()):
 return {'spec':{'source':name,'width':w,'height':h},'layout':0,'cells':cells,'kinds':['FLOOR']*len(cells),'cache':{8:(None,0),0x91:(None,0x2a)},'connections':connections}
a=source('A',[(5<<12)|8]*4+[(0<<12)|0x91]*2+[(3<<12)|8]*2+[(3<<12)|8]*4,4,3)
with contextlib.redirect_stdout(io.StringIO()):r=g.terrain_courses({'A':a},Rom(),{'A'})['A']
assert r['rises'][4]==6 and r['heights'][0]-r['heights'][8]==6
# A seam that claims both ends of a 6px stair are the same course is invalid.
# Exporting it as a flat map hides broken input and is forbidden.
a=source('A',[(3<<12)|8]*2+[(3<<12)|0x91]*2+[(3<<12)|8]*2,2,3,[{'direction':'north','offset':0,'target':'B'},{'direction':'south','offset':0,'target':'B'}])
b=source('B',[(3<<12)|8]*6,2,3)
try:
 with contextlib.redirect_stdout(io.StringIO()):g.terrain_courses({'A':a,'B':b},Rom(),{'A','B'})
except ValueError as e:assert 'Contradictory source terrace constraints' in str(e)
else:raise AssertionError('contradictory source terrain was silently flattened')
print('PASS terrain constraints: original movement layers keep terraces distinct; contradictory seam graph is rejected')
