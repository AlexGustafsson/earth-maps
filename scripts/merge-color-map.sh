#!/usr/bin/env bash

# Based off of https://www.ianturton.com/tutorials/bluemarble.html

# ./data/textures/originals/earth-color-map-day
prefix="$1"

left=-180
for i in A B C D; do
  right="$(($left + 90))"
  top=90
  for k in 1 2; do
    bottom="$(($top - 90))"
    input="$prefix-$i$k.png"
    output="$prefix-$i$k.tif"
    if [[ -f "$output" ]]; then
      echo "Skipping existing file: $output"
    else
      gdal_translate -of GTiff -co COMPRESS=JPEG -co PHOTOMETRIC=YCBCR -co TILED=yes -a_srs EPSG:4326 -a_ullr $left $top $right $bottom "$input" "$output"
    fi
  done
done

gdal_merge.py -o "$(echo "$prefix" | sed 's/originals/processed/').tif" -of GTiff -co "TILED=YES" -co COMPRESS=JPEG -co PHOTOMETRIC=YCBCR ./data/textures/processed/earth-color-map-day*.tif
