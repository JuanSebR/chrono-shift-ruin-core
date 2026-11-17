from pathlib import Path
import hashlib, json
from PIL import Image, ImageDraw
import numpy as np

OUT = Path(__file__).resolve().parent
SRC = OUT.parent
files = sorted(SRC.glob('*.png'))
before = {p.name: hashlib.sha256(p.read_bytes()).hexdigest() for p in files}
report = {}
for p in files:
    im = Image.open(p)
    a = np.asarray(im.convert('RGBA'))[:,:,3]
    report[p.name] = dict(size=im.size, mode=im.mode, alpha_min=int(a.min()), alpha_max=int(a.max()), transparent_pixels=int((a==0).sum()), partial_alpha_pixels=int(((a>0)&(a<255)).sum()), useful_bounds=im.convert('RGBA').getchannel('A').getbbox(), sha256=before[p.name])
platform = Image.open(SRC/'plataforma 3 s2.2.png').convert('RGBA')
pixels = np.array(platform)
pixels[pixels[:,:,3] <= 1] = 0
platform = Image.fromarray(pixels)
bounds = platform.getchannel('A').getbbox()
crop = platform.crop(bounds)
crop.save(OUT/'cyan_platform_cropped.png')
variants = {}
for label, width in [('A',244),('B',150)]:
    height = round(crop.height*width/crop.width)
    variants[label] = crop.resize((width,height), Image.Resampling.NEAREST)
    variants[label].save(OUT/f'cyan_platform_{label}_{width}px.png')

sheet = Image.new('RGB',(850,310),(35,35,45))
d = ImageDraw.Draw(sheet)
d.text((16,12),'A: 244 px / B: 150 px - nearest - 24 x 40 Player reference',fill='white')
for label, x in [('A',50),('B',470)]:
    im=variants[label]
    sheet.paste(im,(x,105),im)
    d.rectangle((x+im.width//2-12,65,x+im.width//2+11,104),outline='white',width=2)
    d.text((x,255),f'{label}: {im.width} x {im.height}',fill='white')
sheet.save(OUT/'size_comparison_A_B.png')

reference=Image.open(SRC/'diseño general s2.2.png').convert('RGBA')
# Diagnostic only: retain the original platform and explicitly outline its region.
panels=[]
for label in ['A','B']:
    for stage,cx in [('LEFT',260),('CENTER',312),('RIGHT',365)]:
        panel=reference.crop((0,330,620,690)).convert('RGB')
        im=variants[label]
        panel.paste(im,(cx-im.width//2,440-330),im)
        draw=ImageDraw.Draw(panel)
        draw.rectangle((188,470-330,437,605-330),outline='yellow',width=2)
        draw.rectangle((cx-12,400-330,cx+11,439-330),outline='white',width=2)
        draw.text((5,5),f'{label} {stage} x={cx} top=440 | YELLOW: original still present',fill='white',stroke_width=1,stroke_fill='black')
        panels.append(panel)
canvas=Image.new('RGB',(1860,760),(25,25,30))
ImageDraw.Draw(canvas).text((12,8),'DIAGNOSTIC ONLY - background reconstruction pending. Not an approved corrected montage.',fill='yellow')
for i,p in enumerate(panels): canvas.paste(p,((i%3)*620,30+(i//3)*360))
canvas.save(OUT/'boarding_positions_DIAGNOSTIC.png')
after={p.name:hashlib.sha256(p.read_bytes()).hexdigest() for p in files}
assert before==after, 'Original changed'
report['validation']={'originals_unchanged':True,'platform_crop':bounds,'corrected_montage_created':False,'reason':'Exact source-to-reference background transform and occluded pixels not established. Diagnostic previews retain and mark original platform.'}
(OUT/'visual_asset_report.json').write_text(json.dumps(report,indent=2,ensure_ascii=False),encoding='utf-8')
print(json.dumps(report,indent=2,ensure_ascii=False))
