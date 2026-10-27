#!/bin/sh
# Builds the mod into build/deathlyhallows_<VERSION>.jar.
# The version matches the shader pack: taken from the INTRO_LINE1 comment in ../shaders/lib/intro.glsl.
cd "$(dirname "$0")"
VER=$(grep -m1 'INTRO_LINE1' ../shaders/lib/intro.glsl | grep -oE 'V[0-9]+(\.[0-9]+)+' | tr -d V)
[ -z "$VER" ] && { echo 'version not found in intro.glsl'; exit 1; }
NAME=deathlyhallows_$VER.jar

./gradlew --quiet build -Pmod_version="$VER" || { echo 'gradle build failed'; exit 1; }

rm -f build/deathlyhallows_*.jar
cp "build/libs/deathlyhallows-$VER.jar" "build/$NAME"
echo "done: build/$NAME"
