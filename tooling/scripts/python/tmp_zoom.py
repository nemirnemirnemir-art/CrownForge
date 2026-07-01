from PIL import Image
from pathlib import Path
import sys

img_path = Path('assets/1.png')
scale = 3
if len(sys.argv) > 1:
    scale = int(sys.argv[1])

out_path = Path(f'assets/1_zoom{scale}.png')
img = Image.open(img_path)
resampling = getattr(Image, "Resampling", None)
resample_mode = resampling.NEAREST if resampling is not None else getattr(Image, "NEAREST", 0)
img = img.resize((img.width * scale, img.height * scale), resample_mode)
img.save(out_path)
print(f'saved {out_path} size={img.size}')
