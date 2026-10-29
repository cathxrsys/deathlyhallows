#!/bin/sh
# Builds the shader pack zip into the Minecraft shaderpacks folder.
# The version is taken from the INTRO_LINE1 comment in lib/intro.glsl ("V2.0.3").
cd "$(dirname "$0")"
VER=$(grep -m1 'INTRO_LINE1' shaders/lib/intro.glsl | grep -oE 'V[0-9]+(\.[0-9]+)+' | tr -d V)
[ -z "$VER" ] && { echo 'version not found in intro.glsl'; exit 1; }
DIR=~/.minecraft/shaderpacks
NAME=deathlyhallows_$VER.zip

# remove old archives, carry saved settings over to the new name
for old in "$DIR"/deathlyhallows_*.zip; do
    [ -e "$old" ] && [ "$old" != "$DIR/$NAME" ] || continue
    [ -f "$old.txt" ] && [ ! -f "$DIR/$NAME.txt" ] && mv "$old.txt" "$DIR/$NAME.txt"
    rm -f "$old" "$old.txt"
done

# language files are generated from lang_src/*.txt; if the generator fails, leave the archive alone
python3 lang_src/gen.py > /dev/null || { echo 'lang generation failed'; exit 1; }

rm -f "$DIR/$NAME"
zip -rq "$DIR/$NAME" shaders

# point Iris at the new archive
CFG=~/.minecraft/config/iris.properties
[ -f "$CFG" ] && sed -i "s/^shaderPack=deathlyhallows_.*\.zip$/shaderPack=$NAME/" "$CFG"

echo "done: $NAME"
