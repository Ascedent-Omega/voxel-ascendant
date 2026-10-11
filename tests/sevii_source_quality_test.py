#!/usr/bin/env python3
"""Independent source-coordinate oracle for the Sevii visual regression.

Run locally with the matching KASC importer, private ROM and bundle. Only
semantic assertions/coordinates are saved; no extracted artwork is exported.
The native driver consumes the result through SEVII_SOURCE_ORACLE.
"""
import argparse, importlib.util, json, sys
from pathlib import Path

ap = argparse.ArgumentParser(description=__doc__)
ap.add_argument('--importer', type=Path, required=True)
ap.add_argument('--rom', type=Path, required=True)
ap.add_argument('--output', type=Path, required=True)
args = ap.parse_args()
sys.path.insert(0, str(args.importer.parent))
spec = importlib.util.spec_from_file_location('source_import', args.importer)
imp = importlib.util.module_from_spec(spec)
spec.loader.exec_module(imp)
rom = imp.Rom(args.rom.read_bytes())
specs = json.loads(imp.MANIFEST.read_text())['maps']
selected = {(s['group'], s['number']): s for s in specs}
cases = []
for s in specs:
    source = imp.decode_source(rom, s, selected)
    # These reviewed primary drawings are isolated ocean rocks, not cliff
    # faces. Their blocked gameplay cells must remain blocked.
    if s['group']==3:
        for at,value in enumerate(source['cells']):
            mid=value&1023
            if mid in (0x110,0x111,0x118,0x119,0x1cb,0x1cc,0x1d3,0x1d4,0x212,0x213,0x21a,0x21b) and source['kinds'][at]=='WALL'and source['cache'][mid][1]==0x15:
                cases.append(dict(source=s['source'],x=at%s['width'],y=at//s['width'],tag='o'))
    donors={'FiveIsland_RocketWarehouse':(3,0,0x289),'FourIsland_Mart':(1,0,0x285),'TrainerTower_1F':(2,4,0x2e9)}
    if s['source'] in donors:
        x,y,mid=donors[s['source']]
        assert source['cells'][y*s['width']+x]&1023==mid
        assert all(max(source['cache'][mid][0].getpixel((sx,8))[:3])>=32 for sx in range(16))
        cases.append(dict(source=s['source'],x=x,y=y,tag='X',wallDonor=True))
    for at, value in enumerate(source['cells']):
        # Reviewed primary-atlas left, center AND right plank drawings.
        if value & 1023 in (0x1C5, 0x1C6, 0x1C7):
            assert source['kinds'][at] == 'FLOOR', s['source']
            cases.append(dict(source=s['source'], x=at % s['width'],
                              y=at // s['width'], tag='K', material=-130))
    if s['source'] == 'TwoIsland_House':
        # Four original individual seats, a 2x2 table, cabinet, kitchen.
        for x, y, tag in [(4,4,'e'),(4,5,'e'),(7,4,'s'),(7,5,'s'),
                          (5,4,'t'),(6,5,'t'),(2,1,'c'),(8,1,'q'),(1,1,'n'),
                          (0,1,'p'),(0,2,'p'),(0,3,'p'),(0,4,'p'),(0,6,'p'),(0,7,'p'),(3,7,'G')]:
            cases.append(dict(source=s['source'],x=x,y=y,tag=tag))
    if s['source']=='SevenIsland_House_Room1':
        # Its shared secondary Icefall pointer must not override the actual
        # primary-atlas home furniture visible in this source room.
        roles={0x145:'k',0x146:'k',0x103:'p',0x156:'p',0x15e:'p',0x181:'c',0x182:'c',0x158:'X',0x159:'X',
               0x165:'t',0x166:'t',0x16d:'t',0x16e:'t',0x167:'s',
               0x16f:'e',0x109:'G',0x111:'G'}
        for at,value in enumerate(source['cells']):
            if value&1023 in roles:
                cases.append(dict(source=s['source'],x=at%s['width'],y=at//s['width'],tag=roles[value&1023]))
    if s['source'] in ('SevenIsland_House_Room2','FiveIsland_ResortGorgeous_House','FourIsland_LoreleisHouse','ThreeIsland_House1','SixIsland_WaterPath_House1'):
        for at,value in enumerate(source['cells']):
            mid=value&1023
            if mid in (0x123,0x124,0x125,0x12b,0x12c,0x12d,0x133,0x134,0x135):tag='P'
            elif mid in (0x118,0x120,0x158,0x159,0x160,0x168):tag='X'
            elif mid in (0x165,0x166,0x16c,0x16d,0x16e):tag='t'
            elif mid==0x167:tag='s'
            elif mid==0x16f:tag='e'
            else:continue
            cases.append(dict(source=s['source'],x=at%s['width'],y=at//s['width'],tag=tag))
    if s['source'] in ('SevenIsland_House_Room2','FiveIsland_ResortGorgeous_House'):
        # These are the actual primary-atlas crown/pot pairs. A missing
        # 12e crown also pollutes the sampled floor palette with leaf colours
        # and strips leaves off every native plant in the room.
        for at,value in enumerate(source['cells']):
            if value&1023 in (0x102,0x103,0x12e,0x136):
                cases.append(dict(source=s['source'],x=at%s['width'],y=at//s['width'],tag='p'))
    if s['source'] in ('FourIsland_LoreleisHouse','FiveIsland_ResortGorgeous_House'):
        # The secondary drawings are inspected separately from common home
        # graphics: actual table, seat, bed, rug and framed-wall footprints.
        if s['source']=='FiveIsland_ResortGorgeous_House':
            reviewed={0x2f9:'t',0x2fa:'t',0x2fb:'t',0x2fc:'t',0x126:'e',0x127:'s',0x033:'k',0x034:'k',0x300:'k',0x301:'k',0x2fd:'X',0x2fe:'X',0x305:'X',0x306:'X'}
        else:
            reviewed={0x2eb:'t',0x2ec:'t',0x2f3:'t',0x2f4:'t',0x2df:'e',0x2e3:'s',0x2e9:'b',0x2f1:'b',0x2e4:'P',0x2e5:'P',0x2e8:'P',0x2ea:'P',0x2f0:'P',0x2f2:'P',0x2ed:'c',0x2ee:'c',0x2f5:'c',0x2f6:'c'}
        for at,value in enumerate(source['cells']):
            if value&1023 in reviewed:cases.append(dict(source=s['source'],x=at%s['width'],y=at//s['width'],tag=reviewed[value&1023]))
    if s['source'] == 'FiveIsland_RocketWarehouse':
        # Plain floor below the original machines used to become bookcases.
        for x,y in [(7,6),(8,6)]:
            at=y*s['width']+x
            assert source['cells'][at]&1023==0x299
            cases.append(dict(source=s['source'],x=x,y=y,tag='G'))
        for at,value in enumerate(source['cells']):
            if value&1023 in (0x3f0,0x3f1,0x3f2,0x3f3,0x3f8,0x3f9):
                cases.append(dict(source=s['source'],x=at%s['width'],y=at//s['width'],tag='z'))
        for at,value in enumerate(source['cells']):
            mid=value&1023
            if mid in (0x099,0x395):
                assert source['kinds'][at]=='WALL','reviewed puzzle block must be blocked'
                cases.append(dict(source=s['source'],x=at%s['width'],y=at//s['width'],tag='i'))
            elif mid in (0x2b5,0x2b6,0x2b7,0x2ba,0x2bb,0x2bd,0x2be,0x2c3,0x2c4,0x313,0x315,0x31b,0x31d,0x3f4):
                cases.append(dict(source=s['source'],x=at%s['width'],y=at//s['width'],tag='u'))
    if s['source'] in {name+'Island_Harbor' for name in ('One','Two','Three','Four','Five','Six','Seven')}:
        # The original waterline and metal guardrails belong to an open quay.
        for at,value in enumerate(source['cells']):
            mid=value&1023;behavior=source['cache'][mid][1]
            if mid in (0x28c,0x28d,0x28e,0x28f,0x294,0x295,0x296,0x297,0x29d,0x2a5):tag='F'
            elif behavior==0x15:tag='W'
            elif mid==0x292:tag='j'
            else:continue
            cases.append(dict(source=s['source'],x=at%s['width'],y=at//s['width'],tag=tag))
    if s['source'] in ('MtEmber_Exterior','MtEmber_Summit'):
        for at,value in enumerate(source['cells']):
            mid=value&1023;behavior=source['cache'][mid][1];kind=source['kinds'][at]
            if behavior==0x2a:tag='A'
            elif mid!=0 and kind=='WALL'and behavior not in (0x38,0x39,0x3a,0x3b)and not 0x60<=behavior<=0x69:
                tag='C'
            elif kind=='FLOOR'and behavior==0x0c:tag='D'
            else:continue
            cases.append(dict(source=s['source'],x=at%s['width'],y=at//s['width'],tag=tag))
    if s['source']=='SevenIsland_SevaultCanyon':
        for at,value in enumerate(source['cells']):
            if source['kinds'][at]=='FLOOR'and source['cache'][value&1023][1]==0x0c:
                cases.append(dict(source=s['source'],x=at%s['width'],y=at//s['width'],tag='D',material=-171))
    if 'IcefallCave' in s['source']:
        for at,value in enumerate(source['cells']):
            mid=value&1023;behavior=source['cache'][mid][1];kind=source['kinds'][at]
            if kind=='WALL'and mid in (0x282,0x283,0x2cf,0x2d7):tag='R'
            elif behavior in (0x26,0x27)and kind=='FLOOR':tag='I'
            else:continue
            cases.append(dict(source=s['source'],x=at%s['width'],y=at//s['width'],tag=tag))
assert len(cases)>20, 'missing independent bridge samples'
args.output.write_text(json.dumps(dict(cases=cases), indent=2)+'\n')
print('PASS independent source oracle:',len(cases),'cell expectations')
