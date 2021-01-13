#!/usr/bin/env bash

open_processes=""

# See https://visibleearth.nasa.gov/grid
grid="A1 B1 C1 D1 A2 B2 C2 D2"

background() {
 "$@"&
 pid="$!"
 open_processes="$open_processes $pid"
}

download() {
  destination="$1"
  source="$2"

  if [[ -f "$destination" ]]; then
    echo "Skipping $destination - file exists"
    return
  fi

  wget -O "$destination" "$source"
}

download_grid() {
  # The destination to the A1 cell (should contain "A1" in the name)
  first_destination="$1"
  # The source URL to the A1 cell (should contain "A1" in the name)
  first_source="$2"
  for cell in $grid; do
    source="$(sed "s/A1/$cell/" <<<"$first_source")"
    destination="$(sed "s/A1/$cell/" <<<"$first_destination")"
    download "$destination" "$source"
  done
}

# Require graphicsmagick
# > brew install graphicsmagick
merge_png_grid() {
  # The destination to the final image, should have the png file extension
  destination="$1"
  # The source URL to the A1 png cell (should contain "A1" in the name)
  first_source="$2"

  sources=""
  for cell in $grid; do
    source="$(sed "s/A1/$cell/" <<<"$first_source")"
    sources="$source $sources"
  done
  echo "Merging $destination from sources:"
  echo "$sources" | tr ' ' '\n'

  gm montage -monitor -density 300 -tile 4x0 $sources "$destination"
}

merge_tif_grid() {
  # The destination to the final image, should not have a file extension
  destination="$1"
  # The source URL to the A1 tif cell (should contain "A1" in the name)
  first_source="$2"

  sources=""
  for cell in $grid; do
    source="$(sed "s/A1/$cell/" <<<"$first_source")"
    sources="$source $sources"
  done
  echo "Merging $destination from sources:"
  echo "$sources" | tr ' ' '\n'

  gdalbuildvrt -o "$destination.vrt" $sources
  gdal_translate -of PNG -ot Byte -scale "$destination.vrt" "$destination.png"
}

wait_for_processes(){
  for pid in $open_processes; do
    while kill -0 "$pid" &>/dev/null; do
      sleep 0.5
    done
  done
}

cleanup () {
  for pid in $open_processes; do
    kill -9 "$pid" &>/dev/null
  done
}
trap cleanup EXIT

##
# Download Originals
download_originals() {
  mkdir -p data/textures/originals

  # Color map day
  # https://visibleearth.nasa.gov/images/73801/september-blue-marble-next-generation-w-topography-and-bathymetry
  background download_grid data/textures/originals/earth-color-map-day-A1.png https://eoimages.gsfc.nasa.gov/images/imagerecords/73000/73801/world.topo.bathy.200409.3x21600x21600.A1.png

  # Color map night
  # https://visibleearth.nasa.gov/images/144898/earth-at-night-black-marble-2016-color-maps
  background download_grid data/textures/originals/earth-color-map-night-A1.tif https://eoimages.gsfc.nasa.gov/images/imagerecords/144000/144898/BlackMarble_2016_A1_geo.tif

  # Bump map
  # https://visibleearth.nasa.gov/images/73934/topography
  background download_grid data/textures/originals/earth-bump-map-A1.tif https://eoimages.gsfc.nasa.gov/images/imagerecords/73000/73934/gebco_08_rev_elev_A1_grey_geo.tif

  # Clouds
  # https://visibleearth.nasa.gov/images/57747/blue-marble-clouds
  background download data/textures/originals/clouds-color-map.tif https://eoimages.gsfc.nasa.gov/images/imagerecords/57000/57747/cloud_combined_8192.tif

  # Clouds alt
  # https://1.bp.blogspot.com/-puWLaF31coQ/Ukb49iL_BgI/AAAAAAAAK-k/mI7c24mkpj8/s1600/fair_clouds_8k.jpg
  background download data/textures/originals/alternative-clouds-color-map.png https://1.bp.blogspot.com/-puWLaF31coQ/Ukb49iL_BgI/AAAAAAAAK-k/mI7c24mkpj8/s1600/fair_clouds_8k.jpg

  # Specular map
  # http://www.celestiamotherlode.net/catalog/earthbumpspec.html
  background download data/textures/originals/earth-specular-map.zip http://celestiamotherlode.net/creators/jestr/JestrEarthSpecular%20PNG.zip
}

##
# Merge grids
# Requires `gdal_translate`
# > brew install gdal
merge_grids() {
  mkdir -p data/textures/processed

  background ./scripts/merge-color-map.sh data/textures/originals/earth-color-map-day
  background ./scripts/merge-color-map.sh data/textures/originals/earth-color-map-night
  background merge_tif_grid data/textures/processed/earth-bump-map data/textures/originals/earth-bump-map-A1.tif
}

##
# Unpack specular map
unpack_specular_map() {
  unzip data/textures/originals/earth-specular-map.zip -d data/textures/originals/earth-specular-map "JestrEarthSpecular PNG/hires/JestrSpecular PNG/level5/*.png"
  python3 ./scripts/merge-specular-map.py 64 32 "data/textures/originals/earth-specular-map/JestrEarthSpecular PNG/hires/JestrSpecular PNG/level5/*.png"
}

# 1. Download
download_originals

# 2. Merge Grids
merge_grids

# 3. Unpack specular map
background unpack_specular_map

wait_for_processes
