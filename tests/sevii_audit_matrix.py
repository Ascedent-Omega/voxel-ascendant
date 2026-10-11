#!/usr/bin/env python3
"""Export measured native map receipts without treating visual review as PASS."""
import argparse, csv, json
from pathlib import Path
p=argparse.ArgumentParser(description=__doc__)
p.add_argument('--input',type=Path,required=True,help='Native driver map-audit.json')
p.add_argument('--output',type=Path,required=True)
a=p.parse_args();rows=json.loads(a.input.read_text());seen=set()
fields=['map','source','tileset','kind','cells','subtiles','waterCells','grassCells','props','buildings','actors','warps','connections','TileCoverage','Collision','Geometry','Objects','Water','Animation','Actors','Warps','Settings','VisualReview','MobileReview']
with a.output.open('w',newline='') as f:
 w=csv.DictWriter(f,fieldnames=fields);w.writeheader()
 for r in rows:
  assert r['map'] not in seen,'duplicate map receipt';seen.add(r['map'])
  assert r['contract'] and r['missingTags']==0 and r['shapeConflicts']==0,'failed static map receipt: '+r['map']
  assert r['subtiles']==r['cells']*4,'incomplete subtile coverage: '+r['map']
  row={k:r[k] for k in fields[:13]}
  row.update(TileCoverage='PASS admitted profile and all subtiles',Collision='PASS cell/shape; rendered geometry requires review',Geometry='REVIEW rendered heights and seams',Objects='PASS mesh claims; rendered placement requires review',Water='PASS water cell/shape; appearance requires review',Animation='REVIEW native animation',Actors='REVIEW live identity and occlusion',Warps='PASS targets; physical routes and quest state tested separately',Settings='battleStyle='+r['battleStyle'],VisualReview=r['visualReview'],MobileReview=r['mobileReview'])
  w.writerow(row)
print('SEVII_MATRIX_EXPORT_PASS',len(rows))
