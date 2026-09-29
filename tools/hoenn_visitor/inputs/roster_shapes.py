import copy

def shade(h,f):return ''.join(f'{min(255,round(int(h[i:i+2],16)*f)):02x}' for i in [0,2,4])

def create(p):
    name=p['id']; identity=name.split('--')[0]; acc=set(p['accessory'].split(',')); outfit=p['outfit']; hair=p['hair']
    colors=dict(old.COLORS)
    colors.update(hair=p['haircolor'],hairlight=shade(p['haircolor'],1.17),hairdark=shade(p['haircolor'],.72),top=p['top'],bottom=p['bottom'],accent=p['accent'],topshade=shade(p['top'],.75),bottomlight=shade(p['bottom'],1.22))
    old.PALETTE=list(colors)
    m=old.Model('ascendant_'+name); c=m.cube
    skirt=outfit in ['skirt','dress','robe']; short=outfit=='shorts'
    m.bone('body',[0,15,0]); body=m.current
    c('top',(0,22,0),(10,14,6));c('skin',(0,29,0),(4,3,4))
    longskirt=outfit=='robe' or identity in ['agatha','granny']
    if skirt:
        c('bottom' if outfit in ['skirt','robe'] else 'top',(0,15,0),(12,6,7))
        c('topshade',(0,12,-3.7),(12,1,1))
    if outfit in ['vest','coat','jacket','suit']:
        c('accent' if outfit in ['vest','jacket'] else 'white',(0,22,-3.15),(6,12,1))
        for s in [-1,1]:
            c('top',(s*3.7,22,-3.3),(3,14,1));c('top',(s*2.8,26.5,-3.95),(3,3,1),[0,0,s*22])
            if outfit=='coat': c('top',(s*3.6,13 if identity!='cynthia' else 10,0),(3,6 if identity!='cynthia' else 12,7))
    if outfit=='gi':
        c('white',(0,26,-3.7),(2,5,1),[0,0,30]);c('accent',(0,17,-3.8),(11,2,1));c('accent',(-1,14,-3.9),(2,5,1),[0,0,-10])
    if outfit=='overall':
        c('bottom',(0,20,-3.6),(8,9,1))
        for s in [-1,1]:c('bottom',(s*3,26,-3.6),(2,5,1));c('gold',(s*3,24,-4.2),(1,1,1))
    for s,side in [(-1,'right'),(1,'left')]:
        m.bone('leg_'+side,[s*2.7,15,0],'body')
        c('skin' if skirt else 'bottom',(s*2.7,12,0),(4,6,5))
        if longskirt:c('bottom',(s*2.7,11,0),(6,8,7))
        m.bone('shin_'+side,[s*2.7,9,0],'leg_'+side)
        c('skin' if skirt or short else 'bottom',(s*2.7,6,0),(4,6,5))
        if longskirt:c('bottom',(s*2.7,6,0),(6,6,7))
        if identity in ['sabrina','ariana','jessie','team-rocket-female']:c('top' if identity in ['sabrina','ariana'] else 'ink',(s*2.7,5,0),(4,7,6))
        if not skirt and not short:c('bottomlight',(s*2.7,7,-2.55),(2,4,1))
        if short:c('white',(s*2.7,3.8,0),(4,2,5))
        c('topshade' if skirt else 'ink',(s*2.7,2,-1),(5,3,7));c('sole',(s*2.7,.5,-1),(5,1,7))
        if short:c('accent',(s*2.7,2,-4.2),(4,2,1))
        m.bone('arm_'+side,[s*6,27,0],'body')
        c('skin',(s*7,23.5,0),(4,5,4))
        sleeveless=outfit=='bare' or identity in ['biker','cue-ball','lt-surge','rocker','misty','beauty','lorelei','swimmer']
        if not sleeveless:c('white' if outfit=='vest' else 'top',(s*6.8,25.5,0),(5,5,5),[0,0,-s*8])
        m.bone('forearm_'+side,[s*7,21,0],'arm_'+side)
        c('skin',(s*7,18.5,0),(4,5,4))
        if outfit in ['coat','suit','uniform','robe','jacket']:
            c('top',(s*7,19,0),(4,5,5));c('accent',(s*7,17,0),(4,1,5))
        c('ink' if 'gloves' in acc else 'skinlight',(s*7,14.5,-.2),(4,3,4))
        c('skinshade',(s*5.4,14.8,-1.8),(1,2,2))
    # Exactly the original square head, raised eyes, eye/lid bones and blink mechanism.
    for b in base['blue']['geometry']['bones']:
        if b['name'] in ['head','eye_left','eye_right','lid_left','lid_right']:
            b=copy.deepcopy(b)
            if b['name']=='head':b['cubes']=[q for q in b['cubes'] if int(q['uv'][1]/128)*8+int(q['uv'][0]/128) not in [15,16,17]]
            m.bones.append(b)
    head=next(b for b in m.bones if b['name']=='head');m.current=head
    if hair not in ['bald','balding']:
        c('hair',(0,40,1),(12,5,10));c('hairlight',(0,43,1),(9,1,8))
        c('hairdark',(0,35,4.5),(11,7,3))
        for s in [-1,1]:c('hair',(s*5.2,36,.4),(2,5,6))
        if hair in ['short','parted','bob','long','pony','braid','braids','pigtails','beard']:
            c('hair',(-2.5,39,-4.5),(5,4,2),[0,0,-18]);c('hairlight',(2.5,40,-4.5),(5,3,2),[0,0,-15])
        if hair in ['spiky','messy','quiff','mohawk']:
            for x,y,z,rz in ([(-4,42,0,-25),(0,44,0,18),(4,42,1,30),(-2,40,-4,-25)] if hair!='mohawk' else [(0,44,0,0),(0,42,-3,0)]):
                c('hairlight' if y>42 else 'hair',(x,y,z),(3 if hair=='mohawk' else 4,6,4),[0,0,rz])
        if hair in ['bob','long','swept']:
            c('hair',(0,32 if hair=='bob' else 28,5),(12,10 if hair=='bob' else 18,5))
            for s in [-1,1]:c('hair',(s*5.5,33 if hair=='bob' else 29,2),(3,12 if hair=='bob' else 18,7));c('hairlight',(s*5.5,31,5.5),(1,7,1))
        if hair=='swept':
            c('hair',(0,37,8),(12,12,8),[-20,0,0]);c('hairlight',(0,32,12),(9,9,6),[-25,0,0])
        if hair in ['pony','braid']:
            for j in range(3):c('hair' if j%2 else 'hairlight',(6 if hair=='braid' else 0,35-j*5,6+j),(4,6,4),[0,0,10*j])
        if hair in ['pigtails','braids']:
            for s in ([1] if identity=='misty' else [-1,1]):
                c('accent',(s*6.5,35,2),(2,2,3))
                for j in range(3 if hair=='braids' else 2):c('hair',(s*(7+j),34-j*3,3),(4,5,4),[0,0,s*25])
    elif hair=='balding':
        c('hair',(0,35,4.5),(10,6,3))
        for s in [-1,1]:c('hair',(s*5.5,36,1),(2,6,5))
    if hair=='beard':c('hair',(0,30,-3.7),(8,4,3));c('hairlight',(0,28.5,-4),(5,1,2))
    if 'moustache' in acc:
        for s in [-1,1]:c('hair',(s*1.5,32,-5.8),(3,1,2),[0,0,s*10])
    if 'glasses' in acc or 'sunglasses' in acc:
        for s in [-1,1]:
            for y in [33.4,37.1]:c('ink',(s*2.8,y,-6.5),(4,1,1))
            for dx in [-1.8,1.8]:c('ink',(s*2.8+dx,35.2,-6.5),(1,3,1))
            if 'sunglasses' in acc:c('ink',(s*2.8,35.2,-6.5),(3,3,1))
        c('ink',(0,35.8,-6.5),(2,1,1))
    if 'mask' in acc:c('ink',(0,35.6,-4.9),(10,4,1))
    if 'heterochromia' in acc:
        eye=next(b for b in m.bones if b['name']=='eye_left')
        eye['cubes'][2]['uv']=[(old.PALETTE.index('green')%8)*128,(old.PALETTE.index('green')//8)*128]
    if acc & {'cap','safarihat','peaked','sailorhat','hardhat','swimcap','nursehat','chefhat','beanie','tophat'}:
        hat='accent';height=5;depth=11;width=13
        if identity.startswith('team-rocket') or identity=='burglar':hat='ink'
        if identity=='guard':hat='top'
        if identity in ['ash','kris','ss-anne-captain']:hat='white'
        if identity=='gold':hat='gold'
        if 'swimcap' in acc:hat='bottom'
        if acc & {'sailorhat','nursehat','chefhat'}:hat='white'
        if 'tophat' in acc:hat='ink';height=8;width=10;depth=9
        if 'chefhat' in acc:height=8
        c(hat,(0,41,0),(width,height,depth));c('topshade' if 'beanie' in acc else 'ink',(0,38.5,0),(13,1,11))
        if acc & {'cap','peaked','sailorhat','hardhat'}:c(hat,(0,38,-6.5),(12,1,5))
        if acc & {'safarihat','tophat'}:c(hat,(0,38,-.5),(16,1,14))
        if 'nursehat' in acc:c('red',(0,41,-6),(1,3,1));c('red',(0,41,-6),(3,1,1))
        if 'peaked' in acc:c('gold',(0,40,-6),(3,2,1))
        if 'cap' in acc:c('white',(0,41,-6),(3,2,1))
        if identity=='ash':
            for s in [-1,1]:c('red',(s*5,41,-.2),(3,5,11))
            c('red',(0,38,-6.5),(12,1,5));c('green',(0,41,-6.5),(1,2,1))
        if identity=='gold':c('ink',(-3,41,-6),(5,5,1))
    if 'headband' in acc:c('accent',(0,40,-5),(12,1,1))
    if 'goggles' in acc:
        for s in [-1,1]:c('ink',(s*3,40,-6),(4,3,1));c('denimlight',(s*3,40,-6.6),(2,1,1))
    m.current=body
    if 'rocket' in acc:
        # Block-built R, with a visible counter and diagonal leg.
        for center,size in [((2,23,-4.3),(1,6,1)),((0,26,-4.3),(4,1,1)),((-1.5,24.5,-4.3),(1,3,1)),((0,23,-4.3),(4,1,1))]:c('red',center,size)
        c('red',(-.7,21.3,-4.3),(1,3,1),[0,0,-30])
    if 'emblem' in acc:c('white',(0,24,-3.6),(5,3,1));c('white',(0,24,-3.6),(7,1,1))
    if 'stripes' in acc:
        for y in [19,23,27]:c('sole',(0,y,-3.8),(8,1,1))
    if 'apron' in acc:c('white',(0,21,-3.9),(6,9,1));c('white',(0,14,-4.1),(9,5,1))
    if 'suspenders' in acc:
        for s in [-1,1]:c('accent',(s*3,22,-4),(1,12,1))
    if 'sash' in acc:c('accent',(0,20,-3.8),(11,3,1));c('accent',(2,15,-4),(2,7,1))
    if acc & {'belt','dogtags','pockets','badge','studs','bracelet'}:
        if 'belt' in acc:c('accent',(0,16,0),(11,2,7));c('gold',(0,16,-4),(2,2,1))
        if 'dogtags' in acc:c('sole',(0,24,-3.8),(1,4,1))
        if 'badge' in acc:c('gold',(-3,25,-4),(2,2,1))
        if 'pockets' in acc:
            for s in [-1,1]:c('topshade',(s*3,19,-3.9),(3,3,1));c('accent',(s*3,20.5,-4.5),(3,1,1))
        if 'studs' in acc:
            for s in [-1,1]:
                for y in [20,24,27]:c('sole',(s*3.5,y,-4.1),(1,1,1))
        if 'bracelet' in acc:
            for b in m.bones:
                if b['name'].startswith('forearm_'):m.current=b;c('gold',(b['pivot'][0],16.5,0),(4,1,5))
            m.current=body
    if acc & {'bow','tie','collar','scarf','fur','pendant'}:
        for s in [-1,1]:c('white' if 'collar' in acc else 'accent',(s*2,27,-3.9),(3,2,1),[0,0,s*20])
        if 'tie' in acc:c('accent',(0,23.5,-4),(2,5,1))
        if 'pendant' in acc:c('gold',(0,25,-4),(2,2,1))
        if 'scarf' in acc:c('accent',(0,28,0),(11,2,7));c('accent',(4,23,4),(3,8,1),[0,0,-18])
        if 'fur' in acc:
            for s in [-1,1]:c('accent',(s*3,27,-3.5),(3,3,2))
    if 'zip' in acc:c('accent',(0,22,-3.7),(1,12,1))
    if 'muscles' in acc:
        for s in [-1,1]:
            c('skinlight',(s*2.5,25,-3.4),(4,3,1))
            for y in [19,22]:c('skinshade',(s*2,y,-3.4),(3,2,1))
    if 'cape' in acc:c('redshade',(0,20,5),(14,20,2));c('black',(0,27,2),(14,4,8))
    if 'backpack' in acc or 'bag' in acc:c('topshade',(0,22,5),(9,11,4));c('accent',(0,20,7.3),(7,4,1))
    if 'pouch' in acc:c('hairdark',(5.7,16,.5),(3,4,4));c('gold',(5.7,17,-1.8),(1,1,1))
    if 'guitar' in acc:c('hairdark',(0,21,6),(7,9,3));c('hairlight',(0,29,6),(2,10,2))
    if acc & {'cane','net','rod','handheld'}:
        m.current=next(b for b in m.bones if b['name']=='forearm_right')
        if 'handheld' in acc:c('gray',(-7,15,-3),(4,5,1));c('greenlight',(-7,16,-3.7),(2,2,1))
        elif 'cane' in acc:c('hairdark',(-8,8,-3),(1,16,1));c('gold',(-7.5,16,-3),(2,1,2))
        else:
            c('hairdark',(-8,24,-2),(1,25,1))
            if 'net' in acc:
                for x in [-12,-4]:c('white',(x,38,-2),(1,10,1))
                for y in [33,43]:c('white',(-8,y,-2),(9,1,1))
                for x in [-10,-8,-6]:c('sole',(x,38,-2),(0,10,0))
            else:c('sole',(-8,25,-2.5),(0,25,0))
    geometry={'description':{'identifier':'geometry.'+m.name,'texture_width':1024,'texture_height':1024,'visible_bounds_width':5,'visible_bounds_height':5,'visible_bounds_offset':[0,1.5,0]},'bones':m.bones}
    # Identity-sensitive silhouettes while retaining the requested square construction.
    sx=1.12 if name in ['hiker','cue-ball','bruno','lt-surge'] else 1
    sy=.86 if name in ['little-boy','little-girl','game-boy-kid','youngster'] else .94 if name in ['agatha','granny','gramps','mr-fuji'] else 1
    for b in m.bones:
        b['pivot']=[round(b['pivot'][0]*sx,3),round(b['pivot'][1]*sy,3),b['pivot'][2]]
        for q in b.get('cubes',[]):
            # Keep integer BoxUV dimensions; only reposition for stature, preserving unit blocks.
            for field in ['origin','pivot']:
                if field in q:q[field]=[round(q[field][0]*sx,3),round(q[field][1]*sy,3),q[field][2]]
    return {'id':name,'name':name.replace('-',' ').title(),'palette':list(colors.values()),'geometry':geometry,'profile':p}