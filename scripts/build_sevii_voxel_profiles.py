#!/usr/bin/env python3
"""Build presentation-only Sevii recipes from the user's local import.

Requires the matching KASC importer and BPRD ROM. No ROM pixels are copied
into the result: only authored semantic labels and object footprints.
"""
import argparse, hashlib, importlib.util, json, sys
from pathlib import Path
from PIL import Image

# Reviewed FireRed metatile roles. Native collision always wins for water,
# grass, entrances and traversable cells; these are presentation labels.
def nums(text):
    result=set()
    for word in text.split():
        p=word.split('-');result.update(range(int(p[0],16),int(p[-1],16)+1))
    return result
COMMON={
 'f':nums('004'),
 'T':nums('005 00e-00f 014-027 0b4-0b5 0fa-0fb 255'),
 'B':nums('028-063 137 17b-17f 186-18f 197 19f'),
 'C':nums('068-07d 098-0a2 0a8-0aa 0af 10f 11f 125 244-247 279-27a 27c'),
 'L':nums('080-087 0b0-0b3'),
 'D':nums('0bb 0c3-0cf 0d1-0d3 0d5 0e1-0e5 0fe 103 104 114 11c 11e 1d5-1e0 1e6 1e7'),
 'S':nums('002 169'),
 'F':nums('0d6-0d9 0e6-0ec 0f0-0f4 0f8-0f9'),
 'K':nums('1bd-1c7'),
}
# Secondary tileset pointer selects the atlas contract, not a map-name guess.
SECONDARY={
 0x2d4f70:{'B':nums('280-284 286-28e 291-2b4 2c0-2c4 2c6-2cc 2cf 2d2-2e0 2e2-2ec 300-307 380-384 386'),
 'T':nums('310-312 330-333 339-33c 33e-33f 341-344 34c 34d 351-355 373 398'),
 'C':nums('2be 2bf 2c5 2d0 2d1 334-338 33d 345-347 34b 34e-350 356-359 35a 35b 35d 35f-369 37a 388-391'),
 'F':nums('313-31f 321-32c'), 'D':nums('2b8 35e 360 36a 37c-37e 392-397 399-39b')},
 0x2d4f88:{'B':nums('289-28d 291-293 295-2bb 2cb-2cf 2d9-2dd 2e8-2e9 2f0-2f2 307 309-30c'),
 'T':nums('283-285 28f 290 294 2bc 2bd 2c6 2c7 2ff-301'),
 'C':nums('2c1 2c2 2c9-2ca 2d7-2d8 2e1 2e2 2e5-2e7 305-306'),
 'F':nums('281-282 287 2f9-2fa 2fc-2fd 310-312'), 'D':nums('288 2c4 2f6-2f8')},
 0x2d4fa0:{'B':nums('288-28c 28e 28f 291-2bd 2c9-2cb 2cf-2d1 2d4-2d7 2db-2dc 2df-2e1 2e4 2f8-2fa 30b-30c 316-31a 32e-32f 331-33c'),
 'T':nums('281 282 284 290 2fe-307 309-30a 30f 310 35d'),
 'C':nums('27c 2be-2c7 2cc-2ce 2d2 2d8-2da 2dd-2de 2e2 2e3 2e6 2e7 30d 30e 312-315 31c 324 32c 32d 33d-33f 345-34d 350-351'),
 'F':nums('280 283 286 28d'), 'D':nums('340-344 34e-34f 2d3 2e5')},
 0x2d4f28:{'T':nums('284 288-292 298-29a 29f-2a5'), 'D':nums('281 282 297')},
 0x2d4ce8:{'T':nums('284 288-28a 290-292 298-29a 2a0-2a5'), 'D':nums('2a8-2aa')},
}
# Ferry hull artwork is distinct from coastal building facades.
SHIPS={0x2d4f70:nums('288 298 2a4 2ac 2c7 2cf 2d5 2d7 2df 2f0-2f6'),
 0x2d4f88:nums('296 297 29e 29f 2ce 2cf 2d9'),
 0x2d4fa0:nums('288 28e 296 298 29e 29f')}
# Atlas drawings that are sand or natural shore, despite their numeric proximity
# to roofs. These were verified against every unclaimed building component.
SHORE={0x2d4f70:nums('2c1 384'),0x2d4f88:nums('307 309 30a'),
 0x2d4fa0:nums('17b 17c 28f 297 2a7 2af 2b7 2c9 2ca 2d4 2d5 2d7 2db 2dc 316 317 32e 32f 338')}
# Interior props are solid models on their actual drawing footprints.
INTERIOR={
 'n':nums('062 10e 116 11e'), 'p':nums('102 103 12a 12e 132 136 156 15e'),
 'b':nums('118 120 123-125 133 134 158-160'),
 'c':nums('10c 10d 114 115 11c 11d'),
 'q':nums('138 139 140 141 148 149'),
 'l':nums('10f 117 11f'), 'k2':nums('145 146'),
 't':nums('165 166 16c-16e'), 's':nums('167'), 'e':nums('16f'),
}
ROOMS={
 0x2d4b08:('center',{'p':nums('28e 294 2fe 300 301 36a'), 'n':nums('285 293'), 'k2':nums('295'), 'a':nums('2b4 2bf 2f5 2f6 2f8 2fd'), 'r2':nums('2b2 2b3'), 'A':nums('2cc 2cd 2cf 2d0'),
 'h':nums('2aa 2ab 2ad'), 'l2':nums('2a9 2ac'), 't':nums('29c 29d 2a4 2a5'), 's':nums('2a7 2af'), 'r':nums('28c 28d 28f 296-298 2b1 2b5 2b8-2bc 2c4 2c9 2ca 2d1 2d3 2d7 2de-2e2 2e7-2ec 2ef 2f7 2f9 302 303 37e 380'), 'u':nums('340-365'), 'k':nums('2d8 2da 2e3 2e4')}),
 0x2d4da8:('coastal_home',INTERIOR),
 0x2d4fd0:('gate',{'n':nums('299'),'k':nums('28d 28f 293 295-29d 2a5')}),
 0x2d4df0:('rocket',{'n':nums('2cd 2cf 2d6 2e5 2fc 2ff 305-308 33f'), 'u':nums('2b5-2b7 2ba-2be 2c3 2c4 313 315 31b 31d 3f4'), 'z':nums('3f0-3f3 3f8 3f9'), 'i':nums('099 395')}),
 0x2d4fb8:('corporate',{'p':nums('2d5-2d8 2dc-2de'),'h':nums('2be-2c1'), 'n':nums('2c2 2cc 2f0 2f1 2f9 2fb 30f 310'), 's':nums('2b6 2b7')}),
 0x2d4af0:('mart',{'k':nums('298-299 29b-29f 2a6 2a7 2aa-2af 2b1 2b2'),'p':nums('2b4 2b5')}),
 0x2d4c10:('casino',{'p':nums('2e8-2ea 2f0-2f1'),'t':nums('2ee 2f8 2fa 303 307'),'s':nums('2fe 30f 317'),'k':nums('300-302 30a 311')}),
 0x2d4bb0:('home',INTERIOR), 0x2d4e98:('daycare',dict(INTERIOR, t=INTERIOR['t']|nums('30f 310 321 322'))),
 0x2d4e38:('traditional_home',dict(INTERIOR,t=INTERIOR['t']|nums('2df 2e2 2eb-2ef'),b=INTERIOR['b']|nums('2e5-2ea'),k=nums('2fa-2fd'))),
 0x2d4b50:('hotel',dict(INTERIOR,t=INTERIOR['t']|nums('2b9-2bc'),s=INTERIOR['s']|nums('126 127 305 306'))),
}
CAVES={0x2d4f10:'diglett',0x2d4d48:'seafoam',0x2d4f40:'victory_road',
 0x2d4d18:'rock_tunnel',0x2d4b20:'mt_moon',0x2d4f58:'victory_road',0x2d4d30:'diglett'}
