#!/bin/sh

phplemon parser.y
mv parser.php parser.plex
plex parser.plex
rm -f parser.out
rm -f parser.plex
php -w parser.php > parser-strip.php
mv parser-strip.php parser.php