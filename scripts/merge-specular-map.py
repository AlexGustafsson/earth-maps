from sys import argv
from math import floor
from PIL import Image
import re

horizontal_tiles = int(argv[1])
vertical_tiles = int(argv[2])
inputs = argv[3:]

image = None
tile_width = None
tile_height = None

regex = re.compile("([0-9]+)_([0-9]+)\.png")
for input in inputs:
    y, x = regex.findall(input)[0]

    print("Loading {}: ".format(input), end="", flush=True)
    tile = Image.open(input)
    print(" ok ({}x{}px)".format(*tile.size))

    if image is None:
        print("Creating new image: ", end="", flush=True)
        tile_width, tile_height = tile.size
        image = Image.new("RGB", (tile_width * horizontal_tiles, tile_height * vertical_tiles), "black")
        print("ok ({}x{}px)".format(*image.size))

    print("Merging image: ", end="", flush=True)
    image.paste(tile, (int(y) * tile_width, int(x) * tile_height))
    print("ok")

print("Saving image: ", end="", flush=True)
image.save("./data/textures/processed/earth-specular-map.png", dpi=[300, 300])
print("ok")
