from pathlib import Path
from PIL import Image, ImageDraw
import json, math, hashlib, re
OUT = Path(__file__).resolve().parent


COLORS = dict(skin='f1bb81', skinshade='d99562', skinlight='ffcf94', ink='24272c', black='303238', gray='56585b', white='f3ecdc', red='c73630', redlight='e94b37', redshade='952b27', denim='285b84', denimlight='3679a6', sole='bcbcb2', gold='d8b566', hairred='262526', hairblue='b86b25', hairbluelight='da8730', hairbluedark='8e481e', hairgreen='673d27', hairgreenlight='855133', hairgreendark='492f24', purple='684181', purplelight='85549b', green='398362', greenlight='62a37a', greenshade='275d49', eye='403b2f', mouth='b16a48')

PALETTE = list(COLORS)

class Model:
    def __init__(self,name):
        self.name=name; self.bones=[dict(name=name,pivot=[0,0,0])]; self.current=None
    def bone(self,name,pivot,parent=None):
        self.current=dict(name=name,parent=parent or self.name,pivot=pivot,cubes=[])
        self.bones.append(self.current)
    def cube(self,color,center,size,rotation=None,pivot=None):
        assert all(v==int(v) and v>=0 for v in size)
        i=PALETTE.index(color)
        c=dict(origin=[round(center[j]-size[j]/2,3) for j in range(3)],size=size,uv=[(i%8)*128,(i//8)*128],inflate=round(.003*(len(self.current['cubes'])+1),4))
        if rotation: c.update(rotation=rotation,pivot=pivot or center)
        self.current['cubes'].append(c)
    def save(self):
        data={'format_version':'1.12.0','minecraft:geometry':[{'description':{'identifier':'geometry.'+self.name,'texture_width':1024,'texture_height':512,'visible_bounds_width':4,'visible_bounds_height':4,'visible_bounds_offset':[0,1.5,0]},'bones':self.bones}]}
        (OUT/(self.name+'.geo.json')).write_text(json.dumps(data,indent=2))
        return data

def build(who):
    m=Model('ascendant_'+who)
    c=m.cube
    girl=who=='green'
    pants='denim' if who=='red' else 'purple'
    m.bone('body',[0,15,0]); c('black',(0,22,0),(10,14,6)); c('skin',(0,29,0),(4,3,4))
    if who=='red':
        for s in [-1,1]:
            c('red',(s*3.5,22,-.1),(3,13,7)); c('white',(s*2,21,-3.7),(1,12,1))
            c('white',(s*3,27,-3.6),(2,3,1),[0,0,s*18])
            c('redshade',(s*4,18,-3.75),(2,2,1)); c('white',(s*3.5,15.5,-.1),(3,1,7))
        c('redshade',(0,22,5.5),(9,11,5)); c('red',(0,23,7),(8,9,3))
        c('redlight',(0,20,8.7),(7,4,1)); c('black',(0,22.5,9),(8,1,1)); c('gold',(0,22.5,9.55),(2,2,1))
        for s in [-1,1]: c('gray',(s*4,26,3.5),(1,5,2))
    elif who=='blue':
        c('ink',(0,15.5,0),(10,2,6)); c('gold',(0,15.5,-3.7),(3,2,1)); c('ink',(0,15.5,-4.3),(1,1,1))
        c('skin',(0,27.2,-3.1),(3,2,1))
        for s in [-1,1]: c('ink',(s*2,27,-3.7),(3,3,1),[0,0,s*25])
        c('gray',(0,23,-3.4),(1,1,1))
    else:
        c('black',(0,16,0),(12,5,7)); c('gray',(0,14,-3.6),(12,1,1))
        c('gold',(0,26.5,-3.6),(3,1,1))
        c('green',(0,21.5,-4),(2,17,1),[0,0,32])
        c('greenshade',(6.3,15.5,.5),(5,6,4)); c('green',(6.3,16,-1),(5,5,2))
        c('greenlight',(6.3,18,-1.6),(5,2,1)); c('gold',(6.3,17,-2.15),(1,1,1))
    for s,side in [(-1,'right'),(1,'left')]:
        m.bone('leg_'+side,[s*2.7,15,0],'body')
        if girl:
            c('skin',(s*2.7,12,0),(4,6,4))
            m.bone('shin_'+side,[s*2.7,9,0],'leg_'+side)
            c('black',(s*2.7,5,0),(4,8,5))
            c('gray',(s*2.7,8.5,-.1),(4,1,6)); c('ink',(s*2.7,1.8,-1),(5,3,7)); c('sole',(s*2.7,.5,-1),(5,1,7))
            c('gray',(s*2.7,3,-3.6),(3,1,1))
        else:
            c(pants,(s*2.7,12,0),(4,6,5)); c('denimlight' if who=='red' else 'purplelight',(s*2.7,10,-2.55),(2,2,1))
            m.bone('shin_'+side,[s*2.7,9,0],'leg_'+side)
            c(pants,(s*2.7,6,0),(4,6,5)); c('denimlight' if who=='red' else 'purplelight',(s*2.7,7,-2.55),(2,4,1))
            c('ink',(s*2.7,2,-1),(5,3,7)); c('sole',(s*2.7,.5,-1),(5,1,7))
            if who=='red':
                c('red',(s*2.7,2,-4.2),(4,2,1)); c('white',(s*2.7,3,-2.5),(3,1,3))
        m.bone('arm_'+side,[s*6,27,0],'body')
        c('skin',(s*7,23.5,0),(4,5,4))
        if not girl: c('black',(s*6.8,25.5,0),(5,5,5),[0,0,-s*8])
        m.bone('forearm_'+side,[s*7,21,0],'arm_'+side)
        c('skin',(s*7,18.5,0),(4,5,4))
        c('purple' if who=='blue' else 'ink',(s*7,17,0),(4,2,5))
        c('skinlight',(s*7,14.5,-.2),(4,3,4)); c('skinshade',(s*5.4,14.8,-1.8),(1,2,2))
    m.bone('head',[0,29,0],'body')
    head=m.current
    c('skin',(0,35,0),(11,10,9)); c('skinlight',(0,32.5,-.4),(9,5,9)); c('skin',(0,30.3,-.1),(7,2,7))
    for s in [-1,1]:
        c('skinshade',(s*5.8,34,.1),(2,3,3)); c('skinlight',(s*6,34,-.5),(1,2,2))
        side='left' if s==1 else 'right'
        m.bone('eye_'+side,[s*2.8,35.4,-5.0],'head')
        c('ink',(s*2.8,35.5,-4.65),(3,4,1)); c('white',(s*2.8,35.3,-5.2),(2,3,1))
        c('green' if girl else 'eye',(s*2.5,35.2,-5.75),(1,3,1)); c('white',(s*2.5,36.1,-6.28),(1,1,0))
        m.bone('lid_'+side,[s*2.8,35.4,-5.0],'head')
        c('skin',(s*2.8,35.4,-4.8),(3,4,1))
        c('ink',(s*2.8,35.1,-5.4),(3,1,1))
        m.current=head
        c('skinshade',(s*3.4,32.7,-5),(2,1,1))
        c('hairgreen' if girl else 'ink',(s*2.8,38,-4.7),(3,1,1),[0,0,-s*8])
    c('skinlight',(0,33.4,-5),(1,2,1)); c('mouth',(0,31.4,-4.6),(2,1,1))
    if who=='red':
        c('hairred',(0,38,1),(12,7,10)); c('hairred',(0,31.5,4.2),(10,3,3))
        # Keep forehead visible; cap, fringe and stepped nape are separate volumes.
        for s in [-1,1]:
            c('hairred',(s*5,33,1),(2,6,7)); c('hairred',(s*5.5,31,2.5),(2,3,3),[0,0,-s*24])
            c('hairred',(s*3.7,38.3,-4.5),(3,3,2),[0,0,s*18])
        c('red',(0,41,0),(13,6,11)); c('redlight',(0,44,0),(11,1,9)); c('redshade',(0,38.5,1),(13,1,10))
        c('white',(0,40.3,-5.6),(6,4,1)); c('red',(0,40,-6.2),(3,2,1))
        c('white',(0,38,-7),(12,1,6)); c('gray',(0,37.45,-7),(12,0,6)); c('redshade',(0,44.8,0),(2,1,2))
    elif who=='blue':
        c('hairblue',(0,40,1),(12,6,10)); c('hairbluedark',(0,35,4),(11,7,4))
        for x,y,z,w,h,d,rz,ry in [(-5,41,0,4,7,6,-40,-10),(5,41,1,4,7,6,35,10),(-2,44,0,4,7,5,30,0),(3,44,2,3,8,4,15,0),(0,40,-4,4,6,3,-25,0),(-4,38.7,-4,3,6,3,-40,0),(4,39,-3,3,5,3,20,0),(-6,38,2,3,5,4,-55,0),(6,38,3,3,5,4,55,0)]:
            c('hairbluelight' if y>41 else 'hairblue',(x,y,z),(w,h,d),[0,ry,rz]); c('hairbluelight',(x,y+h*.38,z),(max(1,w-2),3,max(1,d-2)),[0,ry,rz])
        for s in [-1,1]: c('hairbluedark',(s*5.2,34.5,.5),(2,5,4))
    else:
        c('hairgreen',(0,40.2,1),(12,5,10)); c('hairgreenlight',(0,43,1),(9,1,8))
        c('hairgreen',(0,31,5),(12,17,5)); c('hairgreendark',(0,25.5,5.3),(10,9,5))
        for s in [-1,1]:
            c('hairgreen',(s*5.5,34,2),(3,13,7)); c('hairgreenlight',(s*5.8,26,4),(3,9,5),[0,0,s*15])
            c('hairgreen',(s*5,22.5,4.2),(3,6,4),[0,0,-s*22]); c('hairgreenlight',(s*3,29,7.3),(2,13,1))
            c('greenlight',(s*5.8,32,-1.65),(1,2,1))
        c('hairgreenlight',(-2.5,39.4,-4.5),(5,7,3),[0,0,-35]); c('hairgreen',(1.5,40,-4),(5,4,3),[0,0,-25])
    data=m.save()
    clips={}
    def keys(duration,fn,count=24):
        return {f'{duration*i/count:.6f}':[round(n,5) for n in fn(2*math.pi*i/count)] for i in range(count+1)}
    idle={'body':{'position':keys(2,lambda t:[0,.12*(1-math.cos(t)),0])}}
    walk={'body':{'position':keys(.96,lambda t:[.15*math.sin(t),.6+.25*(1-math.cos(2*t)),0])},'head':{'rotation':keys(.96,lambda t:[0,1.3*math.sin(t),0])}}
    for side,sign in [('left',1),('right',-1)]:
        for part,amp in [('leg',24),('arm',-24)]:
            walk[part+'_'+side]={'rotation':keys(.96,lambda t,a=amp,s=sign:[s*a*math.cos(t),0,0])}
        walk['shin_'+side]={'rotation':keys(.96,lambda t,s=sign:[-32*max(0,s*math.sin(t))**2,0,0])}
        walk['forearm_'+side]={'rotation':keys(.96,lambda t,s=sign:[10+10*(1-s*math.cos(t)),0,0])}
        idle['forearm_'+side]={'rotation':[7,0,0]}
    blink={}
    for side in ['left','right']:
        blink['eye_'+side]={'scale':{'0':[1,1,1],'2.65':[1,1,1],'2.73':[1,.06,1],'2.76':[0,0,0],'2.84':[0,0,0],'2.88':[1,.06,1],'2.98':[1,1,1],'4':[1,1,1]}}
        blink['lid_'+side]={'scale':{'0':[0,0,0],'2.73':[0,0,0],'2.76':[1,1,1],'2.84':[1,1,1],'2.88':[0,0,0],'4':[0,0,0]}}
    for name,seconds,bones in [('ground_idle',2,idle),('ground_walk',.96,walk),('blink',4,blink)]: clips['animation.'+m.name+'.'+name]={'loop':True,'animation_length':seconds,'bones':bones}
    (OUT/(m.name+'.animation.json')).write_text(json.dumps({'format_version':'1.8.0','animations':clips},indent=2))
    poser={'rootBone':m.name,'portraitScale':.7,'portraitTranslation':[0,-.8,0],'profileScale':.5,'profileTranslation':[0,0,0],'poses':{'standing':{'poseTypes':['STAND','PORTRAIT','PROFILE'],'animations':[f"q.bedrock('{m.name}', 'ground_idle')"]},'walking':{'poseTypes':['WALK'],'animations':[f"q.bedrock('{m.name}', 'ground_walk')"]}}}
    for pose in poser['poses'].values(): pose['animations'].append(f"q.bedrock('{m.name}', 'blink')")
    (OUT/(m.name+'.poser.json')).write_text(json.dumps(poser,indent=2))
    return {'name':who.title(),'geometry':data['minecraft:geometry'][0],'animations':clips}