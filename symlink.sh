#!/usr/bin/env bash

# Modify the WoWRep var so it match you own setup. Make sure you have it surrounded by double quotes
# WoWRep  : World of warcraft main directory
WoWRep="/Applications/World of Warcraft"
CWD=$(pwd)

# Don't touch anything bellow this if you aren't experienced
ln -s "$CWD/HeroLib" "$WoWRep/_retail_/Interface/AddOns/HeroLib"
ln -s "$CWD/HeroCache" "$WoWRep/_retail_/Interface/AddOns/HeroCache"
