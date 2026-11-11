#!/usr/bin/env python3
"""Validate all standalone vectors and render labeled review sheets using librsvg and Pillow."""
from pathlib import Path
from concurrent.futures import ThreadPoolExecutor
import json
import subprocess
import xml.etree.ElementTree as ET
from PIL import Image, ImageDraw, ImageFont

ROOT=Path(__file__).resolve().parent
CACHE=Path('/tmp/paroli-effect-icons')
FONT='/usr/share/fonts/noto/NotoSans-Regular.ttf'


def render(item):
    """Reject external dependencies and clipped silhouettes, then render native and small previews."""
    path=ROOT/item['file']
    xml=ET.parse(path).getroot()
    assert xml.attrib['viewBox']=='0 0 512 512',path
    for element in xml.iter():
        assert element.tag.split('}')[-1] not in {'image','script','text','filter','foreignObject'},path
        assert not any(key.endswith('href') for key in element.attrib),path
    output=CACHE/(item['id']+'.png')
    subprocess.run(['rsvg-convert','-o',str(output),str(path)],check=True)
    image=Image.open(output).convert('RGBA')
    box=image.getchannel('A').getbbox()
    assert box and min(box[:2])>12 and max(box[2:])<500,(path,box)
    return item,image


def write_sheet(items,filename,title):
    """A 240-pixel large preview plus a 48-pixel thumbnail exposes detail loss quickly."""
    cols=5;cw=300;ch=338;rows=(len(items)+cols-1)//cols
    image=Image.new('RGB',(cols*cw+40,rows*ch+110),'#eee9e2')
    draw=ImageDraw.Draw(image)
    draw.text((30,22),title,font=ImageFont.truetype(FONT,32),fill='#30223d')
    draw.text((32,67),'SVG review · EN / FR · small samples at 48 px',font=ImageFont.truetype(FONT,16),fill='#30223d')
    for index,(item,icon) in enumerate(items):
        x=20+(index%cols)*cw;y=104+(index//cols)*ch
        draw.rounded_rectangle((x+5,y,x+cw-7,y+ch-12),radius=16,fill='#fffaf0',outline='#30223d',width=2)
        preview=icon.resize((240,240),Image.Resampling.LANCZOS)
        image.paste(preview,(x+25,y+8),preview)
        small=icon.resize((48,48),Image.Resampling.LANCZOS)
        image.paste(small,(x+cw-65,y+225),small)
        for line,text in enumerate([item['en'],item['fr']]):
            size=19 if line==0 else 15
            while ImageFont.truetype(FONT,size).getlength(text)>cw-33:size-=1
            draw.text((x+17,y+269+line*27),text,font=ImageFont.truetype(FONT,size),fill='#30223d' if line==0 else '#74638a')
    image.save(ROOT/filename)


def main():
    CACHE.mkdir(exist_ok=True)
    items=json.loads((ROOT/'catalog.json').read_text())
    assert len(items)==57 and len({item['id'] for item in items})==57
    with ThreadPoolExecutor(max_workers=4) as pool:
        rendered=list(pool.map(render,items))
    write_sheet([pair for pair in rendered if pair[0]['family']=='Bonus'],'bonuses-review.png','29 bonuses')
    write_sheet([pair for pair in rendered if pair[0]['family']=='Joker'],'jokers-review.png','28 Jokers')
    for page in range(5):
        subset=rendered[page*12:(page+1)*12]
        # Additional spacious crops can be inspected without scaling a whole family sheet.
        write_sheet(subset,f'review-{page+1}.png',f'Icon details · {page+1}/5')
    print('PASS: 57 valid dependency-free SVGs; no edge clipping; seven review sheets rendered.')


if __name__=='__main__':main()
