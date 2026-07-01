from pathlib import Path
from PIL import Image
import sys

source = Path('assets/1_zoom6.png') if Path('assets/1_zoom6.png').exists() else Path('assets/1_zoom.png')
img = Image.open(source)
H = img.height
slices = int(sys.argv[1]) if len(sys.argv) > 1 else 12
h = H // slices
for i in range(slices):
    top = i * h
    bottom = (i + 1) * h if i < slices - 1 else H
    crop = img.crop((0, top, img.width, bottom))
    out = Path(f'assets/1_zoom_slice_{i+1}.png')
    crop.save(out)
    print(f'{out} : {top}-{bottom}')
