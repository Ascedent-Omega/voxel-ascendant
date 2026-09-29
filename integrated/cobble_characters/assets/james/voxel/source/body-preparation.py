from pathlib import Path
from PIL import Image, ImageDraw, ImageFilter, ImageOps
import json, zipfile

ROOT = Path(__file__).resolve().parent
source = Image.open(ROOT / 'gemini-original.jpg').convert('RGB')
directions = ['front', 'left', 'back', 'right']
poses = ['stand', 'step-a', 'step-b']
ys = [0, 740, 1364, 1990, 2624]
xs = [0, 540, 1081, 1622]
cw, ch, height = 192, 256, 224
sprites = []
records = []

for row, direction in enumerate(directions):
    row_sprites = []
    for col, pose in enumerate(poses):
        # The source has a stray disconnected trouser fragment next to back/A.
        # Use the clean opposite back pose mirrored, matching the requested pose.
        source_col = 2 if row == 2 and col == 1 else col
        rgb = source.crop((xs[source_col], ys[row], xs[source_col+1], ys[row+1]))
        bg = (41, 50, 59)
        mask = Image.new('L', rgb.size)
        mask.putdata([255 if max(abs(p[k]-bg[k]) for k in range(3)) > 5 else 0 for p in rgb.getdata()])
        # Keep the connected character seeded at its white torso.
        closed = mask.filter(ImageFilter.MaxFilter(3)).filter(ImageFilter.MinFilter(3))
        seed = (rgb.width//2, int(rgb.height*.53))
        if closed.getpixel(seed) == 0:
            candidates = [(x,y) for y in range(int(rgb.height*.4),int(rgb.height*.65)) for x in range(rgb.width//2-50,rgb.width//2+50) if closed.getpixel((x,y))]
            seed = min(candidates, key=lambda p: abs(p[0]-rgb.width//2)+abs(p[1]-rgb.height*.53))
        ImageDraw.floodfill(closed, seed, 128)
        alpha = closed.point(lambda v: 255 if v == 128 else 0)
        rgba = rgb.convert('RGBA')
        rgba.putalpha(alpha)
        bbox = alpha.getbbox()
        sprite = rgba.crop(bbox)
        if row == 2 and col == 1:
            sprite = ImageOps.mirror(sprite)
        scale = height / sprite.height
        sprite = sprite.resize((round(sprite.width*scale), height), Image.Resampling.LANCZOS)
        frame = Image.new('RGBA', (cw,ch))
        frame.alpha_composite(sprite, ((cw-sprite.width)//2, ch-16-height))
        name = f'{direction}-{pose}.png'
        frame.save(ROOT / name)
        row_sprites.append(frame)
        records.append({'direction':direction,'pose':pose,'file':name,'column':col,'row':row,'source_bbox':bbox,'mirrored':row==2 and col==1})
    sprites.append(row_sprites)

atlas = Image.new('RGBA',(cw*3,ch*4))
for row in range(4):
    for col in range(3):
        atlas.alpha_composite(sprites[row][col],(col*cw,row*ch))
atlas.save(ROOT / 'james-walk-3x4-transparent.png')
bg = Image.new('RGBA',atlas.size,(32,43,50,255))
bg.alpha_composite(atlas)
bg.convert('RGB').save(ROOT / 'james-walk-3x4-preview.png')

frames=[]
for pose in [0,1,0,2]:
    canvas=Image.new('RGB',(cw*4,ch+30),(32,43,50))
    draw=ImageDraw.Draw(canvas)
    for row,label in enumerate(['Vorne','Links','Hinten','Rechts']):
        canvas.paste(sprites[row][pose],(row*cw,30),sprites[row][pose])
        draw.text((row*cw+12,10),label,fill=(215,226,230))
    frames.append(canvas)
frames[0].save(ROOT/'walk-preview.gif',save_all=True,append_images=frames[1:],duration=180,loop=0)
(ROOT/'sprites.json').write_text(json.dumps({'provider':'Google Gemini via Safari','source':'https://gemini.google.com/app/8189510a7a4b95be','columns':3,'rows':4,'frame_width':cw,'frame_height':ch,'anchor':[cw//2,ch-16],'directions':directions,'poses':poses,'walk_sequence':[0,1,0,2],'frame_duration_ms':180,'frames':records,'notes':'Generated artwork; locally cut, background removed and aligned. Back step-a mirrors the clean back step-b to exclude an extraneous generated fragment. Not integrated into game runtime.'},indent=2)+'\n')
with zipfile.ZipFile(ROOT/'james-walk-sprites.zip','w',zipfile.ZIP_DEFLATED) as z:
    for p in sorted(ROOT.glob('*.png')): z.write(p,p.name)
    for name in ['sprites.json','walk-preview.gif']: z.write(ROOT/name,name)
print('Created 12 transparent frames, atlas, animation preview and ZIP.')