# The first Seven Island house shares Icefall's secondary tileset, but uses
# ordinary primary-atlas furniture and timber floor. It is an actual home.
PRIMARY_HOMES={'SevenIsland_House_Room1'}
SOURCE_ROOM_ROLES={
 'FourIsland_PokemonDayCare':{
  # The four blocked cells inside the pink rug are the daycare table top,
  # not a free-standing wall or room partition.
  't':nums('29d 29f 2a5 2a7')},
 'TwoIsland_JoyfulGameCorner':{
  # The glass display in the south-east of the room has four top tiles.
  't':nums('30d 30e 315 316'),
  # The left arm and front of the original yellow U-shaped service counter
  # were being classified as walls while its right arm was already furniture.
  'q':nums('306 307 2f5 2f6 2f9')},
 'FiveIsland_ResortGorgeous_House':{
  't':nums('2f9-2fc'),'e':nums('126'),'s':nums('127'),
  'k':nums('033 034 300 301'),'X':nums('2fd 2fe 305 306 2bf 2c7')},
 'FourIsland_LoreleisHouse':{
  't':nums('2eb 2ec 2f3 2f4'),'e':nums('2df'),'s':nums('2e3'),
  'b':nums('2e9 2f1'),'k':nums('2fa-2fd'),
  'c':nums('2ed 2ee 2f5 2f6'),
  'P':nums('2dc-2de 2e0-2e2 2e4-2e6 2e8 2ea 2ef 2f0 2f2 2f7 2fe 2ff')},
}

# These maps use group 1, while the local importer's gameplay outdoor flag
# covers group 3 only. Keep that contract intact; classify presentation from
# the reviewed source maps instead.
OPEN_SKY={'MtEmber_Exterior','MtEmber_Summit','TrainerTower_Roof'}
HARBORS={name+'Island_Harbor' for name in ('One','Two','Three','Four','Five','Six','Seven')}
OPEN_SKY|=HARBORS
ICE_ROCKS=nums('282 283 2cf 2d7 33f 344 347-349 34b 34f 352 354 35c 35e 35f 373 374')
SEA_ROCKS=nums('110 111 118 119 1cb 1cc 1d3 1d4 212 213 21a 21b')

def label(mid,behavior,kind,ptr,outdoor,source=None):
    if mid==0: return 'V'
    if source in HARBORS:
        # These are the open ferry quays, despite the importer's group-1
        # indoor gameplay flag. Water-side guardrails are not bookshelves.
        if kind=='WATER' or behavior==0x15:return 'W'
        if behavior==0x2a:return 'A'
        if 0x60<=behavior<=0x69:return 'E'
        if kind=='FLOOR':return 'G'
        if mid in nums('28c-28f 294-297 29d 2a5'):return 'F'
        return 'j'
    if source=='OneIsland_KindleRoad_EmberSpa':
        if behavior==0x13 or mid in nums('326 327 339'):return 'w'
        if mid in nums('32f-331 333 338 33a'):return 'v'
    if source in ('MtEmber_Exterior','MtEmber_Summit'):
        if kind=='WATER':return 'W'
        if kind=='GRASS':return 'g'
        if behavior==0x2a:return 'A'
        if behavior in (0x38,0x39,0x3a,0x3b):return 'L'
        if 0x60<=behavior<=0x69:return 'E'
        if kind=='FLOOR':return 'D'if behavior==0x0c else 'G'
        # The shared island atlas contains cliffs here, not house/ferry
        # drawings. Never infer architecture from secondary tile IDs alone.
        return 'C'
    if source=='TrainerTower_Roof':
        if behavior==0x61:return 'H'
        if behavior in (0x6a,0x6b,0x6c,0x6d,0x6e,0x6f):return {0x6a:'J',0x6b:'O',0x6c:'J',0x6d:'N',0x6e:'O',0x6f:'Q'}[behavior]
        if 0x60<=behavior<=0x69:return 'E'
        return 'G'if kind=='FLOOR'else 'C'
    if source=='FiveIsland_MemorialPillar'and mid in nums('2c0 2c1 2c8-2ca 2d0 2d1'):return 'm'
    if source=='FiveIsland_MemorialPillar'and kind=='WALL'and mid in nums('2d8 2d9 309 30a'):return 'R'
    if ptr==0x2d4d48 and kind=='WALL'and mid in ICE_ROCKS:return 'R'
    if outdoor and mid in SHIPS.get(ptr,set()):return 'Z'
    if kind=='WATER': return 'W'
    if outdoor and kind=='WALL'and behavior==0x15 and mid in SEA_ROCKS:return 'o'
    if outdoor and mid in SHORE.get(ptr,set()):return 'D' if kind=='FLOOR'else 'C'
    if kind=='GRASS': return 'g'
    if outdoor and kind=='FLOOR'and behavior==0x0c:return 'D'
    if behavior in (0x38,0x39,0x3a,0x3b): return 'L'
    if behavior in {0x2a,0x61,0x6a,0x6b,0x6c,0x6d,0x6e,0x6f}:return {0x2a:'A',0x61:'H',0x6a:'J',0x6b:'O',0x6c:'J',0x6d:'N',0x6e:'O',0x6f:'Q'}[behavior]
    if outdoor and mid in SECONDARY.get(ptr,{}).get('T',set()):return 'T'
    if outdoor and mid in SECONDARY.get(ptr,{}).get('B',set()) | COMMON['B']:return 'B'
    if behavior in (0x60,0x61,0x62,0x63,0x64,0x65,0x66,0x67,0x69,0x6b): return 'E'
    if not outdoor:
        if mid==8:return 'V'
        for tag,ids in SOURCE_ROOM_ROLES.get(source,{}).items():
            if mid in ids:return tag
        if source=='SevenIsland_House_Room1'and mid in (0x181,0x182):return 'c'
        if source in PRIMARY_HOMES or ptr in (0x2d4da8,0x2d4bb0,0x2d4e98,0x2d4e38,0x2d4b50):
            if mid in nums('123-125 12b-12d 133-135'):return 'P' # native rug
            if mid in (0x118,0x120,0x158,0x159,0x160,0x168):return 'X' # wall picture / window
        if ptr in CAVES and source not in PRIMARY_HOMES:
            if behavior in (0x23,0x26,0x27,0x39):return 'I'
            if kind=='FLOOR':return 'G' if behavior in (0,8) else 'P'
            return 'C'
        for tag,ids in ROOMS.get(ptr,('',INTERIOR))[1].items():
            if mid in ids:return tag[0]
        if kind=='FLOOR':return 'G' if behavior==0 else 'P'
        return 'X'
    # Secondary labels take precedence over primary-atlas roles.
    for table in (SECONDARY.get(ptr,{}),COMMON):
        for tag,ids in table.items():
            if mid in ids:return tag
    if kind=='FLOOR':return 'D' if mid in nums('0db-0dd 0ff 102 105') else 'G' if behavior==0 else 'P'
    return 'C' if kind=='WALL' else 'P'

