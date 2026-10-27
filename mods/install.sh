#!/bin/sh
# Builds the mod and copies it into ~/.minecraft/mods, replacing older deathlyhallows jars.
cd "$(dirname "$0")"
./build.sh || exit 1
JAR=$(ls build/deathlyhallows_*.jar | head -n1)
DIR=~/.minecraft/mods

mkdir -p "$DIR"
rm -f "$DIR"/deathlyhallows_*.jar
cp "$JAR" "$DIR/"
echo "installed: $DIR/$(basename "$JAR")"