def components(grid,w,h,tag):
    seen=set();out=[]
    for at,value in enumerate(grid):
        if value!=tag or at in seen:continue
        q=[at];seen.add(at);xs=[];ys=[]
        for i in q:
            x,y=i%w,i//w;xs.append(x);ys.append(y)
            for xx,yy in ((x-1,y),(x+1,y),(x,y-1),(x,y+1)):
                j=yy*w+xx
                if 0<=xx<w and 0<=yy<h and j not in seen and grid[j]==tag:seen.add(j);q.append(j)
        out.append([min(xs),min(ys),max(xs)-min(xs)+1,max(ys)-min(ys)+1,len(q)])
    return out

def terrain_courses(sources,rom,exteriors):
    """Prove terrace courses from complete stair mouths and native seams.

    No row-wide guessed elevation: separate walkable components get a course
    only when a complete north/south flight joins them. Connected source maps
    share the same datum, including their generated runtime partitions.
    """
    records={};edges={};node=0
    def edge(a,b,rise):
        edges.setdefault(a,[]).append((b,rise));edges.setdefault(b,[]).append((a,-rise))
    for name in sorted(exteriors):
        src=sources[name];w,h=src['spec']['width'],src['spec']['height'];ptr=rom.ptr(src['layout']+20)
        tags=[label(v&1023,src['cache'][v&1023][1],k,ptr,True,name)for v,k in zip(src['cells'],src['kinds'])]
        falls={at for at,(v,k)in enumerate(zip(src['cells'],src['kinds']))if(k=='WATER'or name=='OneIsland_KindleRoad_EmberSpa')and src['cache'][v&1023][1]==0x13}
        eligible=('FLOOR','GRASS','WATER')if falls else('FLOOR','GRASS')
        comp={};groups=[]
        for at,k in enumerate(src['kinds']):
            if k not in eligible or tags[at]=='A'or at in falls or at in comp:continue
            n=node;node+=1;q=[at];comp[at]=n
            for pos in q:
                x,y=pos%w,pos//w
                for xx,yy in ((x-1,y),(x+1,y),(x,y-1),(x,y+1)):
                    j=yy*w+xx
                    # Original FRLG collision rejects unequal nonzero
                    # movement elevations. They are labels, not heights:
                    # derive actual relief only from the stair constraints.
                    ea,eb=src['cells'][pos]>>12,src['cells'][j]>>12 if 0<=xx<w and 0<=yy<h else 0
                    compatible=ea in (0,15)or eb in (0,15)or ea==eb
                    # Surf mounts/dismounts between water layer 1 and bank
                    # layer 3. Where this solver admits water for a cascade,
                    # those banks share its course; layer 5 terraces do not.
                    if (0<=xx<w and 0<=yy<h and {ea,eb}=={1,3}
                        and 'WATER'in (src['kinds'][pos],src['kinds'][j])):compatible=True
                    if 0<=xx<w and 0<=yy<h and j not in comp and j not in falls and src['kinds'][j]in eligible and tags[j]!='A'and compatible:comp[j]=n;q.append(j)
            groups.append((n,q))
        flights=[]
        for x,y,bw,bh,count in components(tags,w,h,'A'):
            north={comp.get((y-1)*w+xx)for xx in range(x,x+bw)}if y>0 else{None}
            south={comp.get((y+bh)*w+xx)for xx in range(x,x+bw)}if y+bh<h else{None}
            if count==bw*bh and len(north)==len(south)==1 and None not in north|south:
                a,b=next(iter(north)),next(iter(south))
                if a!=b:edge(b,a,6);flights.append((x,y,bw,bh,a,b))
        fall_flights=[]
        fall_tags=['w'if at in falls else'-'for at in range(w*h)]
        for x,y,bw,bh,count in components(fall_tags,w,h,'w'):
            north={comp.get((y-1)*w+xx)for xx in range(x,x+bw)}if y>0 else{None}
            south={comp.get((y+bh)*w+xx)for xx in range(x,x+bw)}if y+bh<h else{None}
            if count==bw*bh and len(north)==len(south)==1 and None not in north|south:
                a,b=next(iter(north)),next(iter(south))
                if a!=b:edge(b,a,bh*6);fall_flights.append((x,y,bw,bh,a,b))
            elif count==bw*bh and y==0 and len(south)==1 and None not in south:
                # Ember Spa's source cascade starts at the map's north edge.
                # Its visible rows supply relief above the verified lower
                # pond; the virtual mouth adds no off-map walkable geometry.
                a=node;node+=1;b=next(iter(south));edge(b,a,bh*6)
                fall_flights.append((x,y,bw,bh,a,b))
            elif count==bw*bh and name=='OneIsland_KindleRoad_EmberSpa'and comp:
                # These bathing cascades are ornamental blocked drawings,
                # including the bath borders. Anchor their relief to the
                # nearest existing walking course, keeping all collisions.
                foot=min(comp,key=lambda at:abs(at%w-(x+bw//2))+abs(at//w-(y+bh)))
                b=comp[foot];a=node;node+=1;edge(b,a,bh*6)
                fall_flights.append((x,y,bw,bh,a,b))
        records[name]={'src':src,'w':w,'h':h,'tags':tags,'comp':comp,'groups':groups,'flights':flights,'falls':falls,'fall_flights':fall_flights}
    def neighbour(rec,d,x,y):
        target=records.get(d['target'])
        if not target:return
        direction=d['direction'];offset=d['offset']
        if direction=='north':xx,yy=x-offset,target['h']-1
        elif direction=='south':xx,yy=x-offset,0
        elif direction=='west':xx,yy=target['w']-1,y-offset
        else:xx,yy=0,y-offset
        if 0<=xx<target['w']and 0<=yy<target['h']:return target,yy*target['w']+xx
    for rec in records.values():
        w,h=rec['w'],rec['h']
        for d in rec['src']['connections']:
            border=[(x,0 if d['direction']=='north'else h-1)for x in range(w)]if d['direction']in ('north','south')else[(0 if d['direction']=='west'else w-1,y)for y in range(h)]
            for x,y in border:
                a=rec['comp'].get(y*w+x);hit=neighbour(rec,d,x,y)
                b=hit[0]['comp'].get(hit[1])if hit else None
                if a is not None and b is not None:edge(a,b,0)
    levels={};conflicts=0
    for n in range(node):
        if n in levels:continue
        levels[n]=0;q=[n];bad=False
        for a in q:
            for b,rise in edges.get(a,[]):
                expected=levels[a]+rise
                if b in levels:bad|=levels[b]!=expected
                else:levels[b]=expected;q.append(b)
        low=min(levels[x]for x in q)
        if bad:raise ValueError('Contradictory source terrace constraints: '+repr(q))
        for a in q:levels[a]=levels[a]-low
        conflicts+=bad
    print('Terrain components:',node,'contradictory contour groups:',conflicts)
    for rec in records.values():
        w,h=rec['w'],rec['h'];values={at:levels[n]for at,n in rec['comp'].items()};q=list(values);distance={at:0 for at in q}
        # Retaining rocks/facades inherit their closest walkable course.
        for at in q:
            x,y=at%w,at//w
            for xx,yy in ((x-1,y),(x+1,y),(x,y-1),(x,y+1)):
                j=yy*w+xx
                if 0<=xx<w and 0<=yy<h and j not in distance and rec['tags'][j]not in ('A','W','V'):
                    distance[j]=distance[at]+1;values[j]=values[at];q.append(j)
        rises={}
        for x,y,bw,bh,a,b in rec['flights']:
            rise=levels[a]-levels[b]
            if rise==6:
                for yy in range(y,y+bh):
                    for xx in range(x,x+bw):values[yy*w+xx]=levels[b];rises[yy*w+xx]=rise
        # Partial stair mouths can open onto one narrow road cell. Derive
        # their exact endpoints from the solved courses rather than adding
        # a freestanding hump to an otherwise level walking surface.
        for x,y,bw,bh,count in components(rec['tags'],w,h,'A'):
            north={levels[rec['comp'][(y-1)*w+xx]]for xx in range(x,x+bw)if y>0 and (y-1)*w+xx in rec['comp']}
            south={levels[rec['comp'][(y+bh)*w+xx]]for xx in range(x,x+bw)if y+bh<h and (y+bh)*w+xx in rec['comp']}
            if count==bw*bh and len(north)==len(south)==1:
                a,b=next(iter(north)),next(iter(south));assert abs(a-b)<=6,(rec['src']['spec']['source'],x,y,a,b)
                for yy in range(y,y+bh):
                    for xx in range(x,x+bw):values[yy*w+xx]=min(a,b);rises[yy*w+xx]=a-b
        # Enclosed ponds follow their lowest adjacent bank; open seas stay at
        # the common zero course. Never lift water from an unrelated roof.
        seen=set()
        for at,tag in enumerate(rec['tags']):
            if tag!='W'or at in seen or at in rec['falls']:continue
            sea=False;q=[at];seen.add(at);banks=[]
            for j in q:
                x,y=j%w,j//w;sea|=x in (0,w-1)or y in (0,h-1)
                for xx,yy in ((x-1,y),(x+1,y),(x,y-1),(x,y+1)):
                    k=yy*w+xx
                    if 0<=xx<w and 0<=yy<h:
                        if rec['tags'][k]=='W'and k not in seen and k not in rec['falls']:seen.add(k);q.append(k)
                        elif k in rec['comp']:banks.append(values[k])
            level=0 if sea or not banks else min(banks)
            for j in q:values[j]=level
        for x,y,bw,bh,a,b in rec['fall_flights']:
            if levels[a]-levels[b]==bh*6:
                for yy in range(y,y+bh):
                    for xx in range(x,x+bw):values[yy*w+xx]=levels[a]-(yy-y)*6
        rec['heights']=[values.get(at,0)for at in range(w*h)];rec['rises']=rises
    return records

def main():
    ap=argparse.ArgumentParser(description=__doc__);ap.add_argument('--importer',type=Path,required=True);ap.add_argument('--rom',type=Path,required=True);ap.add_argument('--bundle',type=Path,required=True);ap.add_argument('--output',type=Path,required=True);args=ap.parse_args()
    sys.path.insert(0,str(args.importer.parent));sp=importlib.util.spec_from_file_location('sevii_import',args.importer);imp=importlib.util.module_from_spec(sp);sp.loader.exec_module(imp)
    rom=imp.Rom(args.rom.read_bytes());specs=json.loads(imp.MANIFEST.read_text())['maps'];selected={(s['group'],s['number']):s for s in specs}
    sources={s['source']:imp.decode_source(rom,s,selected) for s in specs};bundle=json.loads(args.bundle.read_text());profiles={};report={}
    exteriors={d['kaSeviiSource']for d in bundle['maps']if d['outdoor']or d['kaSeviiSource']in OPEN_SKY or rom.ptr(sources[d['kaSeviiSource']]['layout']+20)in (0x2d4f28,0x2d4ce8)}
    relief={'FourIsland_IcefallCave_Entrance','OneIsland_KindleRoad_EmberSpa'}
    terrain=terrain_courses(sources,rom,exteriors|relief)
    for d,ts in zip(bundle['maps'],bundle['tilesets']):
        assert ts['id']==d['tileset'];src=sources[d['kaSeviiSource']];ptr=rom.ptr(src['layout']+20);outdoor=d['outdoor'];exterior=d['kaSeviiSource']in exteriors
        keys,source_blocks=imp.block_keys(src,(*d['kaSeviiSourceOrigin'],*d['kaSeviiSourceSize']))
        assert source_blocks==d['blocks'],d['id']
        images={hashlib.sha256(image.tobytes()).digest():(mid,behavior) for mid,(image,behavior) in src['cache'].items()}
        atlas=Image.open(args.bundle.parent/Path(ts['image']).name).convert('RGBA');tokens=[]
        for bi,row in enumerate(ts['blocks']):
            tags=[]
            for q,kind in enumerate(ts['sourceCellCollision'][bi]):
                tile=row[q//2*8+q%2*2];x=tile%64*8;y=tile//64*8
                mid,behavior=images.get(hashlib.sha256(atlas.crop((x,y,x+16,y+16)).tobytes()).digest(),(0,0))
                # Original metatile identity is authoritative, even when two
                # drawings share pixels. Only runtime ice/gate variants need
                # the atlas fallback; their exact collision still gates them.
                if bi<len(keys):
                    value,expected_kind=keys[bi][q];assert expected_kind==kind
                    mid=value&1023;behavior=src['cache'][mid][1]
                tags.append(label(mid,behavior,kind,ptr,exterior,d['kaSeviiSource']))
            tokens.append(''.join(tags))
        w,h=src['spec']['width'],src['spec']['height'];grid=[label(v&1023,src['cache'][v&1023][1],k,ptr,exterior,d['kaSeviiSource'])for v,k in zip(src['cells'],src['kinds'])]
        # Complete authored object footprints, including hull water and entrance gaps.
        for warp in src['warps']:
            role=None
            if exterior and warp['target'].endswith('_Harbor'):
                role='Z';bx,by,bw,bh=warp['x']-3,warp['y']+1,7,5
                for yy in range(warp['y'],warp['y']+1):
                    for xx in range(warp['x']-1,warp['x']+2):
                        if 0<=xx<w and 0<=yy<h:grid[yy*w+xx]='d'
            elif src['spec']['source']=='SevenIsland_TanobyRuins'and 'Chamber'in warp['target']:
                role='y';bx,by,bw,bh=warp['x']-1,warp['y']-3,3,4
            if role:
                for yy in range(by,by+bh):
                    for xx in range(bx,bx+bw):
                        if 0<=xx<w and 0<=yy<h:grid[yy*w+xx]=role
        props=[];ox,oy=d['kaSeviiSourceOrigin'];sw,sh=d['kaSeviiSourceSize']
        if exterior:
            # Each ocean boulder is a complete 32px drawing, even where
            # neighbouring boulders touch. A lower wave course may use the
            # alternate primary drawing; it is still the same round rock.
            claimed=set()
            for at,value in enumerate(src['cells']):
                mid=value&1023;x,y=at%w,at//w
                if grid[at]!='o'or mid not in (0x110,0x1cb,0x212)or x+1>=w or y+1>=h:continue
                below=(0x1d3,)if mid==0x1cb else(0x118,0x21a)
                if src['cells'][at+1]&1023!=mid+1 or src['cells'][at+w]&1023 not in below or src['cells'][at+w+1]&1023!=(src['cells'][at+w]&1023)+1:continue
                assert all(grid[at+dy*w+dx]=='o'for dy in range(2)for dx in range(2))
                claimed.update(at+dy*w+dx for dy in range(2)for dx in range(2))
                if x<ox+sw and x+2>ox and y<oy+sh and y+2>oy:
                    props.append({'tag':'o','x':x-ox,'y':y-oy,'w':2,'h':2,'doors':[]})
            for at,tag in enumerate(grid):
                if tag=='o'and at not in claimed:
                    x,y=at%w,at//w
                    if ox<=x<ox+sw and oy<=y<oy+sh:props.append({'tag':'o','x':x-ox,'y':y-oy,'w':1,'h':1,'doors':[]})
        for tag in (('B','Z','d','y','m','j','F','S','f') if exterior else ('n','p','b','t','s','e','a','h','r','k','u','q','l','c','z','i'))+('A','H'):
            for x,y,bw,bh,count in components(grid,w,h,tag):
                if tag=='i':
                    # Each blocked puzzle barrier belongs to its own source
                    # cell. Bounding a connected L-shape would fill its path.
                    for yy in range(y,y+bh):
                        for xx in range(x,x+bw):
                            if grid[yy*w+xx]=='i'and ox<=xx<ox+sw and oy<=yy<oy+sh:
                                props.append({'tag':'i','x':xx-ox,'y':yy-oy,'w':1,'h':1,'doors':[]})
                    continue
                if tag=='z':
                    # Adjacent 32px shipping crates are separate objects.
                    for yy in range(y,y+bh):
                        for xx in range(x,x+bw):
                            if src['cells'][yy*w+xx]&1023 not in (0x3f0,0x3f2):continue
                            if xx<ox+sw and xx+2>ox and yy<oy+sh and yy+2>oy:
                                assert all(grid[(yy+dy)*w+xx+dx]=='z'for dy in range(2)for dx in range(2)),('incomplete crate',d['id'],xx,yy)
                                props.append({'tag':'z','x':xx-ox,'y':yy-oy,'w':2,'h':2,'doors':[]})
                    continue
                if tag=='j':
                    doors=[{'x':v['x']-ox,'y':v['y']-oy,'destMap':next((m['id']for m in bundle['maps']if m['kaSeviiSource']==v['target']),'')}for v in src['warps']if x<=v['x']<x+bw and y<=v['y']<y+bh]
                    windows=[{'x':xx-x,'y':yy-y}for yy in range(y,y+bh)for xx in range(x,x+bw)if src['cells'][yy*w+xx]&1023==0x292]
                    props.append({'tag':'j','x':x-ox,'y':y-oy,'w':bw,'h':bh,'doors':doors,'windows':windows})
                    continue
                if tag=='p':
                    # Face-on plants occupy two rows. Touching drawings are
                    # separate pots, not one long rectangular hedge.
                    for xx in range(x,x+bw):
                        yy=y
                        while yy<y+bh:
                            if grid[yy*w+xx]!=tag:yy+=1;continue
                            ph=2 if yy+1<y+bh and grid[(yy+1)*w+xx]==tag else 1
                            if xx<ox+sw and xx+1>ox and yy<oy+sh and yy+ph>oy:
                                props.append({'tag':tag,'x':xx-ox,'y':yy-oy,'w':1,'h':ph,'doors':[]})
                            yy+=ph
                    continue
                if tag in ('s','e','a'):
                    # Adjacent chairs are separate seats, never a stretched sofa.
                    for yy in range(y,y+bh):
                        for xx in range(x,x+bw):
                            if grid[yy*w+xx]==tag and ox<=xx<ox+sw and oy<=yy<oy+sh:
                                props.append({'tag':tag,'x':xx-ox,'y':yy-oy,'w':1,'h':1,'doors':[]})
                    continue
                if tag=='B':
                    if bw<2 or bh<2 or count<bw*bh*.6:
                        for yy in range(y,y+bh):
                            for xx in range(x,x+bw):
                                if grid[yy*w+xx]=='B'and ox<=xx<ox+sw and oy<=yy<oy+sh:
                                    props.append({'tag':'v','x':xx-ox,'y':yy-oy,'w':1,'h':1,'doors':[]})
                        continue
                elif tag not in ('Z','m')and count!=bw*bh:
                    for yy in range(y,y+bh):
                        xx=x
                        while xx<x+bw:
                            if grid[yy*w+xx]!=tag:xx+=1;continue
                            start=xx
                            while xx<x+bw and grid[yy*w+xx]==tag:xx+=1
                            if start<ox+sw and xx>ox and oy<=yy<oy+sh:
                                props.append({'tag':tag,'x':start-ox,'y':yy-oy,'w':xx-start,'h':1,'doors':[]})
                    continue
                if x>=ox+sw or y>=oy+sh or x+bw<=ox or y+bh<=oy:continue
                doors=[]
                if tag=='B':
                    for warp in src['warps']:
                        if x<=warp['x']<x+bw and y<=warp['y']<=y+bh+(1 if src['spec']['source']=='SevenIsland_TanobyRuins'else 0):
                            bh=max(bh,warp['y']-y+1)
                            doors.append({'x':warp['x']-ox,'y':warp['y']-oy,'destMap':next((m['id']for m in bundle['maps']if m['kaSeviiSource']==warp['target']),'')})
                    if not doors:
                        for yy in range(y,y+bh):
                            xx=x
                            while xx<x+bw:
                                if grid[yy*w+xx]!='B':xx+=1;continue
                                start=xx
                                while xx<x+bw and grid[yy*w+xx]=='B':xx+=1
                                if start<ox+sw and xx>ox and oy<=yy<oy+sh:
                                    props.append({'tag':'v','x':start-ox,'y':yy-oy,'w':xx-start,'h':1,'doors':[]})
                        continue
                if tag=='B'and len(doors)>1:
                    # Reviewed touching drawings retain separate entrances:
                    # a house door is one cell from its left edge; the
                    # Center/Mart/game-corner doors are two cells in.
                    pieces=[]
                    for door in doors:
                        dest=door['destMap'];wide=4 if 'MART'in dest else 5
                        inset=2 if any(v in dest for v in ('CENTER','MART','CORNER'))else 1
                        left=door['x']+ox-inset
                        pieces.append({'tag':tag,'x':left-ox,'y':y-oy,'w':wide,'h':bh,'doors':[door]})
                    covered=[xx for piece in pieces for xx in range(piece['x']+ox,piece['x']+ox+piece['w'])]
                    assert sorted(covered)==list(range(x,x+bw)),('ambiguous touching buildings',d['kaSeviiSource'],x,y)
                    props.extend(piece for piece in pieces if piece['x']<sw and piece['x']+piece['w']>0)
                else:
                    props.append({'tag':tag,'x':x-ox,'y':y-oy,'w':bw,'h':bh,'doors':doors,**({'rise':terrain[d['kaSeviiSource']]['rises'].get(y*w+x,0)}if tag=='A'and exterior else{})})
        theme=ROOMS.get(ptr,('coastal_home',{}))[0]
        cave=CAVES.get(ptr) if d['kaSeviiSource'] not in PRIMARY_HOMES else None
        kind='water' if exterior else 'cave' if cave else 'room'
        if exterior and ('BerryForest'in d['kaSeviiSource']or 'PatternBush'in d['kaSeviiSource']):kind='canopy'
        if exterior and d['kaSeviiSource'].startswith('MtEmber'):kind='mountain'
        # Original MapHeader.mapType, not an imported atlas-name heuristic.
        # FRLG uses TOWN for its island settlements; retain its distinction
        # from ROUTE/UNDERGROUND/INDOOR without touching gameplay definitions.
        map_type=rom.data[src['header']+0x17]
        assert map_type in (1,3,4,8), ('unsupported source map type',d['kaSeviiSource'],map_type)
        profiles[d['id']]={'source':d['kaSeviiSource'],'sourceMapType':map_type,'origin':[ox,oy],'size':[d['width'],d['height']], 'atlas':[ts['imageWidth'],ts['imageHeight']],
            'island':d['kaSeviiIsland'],'outdoor':outdoor,'exterior':exterior,'kind':kind,'theme':theme,'cave':cave,'blocks':tokens,'props':props,
            'collision':[''.join({'WALL':'X','FLOOR':'G','WATER':'W','GRASS':'g'}[k]for k in r)for r in ts['sourceCellCollision']]}
        if kind=='canopy':
            # The illumination follows original tree plots across the whole
            # source, not the runtime partition or a repeating shadow grid.
            trees=[(at%w,at//w)for at,tag in enumerate(grid)if tag=='T']
            profiles[d['id']]['canopySize']=[w,h]
            profiles[d['id']]['canopyDensity']=[''.join(chr(33+round(90*max(0,1-min(
                ((xx-tx)**2+(yy-ty)**2)**.5 for tx,ty in trees)/5)))
                if trees else chr(33)for xx in range(w))for yy in range(h)]
        if kind=='cave':
            # White/rock-filled exterior is blocked C, not necessarily V.
            # Keep one native rock course around the complete source floor.
            # Enclosed pits/islands and runtime seams are not outer walls.
            portals={(v['x'],v['y'])for v in src['warps']}
            outside=set();queue=[]
            def external(xx,yy):
                return grid[yy*w+xx]in ('C','V')and(xx,yy)not in portals
            for at,tag in enumerate(grid):
                xx,yy=at%w,at//w
                if external(xx,yy)and(xx in (0,w-1)or yy in (0,h-1)):
                    outside.add(at);queue.append(at)
            for at in queue:
                xx,yy=at%w,at//w
                for nx,ny in ((xx-1,yy),(xx+1,yy),(xx,yy-1),(xx,yy+1)):
                    j=ny*w+nx
                    if 0<=nx<w and 0<=ny<h and external(nx,ny)and j not in outside:
                        outside.add(j);queue.append(j)
            body={at for at,tag in enumerate(grid)if at not in outside and tag!='V'}
            frame=set()
            for at in body:
                xx,yy=at%w,at//w
                for nx,ny in ((xx-1,yy),(xx+1,yy),(xx,yy-1),(xx,yy+1)):
                    if 0<=nx<w and 0<=ny<h and grid[ny*w+nx]=='C':frame.add(ny*w+nx)
            body|=frame
            def cave_edge(xx,yy):
                if not(0<=xx<w and 0<=yy<h)or yy*w+xx not in body:return 0
                return sum(1<<i for i,(dx,dy)in enumerate(((-1,0),(1,0),(0,-1),(0,1)))
                    if not(0<=xx+dx<w and 0<=yy+dy<h)or((yy+dy)*w+xx+dx in outside and(yy+dy)*w+xx+dx not in body))
            profiles[d['id']]['caveEdges']=[''.join(chr(33+cave_edge(xx,yy))
                for xx in range(ox,ox+d['width']*2))for yy in range(oy,oy+d['height']*2)]
            profiles[d['id']]['caveBody']=[''.join('1'if yy*w+xx in body and 0<=xx<w and 0<=yy<h else'0'
                for xx in range(ox,ox+d['width']*2))for yy in range(oy,oy+d['height']*2)]
            profiles[d['id']]['caveCeiling']=96+max(terrain[d['kaSeviiSource']]['heights'])if d['kaSeviiSource']in relief else 96
        if exterior or cave=='seafoam':
            portals={(v['x'],v['y'])for v in src['warps']}
            def cliff(xx,yy):
                return 0<=xx<w and 0<=yy<h and grid[yy*w+xx]=='C'and src['kinds'][yy*w+xx]=='WALL'and(xx,yy)not in portals
            masks=[]
            for yy in range(oy,oy+d['height']*2):
                row=''
                for xx in range(ox,ox+d['width']*2):
                    mask=sum(1<<i for i,(dx,dy)in enumerate(((-1,0),(1,0),(0,-1),(0,1)))if cliff(xx+dx,yy+dy))if cliff(xx,yy)else 0
                    row+=chr(33+mask)
                masks.append(row)
            profiles[d['id']]['cliffMasks']=masks
        for prop in props:
            if prop['tag']=='B':
                px,py=prop['x']+ox,prop['y']+oy;ph=prop['h']*16
                dest=prop['doors'][0]['destMap'];roof=ph-(16 if ph<=48 else 32);first=0
                primary=next((yy for yy in range(prop['h'])if src['cells'][(py+yy)*w+px]&1023==(0x028 if 'MART'in dest else 0x048)),None)
                if primary is not None and ('CENTER'in dest or 'MART'in dest):first=primary*16;roof=first+40
                elif prop['w']==5 and ('HOUSE'in dest or 'CORNER'in dest):roof=ph-16;first=8 if ph>=64 and 'HOUSE'in dest else 0
                elif 'WAREHOUSE'in dest:roof=ph-24
                if ptr==0x2d4f70 and (src['cells'][py*w+px]&1023)==0x2c0:first=16
                prop['nativeRoofRows']=roof;prop['nativeRoofStart']=first
                levels={terrain[d['kaSeviiSource']]['heights'][ (door['y']+oy)*w+door['x']+ox]for door in prop['doors']}
                if len(levels)==1:prop['nativeSourceBase']=levels.pop()
            if prop['tag']=='p':
                px,py=prop['x']+ox,prop['y']+oy
                if py>0 and src['cells'][(py-1)*w+px]&1023==0x122:prop['nativeAbove']=1
        if exterior:
            trees=[]
            for x,y,bw,bh,count in components(grid,w,h,'T'):
                seen=set()
                # Primary trees paint left/right halves of one 32px crown.
                # Pair only those authored metatile courses; neighbouring
                # secondary sprites are not evidence of a shared trunk.
                left_halves=nums('00e 014 016 01c 01e 024 026 0b4 0fa')
                canopy_left=nums('288 290 298 2a0 2a3')if ptr in (0x2d4f28,0x2d4ce8)else set()
                # Repeating forest courses are neighbouring crowns. Join
                # only the reviewed top -> crown -> foot spelling, stopping
                # before the next crown; do not merge arbitrary T rows.
                follows={0x00e:{0x01e},0x014:{0x01c},0x016:{0x01e},0x01e:{0x024,0x026},0x0fa:{0x014},
                         0x288:{0x290,0x2a0},0x298:{0x290,0x2a0},0x2a0:{0x2a3}}
                for yy in range(y,y+bh):
                    for xx in range(x,x+bw):
                        at=yy*w+xx
                        if at in seen or grid[at]!='T':continue
                        mid=src['cells'][at]&1023
                        pw=2 if mid in left_halves and xx+1<w and grid[at+1]=='T'and (src['cells'][at+1]&1023)==mid+1 and at+1 not in seen else 1
                        if mid in canopy_left and xx+2<w and all(grid[at+dx]=='T'and at+dx not in seen for dx in range(3)):pw=3
                        ph=1;previous=mid
                        while ph<3 and yy+ph<y+bh and all(grid[(yy+ph)*w+xx+dx]=='T'and (yy+ph)*w+xx+dx not in seen for dx in range(pw)):
                            below=src['cells'][(yy+ph)*w+xx]&1023
                            if below not in follows.get(previous,set()):break
                            previous=below;ph+=1
                        seen.update((yy+dy)*w+xx+dx for dy in range(ph)for dx in range(pw))
                        if xx<ox+sw and xx+pw>ox and yy<oy+sh and yy+ph>oy:
                            trees.append({'tag':'T','x':xx-ox,'y':yy-oy,'w':pw,'h':ph})
            profiles[d['id']]['nativeTrees']=trees
            elevations=terrain[d['kaSeviiSource']]['heights']
            rows=[]
            for yy in range(oy,oy+d['height']*2):
                rows.append(''.join(chr(33+elevations[yy*w+xx]//6)if xx<ox+sw and yy<oy+sh else '!'for xx in range(ox,ox+d['width']*2)))
            profiles[d['id']]['courses']=rows
        elif d['kaSeviiSource']in relief:
            elevations=terrain[d['kaSeviiSource']]['heights']
            profiles[d['id']]['courses']=[''.join(chr(33+elevations[yy*w+xx]//6)if xx<ox+sw and yy<oy+sh else'!'for xx in range(ox,ox+d['width']*2))for yy in range(oy,oy+d['height']*2)]
            profiles[d['id']]['waterfallRelief']=bool(terrain[d['kaSeviiSource']]['fall_flights'])
        elif kind=='room':
            candidates=[]
            for yy in range(oy,min(h,oy+sh)):
                for xx in range(ox,min(w,ox+sw)):
                    at=yy*w+xx
                    if grid[at]!='X':continue
                    height=2 if yy+1<min(h,oy+sh) and grid[at+w]=='X'else 1
                    image=src['cache'][src['cells'][at]&1023][0]
                    colors=set(image.getdata())
                    if max(max(c[:3])for c in colors)<32:continue
                    # The repeated middle wall row must be actual wall paint.
                    # Few-colour black padding/vertical corner strips used to
                    # beat the complete panels in marts, tower and warehouse.
                    bodyBlack=sum(max(image.getpixel((sx,8))[:3])<32 for sx in range(16))
                    padding=sum(max(c[:3])<32 for c in image.getdata())
                    candidates.append((bodyBlack>0,padding>0,yy,len(colors),xx,height))
            if candidates:
                _,_,yy,_,xx,height=min(candidates)
                profiles[d['id']]['nativeWallSource']={'x':xx-ox,'y':yy-oy,'w':1,'h':height}
            pictures=[]
            for yy in range(h):
                for xx in range(w):
                    if src['cells'][yy*w+xx]&1023==0x119 and grid[yy*w+xx]=='X'and ox<=xx<ox+sw and oy<=yy<oy+sh:
                        assert yy+1<min(h,oy+sh) and src['cells'][(yy+1)*w+xx]&1023==0x121,('picture continuation',d['id'],xx,yy)
                        pictures.append({'x':xx-ox,'y':yy-oy,'w':1,'h':2,'cropTop':8,'cropBottom':8})
            profiles[d['id']]['nativeWallPictures']=pictures
            for yy in range(oy,min(h,oy+sh)):
                for xx in range(ox,min(w-1,ox+sw-1)):
                    if src['cells'][yy*w+xx]&1023==0x158 and src['cells'][yy*w+xx+1]&1023==0x159 and grid[yy*w+xx]=='X'and grid[yy*w+xx+1]=='X':
                        pictures.append({'x':xx-ox,'y':yy-oy,'w':2,'h':1,'cropTop':0,'cropBottom':8})
            for yy in range(oy,min(h,oy+sh)):
                for xx in range(ox,min(w,ox+sw)):
                    upper=src['cells'][yy*w+xx]&1023
                    lower={0x118:0x120,0x160:0x168,0x2bf:0x2c7}.get(upper)
                    if lower and yy+1<min(h,oy+sh)and src['cells'][(yy+1)*w+xx]&1023==lower and grid[yy*w+xx]=='X':
                        pictures.append({'x':xx-ox,'y':yy-oy,'w':1,'h':2,'cropTop':8,'cropBottom':8})
                    if d['kaSeviiSource']=='FiveIsland_ResortGorgeous_House'and upper==0x2fd:
                        assert src['cells'][yy*w+xx+1]&1023==0x2fe and src['cells'][(yy+1)*w+xx]&1023==0x305 and src['cells'][(yy+1)*w+xx+1]&1023==0x306
                        pictures.append({'x':xx-ox,'y':yy-oy,'w':2,'h':2,'cropTop':8,'cropBottom':8})
        report[d['id']]={'kind':kind,'props':len(props)}
    def lua(v):
        if v is None:return 'nil'
        if isinstance(v,bool):return str(v).lower()
        if isinstance(v,str):return json.dumps(v,ensure_ascii=False)
        if isinstance(v,(int,float)):return str(v)
        if isinstance(v,list):return '{'+','.join(lua(x)for x in v)+'}'
        return '{'+','.join('['+lua(k)+']='+lua(x)for k,x in v.items())+'}'
    args.output.write_text('-- Generated semantic recipes; no ROM artwork. See scripts/build_sevii_voxel_profiles.py.\nreturn '+lua(profiles)+'\n')
    print('Profiles:',len(profiles),'sources:',len(sources),'props:',sum(v['props']for v in report.values()),'bytes:',args.output.stat().st_size)
if __name__=='__main__':main()
